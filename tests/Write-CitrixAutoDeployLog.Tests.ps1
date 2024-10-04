# FILE: module/CitrixAutodeploy/functions/Write-CtxAutodeployLog.Tests.ps1

Describe 'Write-CtxAutodeployLog' {
    BeforeAll {
        Import-Module "${PSScriptRoot}/../module/CitrixAutodeploy" -Force -ErrorAction Stop -DisableNameChecking -WarningAction SilentlyContinue
    }

    Context 'CI environment' {
        It 'Should write message to host' {
            $env:CI = $true
            $Params = @{
                Message   = 'Test message written to stdout'
                EventId   = 2
                EntryType = [System.Diagnostics.EventLogEntryType]::Information
            }

            { Write-CtxAutodeployLog @Params } | Should -Not -Throw
        }
    }

    Context 'Non-CI environment' {
        It 'Should write to Windows event log in non-CI environment' {
            $env:CI = $false
            $Params = @{
                Message   = 'Test event log message'
                EventId   = 3
                EntryType = [System.Diagnostics.EventLogEntryType]::Information
            }

            Mock Write-EventLog

            { Write-CtxAutodeployLog @Params } | Should -Not -Throw

            Should -Invoke Write-EventLog -Exactly 1 -Scope It
        }
        It 'Should not write to Windows event log if EventId is missing in non-CI environment' {
            $env:CI = $false
            $Params = @{
                Message   = 'Test message without EventId'
                EventId   = 6
                EntryType = [System.Diagnostics.EventLogEntryType]::Information
            }

            Mock Write-EventLog

            { Write-CtxAutodeployLog @Params } | Should -Not -Throw

            Should -Not -Invoke Write-EventLog -Scope It
        }
    }
}