param(
  [string]$DeviceId = "emulator-5554",
  [string]$Flutter = "C:\Users\pfawa\flutter\bin\flutter.bat"
)

$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$EnvPath = Join-Path $ProjectRoot ".env"

if (-not (Test-Path -LiteralPath $EnvPath)) {
  throw "Missing .env in $ProjectRoot"
}

$Config = @{}
Get-Content -LiteralPath $EnvPath | ForEach-Object {
  $Line = $_.Trim()
  if ($Line.Length -eq 0 -or $Line.StartsWith("#") -or -not $Line.Contains("=")) {
    return
  }
  $Parts = $Line.Split("=", 2)
  $Config[$Parts[0].Trim()] = $Parts[1].Trim()
}

function Read-ConfigValue {
  param(
    [string]$Key,
    [string]$Fallback = ""
  )
  if ($Config.ContainsKey($Key) -and -not [string]::IsNullOrWhiteSpace($Config[$Key])) {
    return $Config[$Key]
  }
  return $Fallback
}

$ApiKey = Read-ConfigValue "AI_API_KEY"
if ([string]::IsNullOrWhiteSpace($ApiKey)) {
  throw "AI_API_KEY is empty in .env"
}

$FlutterArgs = @(
  "run",
  "-d", $DeviceId,
  "--dart-define=USE_MOCK_AI=$(Read-ConfigValue "USE_MOCK_AI" "false")",
  "--dart-define=AI_PROVIDER=$(Read-ConfigValue "AI_PROVIDER" "openai")",
  "--dart-define=AI_MODEL=$(Read-ConfigValue "AI_MODEL" "gpt-4.1-mini")",
  "--dart-define=AI_API_KEY=$ApiKey"
)

& $Flutter @FlutterArgs
