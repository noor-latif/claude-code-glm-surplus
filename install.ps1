# ClaudeZ installer for Windows PowerShell 5.1 and 7.
# Non-interactive: $env:SURPLUS_API_KEY = '...'; .\install.ps1
param(
  [switch]$Uninstall,
  [switch]$Purge,
  [switch]$NoMcp
)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$Repo = 'noor-latif/claude-code-glm-surplus'
$Ref = 'v1.3.0'
$PlanUrl = 'https://www.surplusintelligence.ai/app/buy/quickstart'
$Dest = Join-Path $HOME '.claudez'
$KeyFile = Join-Path $HOME '.config/surplus/api_key'
$MarkBegin = '# >>> claudez >>>'
$MarkEnd = '# <<< claudez <<<'
$DenyRule = 'Read(~/.config/surplus/**)'
$OnWindows = ($PSVersionTable.PSEdition -eq 'Desktop') -or $IsWindows
$PsExe = if ($OnWindows) { 'powershell' } else { 'pwsh' }

function Say($m) { Write-Host "==> $m" }
function Warn($m) { Write-Warning $m }
function Fwd($p) { $p -replace '\\', '/' }

function Get-ProfilePaths {
  if ($OnWindows) {
    $docs = [Environment]::GetFolderPath('MyDocuments')
    @((Join-Path $docs 'WindowsPowerShell/profile.ps1'), (Join-Path $docs 'PowerShell/profile.ps1'))
  } else {
    @($PROFILE.CurrentUserAllHosts)
  }
}

function Remove-Block($path) {
  if (-not (Test-Path $path)) { return }
  $lines = @(Get-Content $path)
  if ($lines -notcontains $MarkBegin) { return }
  $out = @()
  $skip = $false
  foreach ($line in $lines) {
    if ($line -eq $MarkBegin) { $skip = $true; continue }
    if ($line -eq $MarkEnd) { $skip = $false; continue }
    if (-not $skip) { $out += $line }
  }
  Set-Content -Path $path -Value $out
}

function Read-Settings {
  $file = Join-Path $Dest 'settings.json'
  if ((Test-Path $file) -and "$(Get-Content $file -Raw)".Trim()) {
    return Get-Content $file -Raw | ConvertFrom-Json
  }
  return [pscustomobject]@{}
}

function Set-Prop($obj, $name, $value) {
  if ($obj.PSObject.Properties[$name]) { $obj.$name = $value }
  else { $obj | Add-Member -NotePropertyName $name -NotePropertyValue $value }
}

function Write-Settings($obj) {
  $json = $obj | ConvertTo-Json -Depth 20
  [IO.File]::WriteAllText((Join-Path $Dest 'settings.json'), $json, (New-Object Text.UTF8Encoding $false))
}

function Invoke-Uninstall {
  Say 'Removing claudez'
  foreach ($profile in Get-ProfilePaths) { Remove-Block $profile }
  if (Get-Command claude -ErrorAction SilentlyContinue) {
    $env:CLAUDE_CONFIG_DIR = $Dest
    claude mcp remove -s user duckduckgo-search 2>$null
  }
  $settingsFile = Join-Path $Dest 'settings.json'
  if (Test-Path $settingsFile) {
    $settings = Read-Settings
    if ($settings.statusLine -and "$($settings.statusLine.command)" -match 'claudez[/\\]statusline') {
      $settings.PSObject.Properties.Remove('statusLine')
    }
    if ($settings.permissions -and $settings.permissions.deny) {
      $settings.permissions.deny = @($settings.permissions.deny | Where-Object { $_ -ne $DenyRule })
    }
    Write-Settings $settings
  }
  Remove-Item -Force -ErrorAction SilentlyContinue (Join-Path $Dest 'claudez.ps1')
  Remove-Item -Force -ErrorAction SilentlyContinue (Join-Path $Dest 'statusline.ps1')
  if ($Purge) { Remove-Item -Force -ErrorAction SilentlyContinue $KeyFile; Say "Deleted $KeyFile" }
  else { Say "Kept your key in $KeyFile (use -Purge to delete it)" }
  Say "Done. $Dest is kept because it holds your Claude Code history and settings."
}

function Invoke-Install {
  if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Warn 'Claude Code not found. Install it first: https://code.claude.com/docs/en/setup'
  }

  New-Item -ItemType Directory -Force (Split-Path $KeyFile) | Out-Null
  if ($env:SURPLUS_API_KEY) {
    Set-Content -Path $KeyFile -Value $env:SURPLUS_API_KEY.Trim() -NoNewline
    Say 'Saved key from SURPLUS_API_KEY'
  } elseif ((Test-Path $KeyFile) -and "$(Get-Content $KeyFile -Raw)".Trim()) {
    Say "Using existing key in $KeyFile"
  } else {
    Write-Host "Get a Surplus API key: $PlanUrl"
    $secure = Read-Host 'Paste your Surplus API key (input hidden)' -AsSecureString
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try { $key = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
    $key = ($key -replace '\s', '')
    if (-not $key) { throw "No key entered. Get a Surplus API key at $PlanUrl" }
    Set-Content -Path $KeyFile -Value $key -NoNewline
  }
  if ($OnWindows) { icacls $KeyFile /inheritance:r /grant:r "$($env:USERNAME):F" | Out-Null }
  else { chmod 600 $KeyFile }

  New-Item -ItemType Directory -Force $Dest | Out-Null
  $src = if ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot 'scripts/claudez.ps1'))) { $PSScriptRoot } else { $null }
  foreach ($file in 'scripts/claudez.ps1', 'scripts/statusline.ps1') {
    $dst = Join-Path $Dest (Split-Path $file -Leaf)
    if ($src) { Copy-Item -Force (Join-Path $src $file) $dst }
    else { Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/$Repo/$Ref/$file" -OutFile $dst }
    if ($OnWindows) { Unblock-File $dst }
  }

  $settingsFile = Join-Path $Dest 'settings.json'
  if (Test-Path $settingsFile) { Copy-Item -Force $settingsFile "$settingsFile.bak.claudez" }
  $settings = Read-Settings
  if (-not $settings.permissions) { Set-Prop $settings 'permissions' ([pscustomobject]@{}) }
  Set-Prop $settings.permissions 'deny' (@(@($settings.permissions.deny) + $DenyRule | Where-Object { $_ } | Select-Object -Unique))
  $statusCmd = "$PsExe -NoProfile -ExecutionPolicy Bypass -File $(Fwd (Join-Path $Dest 'statusline.ps1'))"
  if (-not $settings.statusLine -or "$($settings.statusLine.command)" -match 'claudez[/\\]statusline') {
    Set-Prop $settings 'statusLine' ([pscustomobject]@{ type = 'command'; command = $statusCmd; padding = 0 })
  }
  if (-not $settings.modelOverrides) { Set-Prop $settings 'modelOverrides' ([pscustomobject]@{}) }
  $settings.modelOverrides | Add-Member -Force -NotePropertyName 'claude-sonnet-4-6' -NotePropertyValue 'glm-5.3'
  Write-Settings $settings

  foreach ($profile in Get-ProfilePaths) {
    New-Item -ItemType Directory -Force (Split-Path $profile) | Out-Null
    if (Test-Path $profile) { Copy-Item -Force $profile "$profile.bak.claudez"; Remove-Block $profile | Out-Null }
    Add-Content -Path $profile -Value @(
      $MarkBegin,
      '# Claude Code through Surplus Intelligence',
      '$czScript = Join-Path $HOME ''.claudez/claudez.ps1''; if (Test-Path $czScript) { . $czScript }; Remove-Variable czScript',
      $MarkEnd
    )
  }

  if (-not $NoMcp -and (Get-Command claude -ErrorAction SilentlyContinue)) {
    $env:CLAUDE_CONFIG_DIR = $Dest
    claude mcp add -s user duckduckgo-search -- npx -y duckduckgo-websearch 2>$null
    Say 'MCP server ready: DuckDuckGo web search'
  }
  Say 'Installed. Open a new PowerShell window, then run: claudez'
}

if ($Uninstall) { Invoke-Uninstall } else { Invoke-Install }
