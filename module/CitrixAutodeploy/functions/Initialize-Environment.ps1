function Initialize-Environment {
    try {
        $Modules = @(
            "Citrix.ADIdentity.Commands",
            "Citrix.Broker.Commands",
            "Citrix.Common.Commands",
            "Citrix.ConfigurationLogging.Commands",
            "Citrix.Host.Commands",
            "Citrix.MachineCreation.Commands"
        )

        $Modules | Import-Module -DisableNameChecking -Force -ErrorAction Stop -WarningAction SilentlyContinue
    }
    catch {
        Write-CitrixAutoDeployLog -Message $_.Exception -EventId 1 -EntryType Error
        throw $_
    }

    if ($env:CI) {
        return
    }

    # if (Get-EventLog -LogName 'Citrix Autodeploy' -ErrorAction SilentlyContinue) {
    #     return
    # } else {
    #     throw "'Citrix Autodeploy' event log not found. Please run setup.ps1 to create it."
    # }

    if ((Get-EventLog -List).Log -notcontains 'Citrix Autodeploy') {
        #Write-CitrixAutoDeployLog -Message "'Citrix Autodeploy' event log not found. Please run setup.ps1 to create it." -EventId 1 -EntryType Error
        exit 1
    }
}
