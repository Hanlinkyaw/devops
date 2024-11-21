# Define the log file path based on the current date
$logFile = "D:\Log\MPUSettlementScheduler\MPUSettlement_Scheduler_$(Get-Date -Format 'yyyyMMdd').txt"

# Define the keyword to search for
$keyword = "Settlement Scheduler - END"

# Check if the file exists
if (Test-Path $logFile) {
    # Search for the keyword in the log file
    $found = Select-String -Path $logFile -Pattern $keyword

    if ($found) {
        # If the keyword is found, send a message to the Telegram bot
        $message = "Settlement Scheduler is OK. The keyword 'Settlement Scheduler - END' was found in the log file: $logFile"
    } else {
        # If the keyword is not found, send a different message
        $message = "Warning: The keyword 'Settlement Scheduler - END' was NOT found in the log file: $logFile"
    }

    # Define the Telegram bot token and chat ID
    $botToken = "7527978778:AAGAIqi2_AVhVq5KnwRgJ7EDwaBESEB-ucU"
    $chatId = "-4520196568"
    $telegramApiUrl = "https://api.telegram.org/bot$botToken/sendMessage"

    # Send the message to Telegram
    $response = Invoke-RestMethod -Uri $telegramApiUrl -Method Post -Body @{
        chat_id = $chatId
        text    = $message
    }
    
    Write-Output "Message sent to Telegram."
} else {
    Write-Output "Log file not found: $logFile"
}
