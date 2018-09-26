function Find-HXHostSetList {
    [CmdletBinding()]
    [OutputType([psobject])]
    param(    
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string] $Uri,

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [Microsoft.PowerShell.Commands.WebRequestSession] $WebSession,

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string] $TokenSession, 

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [string] $Hostset,

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias("hostset_id")] 
        [int] $HostsetId,

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

        [Parameter(Mandatory=$false)]
        [switch] $Passthru

        # TODO: has_* fields. 
    )

    begin { }
    process {

        # Uri filtering:
        if ($Uri -match '\d$') { $Endpoint = $Uri+"/hx/api/v3/host_sets/$HostsetId/hosts/?" }
        elseif ($Uri -match '\d/$') { $Endpoint = $Uri+"hx/api/v3/host_sets/$HostsetId/hosts/?" }
        else { $Endpoint = $Uri + "/?" }

         # Header:
         $headers = @{ "Accept" = "application/json" }
         if (-not($WebSession) -and ($TokenSession)) { $headers += @{ "X-FeApi-Token" = $TokenSession } }

        if ($Search) { $Endpoint = $Endpoint + "&search=" + $Search }
        if ($Offset) { $Endpoint = $Endpoint + "&offset=" + $Offset }
        if ($Limit) { $Endpoint = $Endpoint + "&limit=" + $Limit }
        if ($Sort) { $Endpoint = $Endpoint + "&sort=" + $Sort }
        if ($Filter) { $Endpoint = $Endpoint + "&" + $Filter }

        # Request:
        $WebRequest = Invoke-WebRequest -Uri $Endpoint -WebSession $WebSession -Method Get -Headers $headers -SkipCertificateCheck
        $WebRequestContent = $WebRequest.Content | ConvertFrom-Json

        # Return the object:
        
        $out = New-Object System.Object
        $out | Add-Member -Type NoteProperty -Name hostset_id -Value $HostsetId
        $out | Add-Member -Type NoteProperty -Name hostset -Value $Hostset
        $out | Add-Member -Type NoteProperty -Name data -Value $WebRequestContent.data

        # Check if login data is required to be passed thru:
        if ($Passthru) {
            $out | Add-Member -Type NoteProperty -Name Uri -Value $Uri
            if ($WebSession) { $out | Add-Member -Type NoteProperty -Name WebSession -Value $WebSession } 
            if ($TokenSession) { $out | Add-Member -Type NoteProperty -Name TokenSession -Value $TokenSession }
        }

        $out
    }
    end { }
}