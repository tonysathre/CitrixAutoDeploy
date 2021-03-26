# Citrix Autodeploy for MCS
Monitors Citrix MCS delivery groups and automatically creates machines based on the number of machines you want always available to be assigned to users. The main goal of this is to eliminate the need to monitor your delivery groups and manually spin up machines when there aren't any left to be assigned.

## Prerequisites
#### General
* Windows Server 2012+
* Powershell 5.1+
* Citrix (CVAD) Powershell snapins 1912 LTSR

_Older versions may work but only these were tested_

#### Active Directory
Active Directory service account with permissions to create computer objects in the OU's used by your machine catalogs. See [this](https://support.citrix.com/article/CTX136282) link for details on the required Active Directory permissions.

#### Citrix Studio
The Active Directory service account will need the 'Machine Catalog Administrator' and 'Delivery Group Administrator' roles.

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

The scheduled task settings can be modified in Task Scheduler

#### Configuration
You will need to configure which machine catalogs and delivery groups you want to monitor in the file [`citrix_autodeploy_config.json`](citrix_autodeploy_config.json). The example config file that's included contains the following:
````
{
	"AutodeployMonitors" : {
		"AutodeployMonitor": [
            {
                "AdminAddress" : "ddc1.example.com",
				"BrokerCatalog" : "Example Machine Catalog",
                "DesktopGroupName" : "Example Delivery Group",
                "MinAvailableMachines" : 5,
                "PreTask" : ".\\pre-task\\pre-task-example.ps1",
                "PostTask" : ".\\post-task\\enable-maintenance-mode.ps1"
            },
			{
                "AdminAddress" : "ddc2.example.com",
				"BrokerCatalog" : "Example Machine Catalog",
                "DesktopGroupName" : "Example Delivery Group",
                "MinAvailableMachines" : 1,
                "PreTask" : "",
                "PostTask" : ""
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
|PreTask              | Script or command-line to run before creating a new machine
|PostTask             | Script or command-line to run after creating a new machine

MinAvailableMachines works by checking how many **unassigned** machines there are in the delivery group. It then subtracts that number from MinAvailableMachines to determine how many machines it must create to satisfy the configured MinAvailableMachines.

#### Email alerts
For email alerts to function you must configure the included [`citrix_autodeploy_monitor_error.ps1`](citrix_autodeploy_monitor_error.ps1) and [`citrix_autodeploy_monitor_machine_creation.ps1`](citrix_autodeploy_monitor_machine_creation.ps1) scripts. You may also need to allow the machine running Citrix Autodeploy to relay email through your SMTP server.

#### Pre and post deployment tasks
You can define a script or command-line to run in the [`citrix_autodeploy_config.json`](citrix_autodeploy_config.json) before each machine is created, and after each machine is created. This can be useful for things such as putting a machine in maintenance mode or registering it with your CMDB.