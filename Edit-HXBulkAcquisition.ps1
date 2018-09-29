function Edit-HXBulkAcquisition {
    [CmdletBinding()]
    [OutputType([psobject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $Uri,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $TokenSession, 

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [System.Net.WebProxy] $Proxy,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias("bulkacquisition_id")]
        [int] $BulkAcquisitionId,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateSet("start", "stop", "refresh")]
        [string] $Action,

        [Parameter(Mandatory = $false)]
        [switch] $Passthru,

        [Parameter(Mandatory = $false)]
        [switch] $Raw
    )

    begin { }
    process {
        # Uri filtering:
        if ($Uri -match '\d$') { $Endpoint = $Uri + "/hx/api/v3/acqs/bulk/$BulkAcquisitionId/actions/$Action" }
        elseif ($Uri -match '\d/$') { $Endpoint = $Uri + "hx/api/v3/acqs/bulk/$BulkAcquisitionId/actions/$Action" }
        else { $Endpoint = $Uri + "/?" }

        # Request:
        $WebClient = New-Object System.Net.WebClient
        $WebClient.Headers.add('Accept', 'application/json')
        $WebClient.Headers.add('X-FeApi-Token', $TokenSession)
        if ($null -ne $Proxy) { $WebClient.Proxy = $Proxy }
        $WebRequest = $WebClient.DownloadString($Endpoint)
        $WebRequestContent = $WebRequest | ConvertFrom-Json

        # Return the object:
        $WebRequestContent.data | Foreach-Object {
            $out = New-Object System.Object
            $out | Add-Member -Type NoteProperty -Name bulkacquisition_id -Value $_._id
            $out | Add-Member -Type NoteProperty -Name revision -Value $_._revision
            $out | Add-Member -Type NoteProperty -Name comment -Value $_.comment
            $out | Add-Member -Type NoteProperty -Name create_time -Value $_.create_time
            $out | Add-Member -Type NoteProperty -Name state -Value $_.state
            $out | Add-Member -Type NoteProperty -Name endpoint -Value $_.url
            $out | Add-Member -Type NoteProperty -Name Uri -Value $Uri
            $out | Add-Member -Type NoteProperty -Name TokenSession -Value $TokenSession
            if ($null -ne $Proxy) { $out | Add-Member -Type NoteProperty -Name Proxy -Value $Proxy } 

            $out
        }
    }
    end { }
}