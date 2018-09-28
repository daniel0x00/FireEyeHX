function Find-HXHostSet {
    [CmdletBinding()]
    [OutputType([psobject])]
    param(    
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string] $Uri,

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [Microsoft.PowerShell.Commands.WebRequestSession] $WebSession,

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [string] $Search,

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [string] $Offset,

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [string] $Limit,

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [string] $Sort,

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [string] $Filter
    )

    begin { }
    process {

        # Uri filtering:
        if ($Uri -match '\d$') { $Endpoint = $Uri+'/hx/api/v3/host_sets/?' }
        elseif ($Uri -match '\d/$') { $Endpoint = $Uri+'hx/api/v3/host_sets/?' }
        else { $Endpoint = $Uri + "/?" }

        # Header:
        $headers = @{ "Accept" = "application/json" }

        if ($Search) { $Endpoint = $Endpoint + "&search=" + $Search }
        if ($Offset) { $Endpoint = $Endpoint + "&offset=" + $Offset }
        if ($Limit) { $Endpoint = $Endpoint + "&limit=" + $Limit }
        if ($Sort) { $Endpoint = $Endpoint + "&sort=" + $Sort }
        if ($Filter) { $Endpoint = $Endpoint + "&" + $Filter }

        # Request:
        $WebRequest = Invoke-WebRequest -Uri $Endpoint -WebSession $WebSession -Method Get -Headers $headers -SkipCertificateCheck
        $WebRequestContent = $WebRequest.Content | ConvertFrom-Json

        # Return the object:
        $WebRequestContent.data.entries | Foreach-Object {
            $out = New-Object System.Object
            $out | Add-Member -Type NoteProperty -Name hostset_id -Value $_._id
            $out | Add-Member -Type NoteProperty -Name revision -Value $_._revision
            $out | Add-Member -Type NoteProperty -Name hostset -Value $_.name
            $out | Add-Member -Type NoteProperty -Name type -Value $_.type
            $out | Add-Member -Type NoteProperty -Name endpoint -Value $_.url
            $out | Add-Member -Type NoteProperty -Name Uri -Value $Uri
            $out | Add-Member -Type NoteProperty -Name WebSession -Value $WebSession

            $out
        }
    }
    end { }
}