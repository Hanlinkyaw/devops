<#
.SYNOPSIS
    Archives logs older than 3 months, uploads them to AWS S3, and deletes the source logs.
.DESCRIPTION
    This script identifies logs older than 3 months in a specified directory, archives them using 7-zip, 
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
$sourceFolder = "D:/Log/MobileAPI"
$archiveFolder = "D:/Archive_logs/MobileAPI"
$date = Get-Date -Format "yyyyMMdd"
$archiveName = "Monthly_Logs_$date.7z"
$archivePath = Join-Path $archiveFolder $archiveName
$s3BucketPath = "s3://nearme-log/ec2-nearmeweb-PROD-apse1/Archive_logs/MobileAPI"

# Ensure archive directory exists
if (-not (Test-Path $archiveFolder)) {
    New-Item -Path $archiveFolder -ItemType Directory
}

# Archive logs older than 3 months using 7-zip
$logsToArchive = Get-ChildItem $sourceFolder -Recurse -File | Where-Object {
    $_.LastWriteTime -lt (Get-Date).AddMonths(-3)
}

if ($logsToArchive.Count -gt 0) {
    & "C:\Program Files\7-Zip\7z.exe" a -t7z $archivePath $logsToArchive.FullName

    # Upload to AWS S3
    aws s3 cp $archiveFolder $s3BucketPath --recursive

    # Confirm the upload was successful
    $uploadSuccess = aws s3 ls $s3BucketPath | Select-String -Pattern $archiveName
    if ($uploadSuccess) {
        # Delete source logs that were archived
        $logsToArchive | ForEach-Object { Remove-Item $_.FullName -Force }
    } else {
        Write-Host "Upload failed, logs will not be deleted."
    }
} else {
    Write-Host "No logs older than 3 months to archive."
}

