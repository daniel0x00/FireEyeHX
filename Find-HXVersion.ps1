function Find-HXVersion {
    [CmdletBinding()]
    [OutputType([psobject])]
    param(    
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string] $Uri,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $TokenSession, 

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [System.Net.WebProxy] $Proxy
    )

    begin { }
    process {
        # Uri filtering:
        if ($Uri -match '\d$') { $Endpoint = $Uri+'/hx/api/v3/version' }
        elseif ($Uri -match '\d/$') { $Endpoint = $Uri+'hx/api/v3/version' }
        else { $Endpoint = $Uri }

        # Request:
        $WebClient = New-Object System.Net.WebClient
        $WebClient.Headers.add('Accept', 'application/json')
        $WebClient.Headers.add('X-FeApi-Token', $TokenSession)
        if ($null -ne $Proxy) { $WebClient.Proxy = $Proxy }
        $WebRequest = $WebClient.DownloadString($Endpoint)
        $WebRequestContent = $WebRequest | ConvertFrom-Json

        # Return the object:
        $out = New-Object System.Object
        $out | Add-Member -Type NoteProperty -Name applianceId -Value $WebRequestContent.data.applianceId
        $out | Add-Member -Type NoteProperty -Name intelLastUpdateTime -Value $WebRequestContent.data.intelLastUpdateTime
        $out | Add-Member -Type NoteProperty -Name intelVersion -Value $WebRequestContent.data.intelVersion
        $out | Add-Member -Type NoteProperty -Name isUpgraded -Value $WebRequestContent.data.isUpgraded
        $out | Add-Member -Type NoteProperty -Name msoVersion -Value $WebRequestContent.data.msoVersion
        $out | Add-Member -Type NoteProperty -Name version -Value $WebRequestContent.data.version
        $out | Add-Member -Type NoteProperty -Name Uri -Value $Uri
        $out | Add-Member -Type NoteProperty -Name TokenSession -Value $TokenSession
        if ($null -ne $Proxy) { $out | Add-Member -Type NoteProperty -Name Proxy -Value $Proxy } 
        
        $out
    }
    end { }
}