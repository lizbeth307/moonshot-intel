# Platform API probe — run AFTER creating key at platform.kimi.ai
# Usage:
#   $env:MOONSHOT_API_KEY = "sk-..."
#   powershell -ExecutionPolicy Bypass -File platform-probe.ps1

param(
    [string]$ApiKey = $env:MOONSHOT_API_KEY,
    [string]$BaseUrl = "https://api.moonshot.ai/v1"
)

$ErrorActionPreference = 'Continue'
$logPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'platform-probe.log'

function Write-Log($step, $data) {
    $line = @{ ts = (Get-Date).ToUniversalTime().ToString('o'); step = $step; data = $data } | ConvertTo-Json -Compress -Depth 10
    Add-Content -Path $logPath -Value $line -Encoding UTF8
}

Write-Host "=== Platform API probe ===" -ForegroundColor Cyan

if (-not $ApiKey) {
    Write-Host "Set MOONSHOT_API_KEY or pass -ApiKey" -ForegroundColor Red
    exit 1
}

$hdr = "Authorization: Bearer $ApiKey"

# Balance
$bal = curl.exe -sS --max-time 15 -H $hdr "$BaseUrl/users/me/balance" -w "`nHTTP:%{http_code}" 2>&1 | Out-String
Write-Log 'balance' @{ http = ($bal -split "`n")[-1]; body = ($bal -replace "`nHTTP:.*", '').Trim().Substring(0, [Math]::Min(500, ($bal -replace "`nHTTP:.*", '').Trim().Length)) }

# Models
$models = curl.exe -sS --max-time 15 -H $hdr "$BaseUrl/models" -w "`nHTTP:%{http_code}" 2>&1 | Out-String
Write-Log 'models' @{ http = ($models -split "`n")[-1]; body = ($models -replace "`nHTTP:.*", '').Trim().Substring(0, [Math]::Min(800, ($models -replace "`nHTTP:.*", '').Trim().Length)) }

# Chat K3
$bodyFile = Join-Path $env:TEMP 'platform-chat.json'
[IO.File]::WriteAllText($bodyFile, '{"model":"kimi-k3","messages":[{"role":"user","content":"Reply OK"}],"max_tokens":8}', [Text.UTF8Encoding]::new($false))
$chat = curl.exe -sS --max-time 45 -X POST "$BaseUrl/chat/completions" -H $hdr -H "Content-Type: application/json" --data-binary "@$bodyFile" -w "`nHTTP:%{http_code}" 2>&1 | Out-String
Write-Log 'chat' @{ http = ($chat -split "`n")[-1]; body = ($chat -replace "`nHTTP:.*", '').Trim().Substring(0, [Math]::Min(500, ($chat -replace "`nHTTP:.*", '').Trim().Length)) }

Write-Host "Log: $logPath" -ForegroundColor Green
Write-Host "Next: kimi -> /login -> Kimi Platform (API key) to use same key in CLI"
