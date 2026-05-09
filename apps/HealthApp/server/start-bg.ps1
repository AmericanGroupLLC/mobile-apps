$proc = Start-Process -FilePath "node" -ArgumentList "server.js" -PassThru -WindowStyle Hidden -RedirectStandardOutput "server.log" -RedirectStandardError "server.err.log"
$proc.Id | Out-File -FilePath "server.pid" -NoNewline
Write-Host "Started PID $($proc.Id)"
