function Download-HXBulkAcquisition {
    [CmdletBinding()]
    [OutputType([psobject])]
    param(    
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string] $Uri,

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [Microsoft.PowerShell.Commands.WebRequestSession] $WebSession,

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string] $TokenSession, 

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string] $Acquisition,

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [string] $Hostname="undefined",

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [string] $Path
    )

    begin { }
    process {

        # Uri filtering:
        if ($Uri -match '\d$') { 
            $Endpoint = $Uri+$Acquisition
            Write-Verbose "Endpoint: $Endpoint"
        }

        # Timestamp calculation:
        $timestamp = Get-Date -Format o | foreach {$_ -replace ":", "."}

        # Path filtering:
        if (-not($Path -match '.zip$')) {
            $_path = (Get-Item -Path ".\" -Verbose).FullName + $timestamp + '_' + $Hostname + '_' + [System.IO.Path]::GetFileName($Acquisition)
        }

        # Header:
        $headers = @{ "Accept" = "application/octet-stream" }
        if (-not($WebSession) -and ($TokenSession)) { $headers += @{ "X-FeApi-Token" = $TokenSession } }

        # Request:
        $null = Invoke-WebRequest -Uri $Endpoint -WebSession $WebSession -Method Get -Headers $headers -OutFile $_path 

        Write-Verbose "File $Endpoint downloaded successfully to $_path"
    }
    end { }
}