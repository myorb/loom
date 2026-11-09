# loom init — idempotent project skeleton. Never overwrites. Run from the project root.
# Windows PowerShell 5.1+ and pwsh. Same result as init.sh. Prints one line; $env:LOOM_VERBOSE=1 lists paths.
$ErrorActionPreference = 'Stop'
$Tpl  = Join-Path $PSScriptRoot '..\templates'
$script:made = 0; $script:kept = 0; $script:detail = @()

function Note($what, $path) { $script:detail += "  $what $path" }
function Put($src, $dst) {
  if (Test-Path $dst) { $script:kept++; Note 'kept' $dst; return }
  $dir = Split-Path $dst -Parent
  if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
  Copy-Item $src $dst; $script:made++; Note 'made' $dst
}
function Line($file, $text) {
  if (-not (Test-Path $file)) { New-Item -ItemType File -Path $file | Out-Null }
  $hit = Get-Content $file | Where-Object { $_ -ceq $text }
  if ($hit) { $script:kept++; Note 'kept' "${file}: $text"; return }
  $raw = [IO.File]::ReadAllText((Resolve-Path $file)); if ($raw.Length -gt 0 -and -not $raw.EndsWith("`n")) { [IO.File]::AppendAllText((Resolve-Path $file), "`n") }
  Add-Content -Path $file -Value $text; $script:made++; Note 'made' "${file}: $text"
}

git rev-parse --is-inside-work-tree 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) { $script:kept++; Note 'kept' 'git (already a repo)' } else { & git init -q; $script:made++; Note 'made' '.git' }

foreach ($d in 'flows','features','frames','decisions','risks','concepts') {
  $p = "docs\$d"
  if (-not (Test-Path $p)) { New-Item -ItemType Directory -Path $p | Out-Null }
  $k = Join-Path $p '.gitkeep'
  if (Test-Path $k) { $script:kept++ } else { New-Item -ItemType File -Path $k | Out-Null; $script:made++; Note 'made' "docs/$d/" }
}

if ($args -contains '--template') { Put (Join-Path $Tpl 'PROJECT.md') 'docs\PROJECT.md' }
Put (Join-Path $Tpl 'graph.json') 'docs\.obsidian\graph.json'

Line 'CLAUDE.md' '@docs/PROJECT.md'
Line 'CLAUDE.md' 'Work in this repo with the loom:lead skill.'

foreach ($l in Get-Content (Join-Path $Tpl 'gitignore')) { if ($l) { Line '.gitignore' $l } }

"loom skeleton: $($script:made) made · $($script:kept) kept"
if ($env:LOOM_VERBOSE -eq '1') { $script:detail }
