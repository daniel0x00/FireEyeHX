function Get-HXHostSet {
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
        [switch] $Passthru,

        [Parameter(Mandatory=$false)]
        [switch] $Raw
    )

    begin { }
    process {

        # Uri filtering:
        if ($Uri -match '\d$') { $Endpoint = $Uri+'/hx/api/v3/host_sets/?' }
        elseif ($Uri -match '\d/$') { $Endpoint = $Uri+'hx/api/v3/host_sets/?' }
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
        $WebRequest = Invoke-WebRequest -Uri $Endpoint -WebSession $WebSession -Method Get -Headers $headers
        $WebRequestContent = $WebRequest.Content | ConvertFrom-Json

        # Return the object:
        

        if (-not($Raw)) {
            $WebRequestContent.data.entries | Foreach-Object {
                $out = New-Object System.Object
                $out | Add-Member -Type NoteProperty -Name id -Value $_._id
                $out | Add-Member -Type NoteProperty -Name revision -Value $_._revision
                $out | Add-Member -Type NoteProperty -Name hostset -Value $_.name
                $out | Add-Member -Type NoteProperty -Name type -Value $_.type
                $out | Add-Member -Type NoteProperty -Name url -Value $_.url

                # Check if login data is required to be passed thru:
                if ($Passthru) {
                    $out | Add-Member -Type NoteProperty -Name Uri -Value $Uri
                    if ($WebSession) { $out | Add-Member -Type NoteProperty -Name WebSession -Value $WebSession } 
                    if ($TokenSession) { $out | Add-Member -Type NoteProperty -Name TokenSession -Value $TokenSession }
                }

                $out
            }
        }
        else {
            $out = New-Object System.Object
            $out | Add-Member -Type NoteProperty -Name Uri -Value $Uri
            $out | Add-Member -Type NoteProperty -Name Endpoint -Value $Endpoint
            $out | Add-Member -Type NoteProperty -Name WebSession -Value $WebSession
            $out | Add-Member -Type NoteProperty -Name TokenSession -Value $TokenSession
            $out | Add-Member -Type NoteProperty -Name RequestStatusCode -Value $WebRequest.StatusCode
            $out | Add-Member -Type NoteProperty -Name RequestContent -Value $WebRequestContent
            $out
        }
    }
    end { }
}