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
        if ($Uri -match '\d$') { $Endpoint = $Uri+$Acquisition }

        # Timestamp calculation:
        $timestamp = Get-Date -Format o | foreach {$_ -replace ":", "."}

        # Path filtering:
        if (-not($Path -match '.zip$')) {
            $_path = (Get-Item -Path ".\" -Verbose).FullName + $timestamp + '_' + $Hostname + '_' + [System.IO.Path]::GetFileName($Acquisition)
        }

        # Webclient object. Not using Invoke-WebRequest because the downloaded object is streamed into memory first, harming the performance of the script:
        $wc = New-Object System.Net.WebClient
        $wc.Headers.add('Accept','application/octet-stream')
        $wc.Headers.add('X-FeApi-Token',$TokenSession)
        $wc.DownloadFile($Endpoint, $_path)

        Write-Verbose "File $Endpoint downloaded successfully to $_path"
    }
    end { }
}