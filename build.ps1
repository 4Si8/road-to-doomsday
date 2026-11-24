# Builds the static Stremio/Nuvio addon from data/watchorder.json into ./addon
# Usage:  powershell -ExecutionPolicy Bypass -File build.ps1
$ErrorActionPreference = 'Stop'
$root    = $PSScriptRoot
$outDir  = Join-Path $root 'addon'
$utf8    = New-Object System.Text.UTF8Encoding($false)   # no BOM: some JSON parsers reject it

$items = [IO.File]::ReadAllText((Join-Path $root 'data/watchorder.json'), $utf8) | ConvertFrom-Json

$dot = [char]0x00B7
$tierLabel = @{ essential = 'Essential'; recommended = 'Recommended'; optional = 'Optional' }

# One catalog per filter. Each item keeps its own type (movie/series), as the Stremio protocol allows.
# The catalog `type` is a custom one-word label rather than movie/series, because Nuvio shows rows
# as "<name> - <type label>" and these rows mix movies and series. Keep it a single URL-safe word:
# Nuvio TV puts it in the request path unencoded. Nuvio rows render as "Road to Doomsday - Speedrun".
$catalogs = @(
    @{ id = 'doomsday-full';      type = 'Complete';   name = 'Road to Doomsday'; filter = { param($i) $true } },
    @{ id = 'doomsday-essential'; type = 'Essentials'; name = 'Road to Doomsday'; filter = { param($i) $i.tier -eq 'essential' } },
    @{ id = 'doomsday-speedrun';  type = 'Speedrun';   name = 'Road to Doomsday'; filter = { param($i) $i.speedrun } }
)

function Write-Json($path, $obj) {
    $dir = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
    [IO.File]::WriteAllText($path, ($obj | ConvertTo-Json -Depth 10 -Compress), $utf8)
}

if (Test-Path $outDir) { Remove-Item -Recurse -Force $outDir -Confirm:$false }

foreach ($c in $catalogs) {
    $selected = @($items | Where-Object { & $c.filter $_ })
    $n = 0
    $metas = foreach ($i in $selected) {
        $n++
        $tier = $tierLabel[$i.tier]
        $desc = "#$n of $($selected.Count) $dot $tier"
        if ($i.runtime) { $desc += " $dot $($i.runtime)" }
        $desc += "`n`n$($i.note)"
        [ordered]@{
            id          = $i.id
            type        = $i.type
            name        = "$n. $($i.name)"
            releaseInfo = "$($i.year) $dot $tier"
            poster      = "https://images.metahub.space/poster/medium/$($i.id)/img"
            posterShape = 'poster'
            background  = "https://images.metahub.space/background/medium/$($i.id)/img"
            logo        = "https://images.metahub.space/logo/medium/$($i.id)/img"
            description = $desc
        }
    }
    Write-Json (Join-Path $outDir "catalog/$($c.type)/$($c.id).json") @{ metas = @($metas) }
    Write-Host ("{0,-20} {1,3} items" -f $c.id, $selected.Count)
}

$manifest = [ordered]@{
    id          = 'community.road-to-doomsday'
    version     = '1.2.0'
    name        = 'Road to Doomsday'
    description = 'Every movie and series to watch before Avengers: Doomsday (Dec 18, 2026), in order. Combines Marvel''s official Disney+ list, Rotten Tomatoes, marvelwatchlist.com, 9to5Marvel and Murphy''s Multiverse.'
    logo        = 'https://images.metahub.space/logo/medium/tt21357150/img'
    background  = 'https://images.metahub.space/background/medium/tt21357150/img'
    resources   = @('catalog')
    types       = @(@('movie', 'series') + @($catalogs | ForEach-Object { $_.type }))
    idPrefixes  = @('tt')
    catalogs    = @($catalogs | ForEach-Object { [ordered]@{ type = $_.type; id = $_.id; name = $_.name } })
    behaviorHints = @{ configurable = $false; configurationRequired = $false }
}
Write-Json (Join-Path $outDir 'manifest.json') $manifest
Write-Host "Built -> $outDir"
