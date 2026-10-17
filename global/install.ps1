# Windows counterpart of install.sh: same shared files, no RTK hook (bash/Linux only).
# Run from PowerShell:  pwsh -File .\global\install.ps1
$ErrorActionPreference = 'Stop'
$source = $PSScriptRoot
$repo   = Split-Path $source -Parent
$target = if ($env:CLAUDE_HOME) { $env:CLAUDE_HOME } else { Join-Path $env:USERPROFILE '.claude' }
$personal = if ($env:PERSONAL_DIR) { $env:PERSONAL_DIR } else { Split-Path $repo -Parent }
New-Item -ItemType Directory -Force $target | Out-Null

function Set-Junction($name, $dest) {
  $p = Join-Path $target $name
  $item = Get-Item $p -Force -ErrorAction SilentlyContinue
  if ($item -and $item.LinkType -ne 'Junction') { Move-Item $p "$p.bak" -Force }
  elseif ($item) { $item.Delete() }
  # Junctions cannot target UNC paths (repo living inside WSL); those need a symbolic link.
  $type = if ($dest.StartsWith('\\')) { 'SymbolicLink' } else { 'Junction' }
  New-Item -ItemType $type -Path $p -Target $dest | Out-Null
  Write-Host "linked $p"
}
Set-Junction 'rules' $repo
Set-Junction 'standards' (Join-Path $source 'standards')

# CLAUDE.md only imports the shared file, so it never drifts from the repository.
Set-Content (Join-Path $target 'CLAUDE.md') '@rules/global/CLAUDE.md' -Encoding utf8
Copy-Item (Join-Path $source 'CLAUDE-omc.md') $target -Force
Copy-Item (Join-Path $source 'RTK.md') $target -Force

$settingsPath = Join-Path $target 'settings.json'
$cur = if (Test-Path $settingsPath) { Get-Content $settingsPath -Raw | ConvertFrom-Json -AsHashtable } else { @{} }
$base = Get-Content (Join-Path $source 'settings.base.json') -Raw | ConvertFrom-Json -AsHashtable
foreach ($k in $base.Keys) { $cur[$k] = $base[$k] }
$perm = if ($cur.ContainsKey('permissions')) { $cur['permissions'] } else { @{} }
$perm['additionalDirectories'] = @($personal)
$cur['permissions'] = $perm
$hudPath = (Join-Path $target 'hud/omc-hud.mjs') -replace '\\','/'
$cur['statusLine'] = @{ type = 'command'; command = "node $hudPath" }
$cur | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding utf8
Write-Host "merged $settingsPath"

# Global gitignore versionado + fim de linha igual ao WSL (a pasta é compartilhada; CRLF quebra scripts .sh).
git config --global core.excludesfile ((Join-Path $source 'gitignore_global') -replace '\\','/')
git config --global core.autocrlf input
Write-Host 'git core.excludesfile e core.autocrlf=input configurados'
