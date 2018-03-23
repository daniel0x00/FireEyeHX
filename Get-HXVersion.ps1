function Get-HXVersion {
    [CmdletBinding()]
    [OutputType([psobject])]
    param(    
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string] $Uri,

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [Microsoft.PowerShell.Commands.WebRequestSession] $WebSession,

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string] $TokenSession,

        [Parameter(Mandatory=$false)]
        [switch] $Raw=$false
    )

    begin { }
    process {

        # Uri filtering:
        if ($Uri -match '\d$') { 
            $Endpoint = $Uri+'/hx/api/v3/version'
            Write-Verbose "Endpoint: $Endpoint"
        }
        else { $Endpoint = $Uri }

        # Request:
        $WebRequest = Invoke-WebRequest -Uri $Endpoint -WebSession $WebSession -Method Get 
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