function Test-DdcConnection {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$AdminAddress,

        [Parameter()]
        [ValidateSet('http', 'https')]
        [string]$Protocol = 'https'
    )

    Write-VerboseLog -Message 'Function {MyCommand} called with parameters: {PSBoundParameters}' -PropertyValues $MyInvocation.MyCommand, ($PSBoundParameters | Out-String)

    Write-DebugLog -Message 'Testing connection to delivery controller {AdminAddress}:{Protocol}' -PropertyValues $AdminAddress, $Protocol
    # This API endpoint is only available in CVAD 2308+ according to this document:
    # https://developer-docs.citrix.com/en-us/citrix-virtual-apps-desktops/citrix-cvad-rest-apis/citrix-virtual-apps-and-desktops-apis-release-notes#citrix-virtual-apps-and-desktops-7-2308
    $Endpoint = 'cvad/manage/HealthCheck'
    $Uri = "${Protocol}://${AdminAddress}/${Endpoint}"

    try {
        return Invoke-RestMethod -Uri $Uri -Method Get -UseBasicParsing
    }
    catch {
        Write-DebugLog -Message 'Connection to delivery controller {AdminAddress}:{Protocol} failed' -PropertyValues $AdminAddress, $Protocol
        return $false
    }
}
