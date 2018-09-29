function Find-HXHostSetList {
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
        [Alias("hostset_id")] 
        [int] $HostsetId,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string] $Hostset,     

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

        # TODO: has_* fields. 
    )

    begin { }
    process {

        # Uri filtering:
        if ($Uri -match '\d$') { $Endpoint = $Uri + "/hx/api/v3/host_sets/$HostsetId/hosts/?" }
        elseif ($Uri -match '\d/$') { $Endpoint = $Uri + "hx/api/v3/host_sets/$HostsetId/hosts/?" }
        else { $Endpoint = $Uri + "/?" }

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
        $out = New-Object System.Object
        $out | Add-Member -Type NoteProperty -Name hostset_id -Value $HostsetId
        $out | Add-Member -Type NoteProperty -Name hostset -Value $Hostset
        $out | Add-Member -Type NoteProperty -Name data -Value $WebRequestContent.data
        $out | Add-Member -Type NoteProperty -Name Uri -Value $Uri
        $out | Add-Member -Type NoteProperty -Name TokenSession -Value $TokenSession
        if ($null -ne $Proxy) { $out | Add-Member -Type NoteProperty -Name Proxy -Value $Proxy } 

        $out
    }
    end { }
}