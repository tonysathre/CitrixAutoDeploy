[CmdletBinding()]
param (
    [string]$ConfigFilePath = $env:CITRIX_AUTODEPLOY_CONFIG
)

Import-Module ${PSScriptRoot}\module\CitrixAutodeploy -Force -ErrorAction Stop -DisableNameChecking -Scope Local -WarningAction SilentlyContinue

Initialize-Environment

if (-not $ConfigFilePath) {
    Join-Path $PSScriptRoot 'citrix_autodeploy_config.json'
}

$Config = Get-CtxAutodeployConfig -FilePath $ConfigFilePath

foreach ($AutodeployMonitor in $Config.AutodeployMonitors.AutodeployMonitor) {
    $MonitorDetails = ($AutodeployMonitor | Format-List | Out-String).TrimEnd()

    Write-CtxAutodeployLog -Message "Autodeploy job started: ${MonitorDetails}`n" -EventId 0 -EntryType Information

    $AdminAddress       = $AutodeployMonitor.AdminAddress
    $BrokerCatalog      = Get-BrokerCatalog -AdminAddress $AdminAddress -Name $AutodeployMonitor.BrokerCatalog
    $DesktopGroup       = Get-BrokerDesktopGroup -AdminAddress $AdminAddress -Name $AutodeployMonitor.DesktopGroupName
    $PreTask            = $AutodeployMonitor.PreTask
    $PostTask           = $AutodeployMonitor.PostTask

    try {
        $UnassignedMachines = Get-BrokerMachine -AdminAddress $AdminAddress -DesktopGroupName $DesktopGroup.Name -IsAssigned $false
    }
    catch {
        Write-CtxAutodeployLog -Message "$($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message): $($_.Exception.InnerException)" -EventId 1 -EntryType Error
        break
    }

    $MachinesToAdd = $AutodeployMonitor.MinAvailableMachines - $UnassignedMachines.Count

    if ($MachinesToAdd -le 0) {
        Write-CtxAutodeployLog -Message "No machines to add.`n" -EventId 0 -EntryType Information
        continue
    }

    Write-Verbose ("Adding {0} machines to catalog '{1}'" -f $MachinesToAdd, $($BrokerCatalog.Name))
    while ($MachinesToAdd -gt 0) {
        try {
            if ($PreTask) {
                $PreTaskArgs = @{
                    'AutodeployMonitor' = $AutodeployMonitor
                    'DesktopGroup'      = $DesktopGroup
                    'BrokerCatalog'     = $BrokerCatalog
                }
                Invoke-CtxAutodeployTask -Task $PreTask -Type Pre -Context "Catalog: $($BrokerCatalog.Name), DesktopGroup: $($DesktopGroup.Name)" -ArgumentList $PreTaskArgs
            }

            $NewVMParams = @{
                AdminAddress  = $AdminAddress
                BrokerCatalog = $BrokerCatalog
                DesktopGroup  = $DesktopGroup
            }
            $NewBrokerMachine = New-CtxAutodeployVM @NewVMParams

            if ($PostTask) {
                $PostTaskArgs = @{
                    'AutodeployMonitor' = $AutodeployMonitor
                    'DesktopGroup'      = $DesktopGroup
                    'BrokerCatalog'     = $BrokerCatalog
                    'NewBrokerMachine'  = $NewBrokerMachine
                }
                Invoke-CtxAutodeployTask -Task $PostTask -Type Post -Context $NewBrokerMachine.MachineName -ArgumentList $PostTaskArgs
            }

            $MachinesToAdd--
        }
        catch {
            Write-CtxAutodeployLog -Message "$($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message): $($_.Exception.InnerException)" -EventId 1 -EntryType Error
            break
        }
    }
}
