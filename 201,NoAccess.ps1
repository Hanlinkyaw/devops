# Define the input file containing the list of websites
$inputFile = "address.txt"

# Define the output file path
$outputFile = "WebsiteStatus.csv"

# Check if the input file exists
if (-Not (Test-Path $inputFile)) {
    Write-Host "Input file 'address.txt' not found. Please create the file and add website URLs, one per line."
    exit
}

# Read web addresses from the input file
$websites = Get-Content -Path $inputFile

# Get the total number of websites to process
$totalWebsites = $websites.Count

# Create an empty array to store results
$results = @()

# Initialize progress variables
$currentIndex = 0

# Function to check website status
function Check-WebsiteStatus {
    param (
        [string]$url
    )
    try {
        $response = Invoke-WebRequest -Uri $url -Method Head -ErrorAction Stop
        return [PSCustomObject]@{
            URL        = $url
            StatusCode = $response.StatusCode
            Status     = if ($response.StatusCode -eq 200) {
                "Normal"
            } elseif ($response.StatusCode -eq 301 -or $response.StatusCode -eq 302) {
                "Redirect (301/302)"
            } else {
                "Other"
            }
        }
    } catch {
        return [PSCustomObject]@{
            URL        = $url
            StatusCode = "N/A"
            Status     = "No Access"
        }
    }
}

# Loop through each website and check status
foreach ($website in $websites) {
    if (-Not [string]::IsNullOrWhiteSpace($website)) {
        $currentIndex++
        # Calculate and display progress
        $progressPercent = [math]::Round(($currentIndex / $totalWebsites) * 100, 2)
        Write-Progress -Activity "Checking website status" -Status "$progressPercent% completed" -PercentComplete $progressPercent
        
        $result = Check-WebsiteStatus -url $website
        $results += $result
    }
}

# Export results to CSV
$results | Export-Csv -Path $outputFile -NoTypeInformation -Encoding UTF8

Write-Host "Website status check completed. Results saved to $outputFile."
