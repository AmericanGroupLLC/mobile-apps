$temp = Join-Path $env:TEMP 'myhealth-smoke.db'
Get-Item ($temp + '*') -ErrorAction SilentlyContinue | Remove-Item -Force
$content = Get-Content .env
$content = $content -replace 'DB_PATH=.*', "DB_PATH=$temp"
Set-Content -Path .env -Value $content
Get-Content .env
