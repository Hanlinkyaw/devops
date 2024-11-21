# Set thresholds
$cpuThreshold = 7
$ramThreshold = 7
$diskThreshold = 20  # Set threshold to 20%

# Variables to track max usage
$maxCpu = 0
$maxRamUsagePercentage = 0
$maxDiskUsage = @{ }

# Get CPU Usage and identify the top 10 processes/services with the highest CPU usage
$cpuProcesses = Get-WmiObject Win32_PerfFormattedData_PerfProc_Process | Where-Object { $_.IDProcess -ne 0 }  # Exclude the system idle process
$topCpuProcesses = $cpuProcesses | Sort-Object -Property PercentProcessorTime -Descending | Select-Object IDProcess, Name, PercentProcessorTime -First 10

# Get total CPU usage
$cpu = Get-WmiObject Win32_Processor | Measure-Object -Property LoadPercentage -Average | Select-Object -ExpandProperty Average
if ($cpu -gt $maxCpu) {
    $maxCpu = $cpu
}

# Get RAM Usage
$ram = Get-WmiObject Win32_OperatingSystem
$ram_total = [math]::round($ram.TotalVisibleMemorySize / 1MB, 2)
$ram_free = [math]::round($ram.FreePhysicalMemory / 1MB, 2)
$ram_used = $ram_total - $ram_free
$ram_usage_percentage = [math]::round(($ram_used / $ram_total) * 100, 2)

if ($ram_usage_percentage -gt $maxRamUsagePercentage) {
    $maxRamUsagePercentage = $ram_usage_percentage
}

# Get the top 10 processes/services with the highest RAM usage
$ramProcesses = Get-Process | Sort-Object -Property WorkingSet64 -Descending | Select-Object Id, Name, @{Name="Memory (MB)"; Expression={[math]::round($_.WorkingSet64 / 1MB, 2)}} -First 10

# Get Disk Usage and Check Free Space
$disk_issues = foreach ($d in (Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3")) {
    $total = [math]::round($d.Size / 1GB, 2)
    $free = [math]::round($d.FreeSpace / 1GB, 2)
    $used = $total - $free
    $free_percentage = [math]::round(($free / $total) * 100, 2)
    $used_percentage = 100 - $free_percentage

    # Track max disk usage for each drive
    if (-not $maxDiskUsage.ContainsKey($d.DeviceID) -or $used_percentage -gt $maxDiskUsage[$d.DeviceID]) {
        $maxDiskUsage[$d.DeviceID] = $used_percentage
    }

    if ($free_percentage -le $diskThreshold) {
        "`tDrive $($d.DeviceID) - Free: $free GB / Total: $total GB ($free_percentage% Free)`n"
    }
}

# Check if thresholds are exceeded
$sendMessage = $false
$message = "*Resource Usage Alert on NearMe Web Server Prod*`n"

# Format CPU usage in a table-like output
if ($cpu -ge $cpuThreshold) {
    $sendMessage = $true
    $message += "`n*CPU Usage*: $cpu% (Threshold: $cpuThreshold%)`n"
    $message += "`Top 10 processes by CPU usage:`n"
    $message += "`PID           | COMMAND            | %CPU`n"
    $message += "`--------------|---------------------------|-------------`n"
    foreach ($process in $topCpuProcesses) {
        $message += "`PID: $($process.IDProcess) | $([string]::Format("{0,-18}", $process.Name)) | $([math]::round($process.PercentProcessorTime, 2))%`n"
    }
}

# Format RAM usage in a table-like output
if ($ram_usage_percentage -ge $ramThreshold) {
    $sendMessage = $true
    $message += "`n*RAM Usage*: $ram_used GB used out of $ram_total GB ($ram_usage_percentage%) (Threshold: $ramThreshold%)`n"
    $message += "`Top 10 processes by RAM usage:`n"
    $message += "`PID            | COMMAND            | MEMORY(MB)`n"
    $message += "`---------------|----------------------------|----------------------`n"
    foreach ($process in $ramProcesses) {
        $message += "`PID: $($process.Id) | $([string]::Format("{0,-18}", $process.Name)) | $($process.'Memory (MB)') MB`n"
    }
}

# Check disk usage for the / directory
if ($disk_issues) {
    $sendMessage = $true
    $message += "`n*Disk Usage Issues:*`n$($disk_issues -join "`n")`n"
}

# Add maximum observed values to the message
$message += "`n*Max Observed Usage:*`n"
$message += "`tMax CPU Usage: $maxCpu%`n"
$message += "`tMax RAM Usage: $maxRamUsagePercentage%`n"

# Add Disk usage info
if ($maxDiskUsage.Count -gt 0) {
    $message += "`tMax Disk Usage:`n"
    foreach ($disk in $maxDiskUsage.GetEnumerator()) {
        $message += "`tDrive $($disk.Key): $($disk.Value)% used`n"
    }
}

# Send to Telegram Bot if any threshold is exceeded
if ($sendMessage) {
    $botToken = "7527978778:AAGAIqi2_AVhVq5KnwRgJ7EDwaBESEB-ucU"
    $chatId = "-4511721660"
    $telegramApiUrl = "https://api.telegram.org/bot$botToken/sendMessage"

    Invoke-RestMethod -Uri $telegramApiUrl -Method Post -ContentType "application/json" -Body (@{ chat_id = $chatId; text = $message; parse_mode = "Markdown" } | ConvertTo-Json)
}
