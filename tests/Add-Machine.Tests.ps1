Describe 'Add-Machine' {
    # BeforeEach {
    #     Import-Module ${PSScriptRoot}\..\module\CitrixAutodeploy -Force -ErrorAction Stop -DisableNameChecking -Scope Local
    # }
    BeforeAll {
        Import-Module ${PSScriptRoot}\..\module\CitrixAutodeploy -Force -ErrorAction Stop -DisableNameChecking
    }
    It 'Should add machine to Citrix environment' {
        $Params = @{
            AdminAddress  = "test-admin-address"
            BrokerCatalog = [PSCustomObject]@{ Name = "TestCatalog" }
            DesktopGroup  = [PSCustomObject]@{ Name = "TestGroup" }
            PreTask       = "$PSScriptRoot\test_pre_task.ps1"
            PostTask      = "$PSScriptRoot\test_post_task.ps1"
        }

        Mock Get-AcctIdentityPool { return [PSCustomObject]@{ Domain = "TestDomain"; IdentityPoolName = "TestIdentityPool" } }
        Mock Set-AcctIdentityPool { return [PSCustomObject]@{ Domain = "TestDomain"; IdentityPoolName = "TestIdentityPool" } }
        Mock New-AcctADAccount    { return [PSCustomObject]@{ SuccessfulAccounts = [PSCustomObject]@{ ADAccountName = "TestAccount" } } }
        Mock Get-ProvScheme       { return [PSCustomObject]@{ ProvisioningSchemeName = "TestScheme" } }
        #Mock Add-Machine          { return [PSCustomObject]@{ MachineName = "TestMachine" } }

        { Add-Machine @Params } | Should -Not -Throw
    }

    # It 'Should not add machine to Citrix environment when no machines are needed' {
    #     $AddMachineParams = @{
    #         AdminAddress      = "test-admin-address"
    #         BrokerCatalog     = [PSCustomObject]@{ Name = "TestCatalog" }
    #         DesktopGroup      = [PSCustomObject]@{ Name = "TestDesktopGroup" }
    #         PreTask           = "${PSScriptRoot}\test_pre_task.ps1"
    #         PostTask          = "${PSScriptRoot}\test_post_task.ps1"
    #     }

    #     $GetAcctIdentityPool = [PSCustomObject]@{ Domain = "TestDomain"; IdentityPoolName = "TestIdentityPool" }
    #     $SetAcctIdentityPool = [PSCustomObject]@{ Domain = "TestDomain"; IdentityPoolName = "TestIdentityPool" }
    #     $NewAcctADAccount    = [PSCustomObject]@{ SuccessfulAccounts = [PSCustomObject]@{ ADAccountName = "TestAccount" } }
    #     $GetProvScheme       = [PSCustomObject]@{ ProvisioningSchemeName = "TestScheme" }
    #     $AddMachine          = [PSCustomObject]@{ MachineName = "TestMachine" }

    #     Mock Get-AcctIdentityPool { return $GetAcctIdentityPool }
    #     Mock Set-AcctIdentityPool { return $SetAcctIdentityPool }
    #     Mock New-AcctADAccount    { return $NewAcctADAccount }
    #     Mock Get-ProvScheme       { return $GetProvScheme }
    #     Mock Add-Machine          { return $AddMachine }

    #     { Add-Machine @AddMachineParams } | Should -Not -Throw
    # }

    It 'Should throw error if machine addition fails' {
        $AddMachineParams = @{
            AdminAddress      = "test-admin-address"
            BrokerCatalog     = [PSCustomObject]@{ Name = "TestCatalog" }
            DesktopGroup      = [PSCustomObject]@{ Name = "TestDesktopGroup" }
            PreTask           = "${PSScriptRoot}\test_pre_task.ps1"
            PostTask          = "${PSScriptRoot}\test_post_task.ps1"
        }

        Mock Get-AcctIdentityPool { return [PSCustomObject]@{ Domain = "TestDomain"; IdentityPoolName = "TestIdentityPool" } }
        Mock Set-AcctIdentityPool { return [PSCustomObject]@{ Domain = "TestDomain"; IdentityPoolName = "TestIdentityPool" } }
        Mock New-AcctADAccount    { return [PSCustomObject]@{ SuccessfulAccounts = [PSCustomObject]@{ ADAccountName = "TestAccount" } } }
        Mock Get-ProvScheme       { return [PSCustomObject]@{ ProvisioningSchemeName = "TestScheme" } }
        Mock Add-Machine          { throw "Machine addition failed" }

        { Add-Machine @AddMachineParams } | Should -Throw
    }
}
