#!/bin/bash

# Set thresholds
cpuThreshold=75
ramThreshold=75
diskThreshold=80 # Set threshold to 80% for disk usage of the / directory

# Get total CPU usage and identify the top 10 processes with the highest CPU usage
cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')
cpu_int=$(echo "$cpu" | awk '{printf("%.0f\n", $1)}')  # Convert CPU usage to an integer using printf and awk
topCpuProcesses=$(ps -eo pid,comm,%cpu --sort=-%cpu | head -n 11 | awk '{printf "PID: %s | %s: %s%%\n", $1, $2, $3}')  # Top 10 processes by CPU usage

# Get RAM usage in MB
ram_total=$(free -m | grep Mem | awk '{print $2}')  # Total memory in MB
ram_used=$(free -m | grep Mem | awk '{print $3}')   # Used memory in MB
ram_usage_percentage=$(awk "BEGIN {printf(\"%.0f\n\", ($ram_used/$ram_total)*100)}")  # RAM usage percentage converted to an integer

# Get the top 10 processes with the highest RAM usage and display memory usage in MB
topRamProcesses=$(ps -eo pid,comm,%mem,rss --sort=-%mem | head -n 11 | awk '{printf "PID: %s | %s: %.2f MB\n", $1, $2, $4/1024}')  # Top 10 processes by RAM usage (in MB)

# Get Disk usage for the / directory and check free space
disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')  # Disk usage percentage for /
free_space=$(df -h / | awk 'NR==2 {print $4}')  # Free space in / directory
total_space=$(df -h / | awk 'NR==2 {print $2}') # Total space in / directory

# Initialize message variable
sendMessage=false
message="*🚨 Resource Usage Alert on NearMe Zay Server Prod 🚨*:%0A"

# Check CPU usage
if (( cpu_int > cpuThreshold )); then
    sendMessage=true
    message+="%0A*🖥️ CPU Usage*: $cpu_int% (Threshold: $cpuThreshold%)%0A"
    message+="Top 10 processes by CPU usage:%0A\`\`\`%0A"
    message+="$topCpuProcesses%0A\`\`\`"
fi

# Check RAM usage
if (( ram_usage_percentage > ramThreshold )); then
    sendMessage=true
    message+="%0A*💾 RAM Usage*: $ram_used MB used out of $ram_total MB ($ram_usage_percentage%) (Threshold: $ramThreshold%)%0A"
    message+="Top 10 processes by RAM usage (in MB):%0A\`\`\`%0A"
    message+="$topRamProcesses%0A\`\`\`"
fi

# Check disk usage for the / directory
if (( disk_usage > diskThreshold )); then
    sendMessage=true
    message+="%0A*🗄️ Disk Usage*: $disk_usage% (Threshold: $diskThreshold%)%0A"
    message+="Free space: $free_space out of $total_space%0A"
fi

# Send message to Telegram Bot if any threshold is exceeded
if [ "$sendMessage" = true ]; then
    botToken="7527978778:AAGAIqi2_AVhVq5KnwRgJ7EDwaBESEB-ucU"
    chatId="-4511721660"
    telegramApiUrl="https://api.telegram.org/bot$botToken/sendMessage"

    curl -s -X POST $telegramApiUrl -d chat_id=$chatId -d parse_mode="Markdown" -d text="$message"
fi

