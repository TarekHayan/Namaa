param([string]$Output = 'test/fixtures/prayer/calculation/aladhan_reference.json')
$ErrorActionPreference = 'Stop'
$cities = @(
  @{ name='Cairo'; latitude=30.0444; longitude=31.2357; zone='Africa/Cairo' },
  @{ name='Dubai'; latitude=25.2048; longitude=55.2708; zone='Asia/Dubai' },
  @{ name='New York'; latitude=40.7128; longitude=-74.0060; zone='America/New_York' }
)
$methods = @(
  @{ key='egyptian'; id=5 }, @{ key='muslimWorldLeague'; id=3 },
  @{ key='ummAlQura'; id=4 }, @{ key='dubai'; id=16 },
  @{ key='northAmerica'; id=2 }, @{ key='kuwait'; id=9 },
  @{ key='qatar'; id=10 }
)
$dates = @('20-03-2026','21-06-2026','21-12-2026','08-03-2026')
$rows = [System.Collections.Generic.List[object]]::new()
foreach ($city in $cities) {
  foreach ($method in $methods) {
    foreach ($date in $dates) {
      $uri = 'https://api.aladhan.com/v1/timings/{0}?latitude={1}&longitude={2}&method={3}&school=0&timezonestring={4}' -f $date,$city.latitude,$city.longitude,$method.id,[uri]::EscapeDataString($city.zone)
      $response = Invoke-RestMethod -Uri $uri -TimeoutSec 30
      if ($response.code -ne 200 -or $response.data.meta.method.id -ne $method.id -or $response.data.meta.timezone -ne $city.zone) { throw "Unexpected reference response: $uri" }
      $rows.Add(@{ city=$city.name; latitude=$city.latitude; longitude=$city.longitude; zone=$city.zone; method=$method.key; methodId=$method.id; date=$date; source=$uri; capturedUtc=[DateTime]::UtcNow.ToString('o'); timings=$response.data.timings; metadata=$response.data.meta })
    }
  }
}
$destination = Join-Path (Get-Location) $Output
$parent = Split-Path $destination -Parent
New-Item -ItemType Directory -Path $parent -Force | Out-Null
$rows | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $destination -Encoding utf8
Write-Output "Captured $($rows.Count) reference rows in $destination"
