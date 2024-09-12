Describe "Wait-ForIdentityPoolUnlock" {
    It "Should wait until the identity pool is unlocked within the timeout" {
        $IdentityPool = [PSCustomObject]@{ Lock = $true }

        Mock Start-Sleep { $IdentityPool.Lock = $false }

        { Wait-ForIdentityPoolUnlock -IdentityPool $IdentityPool -Timeout 5 } | Should -Not -Throw
    }

    It "Should timeout if the identity pool remains locked" {
        $IdentityPool = [PSCustomObject]@{ Lock = $true }

        { Wait-ForIdentityPoolUnlock -IdentityPool $IdentityPool -Timeout 5 } | Should -Throw
    }
}
