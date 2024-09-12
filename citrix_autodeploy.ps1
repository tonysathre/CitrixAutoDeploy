[CmdletBinding()]
param (
    [string]$ConfigFilePath = $env:CITRIX_AUTODEPLOY_CONFIG
)

Import-Module ${PSScriptRoot}\module\CitrixAutodeploy -Force -ErrorAction Stop -DisableNameChecking -Scope Local -WarningAction SilentlyContinue

Initialize-Environment

if (-not $ConfigFilePath) {
    Join-Path $PSScriptRoot 'citrix_autodeploy_config.json'
}

$Config = Get-Config -FilePath $ConfigFilePath

foreach ($AutodeployMonitor in $Config.AutodeployMonitors.AutodeployMonitor) {
    $MonitorDetails = $AutodeployMonitor | Format-List | Out-String
    Write-CitrixAutoDeployLog -Message "Autodeploy job started: $MonitorDetails" -EventId 0 -EntryType Information

    try {
        $AdminAddress       = $AutodeployMonitor.AdminAddress
        $BrokerCatalog      = Get-BrokerCatalog -AdminAddress $AdminAddress -Name $AutodeployMonitor.BrokerCatalog
        $DesktopGroupName   = Get-BrokerDesktopGroup -AdminAddress $AdminAddress -Name $AutodeployMonitor.DesktopGroupName
        $UnassignedMachines = Get-BrokerDesktop -AdminAddress $AdminAddress -DesktopGroupName $DesktopGroupName.Name -IsAssigned $false
        $MachinesToAdd      = $AutodeployMonitor.MinAvailableMachines - $UnassignedMachines.Count
        $PreTask            = $AutodeployMonitor.PreTask
        $PostTask           = $AutodeployMonitor.PostTask
    }
    catch {
        Write-CitrixAutoDeployLog -Message "$($_.Exception.Message)`n`n$($_.Exception.StackTrace)" -EventId 1 -EntryType Error
        break
    }
    write-host "Machines to add: $MachinesToAdd"
    while ($MachinesToAdd -gt 0) {
        try {
            Add-Machine -AdminAddress $AdminAddress -BrokerCatalog $BrokerCatalog -DesktopGroup $DesktopGroup -PreTask $PreTask -PostTask $PostTask
            $MachinesToAdd--
        }
        catch {
            Write-CitrixAutoDeployLog -Message "$($_.Exception.Message)`n`n$($_.Exception.StackTrace)" -EventId 1 -EntryType Error
            break
        }
    }
}
