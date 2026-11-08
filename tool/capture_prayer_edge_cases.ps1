param([string]$Output = 'test/fixtures/prayer/calculation/aladhan_edge_cases.json')

$ErrorActionPreference = 'Stop'
$cases = @(
  @{
    name = 'zero_coordinates'
    url = 'https://api.aladhan.com/v1/timings/20-03-2026?latitude=0&longitude=0&method=5&school=0&timezonestring=Africa%2FAccra&iso8601=true'
  },
  @{
    name = 'tromso_polar_day'
    url = 'https://api.aladhan.com/v1/timings/21-06-2026?latitude=69.6492&longitude=18.9553&method=5&school=0&timezonestring=Europe%2FOslo&iso8601=true'
  },
  @{
    name = 'stockholm_summer_twilight'
    url = 'https://api.aladhan.com/v1/timings/21-06-2026?latitude=59.3293&longitude=18.0686&method=5&school=0&timezonestring=Europe%2FStockholm&iso8601=true'
  }
)

$rows = foreach ($case in $cases) {
  $response = Invoke-WebRequest -Uri $case.url -SkipHttpErrorCheck -TimeoutSec 30
  @{
    name = $case.name
    source = $case.url
    capturedUtc = [DateTime]::UtcNow.ToString('o')
    httpStatus = [int]$response.StatusCode
    response = $response.Content | ConvertFrom-Json -AsHashtable
  }
}

$destination = Join-Path (Get-Location) $Output
$rows | ConvertTo-Json -Depth 15 | Set-Content -LiteralPath $destination -Encoding utf8
Write-Output "Captured $($rows.Count) independent edge-case responses in $destination"
