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

# Format the message with URL encoded newlines
message="Resource Usage on $server_name:%0ACPU Usage: $cpu_usage%0ARAM Total: $ram_total MB%0ARAM Used: $ram_used MB%0ARAM Free: $ram_free MB%0A%0ADisk Usage:%0A$disk_info"

# Send to Telegram Bot
bot_token="7527978778:AAGAIqi2_AVhVq5KnwRgJ7EDwaBESEB-ucU"
#chat_id="1657309447"
chat_id="-4511721660"
telegram_api_url="https://api.telegram.org/bot$bot_token/sendMessage"

curl -s -X POST $telegram_api_url -d chat_id=$chat_id -d text="$message"
