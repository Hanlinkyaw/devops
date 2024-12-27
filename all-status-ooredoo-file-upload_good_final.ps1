# SFTP Credentials and Configuration
$Username = "nearme"         # Replace with your SFTP username
$PrivateKeyPath = "D:\script-ooredoo\Private_key.ppk"  # Path to your private key file
$SftpHost = "103.242.99.17"                  # Replace with your SFTP server
$Port = 22
$LocalFolder = "D:\OoredooFiles\"  # Path to the folder containing files to upload
$RemoteDir = "/sftp/NearMe/UAT/"             # Remote directory on the SFTP server
$ArchiveDir = "D:\OoredooBackup\"                 # Directory to move and archive the uploaded files
$WinSCPPath = "C:\Program Files (x86)\WinSCP\WinSCP.com"
$TelegramToken = "7729532039:AAECh_oPPyNzDpAV-IKrq8ZWUlJvOWE23_w"  # Replace with your Telegram bot token
$TelegramChatID = "-4693912712"    # Replace with your Telegram chat ID

# Function to send a message to the Telegram bot
function Send-TelegramMessage {
    param (
        [string]$Message
    )

    $Url = "https://api.telegram.org/bot$TelegramToken/sendMessage"
    $Body = @{ chat_id = $TelegramChatID; text = $Message }
    Invoke-RestMethod -Uri $Url -Method Post -ContentType "application/json" -Body ($Body | ConvertTo-Json -Depth 10)
}

# Ensure the archive directory exists
if (!(Test-Path -Path $ArchiveDir)) {
    New-Item -ItemType Directory -Path $ArchiveDir
}

# Build the WinSCP script
$WinSCPScript = @"
open sftp://${Username}@${SftpHost}:${Port} -privatekey="$PrivateKeyPath"
option batch abort
option confirm off
put "$LocalFolder*.csv" "$RemoteDir"
exit
"@

# Write the WinSCP script to a temporary file
$TempScriptFile = [System.IO.Path]::GetTempFileName()
Set-Content -Path $TempScriptFile -Value $WinSCPScript

# Execute the WinSCP command with the script
Write-Output "Starting upload of files in $LocalFolder to SFTP server..."
$output = & "$WinSCPPath" /script=$TempScriptFile

# Display the output
Write-Output $output

# Check the upload status
if ($output -match "Authentication failed") {
    $ErrorMessage = "Authentication failed: Unable to connect to SFTP server."
    Write-Output $ErrorMessage
    Send-TelegramMessage -Message $ErrorMessage
    return
} elseif ($output -match "Network error") {
    $ErrorMessage = "Network error: Unable to connect to SFTP server."
    Write-Output $ErrorMessage
    Send-TelegramMessage -Message $ErrorMessage
    return
} elseif ($output -match "Host key") {
    $ErrorMessage = "Host key error: Host key verification failed."
    Write-Output $ErrorMessage
    Send-TelegramMessage -Message $ErrorMessage
    return
} elseif ($output -match "100%") {
    Write-Output "Files uploaded successfully."
    Send-TelegramMessage -Message "Files uploaded successfully to SFTP server."
} 

# Check if there are any .csv files to archive
$CsvFiles = Get-ChildItem -Path $LocalFolder -Filter "*.csv" -File
if ($CsvFiles.Count -eq 0) {
    $ErrorMessage = "No .csv files found in $LocalFolder"
    Write-Output $ErrorMessage
    Send-TelegramMessage -Message $ErrorMessage
    return
}

# Ensure the destination directory exists
if (!(Test-Path -Path $ArchiveDir)) {
    New-Item -ItemType Directory -Path $ArchiveDir
    Write-Output "Created destination directory: $ArchiveDir"
}


 # Move and archive files
    foreach ($File in $CsvFiles) {
        $DestinationFile = Join-Path $ArchiveDir $File.Name

        try {
            Move-Item -Path $File.FullName -Destination $DestinationFile -ErrorAction Stop
            Write-Output "Moved file: $($File.FullName) to $DestinationFile"

            # Create a ZIP archive
            $Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $ZipFile = Join-Path $ArchiveDir "Archive_$Timestamp.zip"
            Compress-Archive -Path $DestinationFile -DestinationPath $ZipFile
            Write-Output \"Files archived successfully. Archive: \$ZipFile\"
			
			 # Remove the original files after archiving
			Get-ChildItem -Path $ArchiveDir -Filter "*.csv" -File | Remove-Item -Force
			Write-Output "Created ZIP archive: $ZipFile"
			$Message = "Files archived successfully. Archive: $ZipFile"
			Invoke-RestMethod -Uri "https://api.telegram.org/bot$TelegramToken/sendMessage" -Method Post -Body @{chat_id=$TelegramChatID; text=$Message}

            # Remove the original file after zipping
            #Remove-Item -Path $DestinationFile -Force
            #Write-Output "Removed original file: $DestinationFile"


        } catch {
            Write-Output "Error moving or archiving file: $($File.FullName). Error: $($_.Exception.Message)"
        }
    }
	
	

	
# Move and archive files This is create one Arichive file for all csv format.

#$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
#$ZipFile = Join-Path $ArchiveDir "Archive_$Timestamp.zip"


#try {
#    Compress-Archive -Path "$LocalFolder*.csv" -DestinationPath $ZipFile -Force
 ##   Write-Output "Files archived successfully. Archive: $ZipFile"
  #  Send-TelegramMessage -Message "Files archived successfully. Archive: $ZipFile"
	

 #   Remove-Item -Path "$LocalFolder*.csv" -Force
 #   Write-Output "Original files removed after archiving."
#} catch {
 #   $ErrorMessage = "Error during file archiving or cleanup: $($_.Exception.Message)"
  #  Write-Output $ErrorMessage
 #   Send-TelegramMessage -Message $ErrorMessage
#}

# Clean up the temporary script file
Remove-Item -Path $TempScriptFile -Force
