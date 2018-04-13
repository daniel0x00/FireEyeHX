function Get-HXVersion {
    [CmdletBinding()]
    [OutputType([psobject])]
    param(    
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string] $Uri,

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [Microsoft.PowerShell.Commands.WebRequestSession] $WebSession,

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string] $TokenSession,

        [Parameter(Mandatory=$false)]
        [switch] $Passthru,

        [Parameter(Mandatory=$false)]
        [switch] $Raw
    )

    begin { }
    process {

        # Uri filtering:
        if ($Uri -match '\d$') { $Endpoint = $Uri+'/hx/api/v3/version' }
        elseif ($Uri -match '\d/$') { $Endpoint = $Uri+'hx/api/v3/version' }
        else { $Endpoint = $Uri }

        # Header:
        $headers = @{ "Accept" = "application/json" }
        if (-not($WebSession) -and ($TokenSession)) { $headers += @{ "X-FeApi-Token" = $TokenSession } }

        # Request:
        $WebRequest = Invoke-WebRequest -Uri $Endpoint -WebSession $WebSession -Method Get -Headers $headers
        $WebRequestContent = $WebRequest.Content | ConvertFrom-Json

        # Return the object:
        $out = New-Object System.Object

        if (-not($Raw)) {
            $out | Add-Member -Type NoteProperty -Name applianceId -Value $WebRequestContent.data.applianceId
            $out | Add-Member -Type NoteProperty -Name intelLastUpdateTime -Value $WebRequestContent.data.intelLastUpdateTime
            $out | Add-Member -Type NoteProperty -Name intelVersion -Value $WebRequestContent.data.intelVersion
            $out | Add-Member -Type NoteProperty -Name isUpgraded -Value $WebRequestContent.data.isUpgraded
            $out | Add-Member -Type NoteProperty -Name msoVersion -Value $WebRequestContent.data.msoVersion
            $out | Add-Member -Type NoteProperty -Name version -Value $WebRequestContent.data.version

            # Check if login data is required to be passed thru:
            if ($Passthru) {
                $out | Add-Member -Type NoteProperty -Name Uri -Value $Uri
                if ($WebSession) { $out | Add-Member -Type NoteProperty -Name WebSession -Value $WebSession } 
                if ($TokenSession) { $out | Add-Member -Type NoteProperty -Name TokenSession -Value $TokenSession }
            }
        }
        else {
            $out | Add-Member -Type NoteProperty -Name Uri -Value $Uri
            $out | Add-Member -Type NoteProperty -Name Endpoint -Value $Endpoint
            $out | Add-Member -Type NoteProperty -Name WebSession -Value $WebSession
            $out | Add-Member -Type NoteProperty -Name TokenSession -Value $TokenSession
            $out | Add-Member -Type NoteProperty -Name RequestStatusCode -Value $WebRequest.StatusCode
            $out | Add-Member -Type NoteProperty -Name RequestContent -Value $WebRequestContent
        }
        
        $out
    }
    end { }
}