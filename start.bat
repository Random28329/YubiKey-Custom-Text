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
Write-Host 'Press Enter to WRITE a new entry (a random secret name is generated),'
$name = Read-Host 'or type an existing name to READ it back'
$name = $name.Trim().ToLower() -replace '\.localhost$', ''

if (-not $name) {
    # 16 random characters from a cryptographic random generator
    $chars = 'abcdefghijkmnpqrstuvwxyz23456789'.ToCharArray()
    $bytes = New-Object byte[] 16
    [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    $name = -join ($bytes | ForEach-Object { $chars[$_ % $chars.Length] })
}

if ($name -notmatch '^[a-z0-9-]{1,63}$') {
    Write-Host 'Name may only contain letters, digits and dashes.'
    Read-Host 'Press Enter to close'
    exit
}

$url = "http://$name.localhost:8000/"

# Tiny web server: listens ONLY on this PC (127.0.0.1), always returns the one HTML file
$listener = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback, 8000)
$listener.Start()

Write-Host ''
Write-Host "Secret name:  $name"
Write-Host "Page:         $url"
Write-Host ''
Write-Host 'Close this window when done.'
Start-Process $url

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
