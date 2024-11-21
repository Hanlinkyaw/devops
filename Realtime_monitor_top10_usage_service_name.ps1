# Set thresholds
$cpuThreshold = 80
$ramThreshold = 80
$diskThreshold = 10  # Set threshold to 80%

# Variables to track max usage
$maxCpu = 0
$maxRamUsagePercentage = 0
$maxDiskUsage = @{}

# Get CPU Usage and identify the top 10 processes/services with the highest CPU usage
$cpuProcesses = Get-WmiObject Win32_PerfFormattedData_PerfProc_Process | Where-Object { $_.IDProcess -ne 0 }  # Exclude the system idle process
$topCpuProcesses = $cpuProcesses | Sort-Object -Property PercentProcessorTime -Descending | Select-Object Name, PercentProcessorTime -First 10

# Get total CPU usage
$cpu = Get-WmiObject Win32_Processor | Measure-Object -Property LoadPercentage -Average | Select-Object -ExpandProperty Average
if ($cpu -gt $maxCpu) {
    $maxCpu = $cpu
}

# Get RAM Usage
$ram = Get-WmiObject Win32_OperatingSystem
$ram_total = [math]::round($ram.TotalVisibleMemorySize/1MB,2)
$ram_free = [math]::round($ram.FreePhysicalMemory/1MB,2)
$ram_used = $ram_total - $ram_free
$ram_usage_percentage = [math]::round(($ram_used/$ram_total)*100,2)

if ($ram_usage_percentage -gt $maxRamUsagePercentage) {
    $maxRamUsagePercentage = $ram_usage_percentage
}

# Get the top 10 processes/services with the highest RAM usage
$ramProcesses = Get-Process | Sort-Object -Property WorkingSet64 -Descending | Select-Object Name, @{Name="Memory (MB)"; Expression={[math]::round($_.WorkingSet64 / 1MB, 2)}} -First 10

# Get Disk Usage and Check Free Space
$disk_issues = foreach ($d in (Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3")) {
    $total = [math]::round($d.Size/1GB,2)
    $free = [math]::round($d.FreeSpace/1GB,2)
    $used = $total - $free
    $free_percentage = [math]::round(($free/$total)*100,2)
    $used_percentage = 100 - $free_percentage

    # Track max disk usage for each drive
    if (-not $maxDiskUsage.ContainsKey($d.DeviceID) -or $used_percentage -gt $maxDiskUsage[$d.DeviceID]) {
        $maxDiskUsage[$d.DeviceID] = $used_percentage
    }

    if ($free_percentage -le $diskThreshold) {
        "$($d.DeviceID) has only $free GB free out of $total GB ($free_percentage% free)"
    }
}

# Check if thresholds are exceeded
$sendMessage = $false
$message = "Resource Usage Alert on NearMe App Server Prod :`n"

if ($cpu -ge $cpuThreshold) {
    $sendMessage = $true
    $message += "Total CPU Usage is $cpu% (Threshold: $cpuThreshold%)`n"
    $message += "Top 10 processes by CPU usage:`n"
    foreach ($process in $topCpuProcesses) {
        $message += "$($process.Name): $($process.PercentProcessorTime)% CPU`n"
    }
}

if ($ram_usage_percentage -ge $ramThreshold) {
    $sendMessage = $true
    $message += "RAM Usage is $ram_used GB used out of $ram_total GB ($ram_usage_percentage%) (Threshold: $ramThreshold%)`n"
    $message += "Top 10 processes by RAM usage:`n"
    foreach ($process in $ramProcesses) {
        $message += "$($process.Name): $($process.'Memory (MB)') MB RAM`n"
    }
}

if ($disk_issues) {
    $sendMessage = $true
    $message += "Disk Usage Issues:`n$($disk_issues -join "`n")`n"
}

# Add maximum observed values to the message
$message += "`nMax Observed Usage:`n"
$message += "Max CPU Usage: $maxCpu%`n"
$message += "Max RAM Usage: $maxRamUsagePercentage%`n"

if ($maxDiskUsage.Count -gt 0) {
    $message += "Max Disk Usage:`n"
    foreach ($disk in $maxDiskUsage.GetEnumerator()) {
        $message += "$($disk.Key): $($disk.Value)% used`n"
    }
}

# Send to Telegram Bot if any threshold is exceeded
if ($sendMessage) {
    $botToken = "7527978778:AAGAIqi2_AVhVq5KnwRgJ7EDwaBESEB-ucU"
    $chatId = "-4511721660"
    $telegramApiUrl = "https://api.telegram.org/bot$botToken/sendMessage"

    Invoke-RestMethod -Uri $telegramApiUrl -Method Post -ContentType "application/json" -Body (@{ chat_id = $chatId; text = $message } | ConvertTo-Json)
}
