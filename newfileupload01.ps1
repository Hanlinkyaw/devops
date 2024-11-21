# SFTP Credentials and Configuration
$Username = "transfer-nearme"         # Replace with your SFTP username
$Password = "sFtp345@nearme"       # Replace with your SFTP password
$SftpHost = "sftp.mptjo.com.mm"      # Replace with your SFTP server
$Port = 22
$LocalFile = "D:\MPT Sample upload_ Offline.xlsx"  # Path to the file you want to upload
$RemoteDir = "/"                    # Remote directory on the SFTP server (home directory)
$ArchiveDir = "D:\download\"        # Directory to move and archive the uploaded files
$WinSCPPath = "C:\Program Files (x86)\WinSCP\WinSCP.com"

# Ensure the archive directory exists
if (!(Test-Path -Path $ArchiveDir)) {
    New-Item -ItemType Directory -Path $ArchiveDir
}

# Build the WinSCP script
$WinSCPScript = @"
open sftp://${Username}@${SftpHost}:${Port} -password="$Password"
option batch abort
option confirm off
put "$LocalFile" "$RemoteDir"
exit
"@

# Write the WinSCP script to a temporary file
$TempScriptFile = [System.IO.Path]::GetTempFileName()
Set-Content -Path $TempScriptFile -Value $WinSCPScript

# Execute the WinSCP command with the script
Write-Output "Starting upload of file: $LocalFile to SFTP server..."
$output = & "$WinSCPPath" /script=$TempScriptFile

# Display the output
Write-Output $output

# Check the upload status
if ($output -match "Authentication failed") {
    Write-Output "Connection failed: Authentication error."
} elseif ($output -match "Network error") {
    Write-Output "Connection failed: Network error."
} elseif ($output -match "Host key") {
    Write-Output "Connection failed: Host key verification issue."
} elseif ($output -match "100%") {
    Write-Output "File uploaded successfully: $LocalFile"

    # Generate timestamp for ZIP file
    $Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

    # Move the file to the archive directory
    $FileName = Split-Path -Leaf $LocalFile
    $ArchivedFilePath = Join-Path $ArchiveDir $FileName
    Move-Item -Path $LocalFile -Destination $ArchivedFilePath

    # Create a ZIP archive with a timestamped name
    $ZipFile = Join-Path $ArchiveDir "$($FileName)_$Timestamp.zip"
    Compress-Archive -Path $ArchivedFilePath -DestinationPath $ZipFile

    # Remove the original file after archiving
    Remove-Item -Path $ArchivedFilePath -Force
    Write-Output "File archived successfully: $ZipFile"
} else {
    Write-Output "File upload failed: Unknown error."
}

# Clean up the temporary script file
Remove-Item -Path $TempScriptFile -Force
