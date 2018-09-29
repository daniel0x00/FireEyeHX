function New-HXSession {
    [CmdletBinding()]
    [OutputType([psobject])]
    param(    
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string] $Uri,

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [System.Management.Automation.PSCredential] $Credential,

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [string] $Proxy=$null
    )

    begin { }
    process {
        # Uri filtering:
        if ($Uri -match '\d$') { $Endpoint = $Uri+'/hx/api/v3/token' }
        elseif ($Uri -match '\d/$') { $Endpoint = $Uri+'hx/api/v3/token' }
        else { $Endpoint = $Uri }

        # Get the plaintext password from the credential object:
        $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Credential.Password)
        $password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
        $auth = "Basic " + [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("$($Credential.UserName):$($password)"))

        # Create the object to interact by HTTP
        # Usage of HttpWebRequest because WebClient cannot capture response headers properly:
        $WebRequest = [System.Net.HttpWebRequest]::Create($Endpoint);
        $WebRequest.Headers.Add('Authorization',$auth)

        try {
            # Make the request to the controller:
            $WebRequestResponse = $WebRequest.GetResponse()

            # Grab the token:
            $TokenSession = $WebRequestResponse.Headers['X-FeApi-Token'] | Out-String
            $TokenSession = $TokenSession -replace "`t|`n|`r","" # bugfix: 'out-string' introduce a new-line at the end of the string. This hack will remove it. 
                        
            # Return the object:
            $out = New-Object System.Object
            $out | Add-Member -Type NoteProperty -Name Uri -Value $Uri
            $out | Add-Member -Type NoteProperty -Name Endpoint -Value $Endpoint
            $out | Add-Member -Type NoteProperty -Name TokenSession -Value $TokenSession
            $out
        }
        catch { throw }
    }
    end { }
}