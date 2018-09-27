function New-HXSession {
    [CmdletBinding()]
    [OutputType([psobject])]
    param(    
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string] $Uri,

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [System.Management.Automation.PSCredential] $Credential
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

        $headers = @{ Authorization = $auth }

        # Make the request to the controller:
        $WebRequest = Invoke-WebRequest -Uri $Endpoint -Method Get -SessionVariable LoginSession -ErrorAction Stop -Headers $headers -SkipCertificateCheck 

        # Return the object:
        $out = New-Object System.Object
        $out | Add-Member -Type NoteProperty -Name Uri -Value $Uri
        $out | Add-Member -Type NoteProperty -Name Endpoint -Value $Endpoint
        $out | Add-Member -Type NoteProperty -Name WebSession -Value $LoginSession
        $out
    }
    end { }
}