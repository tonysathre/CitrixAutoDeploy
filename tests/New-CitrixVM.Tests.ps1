Describe 'New-CitrixVM' {
    BeforeEach {
        . "${PSScriptRoot}\..\module\CitrixAutodeploy\functions\New-CitrixVM.ps1"
    }

    It 'Should create a new Citrix VM' {
        Mock New-ProvVM                { return [guid]::NewGuid() }
        Mock Get-ProvTask              { return [PSCustomObject]@{ Active = $false; TerminatingError = $false } }
        Mock New-BrokerMachine         { return [PSCustomObject]@{ MachineName = 'MockMachine' } }
        Mock Add-BrokerMachine         { return $null }
        Mock Write-CitrixAutoDeployLog { return "Creating VM 'MockAccount' in catalog 'MockCatalog' and adding to delivery group 'MockDesktopGroup'" }

        $Params = @{
            AdminAddress  = 'TestAdminAddress'
            BrokerCatalog = [PSCustomObject]@{ Name = 'TestCatalog'; Uid = 1234567890 }
            DesktopGroup  = [PSCustomObject]@{ Name = 'TestDesktopGroup' }
            NewAdAccount  = [PSCustomObject]@{ SuccessfulAccounts = [PSCustomObject]@{ ADAccountName = 'DOMAIN\TestAccount$'; ADAccountSid = 'S-1-5-21-1234567890-123456789-1234567890-1234' } }
            ProvScheme    = [PSCustomObject]@{ ProvisioningSchemeName = 'TestScheme' }
            Logging       = [PSCustomObject]@{ Id = [guid]::NewGuid() }
        }

        { New-CitrixVM @Params } | Should -Not -Throw
        Should -Invoke New-ProvVM                -Exactly 1 -Scope It
        Should -Invoke Get-ProvTask              -Exactly 1 -Scope It
        Should -Invoke New-BrokerMachine         -Exactly 1 -Scope It
        Should -Invoke Add-BrokerMachine         -Exactly 1 -Scope It
        Should -Invoke Write-CitrixAutoDeployLog -Exactly 1 -Scope It
    }

    It 'Should throw error if machine addition fails' {
        $Params = @{
            AdminAddress  = 'TestAdminAddress'
            BrokerCatalog = [PSCustomObject]@{ Name = 'TestCatalog'; Uid = 1234567890 }
            DesktopGroup  = [PSCustomObject]@{ Name = 'TestDesktopGroup' }
            NewAdAccount  = [PSCustomObject]@{ SuccessfulAccounts = [PSCustomObject]@{ ADAccountName = 'DOMAIN\TestAccount$'; ADAccountSid = 'S-1-5-21-1234567890-123456789-1234567890-1234' } }
            ProvScheme    = [PSCustomObject]@{ ProvisioningSchemeName = 'TestScheme' }
            Logging       = [PSCustomObject]@{ Id = [guid]::NewGuid() }
        }

        Mock Add-BrokerMachine { throw "Machine addition failed" }

        { New-CitrixVM @Params } | Should -Throw
    }

    It 'Should throw error if provisioning task fails' {
        Mock New-ProvVM                { return [guid]::NewGuid() }
        Mock Get-ProvTask              { return [PSCustomObject]@{ Active = $false; TerminatingError = $true } }
        Mock New-BrokerMachine         { return [PSCustomObject]@{ MachineName = 'MockMachine' } }
        Mock Add-BrokerMachine         { return $null }
        Mock Write-CitrixAutoDeployLog { return "Creating VM 'MockAccount' in catalog 'MockCatalog' and adding to delivery group 'MockDesktopGroup'" }

        $Params = @{
            AdminAddress  = 'TestAdminAddress'
            BrokerCatalog = [PSCustomObject]@{ Name = 'TestCatalog'; Uid = 1234567890 }
            DesktopGroup  = [PSCustomObject]@{ Name = 'TestDesktopGroup' }
            NewAdAccount  = [PSCustomObject]@{ SuccessfulAccounts = [PSCustomObject]@{ ADAccountName = 'DOMAIN\TestAccount$'; ADAccountSid = 'S-1-5-21-1234567890-123456789-1234567890-1234' } }
            ProvScheme    = [PSCustomObject]@{ ProvisioningSchemeName = 'TestScheme' }
            Logging       = [PSCustomObject]@{ Id = [guid]::NewGuid() }
        }

        { New-CitrixVM @Params } | Should -Throw

        Should -Invoke Write-CitrixAutoDeployLog -Exactly 2 -Scope It
        Should -Invoke New-BrokerMachine         -Exactly 0 -Scope It
        Should -Invoke Add-BrokerMachine         -Exactly 0 -Scope It
    }

    It 'Should handle errors in New-ProvVM' {
        Mock New-ProvVM -MockWith { throw "Provisioning VM failed" }
        Mock Write-CitrixAutoDeployLog
        Mock New-BrokerMachine
        Mock Add-BrokerMachine

        $Params = @{
            AdminAddress  = 'TestAdminAddress'
            BrokerCatalog = [PSCustomObject]@{ Name = 'TestCatalog'; Uid = 1234567890 }
            DesktopGroup  = [PSCustomObject]@{ Name = 'TestDesktopGroup' }
            NewAdAccount  = [PSCustomObject]@{ SuccessfulAccounts = [PSCustomObject]@{ ADAccountName = 'DOMAIN\TestAccount$'; ADAccountSid = 'S-1-5-21-1234567890-123456789-1234567890-1234' } }
            ProvScheme    = [PSCustomObject]@{ ProvisioningSchemeName = 'TestScheme' }
            Logging       = [PSCustomObject]@{ Id = [guid]::NewGuid() }
        }

        { New-CitrixVM @Params } | Should -Throw

        Should -Invoke Write-CitrixAutoDeployLog -Exactly 1 -Scope It
        Should -Invoke New-BrokerMachine -Exactly 0 -Scope It
        Should -Invoke Add-BrokerMachine -Exactly 0 -Scope It
    }

    It 'Should handle errors in Write-CitrixAutoDeployLog' {
        Mock New-ProvVM { return [guid]::NewGuid() }
        Mock Get-ProvTask { return [PSCustomObject]@{ Active = $false; TerminatingError = $false } }
        Mock New-BrokerMachine { return [PSCustomObject]@{ MachineName = 'MockMachine' } }
        Mock Add-BrokerMachine { return $null }
        Mock Write-CitrixAutoDeployLog { throw "Logging failed" }

        $Params = @{
            AdminAddress  = 'TestAdminAddress'
            BrokerCatalog = [PSCustomObject]@{ Name = 'TestCatalog'; Uid = 1234567890 }
            DesktopGroup  = [PSCustomObject]@{ Name = 'TestDesktopGroup' }
            NewAdAccount  = [PSCustomObject]@{ SuccessfulAccounts = [PSCustomObject]@{ ADAccountName = 'DOMAIN\TestAccount$'; ADAccountSid = 'S-1-5-21-1234567890-123456789-1234567890-1234' } }
            ProvScheme    = [PSCustomObject]@{ ProvisioningSchemeName = 'TestScheme' }
            Logging       = [PSCustomObject]@{ Id = [guid]::NewGuid() }
        }

        { New-CitrixVM @Params } | Should -Throw

        Should -Invoke Write-CitrixAutoDeployLog -Exactly 1 -Scope It
        Should -Invoke New-BrokerMachine -Exactly 0 -Scope It
        Should -Invoke Add-BrokerMachine -Exactly 0 -Scope It
    }

    It 'Should handle errors in New-BrokerMachine' {
        Mock New-ProvVM { return [guid]::NewGuid() }
        Mock Get-ProvTask { return [PSCustomObject]@{ Active = $false; TerminatingError = $false } }
        Mock New-BrokerMachine { throw "Creating Broker Machine failed" }
        Mock Write-CitrixAutoDeployLog
        Mock Add-BrokerMachine

        $Params = @{
            AdminAddress  = 'TestAdminAddress'
            BrokerCatalog = [PSCustomObject]@{ Name = 'TestCatalog'; Uid = 1234567890 }
            DesktopGroup  = [PSCustomObject]@{ Name = 'TestDesktopGroup' }
            NewAdAccount  = [PSCustomObject]@{ SuccessfulAccounts = [PSCustomObject]@{ ADAccountName = 'DOMAIN\TestAccount$'; ADAccountSid = 'S-1-5-21-1234567890-123456789-1234567890-1234' } }
            ProvScheme    = [PSCustomObject]@{ ProvisioningSchemeName = 'TestScheme' }
            Logging       = [PSCustomObject]@{ Id = [guid]::NewGuid() }
        }

        { New-CitrixVM @Params } | Should -Throw

        Should -Invoke Write-CitrixAutoDeployLog -Exactly 1 -Scope It
        Should -Invoke New-BrokerMachine -Exactly 1 -Scope It
        Should -Invoke Add-BrokerMachine -Exactly 0 -Scope It
    }

    It 'Should handle sleep and retry logic' {
        $ProvTaskId = [guid]::NewGuid()

        Mock New-ProvVM { return $ProvTaskId }
        Mock Get-ProvTask {
            param ($AdminAddress, $TaskId)
            if ($TaskId -eq $ProvTaskId) {
                return [PSCustomObject]@{ Active = $true; TerminatingError = $false }
            }
        }

        Mock Start-Sleep { return $ProvTask.Active = $false }
        Mock Write-CitrixAutoDeployLog
        Mock New-BrokerMachine { return [PSCustomObject]@{ MachineName = 'TestMachine' } }
        Mock Add-BrokerMachine { return $null }

        $Params = @{
            AdminAddress  = 'TestAdminAddress'
            BrokerCatalog = [PSCustomObject]@{ Name = 'TestCatalog'; Uid = 1234567890 }
            DesktopGroup  = [PSCustomObject]@{ Name = 'TestDesktopGroup' }
            NewAdAccount  = [PSCustomObject]@{ SuccessfulAccounts = [PSCustomObject]@{ ADAccountName = 'DOMAIN\TestAccount$'; ADAccountSid = 'S-1-5-21-1234567890-123456789-1234567890-1234' } }
            ProvScheme    = [PSCustomObject]@{ ProvisioningSchemeName = 'TestScheme' }
            Logging       = [PSCustomObject]@{ Id = [guid]::NewGuid() }
        }

        { New-CitrixVM @Params } | Should -Not -Throw

        Should -Invoke Start-Sleep  -Exactly 1 -Scope It
        Should -Invoke Get-ProvTask -Exactly 2 -Scope It
    }
}
