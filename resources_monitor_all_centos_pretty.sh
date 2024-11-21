#!/bin/bash

# Server Name
server_name="NearMe TMS Prod"

# Get CPU Usage
cpu_usage=$(top -bn1 | grep "Cpu(s)" | \
           sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | \
           awk '{print 100 - $1"%"}')

# Get RAM Usage
ram_total=$(free -m | awk '/^Mem:/{print $2}')
ram_used=$(free -m | awk '/^Mem:/{print $3}')
ram_free=$(free -m | awk '/^Mem:/{print $4}')

# Get Disk Usage
disk_info=$(df -h --output=source,size,used,avail | grep -vE '^tmpfs|cdrom')

# Format Disk Usage for pretty output
formatted_disk_info=$(df -h --output=source,size,used,avail,pcent | grep -vE '^tmpfs|cdrom' | awk '{printf "%-20s %-10s %-10s %-10s %-5s\n", $1, $2, $3, $4, $5}')

# Format the message with URL encoded newlines and Markdown for better readability
message="*Resource Usage on $server_name*:%0A"
message+="*CPU Usage*: $cpu_usage%0A"
message+="*RAM Total*: $ram_total MB%0A"
message+="*RAM Used*: $ram_used MB%0A"
message+="*RAM Free*: $ram_free MB%0A%0A"
message+="*Disk Usage*:%0A\`\`\`%0A$formatted_disk_info%0A\`\`\`"

# Send to Telegram Bot
bot_token="7527978778:AAGAIqi2_AVhVq5KnwRgJ7EDwaBESEB-ucU"
chat_id="-4511721660"
telegram_api_url="https://api.telegram.org/bot$bot_token/sendMessage"

curl -s -X POST $telegram_api_url -d chat_id=$chat_id -d parse_mode="Markdown" -d text="$message"

