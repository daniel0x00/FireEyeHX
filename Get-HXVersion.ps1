function Get-HXVersion {
    [CmdletBinding()]
    [OutputType([psobject])]
    param(    
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string] $Uri,

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [Microsoft.PowerShell.Commands.WebRequestSession] $WebSession,

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string] $TokenSession
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

        # Return the object:
        $out = New-Object System.Object
        $out | Add-Member -Type NoteProperty -Name Uri -Value $Uri
        $out | Add-Member -Type NoteProperty -Name Endpoint -Value $Endpoint
        $out | Add-Member -Type NoteProperty -Name WebSession -Value $WebSession
        $out | Add-Member -Type NoteProperty -Name TokenSession -Value $TokenSession
        $out | Add-Member -Type NoteProperty -Name RequestStatusCode -Value $WebRequest.StatusCode
        $out | Add-Member -Type NoteProperty -Name RequestContent -Value $WebRequest.Content
        $out
    }
    end { }
}