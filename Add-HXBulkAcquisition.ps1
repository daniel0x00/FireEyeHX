function Add-HXBulkAcquisition {
    [CmdletBinding()]
    [OutputType([psobject])]
    param(
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string] $Uri,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $TokenSession, 

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [System.Net.WebProxy] $Proxy,

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateSet("win", "linux", "osx", "*")]
        [string] $Platform,

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({Test-Path $_})]
        [string] $ScriptFile,

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias("hostset_id")] 
        [int] $HostsetId,

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [string] $Comment="PSAutomaticBulkAcquisition"
    )

    begin { }
    process {
        # Uri filtering:
        if ($Uri -match '\d$') { $Endpoint = $Uri+'/hx/api/v3/acqs/bulk' }
        elseif ($Uri -match '\d/$') { $Endpoint = $Uri+'hx/api/v3/acqs/bulk' }
        else { $Endpoint = $Uri + "/?" }

        # Body:
        $base64_script = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes((Get-Content -Path $ScriptFile -Raw -Encoding utf8)))
        $body = "{`"host_set`":{`"_id`":$HostsetId},`"scripts`":[{`"platform`":`"$Platform`",`"b64`":`"$base64_script`"}],`"comment`":`"$Comment`"}"

        # Request:
        $WebClient = New-Object System.Net.WebClient
        $WebClient.Headers.add('Accept', 'application/json')
        $WebClient.Headers.add('X-FeApi-Token', $TokenSession)
        if ($null -ne $Proxy) { $WebClient.Proxy = $Proxy }
        $WebRequest = $WebClient.UploadString($Endpoint, $body)
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