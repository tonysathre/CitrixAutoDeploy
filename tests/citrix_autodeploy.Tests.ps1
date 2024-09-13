Describe 'Main Script Execution' {
    BeforeEach {
        Import-Module "${PSScriptRoot}\..\module\CitrixAutodeploy" -Force -ErrorAction Stop -DisableNameChecking -Scope Local -WarningAction SilentlyContinue
    }

    It 'Should initialize the environment' {
        Mock Initialize-Environment

        . "${PSScriptRoot}/../citrix_autodeploy.ps1"

        Should -Invoke Initialize-Environment -Exactly 1 -Scope It
    }

    It 'Should execute main script logic' {
        $env:CI = $true
        $env:CITRIX_AUTODEPLOY_CONFIG = "${PSScriptRoot}/test_config.json"

        Mock Get-BrokerCatalog      { return [PSCustomObject]@{ Uid = 'TestUid'; Name = 'TestCatalog' } }
        Mock Get-BrokerDesktopGroup { return [PSCustomObject]@{ Name = 'TestGroup' } }
        Mock Get-BrokerDesktop      { return @([PSCustomObject]@{ IsAssigned = $false }) }
        Mock Add-Machine            { return [PSCustomObject]@{ MachineName = 'TestMachine' } }

        . "${PSScriptRoot}/../citrix_autodeploy.ps1"

        Should -Invoke Get-BrokerCatalog      -Exactly 2 -Scope It
        Should -Invoke Get-BrokerDesktopGroup -Exactly 2 -Scope It
        Should -Invoke Get-BrokerDesktop      -Exactly 2 -Scope It
        Should -Invoke Add-Machine            -Exactly 4 -Scope It
    }

    It 'Should only add machines when needed' {
        $env:CI = $true
        $env:CITRIX_AUTODEPLOY_CONFIG = "${PSScriptRoot}/test_config.json"

        Mock Get-BrokerCatalog      { return [PSCustomObject]@{ Uid = 'TestUid'; Name = 'TestCatalog' } }
        Mock Get-BrokerDesktopGroup { return [PSCustomObject]@{ Name = 'TestGroup' } }
        Mock Get-BrokerDesktop      { return @([PSCustomObject]@{ IsAssigned = $false }, [PSCustomObject]@{ IsAssigned = $false }) }
        Mock Add-Machine            { return [PSCustomObject]@{ MachineName = 'TestMachine' } }

        . "${PSScriptRoot}/../citrix_autodeploy.ps1"

        Should -Invoke Get-BrokerCatalog      -Exactly 2 -Scope It
        Should -Invoke Get-BrokerDesktopGroup -Exactly 2 -Scope It
        Should -Invoke Get-BrokerDesktop      -Exactly 2 -Scope It
        Should -Invoke Add-Machine            -Exactly 0 -Scope It
    }

    It 'Should loop when multiple machines are needed' {
        $env:CI = $true
        $env:CITRIX_AUTODEPLOY_CONFIG = "${PSScriptRoot}/test_config.json"

        Mock Get-BrokerCatalog      { return [PSCustomObject]@{ Uid = 'TestUid'; Name = 'TestCatalog' } }
        Mock Get-BrokerDesktopGroup { return [PSCustomObject]@{ Name = 'TestGroup' } }
        Mock Get-BrokerDesktop      { return @([PSCustomObject]@{ IsAssigned = $false }) }
        Mock Add-Machine            { return [PSCustomObject]@{ MachineName = 'TestMachine' } }

        . "${PSScriptRoot}/../citrix_autodeploy.ps1"

        Should -Invoke Get-BrokerCatalog      -Exactly 2 -Scope It
        Should -Invoke Get-BrokerDesktopGroup -Exactly 2 -Scope It
        Should -Invoke Get-BrokerDesktop      -Exactly 2 -Scope It
        Should -Invoke Add-Machine            -Exactly 4 -Scope It
    }

    It 'Should log and handle errors' {
        $env:CI = $true
        $ConfigFilePath = "${PSScriptRoot}/test_config.json"
        $env:CITRIX_AUTODEPLOY_CONFIG = $ConfigFilePath

        Mock Get-BrokerCatalog { throw "Test error" }
        Mock Write-CitrixAutoDeployLog

        { . "${PSScriptRoot}/../citrix_autodeploy.ps1" } | Should -Not -Throw

        Should -Invoke Write-CitrixAutoDeployLog -Exactly 1 -Scope It -ParameterFilter {
            $Message -like "*Test error*"
        }
    }
}