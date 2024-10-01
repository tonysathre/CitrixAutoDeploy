function New-CtxAutodeployVM {
    [OutputType([Citrix.Broker.Admin.SDK.Machine])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$AdminAddress,

        [Parameter(Mandatory)]
        [PSCustomObject]$BrokerCatalog,

        [Parameter(Mandatory)]
        [PSCustomObject]$DesktopGroup
    )

    try {
        $Logging      = Start-LogHighLevelOperation -AdminAddress $AdminAddress -Source "Citrix Autodeploy" -StartTime $([datetime]::Now) -Text "Citrix Autodeploy: Adding machine to catalog '$($BrokerCatalog.Name)'"
        $IdentityPool = Get-AcctIdentityPool -AdminAddress $AdminAddress -IdentityPoolName $BrokerCatalog.Name
        $ProvScheme   = Get-ProvScheme -AdminAddress $AdminAddress -ProvisioningSchemeName $BrokerCatalog.Name

        # TODO: This should be configurable, either in the config file or as a parameter, or via an environment variable
        $Timeout = 60
        Wait-ForIdentityPoolUnlock -IdentityPool $IdentityPool -Timeout $Timeout
        Set-AcctIdentityPool -AdminAddress $AdminAddress -AllowUnicode -Domain $IdentityPool.Domain -IdentityPoolName $IdentityPool.IdentityPoolName -LoggingId $Logging.Id

        $NewAdAccount = New-AcctADAccount -AdminAddress $AdminAddress -Count 1 -IdentityPoolName $IdentityPool.IdentityPoolName -LoggingId $Logging.Id
        $ProvScheme = Get-ProvScheme -AdminAddress $AdminAddress -ProvisioningSchemeName $BrokerCatalog.Name

        $VM = $NewAdAccount.SuccessfulAccounts.ADAccountName.ToString().Split('\')[1].Trim('$')
        Write-CtxAutodeployLog -Message "Creating VM '${VM}' using provisioning scheme '$($ProvScheme.ProvisioningSchemeName)'" -EventId 2 -EntryType Information
        # -RunAsynchronously returns a provisioning task System.Guid
        $ProvTaskId = New-ProvVM -AdminAddress $AdminAddress -ADAccountName $NewAdAccount.SuccessfulAccounts -ProvisioningSchemeName $ProvScheme.ProvisioningSchemeName -RunAsynchronously -LoggingId $Logging.Id
        $ProvTask   = Get-ProvTask -AdminAddress $AdminAddress -TaskId $ProvTaskId
    }
    catch {
        Write-CtxAutodeployLog -Message "$($Error[0].InvocationInfo.PositionMessage)" -EventId 1 -EntryType Error
        Stop-LogHighLevelOperation -AdminAddress $AdminAddress -LoggingId $Logging.Id
        break
    }

    $SleepSeconds  = 1
    while ($ProvTask.Active -eq $true) {
        $ProvTask = Get-ProvTask -AdminAddress $AdminAddress -TaskId $ProvTaskId
        Start-Sleep -Seconds $SleepSeconds
    }

    if ($ProvTask.TerminatingError) {
        Write-CtxAutodeployLog -Message $_ -EventId 1 -EntryType Error
        Stop-LogHighLevelOperation -AdminAddress $AdminAddress -LoggingId $Logging.Id
        break
    }

    try {
        Write-CtxAutodeployLog -Message "Adding machine '${VM}' to catalog '$($BrokerCatalog.Name)'" -EventId 2 -EntryType Information
        $NewBrokerMachine = New-BrokerMachine -AdminAddress $AdminAddress -MachineName $NewAdAccount.SuccessfulAccounts.ADAccountName -CatalogUid $BrokerCatalog.Uid -LoggingId $Logging.Id
    }
    catch {
        Write-CtxAutodeployLog -Message $_ -EventId 1 -EntryType Error
        Stop-LogHighLevelOperation -AdminAddress $AdminAddress -LoggingId $Logging.Id
        break
    }

    try {
        Write-CtxAutodeployLog -Message "Adding machine '$($NewBrokerMachine.MachineName)' in catalog '$($BrokerCatalog.Name)' to desktop group '$($DesktopGroup.Name)'" -EventId 2 -EntryType Information
        # Add-BrokerMachine doesn't have a return value
        Add-BrokerMachine -AdminAddress $AdminAddress -MachineName $NewBrokerMachine.MachineName -DesktopGroup $DesktopGroup.Name -LoggingId $Logging.Id
    }
    catch {
        Write-CtxAutodeployLog -Message $_ -EventId 1 -EntryType Error
        Stop-LogHighLevelOperation -AdminAddress $AdminAddress -LoggingId $Logging.Id
        break
    }

    return $NewBrokerMachine
}
