# SFTP Credentials and Configuration
$Username = "transfer-nearme"         # Replace with your SFTP username
$Password = "sFtp345@nearme"       # Replace with your SFTP password
$SftpHost = "sftp.mptjo.com.mm"      # Replace with your SFTP server
$Port = 22
$LocalFile = "C:\MPT Sample upload_ Offline.xlsx"  # Path to the file you want to upload
$RemoteDir = "/"                    # Remote directory on the SFTP server (home directory)
$WinSCPPath = "C:\Program Files (x86)\WinSCP\WinSCP.com"

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
Write-Output "Starting file upload to SFTP server..."
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
    Write-Output "File uploaded successfully."
} else {
    Write-Output "File upload failed: Unknown error."
}

# Clean up the temporary script file
Remove-Item -Path $TempScriptFile -Force
