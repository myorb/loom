# loom run — one frame, one worktree, one bounded unattended session. Never touches the base branch.
# usage: run.ps1 <docs/frames/F-<slug>.md> [-Dry]        from anywhere inside the repo. Untested port of run.sh.
param([Parameter(Mandatory=$true)][string]$Frame, [switch]$Dry)
$ErrorActionPreference = 'Continue'
$root = (git rev-parse --show-toplevel).Trim(); if (-not [IO.Path]::IsPathRooted($Frame)) { $Frame = Join-Path (Get-Location) $Frame }
Set-Location $root; $Frame = [IO.Path]::GetRelativePath($root, $Frame) -replace '\\', '/'
if (-not (Test-Path $Frame)) { Write-Error "loom run: no such frame: $Frame"; exit 1 }
$id = [IO.Path]::GetFileNameWithoutExtension($Frame); $repo = Split-Path $root -Leaf; $br = "loom/$id"
$home_ = if ($env:LOOM_HOME) { $env:LOOM_HOME } else { Join-Path $HOME '.loom' }
$wt = Join-Path $home_ "$repo\$id"; $runs = Join-Path $root '.loom\runs'
New-Item -ItemType Directory -Force -Path $runs, (Split-Path $wt -Parent) | Out-Null
$status = Join-Path $runs "$id.status"; $report = Join-Path $runs "$id.report.md"; $log = Join-Path $runs "$id.jsonl"

function Rule($k) { $m = Select-String -Path docs/PROJECT.md -Pattern "^- *${k}:" | Select-Object -First 1; if ($m) { ($m.Line -replace "^- *${k}: *", '') } else { '' } }
$b = Rule 'budget'; $minutes = if ($b -match 'minutes=(\d+)') { [int]$Matches[1] } else { 45 }; $usd = if ($b -match 'usd=([\d.]+)') { $Matches[1] } else { '10' }
$setup = Rule 'setup'; $envvars = Rule 'env'

$lock = Join-Path $runs "$id.lock"
if (Test-Path $lock) { Write-Error "loom run: $id is already running (lock $lock)"; exit 1 }
New-Item -ItemType Directory -Path $lock | Out-Null
try {
  git worktree prune
  git show-ref --verify --quiet "refs/heads/$br"
  if ($LASTEXITCODE -eq 0) { Write-Error "loom run: branch $br exists — a re-run needs a new frame ($id-2) or ``drop`` first"; exit 1 }
  git worktree add -q -b $br $wt | Out-Null
  if ((Test-Path (Join-Path $root '.env')) -and -not (Test-Path (Join-Path $wt '.env'))) { Copy-Item (Join-Path $root '.env') (Join-Path $wt '.env') }
  if (-not $setup) {
    if (Test-Path pnpm-lock.yaml) { $setup = 'pnpm install --frozen-lockfile' }
    elseif (Test-Path yarn.lock) { $setup = 'yarn install --frozen-lockfile' }
    elseif (Test-Path package-lock.json) { $setup = 'npm ci' }
    elseif (Test-Path uv.lock) { $setup = 'uv sync' }
    elseif (Test-Path poetry.lock) { $setup = 'poetry install' }
  }
  $started = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
  "id: $id`nbranch: $br`nworktree: $wt`nstarted: $started`nstate: running" | Set-Content -Encoding utf8 $status
  if ($setup) {
    Push-Location $wt; cmd /c "$setup" *> (Join-Path $runs "$id.setup.log"); $ok = $LASTEXITCODE -eq 0; Pop-Location
    if (-not $ok) { "state: failed`nreason: setup failed — see $runs\$id.setup.log" | Add-Content $status; exit 1 }
  }
  if ($Dry) { "state: dry" | Add-Content $status; "loom run ${id}: dry — worktree $wt on $br, setup: $(if ($setup) { $setup } else { 'none' })"; exit 0 }

  $keep = 'PATH','HOME','USERPROFILE','USERNAME','TEMP','TMP','SystemRoot','ComSpec','APPDATA','LOCALAPPDATA','LOOM_RUN_MODEL','LOOM_PLUGIN_DIR'
  $keep += ($envvars -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
  $keep += (Get-ChildItem Env: | Where-Object { $_.Name -like 'ANTHROPIC_*' -or $_.Name -like 'CLAUDE_CODE_*' -or $_.Name -eq 'CLAUDE_CONFIG_DIR' } | ForEach-Object Name)
  Get-ChildItem Env: | Where-Object { $keep -notcontains $_.Name } | ForEach-Object { Remove-Item "Env:$($_.Name)" -ErrorAction SilentlyContinue }
  $env:LOOM_RUN = '1'
  $args_ = @('-p'); if ($env:LOOM_RUN_MODEL) { $args_ += @('--model', $env:LOOM_RUN_MODEL) }; if ($env:LOOM_PLUGIN_DIR) { $args_ += @('--plugin-dir', $env:LOOM_PLUGIN_DIR) }
  $args_ += @('--permission-mode','acceptEdits','--allowedTools','Read,Write,Edit,Glob,Grep,Agent,Skill,Bash','--disallowedTools','AskUserQuestion,WebFetch,WebSearch',
              '--max-turns','120','--max-budget-usd',"$usd",'--output-format','stream-json','--verbose',
              "Use the loom:run skill on $Frame. Unattended run in worktree $wt on branch $br.")
  Push-Location $wt
  $p = Start-Process -FilePath 'claude' -ArgumentList $args_ -NoNewWindow -PassThru -RedirectStandardOutput $log -RedirectStandardError (Join-Path $runs "$id.err")
  if (-not $p.WaitForExit($minutes * 60 * 1000)) { $p.Kill(); $code = 124 } else { $code = $p.ExitCode }
  Pop-Location
  $res = Get-Content $log | ForEach-Object { try { $_ | ConvertFrom-Json } catch { $null } } | Where-Object { $_ -and $_.type -eq 'result' } | Select-Object -Last 1
  if ($res) { $res.result | Set-Content -Encoding utf8 $report; "turns: $($res.num_turns)`ncost_usd: $($res.total_cost_usd)`nsubtype: $($res.subtype)" | Add-Content $status } else { Copy-Item (Join-Path $runs "$id.err") $report }
  $state = 'done'; if (Select-String -Path $report -Pattern '^blocked:' -Quiet) { $state = 'blocked' }; if ($code -eq 124) { $state = 'timeout' } elseif ($code -ne 0 -and $state -eq 'done') { $state = 'failed' }
  "ended: $((Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ'))`nexit: $code`nstate: $state" | Add-Content $status
  "loom run ${id}: $state (exit $code) — report: $report · status: $status"
  if ($state -ne 'done') { exit 1 }
} finally { Remove-Item $lock -Force -ErrorAction SilentlyContinue }
