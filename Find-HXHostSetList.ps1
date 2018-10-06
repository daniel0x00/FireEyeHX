function Find-HXHostSetList {
    [CmdletBinding()]
    [OutputType([psobject])]
    param(    
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $Uri,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Microsoft.PowerShell.Commands.WebRequestSession] $WebSession,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias("hostset_id")] 
        [int] $HostsetId,
        
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string] $Hostset = 'undefined',

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string] $Search,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string] $Offset,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string] $Limit,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string] $Sort,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string] $Filter,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [switch] $HasActiveThreats,
        
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [switch] $HasExecutionAlerts,
        
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [switch] $HasExploitAlerts,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [switch] $HasExploitBlocks,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [switch] $HasMalwareAlerts,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [switch] $HasMalwareCleaned,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [switch] $HasMalwareQuarantined,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [switch] $HasPresenceAlerts
    )

    begin { }
    process {
        # Uri filtering:
        if ($Uri -match '\d$') { $Endpoint = $Uri + "/hx/api/v3/host_sets/$HostsetId/hosts/?" }
        elseif ($Uri -match '\d/$') { $Endpoint = $Uri + "hx/api/v3/host_sets/$HostsetId/hosts/?" }
        else { $Endpoint = $Uri + "/?" }

        # Header:
        $headers = @{ "Accept" = "application/json" }

        if ($Search) { $Endpoint = $Endpoint + "&search=" + $Search }
        if ($Offset) { $Endpoint = $Endpoint + "&offset=" + $Offset }
        if ($Limit) { $Endpoint = $Endpoint + "&limit=" + $Limit }
        if ($Sort) { $Endpoint = $Endpoint + "&sort=" + $Sort }
        if ($HasActiveThreats) { $Endpoint = $Endpoint + "&has_active_threats=1" }
        if ($HasExecutionAlerts) { $Endpoint = $Endpoint + "&has_execution_alerts=1" }
        if ($HasExploitAlerts) { $Endpoint = $Endpoint + "&has_exploit_alerts=1" }
        if ($HasExploitBlocks) { $Endpoint = $Endpoint + "&has_exploit_blocks=1" }
        if ($HasMalwareAlerts) { $Endpoint = $Endpoint + "&has_malware_alerts=1" }
        if ($HasMalwareCleaned) { $Endpoint = $Endpoint + "&has_malware_cleaned=1" }
        if ($HasMalwareQuarantined) { $Endpoint = $Endpoint + "&has_malware_quarantined=1" }
        if ($HasPresenceAlerts) { $Endpoint = $Endpoint + "&has_presence_alerts=1" }
        if ($Filter) { $Endpoint = $Endpoint + "&" + $Filter }

        # Request:
        $WebRequest = Invoke-WebRequest -Uri $Endpoint -WebSession $WebSession -Method Get -Headers $headers -SkipCertificateCheck
        $WebRequestContent = $WebRequest.Content | ConvertFrom-Json

        # Return the object:
        $WebRequestContent.data.entries.foreach( {
            # This will add the previous objects of the pipeline to the output, as well as will produce the output of the function at the same time:
                $_ | Select-Object @{name = 'host_id'; e = {$_._id}}, `
                    @{name = 'hostset_id'; e = {$HostsetId}}, 
                    @{name = 'hostset'; e = {$Hostset}}, `
                    @{name = 'Uri'; e = {$Uri}}, `
                    @{name = 'WebSession'; e = {$WebSession}}, `
                    * | Select-Object -ExcludeProperty _id
            })
    }
    end { }
}