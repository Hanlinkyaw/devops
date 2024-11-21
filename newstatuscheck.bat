@echo off
set output=status_results.csv
echo URL,HTTP_Status > %output%

for /f "tokens=*" %%u in (urls.txt) do (
    echo Checking %%u...
    curl -I --silent --location --write-out "%%{http_code}" --output nul %%u > temp_status.txt
    for /f "delims=" %%s in (temp_status.txt) do (
        echo %%u,%%s >> %output%
    )
)
del temp_status.txt 2>nul
echo Done! Results saved to %output%.
pause

