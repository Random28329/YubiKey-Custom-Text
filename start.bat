<# : batch part (PowerShell sees this whole block as a comment)
@echo off
set "DIR=%~dp0"
set "SELF=%~f0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "iex (Get-Content -LiteralPath $env:SELF -Raw)"
exit /b
#>

# ---------- PowerShell part ----------
$f = Join-Path $env:DIR 'yubikey-text-store.html'
if (!(Test-Path -LiteralPath $f)) {
    Write-Host 'yubikey-text-store.html not found next to start.bat'
    Read-Host 'Press Enter to close'
    exit
}

Write-Host ''
Write-Host 'Custom URL name (becomes  <name>.localhost  in Yubico Authenticator)'
Write-Host '  - Press Enter for a random one, or'
Write-Host '  - type your own (new or existing): letters, digits, dashes;'
Write-Host '    use dots for more parts, e.g. part1.part2 - each part max 63, total max 243'
$name = Read-Host 'Name'
$name = $name.Trim().ToLower() -replace '\.localhost$', ''

$isRandom = -not $name
if (-not $name) {
    # 16 random characters from a cryptographic random generator
    $chars = 'abcdefghijkmnpqrstuvwxyz23456789'.ToCharArray()
    $bytes = New-Object byte[] 16
    [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    $name = -join ($bytes | ForEach-Object { $chars[$_ % $chars.Length] })
}

$label = '[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?'
if ($name -notmatch "^$label(\.$label)*$" -or ("$name.localhost").Length -gt 253) {
    Write-Host 'Invalid name. Rules:'
    Write-Host '  - parts separated by dots, e.g.  part1.part2.part3'
    Write-Host '  - each part: letters, digits, dashes, 1-63 long, no dash at start/end'
    Write-Host '  - whole thing incl. .localhost: max 253 (so max 243 typed)'
    Read-Host 'Press Enter to close'
    exit
}

$url = "http://$name.localhost:8000/"
if ($isRandom) { $openUrl = $url + '#random' } else { $openUrl = $url }

# Tiny web server: listens ONLY on this PC (127.0.0.1), always returns the one HTML file
try {
    $listener = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback, 8000)
    $listener.Start()
} catch {
    Write-Host 'Port 8000 is busy - is another start.bat window still open? Close it and try again.'
    Read-Host 'Press Enter to close'
    exit
}

Write-Host ''
Write-Host "URL name:  $name.localhost"
Write-Host "Page:      $url"
Write-Host ''
Write-Host 'Close this window when done.'
Start-Process $openUrl

while ($true) {
    $client = $listener.AcceptTcpClient()
    try {
        $stream = $client.GetStream()
        $reader = New-Object IO.StreamReader($stream)
        while (($line = $reader.ReadLine()) -ne $null -and $line -ne '') { }   # read and ignore the request
        $body = [IO.File]::ReadAllBytes($f)
        $head = [Text.Encoding]::ASCII.GetBytes(
            "HTTP/1.1 200 OK`r`nContent-Type: text/html; charset=utf-8`r`nContent-Length: $($body.Length)`r`nCache-Control: no-store`r`nConnection: close`r`n`r`n")
        $stream.Write($head, 0, $head.Length)
        $stream.Write($body, 0, $body.Length)
        $stream.Flush()
    } catch { } finally { $client.Close() }
}
