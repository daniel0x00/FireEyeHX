function Get-HXBulkAcquisition {
    [CmdletBinding()]
    [OutputType([psobject])]
    param(    
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string] $Uri,

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
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
        [switch] $Raw=$false
    )

    begin { }
    process {

        # Uri filtering:
        if ($Uri -match '\d$') { 
            $Endpoint = $Uri+'/hx/api/v3/acqs/bulk/?'
            Write-Verbose "Endpoint: $Endpoint"
        }
        else { $Endpoint = $Uri + "/?" }

        if ($Search) { $Endpoint = $Endpoint + "&search=" + $Search }
        if ($Offset) { $Endpoint = $Endpoint + "&offset=" + $Offset }
        if ($Limit) { $Endpoint = $Endpoint + "&limit=" + $Limit }
        if ($Sort) { $Endpoint = $Endpoint + "&sort=" + $Sort }
        if ($Filter) { $Endpoint = $Endpoint + "&" + $Filter }

        # Request:
        $WebRequest = Invoke-WebRequest -Uri $Endpoint -WebSession $WebSession -Method Get
        $WebRequestContent = $WebRequest.Content | ConvertFrom-Json


        # Return the object:
        if (-not($Raw)) {
            $WebRequestContent.data.entries | Foreach-Object {
                $out = New-Object System.Object
                $out | Add-Member -Type NoteProperty -Name id -Value $_._id
                $out | Add-Member -Type NoteProperty -Name revision -Value $_._revision
                $out | Add-Member -Type NoteProperty -Name comment -Value $_.comment
                $out | Add-Member -Type NoteProperty -Name create_actor_id -Value $_.create_actor._id
                $out | Add-Member -Type NoteProperty -Name create_actor_name -Value $_.create_actor.username
                $out | Add-Member -Type NoteProperty -Name create_time -Value $_.create_time
                $out | Add-Member -Type NoteProperty -Name update_actor_id -Value $_.update_actor._id
                $out | Add-Member -Type NoteProperty -Name update_actor_name -Value $_.update_actor.username
                $out | Add-Member -Type NoteProperty -Name update_time -Value $_.update_time
                $out | Add-Member -Type NoteProperty -Name state -Value $_.state
                $out | Add-Member -Type NoteProperty -Name url -Value $_.url
                $out | Add-Member -Type NoteProperty -Name running_state -Value $_.stats.running_state
                
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