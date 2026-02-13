# Ralph Installer - Sets up Ralph in the current project
# Usage: iex (irm https://raw.githubusercontent.com/snarktank/ralph/main/init-ralph.ps1)

$ErrorActionPreference = "Stop"

$BaseUrl = "https://raw.githubusercontent.com/snarktank/ralph/main"
$RalphDir = Join-Path (Get-Location) "scripts\ralph"
$SkillsDir = Join-Path $RalphDir "skills"

Write-Host ""
Write-Host "Installing Ralph into scripts\ralph\ ..." -ForegroundColor Cyan
Write-Host ""

# Create directory structure
New-Item -ItemType Directory -Path (Join-Path $SkillsDir "prd") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $SkillsDir "ralph") -Force | Out-Null

# Download files
$files = @{
    "ralph.ps1"            = "ralph.ps1"
    "CLAUDE.md"            = "CLAUDE.md"
    "prd.json.example"     = "prd.json.example"
    "skills/prd/SKILL.md"  = "skills\prd\SKILL.md"
    "skills/ralph/SKILL.md" = "skills\ralph\SKILL.md"
}

foreach ($entry in $files.GetEnumerator()) {
    $url = "$BaseUrl/$($entry.Key)"
    $dest = Join-Path $RalphDir $entry.Value
    Write-Host "  Downloading $($entry.Key)..."
    Invoke-RestMethod -Uri $url -OutFile $dest
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
