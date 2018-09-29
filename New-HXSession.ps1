function New-HXSession {
    [CmdletBinding()]
    [OutputType([psobject])]
    param(    
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $Uri,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [System.Management.Automation.PSCredential] $Credential,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [object] $Proxy = $false,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [switch] $SkipCertificateCheck
    )

    begin { 
        if ($SkipCertificateCheck) {
            add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
            [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
        }
    }
    process {
        # Uri filtering:
        if ($Uri -match '\d$') { $Endpoint = $Uri + '/hx/api/v3/token' }
        elseif ($Uri -match '\d/$') { $Endpoint = $Uri + 'hx/api/v3/token' }
        else { $Endpoint = $Uri }

        # Get the plaintext password from the credential object:
        $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Credential.Password)
        $password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
        $auth = "Basic " + [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("$($Credential.UserName):$($password)"))

        # Create the object to interact by HTTP
        # Usage of HttpWebRequest because WebClient cannot capture response headers properly:
        $WebRequest = [System.Net.HttpWebRequest]::Create($Endpoint);
        $WebRequest.Headers.Add('Authorization', $auth)
        # Proxy support:
        if ($false -ne $Proxy) { 
            $IProxy = New-Object System.Net.WebProxy
            $IProxy.Address = $Proxy
            $WebRequest.Proxy = $IProxy
        }

        try {
            # Make the request to the controller:
            $WebRequestResponse = $WebRequest.GetResponse()

            # Grab the token:
            $TokenSession = $WebRequestResponse.Headers['X-FeApi-Token'] | Out-String
            $TokenSession = $TokenSession -replace "`t|`n|`r", "" # bugfix: 'out-string' introduce a new-line at the end of the string. This hack will remove it. 
                        
            # Return the object:
            $out = New-Object System.Object
            $out | Add-Member -Type NoteProperty -Name Uri -Value $Uri
            $out | Add-Member -Type NoteProperty -Name Endpoint -Value $Endpoint
            $out | Add-Member -Type NoteProperty -Name TokenSession -Value $TokenSession
            if ($false -ne $Proxy) { $out | Add-Member -Type NoteProperty -Name Proxy -Value $IProxy } 

            $out
        }
        catch { throw }
    }
    end { }
}