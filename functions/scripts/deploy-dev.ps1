$ErrorActionPreference = 'Stop'
$projectId = 'prm393-31822'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$config = Get-Content -LiteralPath (Join-Path $repoRoot 'firebase.json') -Raw | ConvertFrom-Json
if ($config.flutter.platforms.android.default.projectId -ne $projectId) {
    throw 'FlutterFire config must point to the approved team project prm393-31822.'
}
if ((& node -p 'process.versions.node.split(".")[0]') -ne '22') {
    throw 'Put Node.js 22 on PATH before deploying.'
}
$entry = Get-Content -LiteralPath (Join-Path $repoRoot 'functions/src/index.ts') -Raw
[string[]]$functionNames = [regex]::Matches($entry, '(?m)^export const ([A-Za-z][A-Za-z0-9_]*)\s*=') |
    ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
if ($functionNames.Count -eq 0) { throw 'No function exports found; refusing to deploy.' }
$logDir = Join-Path $repoRoot ('evidence/firebase-migration/deploy-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Path $logDir -Force | Out-Null
Push-Location $repoRoot
try {
    # CLI deploys up to 40 functions at once; four avoids this project's startup CPU quota spikes.
    for ($offset = 0; $offset -lt $functionNames.Count; $offset += 4) {
        $last = [Math]::Min($offset + 3, $functionNames.Count - 1)
        $batch = $functionNames[$offset..$last]
        $selector = ($batch | ForEach-Object { 'functions:evia:' + $_ }) -join ','
        Write-Host ('Deploying: ' + ($batch -join ', '))
        & firebase deploy --project $projectId --only $selector --non-interactive --force 2>&1 |
            Tee-Object -FilePath (Join-Path $logDir ('batch-' + ($offset / 4 + 1) + '.log'))
        if ($LASTEXITCODE -ne 0) { throw ('Deploy failed; inspect ' + $logDir) }
    }
}
finally { Pop-Location }
