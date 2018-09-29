function Find-HXBulkAcquisitionDetail {
    [CmdletBinding()]
    [OutputType([psobject])]
    param(    
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string] $Uri,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $TokenSession, 

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [System.Net.WebProxy] $Proxy,

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [string] $Offset,

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [string] $Limit,

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [string] $Sort,

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [string] $Filter,

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias("bulkacquisition_id")] 
        [string] $BulkAcquisitionId,

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [string] $Hostset,

        [Parameter(Mandatory=$false)]
        [switch] $Passthru,

        [Parameter(Mandatory=$false)]
        [switch] $Raw
    )

    begin { }
    process {
        # Uri filtering:
        if ($Uri -match '\d$') { $Endpoint = $Uri+"/hx/api/v3/acqs/bulk/$BulkAcquisitionId/hosts?" }
        elseif ($Uri -match '\d/$') { $Endpoint = $Uri+"hx/api/v3/acqs/bulk/$BulkAcquisitionId/hosts?" }
        else { $Endpoint = $Uri + "/?" }

        # Enable auto-search by a given host-set id:
        if ($Offset) { $Endpoint = $Endpoint + "&offset=" + $Offset }
        if ($Limit) { $Endpoint = $Endpoint + "&limit=" + $Limit }
        if ($Sort) { $Endpoint = $Endpoint + "&sort=" + $Sort }
        if ($Filter) { $Endpoint = $Endpoint + "&" + $Filter }

        # Request:
        $WebClient = New-Object System.Net.WebClient
        $WebClient.Headers.add('Accept', 'application/json')
        $WebClient.Headers.add('X-FeApi-Token', $TokenSession)
        if ($null -ne $Proxy) { $WebClient.Proxy = $Proxy }
        $WebRequest = $WebClient.DownloadString($Endpoint)
        $WebRequestContent = $WebRequest | ConvertFrom-Json

        # Return the object:
        $WebRequestContent.data.entries | Foreach-Object {
            $out = New-Object System.Object
            $out | Add-Member -Type NoteProperty -Name bulkacquisition_id -Value $_.bulk_acq._id
            if ($Hostset) { $out | Add-Member -Type NoteProperty -Name hostset -Value $Hostset } 
            $out | Add-Member -Type NoteProperty -Name revision -Value $_._revision
            $out | Add-Member -Type NoteProperty -Name complete_at -Value $_.complete_at
            $out | Add-Member -Type NoteProperty -Name host_id -Value $_.host._id
            $out | Add-Member -Type NoteProperty -Name hostname -Value $_.host.hostname
            $out | Add-Member -Type NoteProperty -Name queued_at -Value $_.queued_at
            $out | Add-Member -Type NoteProperty -Name acquisition -Value $_.result.url
            $out | Add-Member -Type NoteProperty -Name result_bytes -Value $_.result.bytes
            $out | Add-Member -Type NoteProperty -Name result_ordinal -Value $_.result_ordinal
            $out | Add-Member -Type NoteProperty -Name state -Value $_.state
            $out | Add-Member -Type NoteProperty -Name error -Value $_.error
            $out | Add-Member -Type NoteProperty -Name Uri -Value $Uri
            $out | Add-Member -Type NoteProperty -Name TokenSession -Value $TokenSession
            if ($null -ne $Proxy) { $out | Add-Member -Type NoteProperty -Name Proxy -Value $Proxy } 
            
            $out
        }
    }
    end { }
}