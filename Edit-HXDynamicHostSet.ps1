function Edit-HXDynamicHostSet {
    [CmdletBinding()]
    [OutputType([psobject])]
    param(    
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [string] $Uri,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $TokenSession, 

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [System.Net.WebProxy] $Proxy,

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias("hostset_id")] 
        [string] $HostSetId,

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias("hostset")] 
        [string] $HostSetName,

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({Test-Path $_})]
        [string] $HostSetValueFile
    )

    begin {
        function Convert-HXDynamicHostSetValue {
            <#
            .Description
                Convert an array of input objects into a HostSetValue object array. Each HostSetValue will be divided in the especified size. 
            #>
            [CmdletBinding()]
            [OutputType([psobject])]
            param(
                [Parameter(Mandatory=$true, ValueFromPipeline=$false, Position=0)]
                [object[]] $Data,
                [Parameter(Mandatory=$false, ValueFromPipeline=$false, Position=0)]
                [ValidateRange(1,100)]
                [int] $Size=100,
                [Parameter(Mandatory=$false, ValueFromPipeline=$false, Position=1)]
                [string] $Operator='cidr',
                [Parameter(Mandatory=$false, ValueFromPipeline=$false, Position=2)]
                [string] $Key='Subnet'
            )
        
            $arraylist = New-Object System.Collections.ArrayList(,$Data)
            $arraylist_count = $arraylist.Count
            $out = @()

            # Use the GetRange method from the ArrayList to enumerate a list of $Size objects. It auto calculate the remaining part of the last range with an implicit if technique. 
            1..[Math]::Ceiling($arraylist_count / $Size) | ForEach-Object {
                $out += New-HXDynamicHostSetValue -Operator $Operator -Key $Key -Value ($arraylist.GetRange(($_-1)*$Size, @{$true=$Size;$false=[Math]::Abs(($_-1)*$Size - ($arraylist_count))}[[Math]::Abs(($_-1)*$Size - ($arraylist_count)) -ge $Size]))
            }
        
            $out
        }
        function New-HXDynamicHostSetUnion {
            [CmdletBinding()]
            [OutputType([psobject])]
            param(
                [Parameter(Mandatory=$true, ValueFromPipeline=$false, Position=0)]
                [psobject] $Value1,
                [Parameter(Mandatory=$true, ValueFromPipeline=$false, Position=1)]
                [psobject] $Value2,
                [Parameter(Mandatory=$false, ValueFromPipeline=$false, Position=2)]
                [string] $Operator='union'
            )
            $values = @()
            $values += $Value1
            $values += $Value2 
            $out = New-Object PSObject
            $out | Add-Member -type NoteProperty -name operator -Value $Operator
            $out | Add-Member -type NoteProperty -name operands -Value $values
            $out
        }
        function New-HXDynamicHostSetValue {
            [CmdletBinding()]
            [OutputType([psobject])]
            param(
                [Parameter(Mandatory=$true, ValueFromPipeline=$false, Position=0)]
                [ValidateCount(1,100)]
                [string[]] $Value,
        
                [Parameter(Mandatory=$false, ValueFromPipeline=$false, Position=1)]
                [string] $Operator='cidr',
        
                [Parameter(Mandatory=$false, ValueFromPipeline=$false, Position=2)]
                [string] $Key='Subnet'
            )
            $out = New-Object PSObject
            $out | Add-Member -type NoteProperty -name operator -Value $Operator
            $out | Add-Member -type NoteProperty -name key -Value $Key
            $out | Add-Member -type NoteProperty -name value -Value $Value
            $out
        }
    }
    process {
        # Uri filtering:
        if ($Uri -match '\d$') { $Endpoint = $Uri+"/hx/api/v3/host_sets/dynamic/$HostsetId" }
        elseif ($Uri -match '\d/$') { $Endpoint = $Uri+"hx/api/v3/host_sets/dynamic/$HostsetId" }
        else { $Endpoint = $Uri }

        ## Build the query request:
        # query object
        $query = Convert-HXDynamicHostSetValue -Data (Get-Content -Path $HostSetValueFile -Encoding utf8)

        # add custom static hostset values to the $query var, like:
        # $query += New-HXDynamicHostSetValue -Operator 'equals' -Key 'Domain' -Value 'corporatedomain.com'
        # 
        # if you want to add a list of hostnames from a file, do it using above mechanism:
        # $query += Convert-HXDynamicHostSetValue -Data (Get-Content -Path PATH_TO_YOUR_FILE -Encoding utf8) -Operator 'matches' -Key 'Hostname'

        # if the HostSetValue is greater than 1 object, means it was breaked down in more than 1 part, so a union is needed:
        if ($query.Count -gt 1) { 
            $unionoutput = $null
            $query | ForEach-Object { 
                if ($unionoutput) { $unionoutput = New-HXDynamicHostSetUnion -Value1 $unionoutput -Value2 $_; }
                else { $unionoutput = $_;  }
            }
            $query = $unionoutput
        }

        # Body object:
        $body = New-Object System.Object
        $body | Add-Member -Type NoteProperty -Name name -Value $HostSetName
        $body | Add-Member -Type NoteProperty -Name query -Value $query

        # Request:
        $WebClient = New-Object System.Net.WebClient
        $WebClient.Headers.add('Accept', 'application/json')
        $WebClient.Headers.add('X-FeApi-Token', $TokenSession)
        if ($null -ne $Proxy) { $WebClient.Proxy = $Proxy }
        $WebRequest = $WebClient.UploadString($Endpoint, 'PUT', ($body | ConvertTo-Json -Compress -Depth 99))
    }
    end { }
}