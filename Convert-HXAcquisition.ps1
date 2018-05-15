function Convert-HXAcquisition {
    
    [OutputType([psobject])]
    param(
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string] $Uri = 'undefined',

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateScript( {Test-Path $_})]
        [string] $File,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $Hostname,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string] $Hostset = 'undefined',

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string] $Separator = '~',

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [ValidateScript( {Test-Path $_})]
        [string] $BasePath,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [switch] $ProduceLastSeenFile,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [switch] $DeleteRaw,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [switch] $TrimState
    )

    begin { 
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        function Unzip {
            param(
                [Parameter(Mandatory = $true, Position = 0)]
                [ValidateScript( {Test-Path $_})]
                [string]$ZipFile,

                [Parameter(Mandatory = $true, Position = 1)]
                [string]$OutPath
            )

            [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipFile, $OutPath)
        }

        function Merge-HXAcquisition {
            <#
            .Description
                Merge all acquisitions of the same type associated with the same host. 
            #>
            [CmdletBinding()]
            [OutputType([psobject])]
            param(
                [Parameter(Mandatory = $true, ValueFromPipeline = $false, Position = 0)]
                [ValidateScript( {Test-Path $_})]
                [string] $ManifestFile
            )
        
            # Get the directory of the manifest file:
            $_manifest_firectory = [System.IO.Path]::GetDirectoryName($ManifestFile)
        
            # Read the file content and convert it into a JSON object:
            $unique_xml = $null
            $unique_xml_file_fullpath = $null
            $_manifest_content = Get-Content -Path $ManifestFile -Raw -ErrorAction Stop | ConvertFrom-Json
            $_manifest_content.audits | Group-Object generator | Where-Object {$_.Count -gt 1} | Select-Object -ExpandProperty Group `
                | ForEach-Object { $_.results } | Group-Object type | Where-Object { $_.name -eq 'application/xml' } `
                | Where-Object {$_.Count -gt 1} | Select-Object -ExpandProperty Group | ForEach-Object {
                    
                # Full path of the acquisition:
                $file_fullpath = [System.IO.Path]::Combine($_manifest_firectory, $_.payload)
        
                # First check if the $unique_xml is not null, so we're not treating the first element.
                if (-not($unique_xml -eq $null)) {
                    
                    try {
                        # Import the second-onwards xml:
                        [xml]$secondxml = Get-Content -Path $file_fullpath -Raw #-ErrorAction SilentlyContinue # BUG: FireEyeHX has a bug where sometimes the acquired xml file doesnt contain a closed tag for the itemList xml item.
            
                        # Parse the xml of the second-onwards element in the ForEach-Object (acquisitions):
                        foreach ($node in $secondxml.DocumentElement.ChildNodes) {
                            $unique_xml.DocumentElement.AppendChild($unique_xml.ImportNode($node, $true)) | Out-Null
                        }
            
                        # Delete the second xml file:
                        Remove-Item -Path $file_fullpath
                    }
                    catch { Write-Verbose "[Merge-HXAcquisition] Cannot merge $file_fullpath. File skipped." }
                }
        
                # Check if the $unique_xml is null, so means it is the first element of the ForEach-Object that is being treated. 
                if ($unique_xml -eq $null) {
                    try {
                        [xml]$unique_xml = Get-Content -Path $file_fullpath -Raw #-ErrorAction SilentlyContinue # BUG: FireEyeHX has a bug where sometimes the acquired xml file doesnt contain a closed tag for the itemList xml item.
                        $unique_xml_file_fullpath = $file_fullpath
                    }
                    catch { Write-Verbose "[Merge-HXAcquisition] Cannot merge $file_fullpath. File skipped." }
                }
            }
        
            # Save the merged xml into the first file which was treated:
            if (-not($unique_xml -eq $null)) {
                $unique_xml.Save($unique_xml_file_fullpath)
            }
        }

        function Remove-HXAcquisitionEmptyFile {
            <#
            .Description
                Merge an acquisition file which does not contain any value
            #>
            [CmdletBinding()]
            [OutputType([psobject])]
            param(
                [Parameter(Mandatory = $true, ValueFromPipeline = $false, Position = 0)]
                [ValidateScript( {Test-Path $_})]
                [string] $AcquisitionFile
            )
        
            try { 
                [xml]$xml = Get-Content -Path $AcquisitionFile -Raw
                # Check if the count of child objects is 0, so we can delete the file:
                if ($xml.DocumentElement.ChildNodes.Count -eq 0) {
                    # Delete the xml file:
                    Remove-Item -Path $AcquisitionFile
                }
            }
            catch { Write-Verbose "[Remove-HXAcquisitionEmptyFile] Cannot parse $AcquisitionFile. File skipped." }            
        }

        function TrimState {
            <#
            .Description
                Remove all timestamps and state indicators in a string
            #>
            [CmdletBinding()]
            [OutputType([string])]
            param(
                [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
                [string] $String,

                [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
                [bool] $Enabled = $true,
        
                [Parameter(Mandatory = $false, ValueFromPipeline = $false, Position = 0)]
                [string] $SubstituteString = 'ReplacedByPSAutomaticBulkAcquisitionScript'
            )
            if ($Enabled) {
                $String `
                    -replace '<status>[\w]+</status>', "<status>$SubstituteString</status>" `
                    -replace '<pid>[\d]+</pid>', "<pid>$SubstituteString</pid>" `
                    -replace '<parentpid>[\d]+</parentpid>', "<parentpid>$SubstituteString</parentpid>" `
                    -replace '<totalphysical>[\d]+</totalphysical>', "<totalphysical>$SubstituteString</totalphysical>" `
                    -replace '<availphysical>[\d]+</availphysical>', "<availphysical>$SubstituteString</availphysical>" `
                    -replace '<lpcDevice>.+<\/lpcDevice>', "<lpcDevice>$SubstituteString</lpcDevice>" `
                    -replace '\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z', "$SubstituteString" `
                    -replace '\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z', "$SubstituteString" `
                    -replace '>PT[\w]+S<', ">$SubstituteString<" `
                    | Out-String -NoNewline
            }
            else { $String | Out-String -NoNewline }
        }

        # Set the folders where to operate.
        # Required paths will be as follows:
        # - base path
        # -- raw        ->  where acquisition files will be downloaded in original format (.zip).
        # -- unique     ->  where acquisition files will be extracted. one file per type and per hostname will be keeped here. they will be the 'master' files.
        # -- changes    ->  where acquisition files will be written down only when a change in the acquisition file has been detected (all files will be compared with the files seen in the 'unique' folder).
        # -- tmp        ->  where acquisition files will be first extracted and then compared by md5 with it pair in the 'unique' folder (if any). all files will be deleted from this folder after compared. 
        if (-not($BasePath)) { $_basepath = (Get-Item -Path ".\" -Verbose).FullName  }
        else { $_basepath = $BasePath }

        # Check if the required folder exists:
        $_raw_path = [System.IO.Path]::Combine($_basepath, 'raw')
        $_unique_path = [System.IO.Path]::Combine($_basepath, 'unique')
        $_changes_path = [System.IO.Path]::Combine($_basepath, 'changes')
        $_tmp_path = [System.IO.Path]::Combine($_basepath, 'tmp')

        # Clean the 'tmp' folder:
        if (Test-Path $_tmp_path) { Remove-Item $_tmp_path -Force -Recurse }

        New-Item -ItemType Directory -Force -Path $_raw_path -ErrorAction Stop | Out-Null
        New-Item -ItemType Directory -Force -Path $_unique_path -ErrorAction Stop | Out-Null
        New-Item -ItemType Directory -Force -Path $_changes_path -ErrorAction Stop | Out-Null
        New-Item -ItemType Directory -Force -Path $_tmp_path -ErrorAction Stop | Out-Null

        # Set-up the last-seen file:
        $_generatedat = Get-Date -Format o | ForEach-Object {$_ -replace ":", "."}
        $_lastseenfile = [System.IO.Path]::Combine($_changes_path, $_generatedat + $Separator + "lastseen.csv")
        if (Test-Path $_lastseenfile) { Remove-Item -Path $_lastseenfile -ErrorAction Stop }

        # Set-up timestamp for files acquired:
        $timestamp = $_generatedat

    }

    process {

        Write-Verbose "[Convert-HXAcquisition] Proccesing $File"

        # Controller name:
        $controller = [string](([regex]::Match($Uri, "https?://(?<controller>[\w\-]+)\.")).groups["controller"].value)
        
        # Check if the raw file is not in the raw folder. In case of positive, move it to the proper folder:
        if ([System.IO.Path]::GetDirectoryName($File) -ne $_raw_path) { 
            $_file = [System.IO.Path]::Combine($_raw_path, [System.IO.Path]::GetFileName($File))
            Move-Item -Path $File -Destination $_file -ErrorAction Stop -Force
        }
        else { $_file = $File }

        # Extract the file to the 'tmp' folder:
        Unzip -ZipFile $_file -OutPath $_tmp_path -ErrorAction Stop
 
        # Verify if the 'manifest.json' exists and parse it:
        $_manifest_file = [System.IO.Path]::Combine($_tmp_path, 'manifest.json')
        if (Test-Path $_manifest_file) {

            ## Call Merge-HXAcquisition to merge all acquisitions of the same type
            Merge-HXAcquisition -ManifestFile $_manifest_file

            # Retrieve the content of the manifest file:
            $_manifest_content = Get-Content -Path $_manifest_file -Raw | ConvertFrom-Json

            # Process the manifest and rename the files when needed. Issues files will be deleted:
            $newseen_filenames = @()
            $_manifest_content.audits | ForEach-Object {
                $extractedfile_filetype = $_.generator

                $_.results | ForEach-Object { 
                    $extractedfile_name = $_.payload
                    $extractedfile_contenttype = $_.type

                    # Process the file if it is a xml:
                    if ($extractedfile_contenttype -eq 'application/xml') {

                        # File being processed:
                        $_extractedfile = [System.IO.Path]::Combine($_tmp_path, $extractedfile_name)

                        # Remove empty files. File exists needs to be checked because may be deleted first by Merge-HXAcquisition as a result of a merge files of the same type.
                        if (Test-Path $_extractedfile) { Remove-HXAcquisitionEmptyFile -AcquisitionFile $_extractedfile }

                        # Check if the file of the acquisition exists. May not exists due to a merge of file done by Merge-HXAcquisition:
                        if (Test-Path $_extractedfile) {
                            # Rename the file:
                            $_extractedfile_new_fullpath = [System.IO.Path]::Combine($_tmp_path, $controller + $Separator + $Hostset + $Separator + $Hostname + $Separator + $extractedfile_filetype + ".xml")
                            $_extractedfile_new_filename = [System.IO.Path]::GetFileName($_extractedfile_new_fullpath)
                            Move-Item -Path $_extractedfile -Destination $_extractedfile_new_fullpath -ErrorAction Stop


                            # Process the file once extracted. 
                            #  Goal is to remove the te timestamps into the file, so we can make the file uniqueness and can compare an old file of the same host against the new one by MD5 hash. 
                            #  XML attributes 'created' and 'uid' will be removed from the files:

                            (Get-Content -Path $_extractedfile_new_fullpath -Raw -Encoding UTF8) `
                                -replace 'created="[\w\-:]+"', "controller=`"$controller`" hostset=`"$Hostset`" hostname=`"$Hostname`"" `
                                -replace 'sequence_num="[\d]+"', "controller=`"$controller`" hostset=`"$Hostset`" hostname=`"$Hostname`"" `
                                -replace 'uid="[\w\-]+"', '' `
                                | TrimState -Enabled $TrimState | Out-File $_extractedfile_new_fullpath -Encoding UTF8


                            # Now will check if the extracted file matchs with its pair in the 'unique' folder. 
                            #  In case of negative, it will be pushed to the 'changes' folder. 
                            #  In case of positive, it means there is no change into the file, so nothing will happens.


                            # Set required file paths:
                            $_unique_fullpath = [System.IO.Path]::Combine($_unique_path, $controller + $Separator + $Hostset + $Separator + $Hostname + $Separator + $extractedfile_filetype + ".xml")
                            $_change_fullpath = [System.IO.Path]::Combine($_changes_path, $timestamp + $Separator + $controller + $Separator + $Hostset + $Separator + $Hostname + $Separator + $extractedfile_filetype + ".xml")

                            # Check if file exists in the 'unique' folder:
                            if (Test-Path $_unique_fullpath) {

                                # Check if the extracted file match with the previous version seen in the 'unique' folder:
                                # In case of not matching, it will move the extracted version to the 'changes' folder and it will replace the 'unique' version with the version recently extracted. 
                                if ((Get-FileHash $_extractedfile_new_fullpath -Algorithm MD5).hash -ne (Get-FileHash $_unique_fullpath -Algorithm MD5).hash) {

                                    Remove-Item -Path $_unique_fullpath -ErrorAction Stop
                                    Move-Item -Path $_extractedfile_new_fullpath -Destination $_unique_fullpath 
                                    Copy-Item -Path $_unique_fullpath -Destination $_change_fullpath

                                    # Add the new seen file to an array that will be written down in the resume per hostname file (LastSeenFile).
                                    $newseen_filenames += $extractedfile_filetype

                                    Write-Verbose "[Convert-HXAcquisition] New unmatch: $_extractedfile_new_filename"
                                }
                                else { 
                                    Remove-Item -Path $_extractedfile_new_fullpath
                                    Write-Verbose "[Convert-HXAcquisition] No changes seen in file: $_extractedfile_new_filename"
                                }
                            }
                            # If not found in 'unique' folder, means it is the first time that file is being seen. So copy to file directly to the 'changes' folder:
                            else {
                                Move-Item -Path $_extractedfile_new_fullpath -Destination $_unique_fullpath 
                                Copy-Item -Path $_unique_fullpath -Destination $_change_fullpath

                                # Add the new seen file to an array that will be written down in the resume per hostname file (LastSeenFile).
                                $newseen_filenames += $extractedfile_filetype

                                Write-Verbose "[Convert-HXAcquisition] New seen file: $_extractedfile_new_filename"
                            }
                        }
                    }

                    # Delete the file if it is an issues file:
                    elseif ($extractedfile_contenttype -eq 'application/vnd.mandiant.issues+xml') {
                        $_tmp_fullpath = [System.IO.Path]::Combine($_tmp_path, $extractedfile_name)
                        Remove-Item -Path $_tmp_fullpath
                    }
                } 
            }

            # Remove the manifest file in the 'tmp' folder:
            Remove-Item -Path $_manifest_file -ErrorAction Stop

            # Check if we have to produce the seen file per host:
            if ($ProduceLastSeenFile) {
                $out = New-Object System.Object
                $out | Add-Member -Type NoteProperty -Name controller -Value $controller
                $out | Add-Member -Type NoteProperty -Name hostset -Value $Hostset
                $out | Add-Member -Type NoteProperty -Name hostname -Value $Hostname
                $out | Add-Member -Type NoteProperty -Name seenat -Value $timestamp
                $out | Add-Member -Type NoteProperty -Name newseenfile -Value (($newseen_filenames | Get-Unique) -join ', ')

                # Export to CSV:
                $out | Export-Csv -NoTypeInformation -Encoding utf8 -NoOverwrite -Append -Path $_lastseenfile
            }
        }

        # Check if the DeleteRaw switch is turn on:
        if ($DeleteRaw) {
            if (Test-Path $_file) { Remove-Item -Path $_file }
        } 
    }
    end { }
}