Describe 'Write-CtxAutodeployLog' {
    BeforeAll {
        Import-Module ${PSScriptRoot}\..\module\CitrixAutodeploy -Force -ErrorAction Stop -DisableNameChecking -WarningAction SilentlyContinue
    }

    It 'Should write error message to error stream in CI environment' {
        $env:CI = $true
        $Message = "Test error message written to error stream"
        $EventId = 1
        $EntryType = [System.Diagnostics.EventLogEntryType]::Error

        { Write-CtxAutodeployLog -Message $Message -EventId $EventId -EntryType $EntryType -ErrorVariable Errors -ErrorAction SilentlyContinue
            $Errors.Count | Should Be 1
            $Errors[0].Exception.Message | Should Be (
                $Message
            )
        }
    }

    It 'Should write message to host in CI environment' {
        $env:CI = $true
        $Message = "Test message written to stdout"
        $EventId = 2
        $EntryType = [System.Diagnostics.EventLogEntryType]::Information

        { Write-CtxAutodeployLog -Message $Message -EventId $EventId -EntryType $EntryType } | Should -Not -Throw
    }

    It 'Should write to Windows event log in non-CI environment' {
        $env:CI = $false
        $Message = "Test event log message"
        $EventId = 3
        $EntryType = [System.Diagnostics.EventLogEntryType]::Information

        { Write-CtxAutodeployLog -Message $Message -EventId $EventId -EntryType $EntryType } | Should -Not -Throw
    }
}
