#Requires -Modules PoShLog

param (
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [System.IO.FileInfo]$FilePath = $env:CITRIX_AUTODEPLOY_CONFIG,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [ValidateSet('Verbose', 'Debug', 'Information', 'Warning', 'Error', 'Fatal')]
    [string]$LogLevel = $env:CITRIX_AUTODEPLOY_LOGLEVEL,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [System.IO.FileInfo]$LogFile = $env:CITRIX_AUTODEPLOY_LOGFILE
)

if (-not $LogLevel) {
    $LogLevel = 'Information'
}

Import-Module ${PSScriptRoot}\module\CitrixAutodeploy -Force -ErrorAction Stop -DisableNameChecking -Scope Local -WarningAction SilentlyContinue 4> $null

$Logger = Initialize-CtxAutodeployLogger -LogLevel $LogLevel -LogFile $LogFile

Write-DebugLog -Message "Citrix Autodeploy started via {MyCommand} with parameters: {PSBoundParameters}" -PropertyValues $MyInvocation.MyCommand.Source, ($PSBoundParameters | Out-String)

Initialize-Environment

$Config = Get-CtxAutodeployConfig -FilePath $FilePath

foreach ($AutodeployMonitor in $Config.AutodeployMonitors.AutodeployMonitor) {
    Write-InfoLog -Message "Starting job: {AutodeployMonitor}" -PropertyValues $AutodeployMonitor

    $AdminAddress = $AutodeployMonitor.AdminAddress
    $PreTask      = $AutodeployMonitor.PreTask
    $PostTask     = $AutodeployMonitor.PostTask

    try {
        $BrokerCatalog = Get-BrokerCatalog -AdminAddress $AdminAddress -Name $AutodeployMonitor.BrokerCatalog
    }
    catch {
        Write-ErrorLog -Message "Failed to read catalog '{BrokerCatalog}' from delivery controller '{DeliveryController}'" -Exception $_.Exception -ErrorRecord $_ -PropertyValues $AutodeployMonitor.BrokerCatalog, $AutodeployMonitor.AdminAddress
        continue
    }

    try {
        $DesktopGroup = Get-BrokerDesktopGroup -AdminAddress $AdminAddress -Name $AutodeployMonitor.DesktopGroupName
    }
    catch [Citrix.Broker.Admin.SDK.SdkOperationException] {
        Write-ErrorLog -Message "Failed to read catalog '{DesktopGroupName}' from delivery controller '{DeliveryController}'" -Exception $_.Exception -ErrorRecord $_ -PropertyValues $AutodeployMonitor.BrokerCatalog, $AutodeployMonitor.DesktopGroupName, $AutodeployMonitor.AdminAddress
        continue
    }

    try {
        $UnassignedMachines = Get-BrokerMachine -AdminAddress $AdminAddress -DesktopGroupName $DesktopGroup.Name -IsAssigned $false
    }
    catch {
        Write-ErrorLog -Message "Failed to get unassigned machines for desktop group '{DesktopGroupName}' from delivery controller '{DeliveryController}'" -Exception $_.Exception -ErrorRecord $_ -PropertyValues $AutodeployMonitor.DesktopGroupName, $AutodeployMonitor.AdminAddress
        continue
    }

    $MachinesToAdd = $AutodeployMonitor.MinAvailableMachines - $UnassignedMachines.Count

    if ($MachinesToAdd -le 0) {
        Write-InfoLog -Message ("No machines to add to catalog '{BrokerCatalog}'") -PropertyValues $BrokerCatalog.Name
        continue
    }

    Write-DebugLog -Message "Adding '{MachinesToAdd}' machines to catalog '{BrokerCatalog}'" -PropertyValues $MachinesToAdd, $BrokerCatalog.Name
    while ($MachinesToAdd -gt 0) {
        if ($PreTask) {
            $PreTaskArgs = @{
                'AutodeployMonitor' = $AutodeployMonitor
                'DesktopGroup'      = $DesktopGroup
                'BrokerCatalog'     = $BrokerCatalog
            }

            Write-VerboseLog -Message "Invoking pre-task '{PreTask}'" -PropertyValues $PreTask

            try {
                Invoke-CtxAutodeployTask -FilePath $PreTask -Type Pre -Context "Catalog: $($BrokerCatalog.Name), DesktopGroup: $($DesktopGroup.Name)" -ArgumentList $PreTaskArgs
            }
            catch {
                continue
            }
            finally {
                $MachinesToAdd--
            }
        }

        $NewVMParams = @{
            AdminAddress  = $AdminAddress
            BrokerCatalog = $BrokerCatalog
            DesktopGroup  = $DesktopGroup
        }

        Write-VerboseLog -Message "Creating new machine for catalog '{BrokerCatalog}'" -PropertyValues $BrokerCatalog.Name

        try {
            $NewBrokerMachine = New-CtxAutodeployVM @NewVMParams
        }
        catch {
            Write-ErrorLog -Message "An error occurred while adding a machine to catalog '{0}'" -Exception $_.Exception -ErrorRecord $_ -PropertyValues $BrokerCatalog.Name
            continue
        }
        finally {
            $MachinesToAdd--
        }

        if ($PostTask) {
            $PostTaskArgs = @{
                'AutodeployMonitor' = $AutodeployMonitor
                'DesktopGroup'      = $DesktopGroup
                'BrokerCatalog'     = $BrokerCatalog
                'NewBrokerMachine'  = $NewBrokerMachine
            }
        }

        Write-InfoLog -Message "Invoking post-task '{PostTask}'" -PropertyValues $PostTask

        try {
            Invoke-CtxAutodeployTask -FilePath $PostTask -Type Post -Context $NewBrokerMachine.MachineName -ArgumentList $PostTaskArgs
        }
        catch {
            continue
        }
        finally {
            $MachinesToAdd--
        }
    }
}

if ($InternalLogger) {
    Write-VerboseLog -Message 'Closing internal logger'
    $InternalLogger | Close-Logger
}

Write-VerboseLog -Message 'Closing logger'
$Logger | Close-Logger
