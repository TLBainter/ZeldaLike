param(
    [string]$ProjectPath = (Get-Location).Path
)

$logFile = Join-Path $ProjectPath "debug_output.log"
if (Test-Path $logFile) { Remove-Item $logFile }

Write-Host "=== Godot Debug Session ===" -ForegroundColor Cyan
Write-Host "Project: $ProjectPath" -ForegroundColor Gray
Write-Host "Log: $logFile" -ForegroundColor Gray
Write-Host "All output will be copied to clipboard on exit.`n" -ForegroundColor Yellow

& "U:\Godot_v4.6.2-stable_win64_console.exe" --path "$ProjectPath" --always-on-top 2>&1 | Tee-Object -FilePath $logFile

if (Test-Path $logFile) {
    Get-Content $logFile -Raw | Set-Clipboard
    $lineCount = (Get-Content $logFile).Count
    Write-Host "`n=== Session Ended ===" -ForegroundColor Cyan
    Write-Host "$lineCount lines copied to clipboard." -ForegroundColor Green
} else {
    Write-Host "`nNo log file generated." -ForegroundColor Red
}