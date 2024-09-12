function Wait-ForIdentityPoolUnlock {
    [CmdletBinding()]
    param(
        [PSCustomObject]$IdentityPool,
        [int]$Timeout
    )

    if ($IdentityPool.Lock) {
        $Stopwatch = [Diagnostics.Stopwatch]::StartNew()
        while ($IdentityPool.Lock -and $Stopwatch.Elapsed.Seconds -le $Timeout) {
            Start-Sleep -Seconds 1
        }
        $Stopwatch.Stop()
    }
}
