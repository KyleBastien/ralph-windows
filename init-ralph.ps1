# Ralph Installer - Sets up Ralph in the current project
# Usage: iex (irm https://raw.githubusercontent.com/KyleBastien/ralph-windows/main/init-ralph.ps1)

$ErrorActionPreference = "Stop"

$BaseUrl = "https://raw.githubusercontent.com/KyleBastien/ralph-windows/main"
$RalphDir = Join-Path (Get-Location) "scripts\ralph"
$SkillsDir = Join-Path (Get-Location) ".agents\skills"

Write-Host ""
Write-Host "Installing Ralph into scripts\ralph\ ..." -ForegroundColor Cyan
Write-Host ""

# Create directory structure
New-Item -ItemType Directory -Path $RalphDir -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $SkillsDir "prd") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $SkillsDir "ralph") -Force | Out-Null

# Download ralph files to scripts\ralph
$ralphFiles = @{
    "ralph.ps1" = "ralph.ps1"
    "CLAUDE.md" = "CLAUDE.md"
}

foreach ($entry in $ralphFiles.GetEnumerator()) {
    $url = "$BaseUrl/$($entry.Key)"
    $dest = Join-Path $RalphDir $entry.Value
    Write-Host "  Downloading $($entry.Key)..."
    Invoke-RestMethod -Uri $url -OutFile $dest
}

# Download skills to .agents\skills
$skillFiles = @{
    "skills/prd/SKILL.md"   = "prd\SKILL.md"
    "skills/ralph/SKILL.md" = "ralph\SKILL.md"
}

foreach ($entry in $skillFiles.GetEnumerator()) {
    $url = "$BaseUrl/$($entry.Key)"
    $dest = Join-Path $SkillsDir $entry.Value
    Write-Host "  Downloading $($entry.Key)..."
    Invoke-RestMethod -Uri $url -OutFile $dest
}

# Ensure .claude symlink exists pointing to .agents
$agentsDir = Join-Path (Get-Location) ".agents"
$claudeDir = Join-Path (Get-Location) ".claude"
if (-not (Test-Path $claudeDir)) {
    Write-Host "  Creating .claude -> .agents symlink..."
    try {
        New-Item -ItemType SymbolicLink -Path $claudeDir -Target $agentsDir -Force | Out-Null
    } catch {
        Write-Host "  Requesting admin privileges for symlink creation..." -ForegroundColor Yellow
        try {
            Start-Process -Verb RunAs -FilePath "pwsh" -ArgumentList "-Command", "New-Item -ItemType SymbolicLink -Path '$claudeDir' -Target '$agentsDir' -Force" -Wait
        } catch {
            Write-Host "  Could not create symlink. Please run as admin:" -ForegroundColor Red
            Write-Host "    New-Item -ItemType SymbolicLink -Path '$claudeDir' -Target '$agentsDir'" -ForegroundColor Cyan
        }
    }
} elseif ((Get-Item $claudeDir).Attributes -band [IO.FileAttributes]::ReparsePoint) {
    Write-Host "  .claude symlink already exists"
} else {
    Write-Host "  Warning: .claude directory exists but is not a symlink to .agents" -ForegroundColor Yellow
}

# Update .gitignore
$gitignorePath = Join-Path (Get-Location) ".gitignore"
$ralphIgnores = @(
    "# Ralph working files",
    "scripts/ralph/prd.json",
    "scripts/ralph/progress.txt",
    "scripts/ralph/.last-branch",
    "scripts/ralph/archive/"
)

if (Test-Path $gitignorePath) {
    $content = Get-Content $gitignorePath -Raw
    $missing = $ralphIgnores | Where-Object { $content -notlike "*$_*" }
    if ($missing.Count -gt 0) {
        Write-Host "  Updating .gitignore..."
        Add-Content -Path $gitignorePath -Value ("`n" + ($missing -join "`n"))
    }
} else {
    Write-Host "  Creating .gitignore..."
    $ralphIgnores | Set-Content $gitignorePath
}

Write-Host ""
Write-Host "Ralph installed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Quick start:" -ForegroundColor Yellow
Write-Host "  1. Create a PRD:        copilot -p 'Create a PRD for [your feature]'"
Write-Host "  2. Convert to JSON:     copilot -p 'Convert tasks/prd-feature.md to prd.json'"
Write-Host "  3. Run Ralph:           .\scripts\ralph\ralph.ps1"
Write-Host ""
Write-Host "Options:"
Write-Host "  .\scripts\ralph\ralph.ps1 -Tool copilot    # Default"
Write-Host "  .\scripts\ralph\ralph.ps1 -Tool claude     # Use Claude Code"
Write-Host "  .\scripts\ralph\ralph.ps1 -MaxIterations 5 # Limit iterations"
Write-Host ""
