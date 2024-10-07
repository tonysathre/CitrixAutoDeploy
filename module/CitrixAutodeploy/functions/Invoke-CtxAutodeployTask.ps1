function Invoke-CtxAutodeployTask {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Task,

        [Parameter(Mandatory)]
        [PSCustomObject]$ArgumentList,

        [Parameter(Mandatory = $false)]
        [string]$Context,

        [Parameter(Mandatory)]
        [Validateset('Pre', 'Post')]
        [string]$Type
    )

    Write-VerboseLog -Message "Function {MyCommand} called with parameters: {PSBoundParameters}" -PropertyValues $MyInvocation.MyCommand, ($PSBoundParameters | Out-String)
    Write-VerboseLog -Message "Arguments: {ArgumentList}" -PropertyValues $ArgumentList
    Write-InfoLog -Message "Executing {Type}-task script '{FilePath}' for '{Context}'" -PropertyValues $Type, $FilePath, $Context

    try {
        $Output = . $Task
    }
    catch {
        Write-ErrorLog -Message "An error occurred while executing {Type}-task script '{FilePath}'" -Exception $_.Exception -ErrorRecord $_ -PropertyValues $Type, $FilePath
    }

    Write-InfoLog -Message "{Type}-task script '{FilePath}' output: {Output}" -PropertyValues $Type, $FilePath, $Output
    Write-InfoLog -Message "{Type}-task script '{FilePath}' executed successfully" -PropertyValues $Type, $Task
}
