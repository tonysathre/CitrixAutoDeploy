Describe 'New-CtxAutodeployVM' {
    BeforeEach {
        . "${PSScriptRoot}\..\module\CitrixAutodeploy\functions\New-CtxAutodeployVM.ps1"
    }

    It 'Should create a new Citrix VM' {
        Mock New-ProvVM                { return [guid]::NewGuid() }
        Mock Get-ProvTask              { return [PSCustomObject]@{ Active = $false; TerminatingError = $false } }
        Mock New-BrokerMachine         { return [PSCustomObject]@{ MachineName = 'MockMachine' } }
        Mock Add-BrokerMachine         { return $null }
        Mock Write-CtxAutodeployLog

        $Params = @{
            AdminAddress  = 'TestAdminAddress'
            BrokerCatalog = [PSCustomObject]@{ Name = 'TestCatalog'; Uid = 1234567890 }
            DesktopGroup  = [PSCustomObject]@{ Name = 'TestDesktopGroup' }
            NewAdAccount  = [PSCustomObject]@{ SuccessfulAccounts = [PSCustomObject]@{ ADAccountName = 'DOMAIN\TestAccount$'; ADAccountSid = 'S-1-5-21-1234567890-123456789-1234567890-1234' } }
            ProvScheme    = [PSCustomObject]@{ ProvisioningSchemeName = 'TestScheme' }
            Logging       = [PSCustomObject]@{ Id = [guid]::NewGuid() }
        }

        { New-CtxAutodeployVM @Params } | Should -Not -Throw

        Should -Invoke New-ProvVM                -Exactly 1 -Scope It
        Should -Invoke Get-ProvTask              -Exactly 1 -Scope It
        Should -Invoke New-BrokerMachine         -Exactly 1 -Scope It
        Should -Invoke Add-BrokerMachine         -Exactly 1 -Scope It
        Should -Invoke Write-CtxAutodeployLog -Exactly 2 -Scope It
    }

    It 'Should throw error if New-ProvVM fails' {
        Mock New-ProvVM -MockWith { throw "Provisioning VM failed" }
        Mock Write-CtxAutodeployLog
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

        { New-CtxAutodeployVM @Params } | Should -Throw

        Should -Invoke Write-CtxAutodeployLog -Exactly 1 -Scope It
        Should -Invoke New-BrokerMachine -Exactly 0 -Scope It
        Should -Invoke Add-BrokerMachine -Exactly 0 -Scope It
    }

    It 'Should throw error if Add-BrokerMachine fails' {
        $Params = @{
            AdminAddress  = 'TestAdminAddress'
            BrokerCatalog = [PSCustomObject]@{ Name = 'TestCatalog'; Uid = 1234567890 }
            DesktopGroup  = [PSCustomObject]@{ Name = 'TestDesktopGroup' }
            NewAdAccount  = [PSCustomObject]@{ SuccessfulAccounts = [PSCustomObject]@{ ADAccountName = 'DOMAIN\TestAccount$'; ADAccountSid = 'S-1-5-21-1234567890-123456789-1234567890-1234' } }
            ProvScheme    = [PSCustomObject]@{ ProvisioningSchemeName = 'TestScheme' }
            Logging       = [PSCustomObject]@{ Id = [guid]::NewGuid() }
        }

        Mock Add-BrokerMachine { throw "Machine addition failed" }

        { New-CtxAutodeployVM @Params } | Should -Throw
    }

    It 'Should throw error if provisioning task fails' {
        Mock New-ProvVM                { return [guid]::NewGuid() }
        Mock Get-ProvTask              { return [PSCustomObject]@{ Active = $false; TerminatingError = $true } }
        Mock New-BrokerMachine         { return [PSCustomObject]@{ MachineName = 'MockMachine' } }
        Mock Add-BrokerMachine         { return $null }
        Mock Write-CtxAutodeployLog

        $Params = @{
            AdminAddress  = 'TestAdminAddress'
            BrokerCatalog = [PSCustomObject]@{ Name = 'TestCatalog'; Uid = 1234567890 }
            DesktopGroup  = [PSCustomObject]@{ Name = 'TestDesktopGroup' }
            NewAdAccount  = [PSCustomObject]@{ SuccessfulAccounts = [PSCustomObject]@{ ADAccountName = 'DOMAIN\TestAccount$'; ADAccountSid = 'S-1-5-21-1234567890-123456789-1234567890-1234' } }
            ProvScheme    = [PSCustomObject]@{ ProvisioningSchemeName = 'TestScheme' }
            Logging       = [PSCustomObject]@{ Id = [guid]::NewGuid() }
        }

        { New-CtxAutodeployVM @Params } | Should -Throw

        Should -Invoke Write-CtxAutodeployLog -Exactly 2 -Scope It
        Should -Invoke New-BrokerMachine         -Exactly 0 -Scope It
        Should -Invoke Add-BrokerMachine         -Exactly 0 -Scope It
    }

    It 'Should throw error if New-BrokerMachine fails' {
        Mock New-ProvVM { return [guid]::NewGuid() }
        Mock Get-ProvTask { return [PSCustomObject]@{ Active = $false; TerminatingError = $false } }
        Mock New-BrokerMachine { throw "Creating Broker Machine failed" }
        Mock Write-CtxAutodeployLog
        Mock Add-BrokerMachine

        $Params = @{
            AdminAddress  = 'TestAdminAddress'
            BrokerCatalog = [PSCustomObject]@{ Name = 'TestCatalog'; Uid = 1234567890 }
            DesktopGroup  = [PSCustomObject]@{ Name = 'TestDesktopGroup' }
            NewAdAccount  = [PSCustomObject]@{ SuccessfulAccounts = [PSCustomObject]@{ ADAccountName = 'DOMAIN\TestAccount$'; ADAccountSid = 'S-1-5-21-1234567890-123456789-1234567890-1234' } }
            ProvScheme    = [PSCustomObject]@{ ProvisioningSchemeName = 'TestScheme' }
            Logging       = [PSCustomObject]@{ Id = [guid]::NewGuid() }
        }

        { New-CtxAutodeployVM @Params } | Should -Throw

        Should -Invoke New-ProvVM                -Exactly 1 -Scope It
        Should -Invoke Get-ProvTask              -Exactly 1 -Scope It
        Should -Invoke Write-CtxAutodeployLog -Exactly 2 -Scope It
        Should -Invoke New-BrokerMachine         -Exactly 1 -Scope It
        Should -Invoke Add-BrokerMachine         -Exactly 0 -Scope It
    }

    It 'Should sleep and retry if provisioning task is active' {
        $ProvTaskId = [guid]::NewGuid()

        Mock New-ProvVM { return $ProvTaskId }
        Mock Get-ProvTask {
            param ($AdminAddress, $TaskId)
            if ($TaskId -eq $ProvTaskId) {
                return [PSCustomObject]@{ Active = $true; TerminatingError = $false }
            }
        }

        Mock Start-Sleep { return $ProvTask.Active = $false }
        Mock Write-CtxAutodeployLog
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

        { New-CtxAutodeployVM @Params } | Should -Not -Throw

        Should -Invoke Start-Sleep  -Exactly 1 -Scope It
        Should -Invoke Get-ProvTask -Exactly 2 -Scope It
    }
}
