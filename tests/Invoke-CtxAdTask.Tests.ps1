Describe 'Invoke-CtxAdTask' {
    $TestCases = @(
        @{ Name = 'PreTask';  Type = 'Pre'  },
        @{ Name = 'PostTask'; Type = 'Post' }
    )

    BeforeAll {
        Import-Module "${PSScriptRoot}\..\module\CitrixAutodeploy\functions\Invoke-CtxAdTask.ps1"
    }

    It 'Should execute <_.Name>' -TestCases $TestCases {
        param($Name, $Type)

        $ExpectedOutput = "A test ${Name} script was executed"
        $Task           = "${PSScriptRoot}\test_${Name}.ps1"
        $MachineName    = 'test-machine-name'

        Set-Content -Path $Task -Value "'${ExpectedOutput}'"

        $ActualOutput = Invoke-CtxAdTask -Task $Task -MachineName $MachineName -Type $Type
        $ActualOutput | Should -Be $ExpectedOutput
    }

    # It 'Should execute pre-task script' {
    #     $ExpectedOutput = 'A test pre-task script was executed'
    #     $PreTask        = "${PSScriptRoot}\test_pre_task.ps1"
    #     $MachineName    = 'test-machine-name'

    #     Set-Content -Path $PreTask -Value "'${ExpectedOutput}'"

    #     $ActualOutput = Invoke-CtxAdTask -PreTask $PreTask -MachineName $MachineName -Type Pre
    #     $ActualOutput | Should -Be $ExpectedOutput
    # }

    # It 'Should execute post-task script' {
    #     $ExpectedOutput = 'A test post-task script was executed'
    #     $PostTask       = "${PSScriptRoot}\test_post_task.ps1"
    #     $MachineName    = 'test-machine-name'

    #     Set-Content -Path $PreTask -Value "'${ExpectedOutput}'"

    #     $ActualOutput = Invoke-CtxAdTask -Task $PostTask -MachineName $MachineName -Type Post
    #     $ActualOutput | Should -Be $ExpectedOutput
    # }

    # It 'Should throw error if pre-task script does not exist' {
    #     $PreTask     = "${PSScriptRoot}\non_existent_pre_task.ps1"
    #     $MachineName = 'test-machine-name'

    #     { Invoke-PreTask -PreTask $PreTask -MachineName $MachineName -ErrorVariable Errors } | Should -Throw
    # }

    # It 'Should throw error if pre-task script fails' {
    #     $PreTask     = "${PSScriptRoot}\test_pre_task.ps1"
    #     $MachineName = 'test-machine-name'

    #     Set-Content -Path $PreTask -Value 'throw "Test error"'

    #     { Invoke-PreTask -PreTask $PreTask -MachineName $MachineName } | Should -Throw
    # }
}
