function New-CitrixVM {
    [CmdletBinding()]
    param(
        [string]$AdminAddress,
        [PSCustomObject]$BrokerCatalog,
        [PSCustomObject]$DesktopGroup,
        [PSCustomObject]$NewAdAccount,
        [PSCustomObject]$ProvScheme,
        [PSCustomObject]$Logging
    )

    Write-CitrixAutoDeployLog -Message "Creating VM '$($NewAdAccount.SuccessfulAccounts.ADAccountName.ToString().Split('\')[1].Trim('$'))' in catalog '$($BrokerCatalog.Name)' and adding to delivery group '$($DesktopGroup.Name)'" -EventId 2 -EntryType Information

    $ProvTaskId    = New-ProvVM -AdminAddress $AdminAddress -ADAccountName $NewAdAccount.SuccessfulAccounts -ProvisioningSchemeName $ProvScheme.ProvisioningSchemeName -RunAsynchronously -LoggingId $Logging.Id
    $ProvTask      = Get-ProvTask -AdminAddress $AdminAddress -TaskId $ProvTaskId
    $SleepSeconds  = 15

    while ($ProvTask.Active -eq $true) {
        $ProvTask = Get-ProvTask -AdminAddress $AdminAddress -TaskId $ProvTaskId
        Start-Sleep -Seconds $SleepSeconds
    }

    if ($ProvTask.TerminatingError) {
        Write-CitrixAutoDeployLog -Message "Provisioning task failed with error:`n`n $($ProvTask.TerminatingError)"
        throw "Provisioning task failed with error: $($ProvTask.TerminatingError)"
    }

    $NewBrokerMachine = New-BrokerMachine -AdminAddress $AdminAddress -MachineName $NewAdAccount.SuccessfulAccounts.ADAccountName -CatalogUid $BrokerCatalog.Uid

    if (-not($NewBrokerMachine)) {
        Write-CitrixAutoDeployLog -Message "Failed to create machine '$($NewAdAccount.SuccessfulAccounts.ADAccountName)' in catalog '$($BrokerCatalog.Name)'"
        throw "Failed to create machine '$($NewAdAccount.SuccessfulAccounts.ADAccountName)' in catalog '$($BrokerCatalog.Name)'"
    }

    Add-BrokerMachine -AdminAddress $AdminAddress -MachineName $NewBrokerMachine.MachineName -DesktopGroup $DesktopGroup.Name

    if (-not($?)) {
        Write-CitrixAutoDeployLog -Message "Failed to add machine '$($NewBrokerMachine.MachineName)' to delivery group '$($DesktopGroup.Name)'"
        throw "Failed to add machine '$($NewBrokerMachine.MachineName)' to delivery group '$($DesktopGroup.Name)'"
    }

    return $NewBrokerMachine
}
