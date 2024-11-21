@echo off
set output=status_results.csv
echo URL,HTTP_Status > %output%

for /f "tokens=*" %%u in (urls.txt) do (
    echo Checking %%u...
    curl -I --silent %%u > temp_status.txt
    if exist temp_status.txt (
        type temp_status.txt
        findstr "HTTP" temp_status.txt > found_status.txt
        if exist found_status.txt (
            for /f "tokens=2 delims= " %%s in (found_status.txt) do (
                echo %%u,%%s >> %output%
            )
        ) else (
            echo %%u,NO_STATUS_FOUND >> %output%
        )
    ) else (
        echo %%u,CURL_FAILED >> %output%
    )
)
del temp_status.txt 2>nul
del found_status.txt 2>nul
echo Done! Results saved to %output%.
pause
