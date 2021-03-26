# Citrix Autodeploy for MCS
Monitors Citrix MCS delivery groups and automatically creates machines based on the number of machines you want always available to be assigned to users. The main goal of this is to eliminate the need to monitor your delivery groups and manually spin up machines when there aren't any left to be assigned.

## Prerequisites
#### General
* Windows Server 2012+
* Powershell 5.1+
* Citrix (CVAD) Powershell snapins

#### Active Directory
Active Directory service account with permissions to create computer objects in the OU's used by your machine catalogs. See [this](https://support.citrix.com/article/CTX136282) link for details on the required Active Directory permissions.

#### Citrix Studio
The Active Directory service account will need at least the 'Machine Catalog Administrator' role, and possibly the 'Delivery Group Administrator' role. This still needs to be tested to find the least privileges required.


## Setup
_I would not recommend running this directly on one of your delivery controllers. I run this on a management jump box._
Start Powershell as Administrator then run the following commands:
    
    git clone https://github.com/tonysathre/CitrixAutoDeploy.git
    cd CitrixAutoDeploy
    .\setup.ps1

The setup script performs the following:
* Create an Applications and Services event log called Citrix Autodeploy
* Create three scheduled tasks
  * Citrix Autodeploy
  * Citrix Autodeploy Error Monitor
  * Citrix Autodeploy Machine Creation Monitor
* Delegate the SeBatchLogonRight (Logon as a batch job) privilege to the Active Directory service account on the local machine


#### Configuration
You will need to configure which machine catalogs and delivery groups you want to monitor in the file [`citrix_autodeploy_config.json`](citrix_autodeploy_config.json). The example config file that's included contains the following:
````{
    "AutodeployMonitors" : {
        "AutodeployMonitor": [
            {
                "AdminAddress" : "ddc1.example.com",
                "BrokerCatalog" : "Example Machine Catalog",
                "DesktopGroupName" : "Example Delivery Group",
                "MinAvailableMachines" : 5
            },
            {
                "AdminAddress" : "ddc2.example.com",
                "BrokerCatalog" : "Example Machine Catalog",
                "DesktopGroupName" : "Example Delivery Group",
                "MinAvailableMachines" : 1
            }
        ]
    }
}
````
|Attribute|Description|
|--- | ---|
|AdminAddress         | Delivery controller FQDN
|BrokerCatalog        | Machine catalog name
|DesktopGroupName     | Delivery group name
|MinAvailableMachines | How many machines you want to be available at all times

MinAvailableMachines works by checking how many **unassigned** machines there are in the delivery group. It then subtracts that number from MinAvailableMachines to determine how many machines it must create to satisfy the configured MinAvailableMachines.

#### Email alerts
For email alerts to function you must configure the included [`citrix_autodeploy_monitor_error.ps1`](citrix_autodeploy_monitor_error.ps1) and [`citrix_autodeploy_monitor_machine_creation.ps1`](citrix_autodeploy_monitor_machine_creation.ps1) scripts. You may also need to allow the machine running Citrix Autodeploy to relay email through your SMTP server.

#### Pre and post deployment tasks
When I get time I will be adding a feature that will allow running scripts or code before and after a machine is created. In the meantime this can be accomplished by modifying the [`citrix_autodeploy.ps1`](citrix_autodeploy.ps1) file directly. I have in that script some post-tasks that put the machine in maintenance mode and then power it on, but they're commented out as those are specific to our environment.

This will probably look something like one of the following but I haven't decided what the best way to handle this is (open to suggestions but am leaning towards the first one):

````{
    "AutodeployMonitors" : {
        "AutodeployMonitor": [
            {
                "AdminAddress" : "ddc1.example.com",
                "BrokerCatalog" : "Example Machine Catalog",
                "DesktopGroupName" : "Example Delivery Group",
                "MinAvailableMachines" : 5
                "PreTask" : .\pre-task\script.ps1
                "PostTask : .\post-task\script.ps1
            }
        ]
    }
}
````

or

````{
    "AutodeployMonitors" : {
        "AutodeployMonitor": [
            {
                "AdminAddress" : "ddc1.example.com",
                "BrokerCatalog" : "Example Machine Catalog",
                "DesktopGroupName" : "Example Delivery Group",
                "MinAvailableMachines" : 5
                "PreTask" : {ScriptBlock}
                "PostTask : {ScriptBlock}
            }
        ]
    }
}
````