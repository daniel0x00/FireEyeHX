function Find-HXAlert {
    [CmdletBinding()]
    [OutputType([psobject])]
    param(    
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string] $Uri,

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [Microsoft.PowerShell.Commands.WebRequestSession] $WebSession,

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [Alias("host_id")] 
        [string] $HostId = 'undefined',

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [Alias("hostset_id")] 
        [int] $HostsetId = 0,
        
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string] $Hostset = 'undefined',

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string] $Hostname = 'undefined',

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string] $Domain = 'undefined',

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [Alias("agent_version")] 
        [string] $AgentVersion = 'undefined',

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [Alias("last_poll_ip")] 
        [string] $IpAddress = 'undefined',

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [string] $Resolution,

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
        if ($Uri -match '\d$') { $Endpoint = $Uri+'/hx/api/v3/alerts/?' }
        elseif ($Uri -match '\d/$') { $Endpoint = $Uri+'hx/api/v3/host_sets/?' }
        else { $Endpoint = $Uri + "/?" }

        # Header:
        $headers = @{ "Accept" = "application/json" }

        # Filters:
        if ($Resolution) { $Endpoint = $Endpoint + "&search=" + $Search }
        if ($Offset) { $Endpoint = $Endpoint + "&offset=" + $Offset }
        if ($Limit) { $Endpoint = $Endpoint + "&limit=" + $Limit }
        if ($Sort) { $Endpoint = $Endpoint + "&sort=" + $Sort }

        # Build filterQuery value:
        if ($HostId -ne 'undefined') { $Filter = "agent._id=$HostId" }
        #$payload = "{`"operator`": `"eq`",`"arg`": [`"$HostId`"],`"field`": `"hostname`"}"
        
        # Establish the filter:
        if ($Filter) { $Endpoint = $Endpoint + "&" + $Filter }

        # Request:
        $WebRequest = Invoke-WebRequest -Uri $Endpoint -WebSession $WebSession -Method Get -Headers $headers -SkipCertificateCheck
        $WebRequestContent = $WebRequest.Content | ConvertFrom-Json

        # Return the object:
        # Return the object:
        $WebRequestContent.data.entries.foreach({
            # Save the pipeline object (host information):
            $entry = $_

            # Process the output:
            if ($HostId -ne 'undefined') { 
                $entry | Select-Object @{name = 'alert_id'; expression = {$_._id}}, `
                    @{name = 'host_id'; expression = {$HostId}}, 
                    @{name = 'hostset_id'; expression = {$HostsetId}}, 
                    @{name = 'hostset'; expression = {$Hostset}}, `
                    @{name = 'hostname'; expression = {$Hostname}}, `
                    @{name = 'domain'; expression = {$Domain}}, `
                    @{name = 'agent_version'; expression = {$AgentVersion}}, `
                    @{name = 'last_poll_ip'; expression = {$IpAddress}}, `
                    @{name = 'Uri'; expression = {$Uri}}, `
                    @{name = 'WebSession'; expression = {$WebSession}}, `
                    * | Select-Object -ExcludeProperty _id
            }
            else {
                $entry | Select-Object @{name = 'alert_id'; expression = {$_._id}}, `
                    @{name = 'Uri'; expression = {$Uri}}, `
                    @{name = 'WebSession'; expression = {$WebSession}}, `
                    * | Select-Object -ExcludeProperty _id
            }
        })
    }
    end { }
}