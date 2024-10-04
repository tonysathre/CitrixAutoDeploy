function New-CtxAutodeployVM {
    [OutputType([Citrix.Broker.Admin.SDK.Machine])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$AdminAddress,

        [Parameter(Mandatory)]
        [PSCustomObject]$BrokerCatalog,

        [Parameter(Mandatory)]
        [PSCustomObject]$DesktopGroup,

        [Parameter()]
        [int]$Timeout = 60
    )

    try {
        $Logging = Start-LogHighLevelOperation -AdminAddress $AdminAddress -Source 'Citrix Autodeploy' -StartTime ([datetime]::Now) -Text "Citrix Autodeploy: Adding machine to catalog '$($BrokerCatalog.Name)'"
        $IdentityPool = Get-AcctIdentityPool -AdminAddress $AdminAddress -IdentityPoolName $BrokerCatalog.Name
        $ProvisioningScheme = Get-ProvScheme -AdminAddress $AdminAddress -ProvisioningSchemeName $BrokerCatalog.Name

        Wait-ForIdentityPoolUnlock -IdentityPool $IdentityPool -Timeout $Timeout
        Set-AcctIdentityPool -AdminAddress $AdminAddress -AllowUnicode -Domain $IdentityPool.Domain -IdentityPoolName $IdentityPool.IdentityPoolName -LoggingId $Logging.Id

        Write-CtxAutodeployLog -Message "Creating AD account in identity pool '$($IdentityPool.IdentityPoolName)'" -EventId 2 -EntryType Information
        $NewAdAccount = New-AcctADAccount -AdminAddress $AdminAddress -Count 1 -IdentityPoolName $IdentityPool.IdentityPoolName -LoggingId $Logging.Id
        $ProvisioningScheme = Get-ProvScheme -AdminAddress $AdminAddress -ProvisioningSchemeName $BrokerCatalog.Name

        $AdAccountName = $NewAdAccount.SuccessfulAccounts.ADAccountName.ToString().Split('\')[1].Trim('$')
        Write-CtxAutodeployLog -Message "Creating VM '${AdAccountName}' using provisioning scheme '$($ProvisioningScheme.ProvisioningSchemeName)'" -EventId 2 -EntryType Information

        $ProvisioningTaskId = New-ProvVM -AdminAddress $AdminAddress -ADAccountName $NewAdAccount.SuccessfulAccounts -ProvisioningSchemeName $ProvisioningScheme.ProvisioningSchemeName -RunAsynchronously -LoggingId $Logging.Id
        $ProvisioningTask = Get-ProvTask -AdminAddress $AdminAddress -TaskId $ProvisioningTaskId

        while ($ProvisioningTask.Active -eq $true) {
            Start-Sleep -Seconds 1
            $ProvisioningTask = Get-ProvTask -AdminAddress $AdminAddress -TaskId $ProvisioningTaskId
        }

        if ($ProvisioningTask.TerminatingError) {
            Write-CtxAutodeployLog -Message "Provisioning task failed: $($ProvisioningTask.TerminatingError)" -EventId 1 -EntryType Error
            Stop-LogHighLevelOperation -AdminAddress $AdminAddress -HighLevelOperationId $Logging.Id -EndTime ([datetime]::Now) -IsSuccessful $false
            throw
        }

        Write-CtxAutodeployLog -Message "Adding VM '$AdAccountName' to catalog '$($BrokerCatalog.Name)'" -EventId 2 -EntryType Information
        $NewBrokerMachine = New-BrokerMachine -AdminAddress $AdminAddress -MachineName $NewAdAccount.SuccessfulAccounts.ADAccountSid -CatalogUid $BrokerCatalog.Uid -LoggingId $Logging.Id

        Write-CtxAutodeployLog -Message "Adding VM '$($NewBrokerMachine.MachineName)' in catalog '$($BrokerCatalog.Name)' to desktop group '$($DesktopGroup.Name)'" -EventId 2 -EntryType Information
        Add-BrokerMachine -AdminAddress $AdminAddress -MachineName $NewBrokerMachine.MachineName -DesktopGroup $DesktopGroup.Name -LoggingId $Logging.Id

        $IsSuccessful = $true

        return $NewBrokerMachine
    }
    catch {
        $IsSuccessful = $false
        Write-CtxAutodeployLog -Message "$($MyInvocation.MyCommand) on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message): $($_.Exception.InnerException)" -EventId 1 -EntryType Error
    }
    finally {
        if (-not $NewBrokerMachine) {
            Write-CtxAutodeployLog -Message ("Cleaning up AD account: {0}" -f $NewAdAccount.SuccessfulAccounts.ADAccountName) -EventId 1 -EntryType Information
            Remove-AcctADAccount -AdminAddress $AdminAddress -ADAccountName $NewAdAccount.SuccessfulAccounts.ADAccountName -LoggingId $Logging.Id
        }

        Write-CtxAutodeployLog -Message "Machine '${AdAccountName}' created successfully" -EventId 1 -EntryType Information
        Stop-LogHighLevelOperation -AdminAddress $AdminAddress -HighLevelOperationId $Logging.Id -EndTime ([datetime]::Now) -IsSuccessful $IsSuccessful
    }
}
