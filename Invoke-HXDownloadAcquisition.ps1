function Invoke-HXDownloadAcquisition {
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
        [string] $Acquisition,

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [string] $Hostname='undefined',

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [string] $Hostset='undefined',

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [string] $Separator='~',

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [string] $Path
    )

    begin { }
    process {
        # Uri filtering:
        if ($Uri -match '\d$') { $Endpoint = $Uri+$Acquisition }
        elseif ($Uri -match '\d/$') { $Endpoint = $Uri+$Acquisition }

        # Timestamp calculation:
        $timestamp = Get-Date -Format o | ForEach-Object {$_ -replace ":", "."}

        # Controller name:
        $controller = [string](([regex]::Match($Uri,"https?://(?<controller>[\w\-]+)\.")).groups["controller"].value)

        # Path filtering:
        if (-not($Path -match '.zip$')) {
            ## filename with FireEye hostname id on it:

            #$_path = (Get-Item -Path ".\" -Verbose).FullName + $timestamp + $Separator + $controller + $Separator + $Hostset + $Separator + $Hostname + $Separator + [System.IO.Path]::GetFileName($Acquisition)
            
            ## Filename without FireEye hostname id on it:

            # Determine the path to write to:
            if ($Path) { $_path = [System.IO.Path]::GetFullPath($Path) }
            else { $_path = (Get-Item -Path ".\" -Verbose).FullName }

            # Set up the path to the 'raw' folder:
            $_path = [System.IO.Path]::Combine($_path, 'raw')
            New-Item -ItemType Directory -Force -Path $_path -ErrorAction Stop | Out-Null

            # Determine the hostname:
            if ($Hostname -eq 'undefined') { $_hostname = [System.IO.Path]::GetFileName($Acquisition) -replace '.zip', '' }
            else { $_hostname = $Hostname }

            $_path = [System.IO.Path]::Combine($_path, $timestamp + $Separator + $controller + $Separator + $Hostset + $Separator + $_hostname + ".zip")
        }
        else { $_path = $Path }

        # Request:
        $WebClient = New-Object System.Net.WebClient
        $WebClient.Headers.add('Accept', 'octet-stream')
        $WebClient.Headers.add('X-FeApi-Token', $TokenSession)
        if ($null -ne $Proxy) { $WebClient.Proxy = $Proxy }
        $WebClient.DownloadFile($Endpoint, $_path)

        # Return the object:
        $out = New-Object System.Object
        $out | Add-Member -Type NoteProperty -Name Uri -Value $Uri
        $out | Add-Member -Type NoteProperty -Name Acquisition -Value $Acquisition
        $out | Add-Member -Type NoteProperty -Name Hostname -Value $Hostname
        $out | Add-Member -Type NoteProperty -Name Hostset -Value $Hostset
        $out | Add-Member -Type NoteProperty -Name File -Value $_path
        $out
    }
    end { }
}