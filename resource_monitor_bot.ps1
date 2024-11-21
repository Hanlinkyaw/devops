# Set thresholds
$cpuThreshold = 80
$ramThreshold = 80
$diskThreshold = 80  # Set threshold to 80%

# Get CPU Usage
$cpu = Get-WmiObject Win32_Processor | Measure-Object -Property LoadPercentage -Average | Select-Object -ExpandProperty Average

# Get RAM Usage
$ram = Get-WmiObject Win32_OperatingSystem
$ram_total = [math]::round($ram.TotalVisibleMemorySize/1MB,2)
$ram_free = [math]::round($ram.FreePhysicalMemory/1MB,2)
$ram_used = $ram_total - $ram_free
$ram_usage_percentage = [math]::round(($ram_used/$ram_total)*100,2)

# Get Disk Usage and Check Free Space
$disk_issues = foreach ($d in (Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3")) {
    $total = [math]::round($d.Size/1GB,2)
    $free = [math]::round($d.FreeSpace/1GB,2)
    $free_percentage = [math]::round(($free/$total)*100,2)

    if ($free_percentage -ge $diskThreshold) {
        "$($d.DeviceID) has only $free GB free out of $total GB ($free_percentage% free)"
    }
}

# Check if thresholds are exceeded
$sendMessage = $false
$message = "Resource Usage Alert on NearMe App Server Prod :`n"

if ($cpu -ge $cpuThreshold) {
    $sendMessage = $true
    $message += "CPU Usage is $cpu% (Threshold: $cpuThreshold%)`n"
}

if ($ram_usage_percentage -ge $ramThreshold) {
    $sendMessage = $true
    $message += "RAM Usage is $ram_used GB used out of $ram_total GB ($ram_usage_percentage%) (Threshold: $ramThreshold%)`n"
}

if ($disk_issues) {
    $sendMessage = $true
    $message += "Disk Usage Issues:`n$($disk_issues -join "`n")`n"
}

# Send to Telegram Bot if any threshold is exceeded
if ($sendMessage) {
    $botToken = "7527978778:AAGAIqi2_AVhVq5KnwRgJ7EDwaBESEB-ucU"
    $chatId = "-4520196568"
    $telegramApiUrl = "https://api.telegram.org/bot$botToken/sendMessage"

    Invoke-RestMethod -Uri $telegramApiUrl -Method Post -ContentType "application/json" -Body (@{ chat_id = $chatId; text = $message } | ConvertTo-Json)
}
