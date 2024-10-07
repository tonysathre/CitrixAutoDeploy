#Requires -Modules PoShLog

param (
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [System.IO.FileInfo]$ConfigFilePath = $env:CITRIX_AUTODEPLOY_CONFIG,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [ValidateSet('Verbose', 'Debug', 'Information', 'Warning', 'Error', 'Fatal')]
    [string]$LogLevel = $env:CITRIX_AUTODEPLOY_LOGLEVEL,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [System.IO.FileInfo]$LogFile = $env:CITRIX_AUTODEPLOY_LOGFILE
)

Write-VerboseLog -Message "Citrix Autodeploy started via {MyCommand} with parameters: {PSBoundParameters}" -PropertyValues $MyInvocation.MyCommand.Source, ($PSBoundParameters | Out-String)

if (-not $LogLevel) {
    $LogLevel = 'Information'
}

Import-Module ${PSScriptRoot}\module\CitrixAutodeploy -Force -ErrorAction Stop -DisableNameChecking -Scope Local -WarningAction SilentlyContinue 4> $null

$Logger = Initialize-CtxAutodeployLogger -LogLevel $LogLevel -LogFile $LogFile

Initialize-Environment

$Config = Get-CtxAutodeployConfig -FilePath $ConfigFilePath

foreach ($AutodeployMonitor in $Config.AutodeployMonitors.AutodeployMonitor) {
    Write-InfoLog -Message "Starting job: {AutodeployMonitor}" -PropertyValues $AutodeployMonitor

    $AdminAddress  = $AutodeployMonitor.AdminAddress
    $BrokerCatalog = Get-BrokerCatalog -AdminAddress $AdminAddress -Name $AutodeployMonitor.BrokerCatalog
    $DesktopGroup  = Get-BrokerDesktopGroup -AdminAddress $AdminAddress -Name $AutodeployMonitor.DesktopGroupName
    $PreTask       = $AutodeployMonitor.PreTask
    $PostTask      = $AutodeployMonitor.PostTask

    try {
        $UnassignedMachines = Get-BrokerMachine -AdminAddress $AdminAddress -DesktopGroupName $DesktopGroup.Name -IsAssigned $false
    }
    catch {
        Write-ErrorLog -Message "Failed to get unassigned machines for desktop group '{DesktopGroupName}'" -Exception $_.Exception -ErrorRecord $_ -PropertyValues $AutodeployMonitor.DesktopGroupName
        continue
    }

    $MachinesToAdd = $AutodeployMonitor.MinAvailableMachines - $UnassignedMachines.Count

    if ($MachinesToAdd -le 0) {
        Write-InfoLog -Message ("No machines to add to catalog '{BrokerCatalog}'") -PropertyValues $BrokerCatalog.Name
        continue
    }

    Write-VerboseLog -Message "Adding '{MachinesToAdd}' machines to catalog '{BrokerCatalog}'" -PropertyValues $MachinesToAdd, $BrokerCatalog.Name
    while ($MachinesToAdd -gt 0) {
        try {
            if ($PreTask) {
                $PreTaskArgs = @{
                    'AutodeployMonitor' = $AutodeployMonitor
                    'DesktopGroup'      = $DesktopGroup
                    'BrokerCatalog'     = $BrokerCatalog
                }
                Write-VerboseLog -Message "Invoking pre-task '{PreTask}'" -PropertyValues $PreTask
                Invoke-CtxAutodeployTask -FilePath $PreTask -Type Pre -Context "Catalog: $($BrokerCatalog.Name), DesktopGroup: $($DesktopGroup.Name)" -ArgumentList $PreTaskArgs
            }

            $NewVMParams = @{
                AdminAddress  = $AdminAddress
                BrokerCatalog = $BrokerCatalog
                DesktopGroup  = $DesktopGroup
            }
            Write-VerboseLog -Message "Creating new machine for catalog '{BrokerCatalog}'" -PropertyValues $BrokerCatalog.Name
            $NewBrokerMachine = New-CtxAutodeployVM @NewVMParams

            if ($PostTask) {
                $PostTaskArgs = @{
                    'AutodeployMonitor' = $AutodeployMonitor
                    'DesktopGroup'      = $DesktopGroup
                    'BrokerCatalog'     = $BrokerCatalog
                    'NewBrokerMachine'  = $NewBrokerMachine
                }
                Write-VerboseLog -Message "Invoking post-task '{PostTask}'" -PropertyValues $PostTask
                Invoke-CtxAutodeployTask -FilePath $PostTask -Type Post -Context $NewBrokerMachine.MachineName -ArgumentList $PostTaskArgs
            }

            $MachinesToAdd--
        }
        catch {
            Write-ErrorLog -Message "An error occurred while adding a machine to catalog '{0}'" -Exception $_.Exception -ErrorRecord $_ -PropertyValues $BrokerCatalog.Name
            continue
        }
        finally {
            $Logger | Close-Logger
        }
    }
}
