# One-time setup so Cursor "Build in Cloud" works
# Prerequisites: GitHub account logged in at https://github.com

param(
    [Parameter(Mandatory = $true)]
    [string]$GitHubUser,
    [string]$RepoName = "moonshot-intel"
)

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root

if (-not (Test-Path ".git")) {
    Write-Error "No .git in $root — run from repo root after git init"
}

$remoteUrl = "https://github.com/$GitHubUser/$RepoName.git"

Write-Host "1. Create EMPTY repo on GitHub (no README):" -ForegroundColor Cyan
Write-Host "   https://github.com/new?name=$RepoName" -ForegroundColor Yellow
Write-Host ""
Read-Host "Press Enter after you created the repo on GitHub"

if (git remote get-url origin 2>$null) {
    git remote remove origin
}
git remote add origin $remoteUrl
Write-Host "2. Remote added: $remoteUrl" -ForegroundColor Green

Write-Host "3. Pushing main..." -ForegroundColor Cyan
git push -u origin main

Write-Host ""
Write-Host "Done. In Cursor:" -ForegroundColor Green
Write-Host "  - Reload window (Ctrl+Shift+P -> Developer: Reload Window)"
Write-Host "  - Open plan -> Build in Cloud"
Write-Host ""
Write-Host "If still silent: update Cursor, then Cursor Settings -> GitHub -> reconnect"
