function Convert-HXAcquisition {
    
    [OutputType([psobject])]
    param(
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [string] $Uri='undefined',

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({Test-Path $_})]
        [string] $File,

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string] $Hostname,

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [string] $Hostset='undefined',

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [string] $Separator='~',

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({Test-Path $_})]
        [string] $BasePath,

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [switch] $ProduceLastSeenFile,

        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [switch] $DeleteRaw

        # TODO: multiples files of each type should be joined. E.g. files-api acquisitions of same host should be joined first before treatement. 
        # TODO: Switch to clean up the 'raw' folder.
    )

    begin { 
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        function Unzip
        {
            param(
                [Parameter(Mandatory=$true, Position=0)]
                [ValidateScript({Test-Path $_})]
                [string]$ZipFile,

                [Parameter(Mandatory=$true, Position=1)]
                [string]$OutPath
            )

            [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipFile, $OutPath)
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

    }
    process {

        Write-Verbose "[Convert-HXAcquisition] Proccesing $File"

        # Timestamp calculation:
        $timestamp = Get-Date -Format o | ForEach-Object {$_ -replace ":", "."}

        # Controller name:
        $controller = [string](([regex]::Match($Uri,"https?://(?<controller>[\w\-]+)\.")).groups["controller"].value)
        
        # Check if the raw file is not in the raw folder. In case of positive, move it to the proper folder:
        if ([System.IO.Path]::GetDirectoryName($File) -ne $_raw_path) { 
            $_file = [System.IO.Path]::Combine($_raw_path, [System.IO.Path]::GetFileName($File))
            Move-Item -Path $File -Destination $_file -ErrorAction Stop -Verbose -Force
        }
        else { $_file = $File }

        # Extract the file to the 'tmp' folder:
        Unzip -ZipFile $_file -OutPath $_tmp_path -ErrorAction Stop
 
        # Verify if the 'manifest.json' exists and parse it:
        $_manifest_file = [System.IO.Path]::Combine($_tmp_path, 'manifest.json')
        if (Test-Path $_manifest_file) {
            # Retrieve the content of the manifest file:
            $_manifest_content = Get-Content $_manifest_file -Raw | ConvertFrom-Json

            # Process the manifest and rename the files when needed. Issues files will be deleted:
            $newseen_filenames = @()
            $_manifest_content.audits | ForEach-Object {
                $extractedfile_filetype = $_.generator

                $_.results | ForEach-Object { 
                    $extractedfile_name = $_.payload
                    $extractedfile_contenttype = $_.type

                    # Process the file if it is a xml:
                    if ($extractedfile_contenttype -eq 'application/xml') {

                        # Rename the file:
                        $_extractedfile = [System.IO.Path]::Combine($_tmp_path, $extractedfile_name)
                        $_extractedfile_new_fullpath = [System.IO.Path]::Combine($_tmp_path, $controller + $Separator + $Hostset + $Separator + $Hostname + $Separator + $extractedfile_filetype + ".xml")
                        $_extractedfile_new_filename = [System.IO.Path]::GetFileName($_extractedfile_new_fullpath)
                        Move-Item -Path $_extractedfile -Destination $_extractedfile_new_fullpath -ErrorAction Stop


                        # Process the file once extracted. 
                        #  Goal is to remove the te timestamps into the file, so we can make the file uniqueness and can compare an old file of the same host against the new one by MD5 hash. 
                        #  XML attributes 'created' and 'uid' will be removed from the files:

                        (Get-Content $_extractedfile_new_fullpath -Raw -Encoding UTF8) `
                            -replace 'created="[\w\-:]+"', "controller=`"$controller`" hostset=`"$Hostset`" hostname=`"$Hostname`"" `
                            -replace 'uid="[\w\-]+"', '' `
                            | Out-File $_extractedfile_new_fullpath -Encoding UTF8


                        # Check if the extracted file matchs with it pair in the 'unique' folder. 
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
                $out | Add-Member -Type NoteProperty -Name processedat -Value $_generatedat
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