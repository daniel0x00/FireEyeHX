function Find-HXBulkAcquisition {
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
        [string] $Search,

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [string] $Offset,

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [string] $Limit,

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [string] $Sort,

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [string] $Filter,

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [Alias("hostset_id")] 
        [string] $HostSetId,

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [string] $HostSet
    )

    begin { }
    process {
        # Uri filtering:
        if ($Uri -match '\d$') { $Endpoint = $Uri+'/hx/api/v3/acqs/bulk/?' }
        elseif ($Uri -match '\d/$') { $Endpoint = $Uri+'hx/api/v3/acqs/bulk?' }
        else { $Endpoint = $Uri + "/?" }

        # Enable auto-search by a given host-set id:
        if (($HostsetId) -and (-not($Search))) { $Search = $HostsetId }

        if ($Search) { $Endpoint = $Endpoint + "&search=" + $Search }
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
            $out | Add-Member -Type NoteProperty -Name bulkacquisition_id -Value $_._id
            if ($Hostset) { $out | Add-Member -Type NoteProperty -Name hostset -Value $Hostset } 
            $out | Add-Member -Type NoteProperty -Name revision -Value $_._revision
            $out | Add-Member -Type NoteProperty -Name comment -Value $_.comment
            $out | Add-Member -Type NoteProperty -Name create_actor_id -Value $_.create_actor._id
            $out | Add-Member -Type NoteProperty -Name create_actor_username -Value $_.create_actor.username
            $out | Add-Member -Type NoteProperty -Name create_time -Value $_.create_time
            $out | Add-Member -Type NoteProperty -Name update_actor_id -Value $_.update_actor._id
            $out | Add-Member -Type NoteProperty -Name update_actor_username -Value $_.update_actor.username
            $out | Add-Member -Type NoteProperty -Name update_time -Value $_.update_time
            $out | Add-Member -Type NoteProperty -Name state -Value $_.state
            $out | Add-Member -Type NoteProperty -Name endpoint -Value $_.url
            $out | Add-Member -Type NoteProperty -Name running_state -Value $_.stats.running_state
            $out | Add-Member -Type NoteProperty -Name Uri -Value $Uri
            $out | Add-Member -Type NoteProperty -Name TokenSession -Value $TokenSession
            if ($null -ne $Proxy) { $out | Add-Member -Type NoteProperty -Name Proxy -Value $Proxy } 
            
            $out
        }
    }
    end { }
}