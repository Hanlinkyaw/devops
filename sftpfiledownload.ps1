# SFTP Credentials and Configuration
$Username = "transfer-nearme"         # Replace with your SFTP username
$Password = "sFtp345@nearme"       # Replace with your SFTP password
$SftpHost = "sftp.mptjo.com.mm"      # Replace with your SFTP server
$Port = 22
$RemoteFile = "/MPT Sample upload_ Offline.xlsx"  # Path to the file on the SFTP server
$LocalDir = "D:\download\"         # Local directory to download the file to
$WinSCPPath = "C:\Program Files (x86)\WinSCP\WinSCP.com"

# Ensure local directory exists
if (!(Test-Path -Path $LocalDir)) {
    New-Item -ItemType Directory -Path $LocalDir
}

# Build the WinSCP script
$WinSCPScript = @"
open sftp://${Username}@${SftpHost}:${Port} -password="$Password"
option batch abort
option confirm off
get "$RemoteFile" "$LocalDir"
exit
"@

# Write the WinSCP script to a temporary file
$TempScriptFile = [System.IO.Path]::GetTempFileName()
Set-Content -Path $TempScriptFile -Value $WinSCPScript

# Execute the WinSCP command with the script
Write-Output "Starting file download from SFTP server..."
$output = & "$WinSCPPath" /script=$TempScriptFile

# Display the output
Write-Output $output

# Check the download status
if ($output -match "Authentication failed") {
    Write-Output "Connection failed: Authentication error."
} elseif ($output -match "Network error") {
    Write-Output "Connection failed: Network error."
} elseif ($output -match "Host key") {
    Write-Output "Connection failed: Host key verification issue."
} elseif ($output -match "100%") {
    Write-Output "File downloaded successfully."
} else {
    Write-Output "File download failed: Unknown error."
}

# Clean up the temporary script file
Remove-Item -Path $TempScriptFile -Force
