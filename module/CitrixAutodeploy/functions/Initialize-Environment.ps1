function Initialize-Environment {
    $Modules = @(
        "Citrix.ADIdentity.Commands",
        "Citrix.Broker.Commands",
        "Citrix.ConfigurationLogging.Commands",
        "Citrix.MachineCreation.Commands"
    )

    try {
        Import-Module $Modules -DisableNameChecking -Force -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null
    }
    catch {
        Write-CtxAutodeployLog -Message $_.Exception -EventId 1 -EntryType Error
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

    $EventLogs = Get-EventLog -List
    if (($EventLogs).Log -notcontains 'Citrix Autodeploy') {
        Write-CtxAutodeployLog -Message "'Citrix Autodeploy' event log not found. Please run setup.ps1 to create it." -EventId 1 -EntryType Error
        throw $_
    }
}
