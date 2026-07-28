# Run AFTER Vivace/Membership OR Platform API key is configured.
# Usage: powershell -ExecutionPolicy Bypass -File post-access-probe.ps1
# Logs NDJSON to ../debug-638b9e.log (session 638b9e)

$ErrorActionPreference = 'Continue'
# Log next to workspace root (parent of moonshot-intel/)
$logPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'debug-638b9e.log'
if (-not (Test-Path (Split-Path $logPath -Parent))) {
    $logPath = Join-Path $PSScriptRoot 'debug-638b9e.log'
}

function Write-ProbeLog($hid, $loc, $msg, $data) {
    $line = @{
        sessionId    = '638b9e'
        id           = "log_$( [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() )"
        timestamp    = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
        hypothesisId = $hid
        location     = $loc
        message      = $msg
        runId        = 'post-access'
        data         = $data
    } | ConvertTo-Json -Compress -Depth 12
    [System.IO.File]::AppendAllText($logPath, $line + "`n", [System.Text.UTF8Encoding]::new($false))
}

Write-Host "=== Kimi post-access probe ===" -ForegroundColor Cyan

# 1. CLI health
$doctor = & "$env:USERPROFILE\.kimi-code\bin\kimi.exe" doctor 2>&1 | Out-String
Write-ProbeLog 'P1' 'doctor' 'output' @{valid = ($doctor -match 'All checked config files are valid')}

$prov = & "$env:USERPROFILE\.kimi-code\bin\kimi.exe" provider list 2>&1 | Out-String
Write-ProbeLog 'P2' 'provider' 'list' @{text = $prov.Trim()}

# 2. OAuth refresh (managed:kimi-code path)
$oauthOk = $false
$accessToken = $null
try {
    $credPath = "$env:USERPROFILE\.kimi-code\credentials\kimi-code.json"
    if (Test-Path $credPath) {
        $cred = Get-Content $credPath -Raw | ConvertFrom-Json
        $form = "grant_type=refresh_token&refresh_token=$($cred.refresh_token)&client_id=17e5f671-d194-4dfb-9706-5516cb48c098"
        $raw = curl.exe -sS --max-time 15 -X POST "https://auth.kimi.com/api/oauth/token" `
            -H "Content-Type: application/x-www-form-urlencoded" -d $form -w "`nHTTP:%{http_code}" 2>&1 | Out-String
        $oauthOk = $raw -match 'access_token' -and $raw -match 'HTTP:200'
        if ($oauthOk) {
            $json = ($raw -replace "`nHTTP:.*", '') | ConvertFrom-Json
            $accessToken = $json.access_token
        }
        Write-ProbeLog 'P3' 'oauth' 'refresh' @{ok = $oauthOk; http = ($raw -split "`n")[-1]}
    }
} catch {
    Write-ProbeLog 'P3' 'oauth' 'refresh' @{ok = $false; error = $_.Exception.Message }
}

# 3. Code API (OAuth path)
if ($accessToken) {
    foreach ($path in @('/models', '/usages')) {
        $r = curl.exe -sS --max-time 15 -H "Authorization: Bearer $accessToken" `
            "https://api.kimi.com/coding/v1$path" -w "`nHTTP:%{http_code}" 2>&1 | Out-String
        $http = ($r -split "`n")[-1] -replace 'HTTP:', ''
        $body = ($r -replace "`nHTTP:.*", '').Trim()
        Write-ProbeLog 'P4' 'code-api' $path @{http = $http; bodyHead = $body.Substring(0, [Math]::Min(200, $body.Length)) }
    }

    $bodyFile = Join-Path $env:TEMP 'kimi-probe-chat.json'
    [System.IO.File]::WriteAllText($bodyFile, '{"model":"kimi-for-coding","messages":[{"role":"user","content":"Reply with exactly: OK"}],"max_tokens":16}', (New-Object System.Text.UTF8Encoding $false))
    $chat = curl.exe -sS --max-time 30 -X POST "https://api.kimi.com/coding/v1/chat/completions" `
        -H "Authorization: Bearer $accessToken" -H "Content-Type: application/json" -H "User-Agent: kimi-cli/0.29.2" `
        --data-binary "@$bodyFile" -w "`nHTTP:%{http_code}" 2>&1 | Out-String
    Write-ProbeLog 'P5' 'code-api' 'chat/completions' @{
        http     = ($chat -split "`n")[-1] -replace 'HTTP:', ''
        bodyHead = ($chat -replace "`nHTTP:.*", '').Substring(0, [Math]::Min(300, ($chat -replace "`nHTTP:.*", '').Length))
    }
}

# 4. CLI prompt
$cli = & "$env:USERPROFILE\.kimi-code\bin\kimi.exe" -p "Reply with exactly: OK" 2>&1 | Out-String
Write-ProbeLog 'P6' 'cli' 'kimi-p' @{
    is402       = ($cli -match '402')
    is403       = ($cli -match '403')
    isMembership = ($cli -match 'membership')
    outputHead  = $cli.Substring(0, [Math]::Min(400, $cli.Length))
}

Write-Host ""
Write-Host "Done. Log: $logPath" -ForegroundColor Green
Write-Host "Expected WITH Vivace: /models=200, /usages=200, chat=200, kimi -p returns OK"
Write-Host "Expected WITHOUT membership: 402 on /models and kimi -p (current state)"
