function Add-Machine {
    [CmdletBinding()]
    param(
        [string]$AdminAddress,
        [PSCustomObject]$BrokerCatalog,
        [PSCustomObject]$DesktopGroup,
        [string]$PreTask,
        [string]$PostTask
    )

    try {
        if ($PreTask) {
            Invoke-CtxAdTask -Task $PreTask -MachineName $NewAdAccount.SuccessfulAccounts.ADAccountName -Type Pre
        }

        $Logging = Start-LogHighLevelOperation -AdminAddress $AdminAddress -Source "Citrix Autodeploy" -StartTime $([datetime]::Now) -Text "Adding 1 Machine to Machine Catalog '$($BrokerCatalog.Name)'"
        $IdentityPool = Get-AcctIdentityPool -AdminAddress $AdminAddress -IdentityPoolName $BrokerCatalog.Name
        $IdentityPoolLockedTimeout = 60

        Wait-ForIdentityPoolUnlock -IdentityPool $IdentityPool -Timeout $IdentityPoolLockedTimeout

        Set-AcctIdentityPool -AdminAddress $AdminAddress -AllowUnicode -Domain $IdentityPool.Domain -IdentityPoolName $IdentityPool.IdentityPoolName -LoggingId $Logging.Id
        $NewAdAccount = New-AcctADAccount -AdminAddress $AdminAddress -Count 1 -IdentityPoolName $IdentityPool.IdentityPoolName -LoggingId $Logging.Id -ErrorAction Stop

        $ProvScheme = Get-ProvScheme -AdminAddress $AdminAddress -ProvisioningSchemeName $BrokerCatalog.Name

        # We save $NewBrokerMachine to a variable so it can be used in PostTask scripts
        $NewBrokerMachine = New-CitrixVM -AdminAddress $AdminAddress -BrokerCatalog $BrokerCatalog -DesktopGroup $DesktopGroup.Name -NewAdAccount $NewAdAccount -ProvScheme $ProvScheme -Logging $Logging

        if ($PostTask) {
            Invoke-CtxAdTask -Task $PostTask -MachineName $NewAdAccount.SuccessfulAccounts.ADAccountName -Type Post
        }

        Stop-LogHighLevelOperation -AdminAddress $AdminAddress -HighLevelOperationId $Logging.Id -EndTime $([datetime]::Now) -IsSuccessful $true
    }
    catch {
        Write-CitrixAutoDeployLog -Message "$($_.Exception.Message)`n`n$($_.Exception.StackTrace)" -EventId 1 -EntryType Error
        Stop-LogHighLevelOperation -AdminAddress $AdminAddress -HighLevelOperationId $Logging.Id -EndTime $([datetime]::Now) -IsSuccessful $false
        throw
    }

    return $NewBrokerMachine
}
