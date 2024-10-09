function Wait-ForIdentityPoolUnlock {
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$IdentityPool,

        [Parameter(Mandatory)]
        [string]$AdminAddress,

        [Parameter()]
        [int]$Timeout = 60
    )

    Write-VerboseLog -Message "Function {MyCommand} called with parameters: {PSBoundParameters}" -PropertyValues $MyInvocation.MyCommand, ($PSBoundParameters | Out-String)
    Write-VerboseLog -Message "Identity pool {IdentityPoolName} is locked. Waiting {Timeout} seconds for it to unlock" -PropertyValues $IdentityPool.IdentityPoolName, $Timeout

    $Stopwatch = [Diagnostics.Stopwatch]::StartNew()

    while ($IdentityPool.Lock -and $Stopwatch.Elapsed.Seconds -le $Timeout) {
        Start-Sleep -Seconds 1
        $IdentityPool = Get-AcctIdentityPool -AdminAddress $AdminAddress -IdentityPoolName $IdentityPool.IdentityPoolName
    }
    Write-VerboseLog -Message "Identity pool {IdentityPoolName} unlocked after {ElapsedSeconds}" -PropertyValues $IdentityPool.IdentityPoolName, $Stopwatch.Elapsed.Seconds
    $Stopwatch.Stop()
}
