Describe 'Initialize-Environment' {
    BeforeAll {
        Import-Module ${PSScriptRoot}\..\module\CitrixAutodeploy -Force -ErrorAction Stop -DisableNameChecking -Scope Local
    }

    Context 'When running in non-CI environment' {
        BeforeEach {
            $env:CI = $false
        }

        It 'Should throw error if event log not found' {
            Mock Write-CitrixAutoDeployLog { }
            Mock Get-EventLog { throw "Event log not found" }

            { Initialize-Environment }
            #Mock Get-EventLog { return @([PSCustomObject]@{ Log = 'Citrix Autodeploy' }, [PSCustomObject]@{ Log = 'System' }) }

            { Initialize-Environment }
            Should -Invoke Get-EventLog -Exactly 1
        }

        It 'Should not throw error if event log found' {
            Mock Get-EventLog { return @{ Log = 'Citrix Autodeploy' } }
            { Initialize-Environment } | Should -Not -Throw
            Should -Invoke Get-EventLog -Exactly 1
        }

        It 'Should add Citrix PowerShell modules' {
            $Modules = @(
                "Citrix.ADIdentity.Commands",
                "Citrix.Broker.Commands",
                "Citrix.Common.Commands",
                "Citrix.ConfigurationLogging.Commands",
                "Citrix.Host.Commands",
                "Citrix.MachineCreation.Commands"
            )

            { Initialize-Environment } | Should -Not -Throw
            $Modules | ForEach-Object { Get-Module -Name $_ } | Should -Not -BeNullOrEmpty
        } -Skip
    }

    Context 'When running in CI environment' {
        BeforeEach {
            $env:CI = $true
        }

        It 'Should not check event log' {
            Mock Get-EventLog { throw "Event log not found" }
            { Initialize-Environment } | Should -Not -Throw
            Should -Invoke Get-EventLog -Exactly 0
        }
    }

    # It 'Should not throw error if event log not found in non-CI environment' {
    #     $env:CI = $false
    #     Mock Get-EventLog { throw "Event log not found" }
    #     { Initialize-Environment } | Should -Throw
    # }

    # It 'Should not throw error if event log found in non-CI environment' {
    #     $env:CI = $false
    #     Mock Get-EventLog { return @{ Log = 'Citrix Autodeploy' } }
    #     { Initialize-Environment } | Should -Not -Throw
    #     Should -Invoke Get-EventLog -Exactly 1
    # }

    # It 'Should not check event log in CI environment' {
    #     $env:CI = $true
    #     Mock Get-EventLog { throw "Event log not found" }
    #     { Initialize-Environment } | Should -Not -Throw
    #     Should -Invoke Get-EventLog -Exactly 0
    # }

    # It 'Should log an error and rethrow if module import fails' {
    #     Mock Import-Module { throw "Module import failed" }
    #     Mock Write-CitrixAutoDeployLog
    #     { Initialize-Environment } | Should -Throw
    #     Assert-MockCalled Write-CitrixAutoDeployLog -Exactly 1 -Scope It
    # } -Skip

    # It 'Should add Citrix PowerShell modules' {

    #     #Remove-Module CitrixAutodeploy -Force
    #     $Modules = @(
    #         "Citrix.ADIdentity.Commands",
    #         "Citrix.Broker.Commands",
    #         "Citrix.Common.Commands",
    #         "Citrix.ConfigurationLogging.Commands",
    #         "Citrix.Host.Commands",
    #         "Citrix.MachineCreation.Commands"
    #     )

    #     #$Modules | ForEach-Object { Get-Module -Name $_ } | Should -Be -BeNullOrEmpty
    #     { Initialize-Environment } | Should -Not -Throw
    #     $Modules | ForEach-Object { Get-Module -Name $_ } | Should -Not -BeNullOrEmpty
    # } -Skip
}