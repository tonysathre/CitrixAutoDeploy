function Test-MaxMachineCount {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory)]
        [string]$AdminAddress,

        [Parameter(Mandatory)]
        [PSCustomObject]$InputObject,

        [Parameter(Mandatory)]
        [int]$MaxMachines,

        [Parameter()]
        $MaxRecordCount = 1000000
    )

    Write-VerboseLog -Message 'Function {MyCommand} called with parameters: {PSBoundParameters}' -PropertyValues $MyInvocation.MyCommand, ($PSBoundParameters | Out-String)

    $Params = @{
        AdminAddress   = $AdminAddress
        MaxRecordCount = $MaxRecordCount
    }

    if ($InputObject -is [Citrix.Broker.Admin.SDK.Catalog]) {
        $Params.Add('CatalogName', $InputObject.Name)
    } else {
        $Params.Add('DesktopGroupName', $InputObject.Name)
    }

    try {
        $Machines = Get-BrokerMachine @Params
    }
    catch {
        Write-ErrorLog -Message "Failed getting machines from delivery controller {AdminAddress}" -Exception $_.Exception -ErrorRecord $_ -PropertyValues $AdminAddress
        throw
    }

    if ($Machines.Count -ge $MaxMachines) {
        return $true
    } else {
        return $false
    }
}
