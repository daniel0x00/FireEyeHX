function Remove-HXBulkAcquisition {
    [CmdletBinding()]
    [OutputType([psobject])]
    param(
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string] $Uri,

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [Microsoft.PowerShell.Commands.WebRequestSession] $WebSession,

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string] $TokenSession, 

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias("bulkacquisition_id")]
        [int] $BulkAcquisitionId
    )

    begin { }
    process {

        # Uri filtering:
        if ($Uri -match '\d$') { $Endpoint = $Uri+"/hx/api/v3/acqs/bulk/$BulkAcquisitionId" }
        elseif ($Uri -match '\d/$') { $Endpoint = $Uri+"hx/api/v3/acqs/bulk/$BulkAcquisitionId" }
        else { $Endpoint = $Uri + "/?" }

        # Header:
        $headers = @{ "Accept" = "application/json" }
        if (-not($WebSession) -and ($TokenSession)) { $headers += @{ "X-FeApi-Token" = $TokenSession } }

        # Request:
        $WebRequest = Invoke-WebRequest -Uri $Endpoint -WebSession $WebSession -Method Delete -Headers $headers -SkipCertificateCheck
        
    }
    end { }
}