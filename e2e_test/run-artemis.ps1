[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$DeviceSerial,
    [string]$ArtemisPath = "$PSScriptRoot/../.local/artemis",
    [switch]$CheckOnly
)

$ErrorActionPreference = 'Stop'
$artemisRoot = (Resolve-Path -LiteralPath $ArtemisPath).Path
if (-not (Test-Path -LiteralPath "$artemisRoot/pyproject.toml")) {
    throw 'Artemis checkout missing. See e2e_test/README.md.'
}
$uv = Get-Command uv -ErrorAction SilentlyContinue
$uvPath = if ($uv) { $uv.Source } else { "$PSScriptRoot/../.local/uv/bin/uv.exe" }
if (-not (Test-Path -LiteralPath $uvPath)) { throw 'uv missing. See e2e_test/README.md.' }
$deviceState = & adb -s $DeviceSerial get-state 2>$null
if ($LASTEXITCODE -ne 0 -or "$deviceState".Trim() -ne 'device') {
    throw 'Selected Android device is unavailable or unauthorized.'
}
$configPath = (Resolve-Path -LiteralPath "$PSScriptRoot/artemis.deepseek.json").Path
$goal = Get-Content -LiteralPath "$PSScriptRoot/scenarios/auth_smoke.txt" -Raw -Encoding UTF8
$savedEnv = @{}
$overrides = @{
    OPENAI_BASE_URL = 'https://api.deepseek.com'
    ARTEMIS_ARTEMIS_JSONC = $configPath
    ARTEMIS_HELPER_AUTO_INSTALL = 'false'
    ARTEMIS_KEEP_DEVICE_AWAKE = 'false'
}
try {
    foreach ($name in $overrides.Keys) {
        $savedEnv[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
        [Environment]::SetEnvironmentVariable($name, $overrides[$name], 'Process')
    }
    Push-Location -LiteralPath $artemisRoot
    try {
        if ($CheckOnly) {
            & $uvPath run --no-sync python "$PSScriptRoot/check_config.py"
            if ($LASTEXITCODE -ne 0) { throw 'Artemis configuration compatibility check failed.' }
            & $uvPath run --no-sync artemis run --help
        } else {
            $installed = & adb -s $DeviceSerial shell pm path com.example.prm393_lab03
            if ($LASTEXITCODE -ne 0 -or "$installed" -notmatch 'package:') {
                throw 'Install an Evia debug APK on the selected device first.'
            }
            $tracePath = "$PSScriptRoot/../.local/artemis-runs/$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            # shortcut: Flash has no independent Checker; review traces before accepting E2E results.
            & $uvPath run --no-sync artemis run $goal --standalone --profile flash `
                --explorer-flash-mode pro --locked-app com.example.prm393_lab03 `
                --device-serial $DeviceSerial --test-name evia-auth-smoke --traces-path $tracePath
        }
        if ($LASTEXITCODE -ne 0) { throw "Artemis exited with code $LASTEXITCODE." }
    } finally { Pop-Location }
} finally {
    foreach ($name in $savedEnv.Keys) {
        [Environment]::SetEnvironmentVariable($name, $savedEnv[$name], 'Process')
    }
}
