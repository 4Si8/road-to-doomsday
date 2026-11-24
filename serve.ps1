# Serves ./addon locally with CORS so Nuvio (on this PC) can install it.
# Usage:  powershell -ExecutionPolicy Bypass -File serve.ps1 [-Port 7000]
# Then add this addon URL in Nuvio:  http://127.0.0.1:7000/manifest.json
param([int]$Port = 7000)
$ErrorActionPreference = 'Stop'
$addonDir = Join-Path $PSScriptRoot 'addon'
if (-not (Test-Path (Join-Path $addonDir 'manifest.json'))) { throw "Run build.ps1 first." }

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://127.0.0.1:$Port/")
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Start()
Write-Host "Road to Doomsday addon: http://127.0.0.1:$Port/manifest.json  (Ctrl+C to stop)"

try {
    while ($listener.IsListening) {
        $ctx = $listener.GetContext()
        $res = $ctx.Response
        $res.Headers.Add('Access-Control-Allow-Origin', '*')
        $res.Headers.Add('Access-Control-Allow-Headers', '*')
        $rel  = [Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath.TrimStart('/'))
        if ($rel -eq '') { $rel = 'manifest.json' }
        $path = [IO.Path]::GetFullPath((Join-Path $addonDir $rel))
        if ($path.StartsWith($addonDir) -and (Test-Path $path -PathType Leaf)) {
            $bytes = [IO.File]::ReadAllBytes($path)
            $res.ContentType = 'application/json; charset=utf-8'
            $res.StatusCode = 200
            $res.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $res.StatusCode = 404
        }
        Write-Host ("{0} {1} {2}" -f $ctx.Request.HttpMethod, $ctx.Request.Url.AbsolutePath, $res.StatusCode)
        $res.Close()
    }
} finally {
    $listener.Stop()
}
