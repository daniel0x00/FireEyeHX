function Find-HXHostSet {
    [CmdletBinding()]
    [OutputType([psobject])]
    param(    
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $Uri,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $TokenSession, 

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [System.Net.WebProxy] $Proxy,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string] $Search,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string] $Offset,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string] $Limit,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string] $Sort,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string] $Filter
    )

    begin { }
    process {
        # Uri filtering:
        if ($Uri -match '\d$') { $Endpoint = $Uri + '/hx/api/v3/host_sets/?' }
        elseif ($Uri -match '\d/$') { $Endpoint = $Uri + 'hx/api/v3/host_sets/?' }
        else { $Endpoint = $Uri + "/?" }

        # Searchs:
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
            $out | Add-Member -Type NoteProperty -Name hostset_id -Value $_._id
            $out | Add-Member -Type NoteProperty -Name revision -Value $_._revision
            $out | Add-Member -Type NoteProperty -Name hostset -Value $_.name
            $out | Add-Member -Type NoteProperty -Name type -Value $_.type
            $out | Add-Member -Type NoteProperty -Name endpoint -Value $_.url
            $out | Add-Member -Type NoteProperty -Name Uri -Value $Uri
            $out | Add-Member -Type NoteProperty -Name TokenSession -Value $TokenSession
            if ($null -ne $Proxy) { $out | Add-Member -Type NoteProperty -Name Proxy -Value $Proxy } 

            $out
        }
    }
    end { }
}