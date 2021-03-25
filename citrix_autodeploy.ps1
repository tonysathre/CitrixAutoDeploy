param (
    [switch]$Verbose
)

if ($Verbose) {
    $VerbosePreference = 'Continue'
    $PSDefaultParameterValues['*:Verbose'] = $true
}

Add-PSSnapin Citrix.*

function Import-ConfigFile {
    try {
        if (Test-Path (Join-Path $PSScriptRoot citrix_Autodeploy_config.json)) {
            $Config = Get-Content (Join-Path $PSScriptRoot citrix_Autodeploy_config.json) | ConvertFrom-Json
        }
    }
    catch {
        Write-EventLog -LogName 'Citrix Powershell Autodeploy' -Source Scripts -Message "$($Error[0].ToString())`r`n`r`n $($Error[0].ScriptStackTrace.ToString())" -EntryType Error -EventId 1
        throw $Error[0]
    }

    Write-Verbose 'Successfully loaded config file.'
    return $Config 
}

# Check if our custom event log exists and if not, create it
if (-not(Get-EventLog -LogName 'Citrix Powershell Autodeploy')) {
    New-EventLog -LogName 'Citrix Powershell Autodeploy' -Source 'Scripts'   
}

Write-Verbose 'Loading config ...'
$Config = Import-ConfigFile

foreach ($AutodeployMonitor in $Config.AutodeployMonitors.AutodeployMonitor) {
    Write-EventLog -LogName 'Citrix Powershell Autodeploy' -Source Scripts -Message "Autodeploy job started: $(($AutodeployMonitor | Format-List | Out-String))" -EventId 0 -EntryType Information
    
    try {
        $AdminAddress = $AutodeployMonitor.AdminAddress
        $BrokerCatalog = Get-BrokerCatalog -AdminAddress $AdminAddress -Name $AutodeployMonitor.BrokerCatalog -ErrorAction Stop
        $DesktopGroupName = Get-BrokerDesktopGroup -AdminAddress $AdminAddress -Name $AutodeployMonitor.DesktopGroupName -ErrorAction Stop
        $UnassignedMachines = Get-BrokerDesktop -AdminAddress $AdminAddress -DesktopGroupName $DesktopGroupName.Name -IsAssigned $false -ErrorAction Stop
        $MachinesToAdd = $AutodeployMonitor.MinAvailableMachines - $UnassignedMachines.Count
    }

    catch {
        Write-EventLog -LogName 'Citrix Powershell Autodeploy' -Source Scripts -Message "$($Error[0].ToString())`r`n`r`n $($Error[0].ScriptStackTrace.ToString())" -EntryType Information -EventId 1
        throw $Error[0]
        break
    }

    if ($MachinesToAdd -ge 1) {
        while ($MachinesToAdd -ne 0) {
            try {
                Write-Verbose "start loop for job '$($DesktopGroupName.Name)'"
                Write-Verbose "machines to add '$($MachinesToAdd)'"
                Write-Verbose '## creating new machine ##'
                
                $Logging = Start-LogHighLevelOperation -AdminAddress $AdminAddress -Source "Powershell Autodeploy" -StartTime $([datetime]::Now) -Text "Adding 1 Machines to Machine Catalog `'$($BrokerCatalog.Name)`'"
                $IdentityPool = Get-AcctIdentityPool -AdminAddress $AdminAddress -IdentityPoolName $BrokerCatalog.Name   
                $IdentityPoolLockedTimeout = 60
                # Check if identity pool is already locked, and if it is, wait for it to be unlocked.
                # This may occur if an admin has created machines in Citrix Studio while this script is running.
                if ($IdentityPool.Lock) {
                    $Stopwatch = [Diagnostics.Stopwatch]::StartNew()
                    while ($IdentityPool.Lock -and $Stopwatch.Elapsed.Seconds -le $IdentityPoolLockedTimeout) {
                        Start-Sleep -Seconds 1
                    }
                    $Stopwatch.Stop()
                }
                
                Set-AcctIdentityPool -AdminAddress $AdminAddress -AllowUnicode -Domain $IdentityPool.Domain -IdentityPoolName $IdentityPool.IdentityPoolName -LoggingId $Logging.Id
                Write-Verbose 'Creating AD account'
                $NewAdAccount = New-AcctADAccount -AdminAddress $AdminAddress -Count 1 -IdentityPoolName $IdentityPool.IdentityPoolName -LoggingId $Logging.Id -ErrorAction Stop
                Write-Verbose "Successfully created AD account: $($NewAdAccount.SuccessfulAccounts)"

                $ProvScheme = Get-ProvScheme -AdminAddress $AdminAddress -ProvisioningSchemeName $BrokerCatalog.Name

                $NewVMProvTask = New-ProvVM -AdminAddress $AdminAddress -ADAccountName $NewAdAccount.SuccessfulAccounts -ProvisioningSchemeName $ProvScheme.ProvisioningSchemeName -RunAsynchronously -LoggingId $Logging.Id
                $ProvTask = Get-ProvTask -AdminAddress $AdminAddress -TaskId $NewVMProvTask
                $ProvTaskSleep = 15
				while ($ProvTask.Active -eq $true) {
                    Start-Sleep -Seconds $ProvTaskSleep
                    $ProvTask = Get-ProvTask -AdminAddress $AdminAddress -TaskId $NewVMProvTask
                }

                Write-Verbose "Starting machine provisioning"
                if (-not($ProvTask.TerminatingError)) {
                    Write-EventLog -LogName 'Citrix Powershell Autodeploy' -Source Scripts -Message "Creating VM $($NewAdAccount.SuccessfulAccounts.ADAccountName.ToString().Split('\')[1].Trim('$')) in catalog `'$($BrokerCatalog.Name)`' and adding to delivery group `'$($DesktopGroupName.Name)`'" -EntryType Information -EventId 2
                    
                    Write-Verbose "Creating machine $($NewAdAccount.SuccessfulAccounts.ADAccountName) in machine catalog $($BrokerCatalog.Name)"
                    $NewBrokerMachine = New-BrokerMachine -AdminAddress $AdminAddress -MachineName $NewAdAccount.SuccessfulAccounts.ADAccountSid -CatalogUid $BrokerCatalog.Uid -LoggingId $Logging.Id
                    
                    Write-Verbose "Adding machine $($NewBrokerMachine) to delivery group $DesktopGroupName"
                    Add-BrokerMachine -AdminAddress $AdminAddress -InputObject $NewBrokerMachine -DesktopGroup $DesktopGroupName -LoggingId $Logging.Id

                    # Put machine in maintenance mode so SCCM can deploy software. SCCM task sequence will take machine out of maintenance mode.
					# TODO: Add pre and post deployment tasks to the config file. Could be things such as putting the newly created machine in maintenance mode
					#       or running a script in the VM.
                    Set-BrokerMachineMaintenanceMode -AdminAddress $AdminAddress -InputObject $NewBrokerMachine -MaintenanceMode $true

                    # Power on machine because Citrix won't power it on after we put it in maintenance mode.
                    New-BrokerHostingPowerAction -AdminAddress $AdminAddress -MachineName $NewBrokerMachine.MachineName -Action TurnOn
                }
            } 
            
            catch {
                Write-EventLog -LogName 'Citrix Powershell Autodeploy' -Source Scripts -Message $Message -EntryType Error -EventId 1
                Stop-LogHighLevelOperation -AdminAddress $AdminAddress -HighLevelOperationId $Logging.Id -EndTime $([datetime]::Now) -IsSuccessful $false
                break
            }

            finally {
                if (-not($Error)) {
                    Stop-LogHighLevelOperation -AdminAddress $AdminAddress -HighLevelOperationId $Logging.Id -EndTime $([datetime]::Now) -IsSuccessful $true
                    Write-EventLog -LogName 'Citrix Powershell Autodeploy' -Source Scripts -Message "Successfully created VM $($NewAdAccount.SuccessfulAccounts.ADAccountName.ToString().Split('\')[1].Trim('$')) in catalog `'$($BrokerCatalog.Name)`' and added it to delivery group `'$($DesktopGroupName.Name)`'" -EntryType Information -EventId 3
                }

                if ($IdentityPool.Lock) {
                    Unlock-AcctIdentityPool -AdminAddress $AdminAddress -IdentityPoolName $IdentityPool.IdentityPoolName -LoggingId $Logging.Id -ErrorAction SilentlyContinue
                }
            }
			
            $MachinesToAdd--
        }
		
        Write-Verbose "End of job '$($DesktopGroupName.Name)'"
        Write-Verbose '##-------------------------------------------##'
		
    } else {
        $Message = "No machines needed for desktop group `'$($AutodeployMonitor.DesktopGroupName)`'`n`nAvailable machines: $($UnassignedMachines.Count)`nRequired available machines: $($AutodeployMonitor.MinAvailableMachines)`n`nAvailable machine names:`n$($UnassignedMachines.DNSName | Format-List | Out-String)"
        Write-EventLog -LogName 'Citrix Powershell Autodeploy' -Source Scripts -Message $Message -EventId 4 -EntryType Information
    }
}