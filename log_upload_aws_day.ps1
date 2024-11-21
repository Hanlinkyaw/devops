<#
.SYNOPSIS
    Archives logs older than 90 days, uploads them to AWS S3, and deletes the source logs.
.DESCRIPTION
    This script identifies logs older than 90 days in a specified directory, archives them using 7-zip,
    uploads the archive to an AWS S3 bucket, confirms the upload, and then deletes the source logs if the upload is successful.
.AUTHOR
    HLK
.VERSION
    1.0
.LICENSE
    MIT License
.DATE
    2024-09-12
#>

# Variables
$sourceFolder = "C:/Logs"
$archiveFolder = "C:/Archive_logs"
$date = Get-Date -Format "yyyyMMdd"
$archiveName = "BI_Monthly_$date.7z"
$archivePath = Join-Path $archiveFolder $archiveName
$s3BucketPath = "s3://nearme-log/ec2-nearmeweb-PROD-apse1/Archive_logs/"

# Ensure archive directory exists
if (-not (Test-Path $archiveFolder)) {
    New-Item -Path $archiveFolder -ItemType Directory
}

# Archive logs older than 90 days using 7-zip
$logsToArchive = Get-ChildItem $sourceFolder -Recurse -File | Where-Object {
    $_.CreationTime -lt (Get-Date).AddDays(-90)
}

if ($logsToArchive.Count -gt 0) {
    & "C:\Program Files\7-Zip\7z.exe" a -t7z $archivePath $logsToArchive.FullName

    # Upload to AWS S3
    aws s3 cp $archivePath $s3BucketPath

    # Confirm the upload was successful
    $uploadSuccess = aws s3 ls $s3BucketPath | Select-String -Pattern $archiveName
    if ($uploadSuccess) {
        # Delete source logs that were archived
        $logsToArchive | ForEach-Object { Remove-Item $_.FullName -Force }
    } else {
        Write-Host "Upload failed, logs will not be deleted."
    }
} else {
    Write-Host "No logs older than 90 days to archive."
}

# Schedule the script to run Monthly at 1:00 AM
#$trigger = New-ScheduledTaskTrigger -Monthly -At "1:00AM" -DaysOfMonth 1
#$action = New-ScheduledTaskAction -Execute "Powershell.exe" -Argument "-File D:\log_upload_aws.ps1"
#Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "MonthlyLogArchiver" -Description "Archives and uploads logs older than 90 days"

