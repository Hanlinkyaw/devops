#!/bin/bash

# Set thresholds
cpuThreshold=75
ramThreshold=75
diskThreshold=20  # Set threshold to 20% for disk usage of the / directory

# Get total CPU usage and identify the top 10 processes with the highest CPU usage
cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')  # Adjusting for CentOS CPU idle percentage extraction
topCpuProcesses=$(ps -eo pid,comm,%cpu --sort=-%cpu | head -n 11)  # Top 10 processes by CPU

# Get RAM usage in MB
ram_total=$(free -m | grep Mem | awk '{print $2}')  # Total memory in MB
ram_used=$(free -m | grep Mem | awk '{print $3}')   # Used memory in MB
ram_usage_percentage=$(awk "BEGIN {printf \"%.2f\", ($ram_used/$ram_total)*100}")  # RAM usage percentage

# Get the top 10 processes with the highest RAM usage and display memory usage in MB
topRamProcesses=$(ps -eo pid,comm,%mem,rss --sort=-%mem | head -n 11 | awk '{printf "PID: %s | %s: %.2f MB\n", $1, $2, $4/1024}')  # Top 10 processes by RAM usage (in MB)

# Get Disk usage for the / directory and check free space
disk_usage=$(df -h / | grep / | awk '{print $5}' | sed 's/%//')  # Disk usage percentage for /
free_space=$(df -h / | grep / | awk '{print $4}')  # Free space in / directory
total_space=$(df -h / | grep / | awk '{print $2}') # Total space in / directory

# Initialize message variable
sendMessage=false
message="*Resource Usage Alert on NearMe TMS Server Prod*%0A"

# Check CPU usage
if (( $(echo "$cpu > $cpuThreshold" | bc -l) )); then
    sendMessage=true
    message+="%0A*CPU Usage*%0A"
    message+="Total CPU Usage: *$cpu%* (Threshold: $cpuThreshold%)%0A"
    message+="Top 10 processes by CPU usage:%0A\`\`\`%0A$topCpuProcesses%0A\`\`\`"
fi

# Check RAM usage
if (( $(echo "$ram_usage_percentage > $ramThreshold" | bc -l) )); then
    sendMessage=true
    message+="%0A*RAM Usage*%0A"
    message+="Used RAM: *$ram_used MB* out of *$ram_total MB* ($ram_usage_percentage%) (Threshold: $ramThreshold%)%0A"
    message+="Top 10 processes by RAM usage:%0A\`\`\`%0A$topRamProcesses%0A\`\`\`"
fi

# Check disk usage for the / directory
if (( disk_usage > diskThreshold )); then
    sendMessage=true
    message+="%0A*Disk Usage*%0A"
    message+="Disk Usage: *$disk_usage%* (Threshold: $diskThreshold%)%0A"
    message+="Free space: *$free_space* out of *$total_space*%0A"
fi

# Send message to Telegram Bot if any threshold is exceeded
if [ "$sendMessage" = true ]; then
    botToken="7527978778:AAGAIqi2_AVhVq5KnwRgJ7EDwaBESEB-ucU"
    chatId="-4511721660"
    telegramApiUrl="https://api.telegram.org/bot$botToken/sendMessage"

    curl -s -X POST $telegramApiUrl -d chat_id=$chatId -d parse_mode="Markdown" -d text="$message"
fi

