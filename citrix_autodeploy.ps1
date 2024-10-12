﻿#Requires -Modules PoShLog

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
    [System.IO.FileInfo]$LogFile = $env:CITRIX_AUTODEPLOY_LOGFILE,

    [Parameter()]
    $MaxRecordCount = $(if ($env:CITRIX_AUTODEPLOY_MAXRECORDCOUNT) { $env:CITRIX_AUTODEPLOY_MAXRECORDCOUNT } else { 10000 }),

    [Parameter()]
    [switch]$DryRun = [System.Convert]::ToBoolean($env:CITRIX_AUTODEPLOY_DRYRUN),

    [Parameter()]
    [string]$LogOutputTemplate = '[{Timestamp:yyyy-MM-dd HH:mm:ss.fff}] [{Level:u3}] {Message:lj}{NewLine}{Exception}'
)

if ($DryRun) {
    $LogOutputTemplate = '[{Timestamp:yyyy-MM-dd HH:mm:ss.fff}] [{Level:u3}] [DRYRUN] {Message:lj}{NewLine}{Exception}'
}

if (-not $LogLevel) {
    $LogLevel = 'Information'
}

Import-Module ${PSScriptRoot}\module\CitrixAutodeploy -Force -ErrorAction Stop -DisableNameChecking -Scope Local -WarningAction SilentlyContinue 4> $null

$Logger = Initialize-CtxAutodeployLogger -LogLevel $LogLevel -LogFile $LogFile -LogOutputTemplate $LogOutputTemplate

Write-DebugLog -Message "Citrix Autodeploy started via {MyCommand} with parameters: {PSBoundParameters}" -PropertyValues $MyInvocation.MyCommand.Source, ($PSBoundParameters | Out-String)

Initialize-Environment

$Config = Get-CtxAutodeployConfig -FilePath $FilePath

foreach ($AutodeployMonitor in $Config.AutodeployMonitors.AutodeployMonitor) {
    Write-InfoLog -Message "Starting job:`n{AutodeployMonitor}" -PropertyValues ($AutodeployMonitor | ConvertTo-Json)

    foreach ($Ddc in $AutodeployMonitor.AdminAddress) {
        if (Test-DdcConnection -AdminAddress $Ddc -Protocol 'https') {
            $AdminAddress = $Ddc
            Write-DebugLog -Message "Using delivery controller {Ddc}" -PropertyValues $Ddc
            break
        }
    }

    if (-Not $AdminAddress) {
        Write-ErrorLog -Message "Failed to connect to any of the configured delivery controllers"
        continue
    }

    $PreTask  = $AutodeployMonitor.PreTask
    $PostTask = $AutodeployMonitor.PostTask

    try {
        $BrokerCatalog = Get-BrokerCatalog -AdminAddress $AdminAddress -Name $AutodeployMonitor.BrokerCatalog -MaxRecordCount $MaxRecordCount
    }
    catch {
        Write-ErrorLog -Message "Failed to read catalog {BrokerCatalog} from delivery controller {DeliveryController}" -Exception $_.Exception -ErrorRecord $_ -PropertyValues $AutodeployMonitor.BrokerCatalog, $AutodeployMonitor.AdminAddress
        continue
    }

    if ($AutodeployMonitor.MaxMachinesInBrokerCatalog) {
        if (Test-MachineCountLimit -AdminAddress $AdminAddress -InputObject $BrokerCatalog -MaxMachines $AutodeployMonitor.MaxMachinesInBrokerCatalog -MaxRecordCount $MaxRecordCount) {
            Write-WarningLog -Message "Max machine count ({MaxMachinesInBrokerCatalog}) reached for catalog {BrokerCatalog}" -PropertyValues $AutodeployMonitor.MaxMachinesInDesktopGroup, $BrokerCatalog.Name
            continue
        }
    }

    try {
        $DesktopGroup = Get-BrokerDesktopGroup -AdminAddress $AdminAddress -Name $AutodeployMonitor.DesktopGroupName
    }
    catch {
        Write-ErrorLog -Message "Failed to read desktop group {DesktopGroupName} from delivery controller {DeliveryController}" -Exception $_.Exception -ErrorRecord $_ -PropertyValues $AutodeployMonitor.BrokerCatalog, $AutodeployMonitor.DesktopGroupName, $AutodeployMonitor.AdminAddress
        continue
    }

    if ($AutodeployMonitor.MaxMachinesInDesktopGroup) {
        if (Test-MachineCountLimit -AdminAddress $AdminAddress -InputObject $DesktopGroup -MaxMachines $AutodeployMonitor.MaxMachinesInDesktopGroup -MaxRecordCount $MaxRecordCount) {
            Write-WarningLog -Message "Max machine count ({MaxMachinesInDesktopGroup}) reached for desktop group {DesktopGroup}" -PropertyValues $AutodeployMonitor.MaxMachinesInDesktopGroup, $DesktopGroup.Name
            continue
        }
    }

    try {
        $UnassignedMachines = Get-BrokerMachine -AdminAddress $AdminAddress -DesktopGroupName $DesktopGroup.Name -IsAssigned $false -MaxRecordCount $MaxRecordCount
        Write-DebugLog -Message "{UnassignedMachines} unassigned machines in desktop group {DesktopGroupName}" -PropertyValues $UnassignedMachines.Count, $DesktopGroup.Name
    }
    catch {
        Write-ErrorLog -Message "Failed to get unassigned machines for desktop group {DesktopGroupName} from delivery controller {DeliveryController}" -Exception $_.Exception -ErrorRecord $_ -PropertyValues $AutodeployMonitor.DesktopGroupName, $AutodeployMonitor.AdminAddress
        continue
    }

    $MachinesToAdd = $AutodeployMonitor.MinAvailableMachines - $UnassignedMachines.Count

    if ($MachinesToAdd -le 0) {
        Write-InfoLog -Message "No machines to add to catalog {BrokerCatalog}" -PropertyValues $BrokerCatalog.Name
        continue
    }

    Write-DebugLog -Message "Adding {MachinesToAdd} machines to catalog {BrokerCatalog}" -PropertyValues $MachinesToAdd, $BrokerCatalog.Name
    while ($MachinesToAdd -gt 0) {
        try {
            $CtxHighLevelLoggerParams = @{
                AdminAddress = $AdminAddress
                Source       = 'Citrix Autodeploy'
                Text         = "Citrix Autodeploy: Adding 1 machine: Catalog: '$($BrokerCatalog.Name)', DesktopGroup: $($DesktopGroup.Name)"
            }

            if (-not $DryRun) {
                $Logging = Start-CtxHighLevelLogger @CtxHighLevelLoggerParams
            }
        }
        catch {
            Write-ErrorLog -Message "Failed to start high-level logging operation" -Exception $_.Exception -ErrorRecord $_
            continue
        }

        $IsSuccessful = $true

        if ($PreTask) {
            $ArgumentList = @{
                'AutodeployMonitor' = $AutodeployMonitor
                'AdminAddress'      = $AdminAddress
                'DesktopGroup'      = $DesktopGroup
                'BrokerCatalog'     = $BrokerCatalog
                'Logging'           = $Logging
            }

            try {
                $CtxAutodeployTask = @{
                    FilePath     = $PreTask
                    Type         = 'Pre'
                    Context      = "Catalog: $($BrokerCatalog.Name), DesktopGroup: $($DesktopGroup.Name)"
                    ArgumentList = $ArgumentList
                }

                Write-InfoLog -Message "Invoking pre-task {PreTask}" -PropertyValues $PreTask
                if (-not $DryRun) {
                    Invoke-CtxAutodeployTask @CtxAutodeployTask
                }
            }
            catch {
                $IsSuccessful = $false
                if (-not $DryRun) {
                    Stop-CtxHighLevelLogger -AdminAddress $AdminAddress -Logging $Logging.Id -IsSuccessful $IsSuccessful
                }
                continue
            }
        }

        $NewVMParams = @{
            AdminAddress  = $AdminAddress
            BrokerCatalog = $BrokerCatalog
            DesktopGroup  = $DesktopGroup
            Logging       = $Logging
        }

        try {
            Write-InfoLog -Message "Creating new machine for catalog {BrokerCatalog}" -PropertyValues $BrokerCatalog.Name
            if (-not $DryRun) {
                $NewBrokerMachine = New-CtxAutodeployVM @NewVMParams
            }
        }
        catch {
            Write-ErrorLog -Message "An error occurred while adding a machine to catalog {BrokerCatalog}" -Exception $_.Exception -ErrorRecord $_ -PropertyValues $BrokerCatalog.Name
            $IsSuccessful = $false

            if (-not $DryRun) {
                Stop-CtxHighLevelLogger -AdminAddress $AdminAddress -Logging $Logging -IsSuccessful $IsSuccessful
            }

            continue
        }
        finally {
            $MachinesToAdd--
        }

        if ($PostTask) {
            $PostTaskArgs = @{
                'AutodeployMonitor' = $AutodeployMonitor
                'AdminAddress'      = $AdminAddress
                'DesktopGroup'      = $DesktopGroup
                'BrokerCatalog'     = $BrokerCatalog
                'NewBrokerMachine'  = $NewBrokerMachine
                'Logging'           = $Logging
            }
        }

        try {
            Write-InfoLog -Message "Invoking post-task {PostTask}" -PropertyValues $PostTask
            if (-not $DryRun) {
                Invoke-CtxAutodeployTask -FilePath $PostTask -Type Post -Context $NewBrokerMachine.MachineName -ArgumentList $PostTaskArgs
            }
        }
        catch {
            $IsSuccessful = $false

            if (-not $DryRun) {
                Stop-CtxHighLevelLogger -AdminAddress $AdminAddress -Logging $Logging -IsSuccessful $IsSuccessful
            }

            continue
        }

        if (-not $DryRun) {
            Stop-CtxHighLevelLogger -AdminAddress $AdminAddress -Logging $Logging -IsSuccessful $IsSuccessful
        }
    }

    Write-InfoLog -Message "Job completed successfully"
}

if ($InternalLogger) {
    Write-VerboseLog -Message 'Closing internal PoShLog logger'
    $InternalLogger | Close-Logger
}

Write-VerboseLog -Message 'Closing PoShLog logger'
$Logger | Close-Logger
