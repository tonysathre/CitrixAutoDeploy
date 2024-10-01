Describe 'Main Script Execution' {
    BeforeEach {
        Import-Module "${PSScriptRoot}\..\module\CitrixAutodeploy" -Force -ErrorAction Stop -DisableNameChecking -Scope Local -WarningAction SilentlyContinue
    }

    It 'Should initialize the environment' {
        Mock Initialize-Environment
        Mock Get-BrokerCatalog
        { . "${PSScriptRoot}/../citrix_autodeploy.ps1" } | Should -Not -Throw

        Should -Invoke Initialize-Environment -Exactly 1 -Scope It
    }

    It 'Should execute main script logic' {
        $env:CI = $true
        $env:CITRIX_AUTODEPLOY_CONFIG = "${PSScriptRoot}/test_config.json"

        Mock Get-BrokerCatalog      { return [PSCustomObject]@{ Uid = 'TestUid'; Name = 'TestCatalog' } }
        Mock Get-BrokerDesktopGroup { return [PSCustomObject]@{ Name = 'TestGroup' } }
        Mock Get-BrokerMachine      { return @([PSCustomObject]@{ IsAssigned = $false }) }
        Mock New-CtxAutodeployMachine            { return [PSCustomObject]@{ MachineName = 'TestMachine' } }

        . "${PSScriptRoot}/../citrix_autodeploy.ps1"

        Should -Invoke Get-BrokerCatalog      -Exactly 2 -Scope It
        Should -Invoke Get-BrokerDesktopGroup -Exactly 2 -Scope It
        Should -Invoke Get-BrokerMachine      -Exactly 2 -Scope It
        Should -Invoke New-CtxAutodeployMachine            -Exactly 4 -Scope It
    }

    It 'Should only add machines when needed' {
        $env:CI = $true
        $env:CITRIX_AUTODEPLOY_CONFIG = "${PSScriptRoot}/test_config.json"

        Mock Get-BrokerCatalog      { return [PSCustomObject]@{ Uid = 'TestUid'; Name = 'TestCatalog' } }
        Mock Get-BrokerDesktopGroup { return [PSCustomObject]@{ Name = 'TestGroup' } }
        Mock Get-BrokerMachine      { return @([PSCustomObject]@{ IsAssigned = $false }, [PSCustomObject]@{ IsAssigned = $false }) }
        Mock New-CtxAutodeployMachine            { return [PSCustomObject]@{ MachineName = 'TestMachine' } }

        . "${PSScriptRoot}/../citrix_autodeploy.ps1"

        Should -Invoke Get-BrokerCatalog      -Exactly 2 -Scope It
        Should -Invoke Get-BrokerDesktopGroup -Exactly 2 -Scope It
        Should -Invoke Get-BrokerMachine      -Exactly 2 -Scope It
        Should -Invoke New-CtxAutodeployMachine            -Exactly 0 -Scope It
    }

    It 'Should loop when multiple machines are needed' {
        $env:CI = $true
        $env:CITRIX_AUTODEPLOY_CONFIG = "${PSScriptRoot}/test_config.json"

        Mock Get-BrokerCatalog      { return [PSCustomObject]@{ Uid = 'TestUid'; Name = 'TestCatalog' } }
        Mock Get-BrokerDesktopGroup { return [PSCustomObject]@{ Name = 'TestGroup' } }
        Mock Get-BrokerMachine      { return @([PSCustomObject]@{ IsAssigned = $false }) }
        Mock New-CtxAutodeployMachine            { return [PSCustomObject]@{ MachineName = 'TestMachine' } }

        . "${PSScriptRoot}/../citrix_autodeploy.ps1"

        Should -Invoke Get-BrokerCatalog      -Exactly 2 -Scope It
        Should -Invoke Get-BrokerDesktopGroup -Exactly 2 -Scope It
        Should -Invoke Get-BrokerMachine      -Exactly 2 -Scope It
        Should -Invoke New-CtxAutodeployMachine            -Exactly 4 -Scope It
    }

    It 'Should log and handle errors' {
        $env:CI = $true
        $ConfigFilePath = "${PSScriptRoot}/test_config.json"
        $env:CITRIX_AUTODEPLOY_CONFIG = $ConfigFilePath

        Mock Get-BrokerCatalog { throw "Test error" }
        Mock Write-CtxAutodeployLog
        Mock New-CtxAutodeployMachine
        { . "${PSScriptRoot}/../citrix_autodeploy.ps1" } | Should -Throw

        Should -Invoke Write-CtxAutodeployLog -Exactly 1 -Scope It
        Should -Invoke New-CtxAutodeployMachine -Exactly 0 -Scope It
    }

    It 'Should continue processing if error occurs during machine addition' {
        $env:CI = $true
        $ConfigFilePath = "${PSScriptRoot}/test_config.json"
        $env:CITRIX_AUTODEPLOY_CONFIG = $ConfigFilePath

        Mock Get-BrokerCatalog      { return [PSCustomObject]@{ Uid = 'TestUid'; Name = 'TestCatalog' } }
        Mock Get-BrokerDesktopGroup { return [PSCustomObject]@{ Name = 'TestGroup' } }
        Mock Get-BrokerMachine      { return @([PSCustomObject]@{ IsAssigned = $false }) }
        Mock New-CtxAutodeployMachine            { throw "Test error" }

        . "${PSScriptRoot}/../citrix_autodeploy.ps1"

        Should -Invoke Get-BrokerCatalog      -Exactly 2 -Scope It
        Should -Invoke Get-BrokerDesktopGroup -Exactly 2 -Scope It
        Should -Invoke Get-BrokerMachine      -Exactly 2 -Scope It
        Should -Invoke New-CtxAutodeployMachine            -Exactly 2 -Scope It
    }
}
