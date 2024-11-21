# Set thresholds (usage should be less than these values)
$cpuThreshold = 90
$ramThreshold = 90
$diskThreshold = 90  # Disk threshold is for usage percentage, not free space

# Define the server name
$serverName = "NearMe App Server Prod"

# Get CPU Usage
$cpu = Get-WmiObject Win32_Processor | Measure-Object -Property LoadPercentage -Average | Select-Object -ExpandProperty Average

# Get RAM Usage
$ram = Get-WmiObject Win32_OperatingSystem
$ram_total = [math]::round($ram.TotalVisibleMemorySize/1MB,2)
$ram_free = [math]::round($ram.FreePhysicalMemory/1MB,2)
$ram_used = $ram_total - $ram_free
$ram_usage_percentage = [math]::round(($ram_used/$ram_total)*100,2)

# Get Disk Usage
$disk_status = $true
$disk_info = foreach ($d in (Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3")) {
    $total = [math]::round($d.Size/1GB,2)
    $free = [math]::round($d.FreeSpace/1GB,2)
    $used = $total - $free
    $usage_percentage = [math]::round(($used/$total)*100,2)

    # Check if any disk exceeds the threshold
    if ($usage_percentage -ge $diskThreshold) {
        $disk_status = $false
    }

    [PSCustomObject]@{
        Drive = $d.DeviceID
        TotalGB = $total
        UsedGB = $used
        FreeGB = $free
        UsagePercentage = $usage_percentage
    }
}

# Check if all resources are within the thresholds
if ($cpu -lt $cpuThreshold -and $ram_usage_percentage -lt $ramThreshold -and $disk_status) {
    # Format the success message with emojis
    $message = " Resource Usage on $serverName is OK! `n"
    $message += " CPU Usage: $cpu% (Threshold: $cpuThreshold%)`n"
    $message += " RAM Usage: $ram_used GB used out of $ram_total GB ($ram_usage_percentage%)`n"
    $message += " Disk Usage: All disks are below the $diskThreshold% threshold.`n"

    $disk_info | ForEach-Object { 
        $message += " Drive $($_.Drive): Used: $($_.UsedGB) GB, Free: $($_.FreeGB) GB (Total: $($_.TotalGB) GB) - Usage: $($_.UsagePercentage)%`n"
    }

    # Send the message to Telegram Bot
    $botToken = "7527978778:AAGAIqi2_AVhVq5KnwRgJ7EDwaBESEB-ucU"
    $chatId = "-4520196568"
    $telegramApiUrl = "https://api.telegram.org/bot$botToken/sendMessage"

    Invoke-RestMethod -Uri $telegramApiUrl -Method Post -ContentType "application/json" -Body (@{ chat_id = $chatId; text = $message } | ConvertTo-Json)
}
else {
    # Handle the case where resources exceed the thresholds
    $message = " Resource Usage Alert on $serverName! Some resources exceed the thresholds. Please check the system."
    Invoke-RestMethod -Uri $telegramApiUrl -Method Post -ContentType "application/json" -Body (@{ chat_id = $chatId; text = $message } | ConvertTo-Json)
}
