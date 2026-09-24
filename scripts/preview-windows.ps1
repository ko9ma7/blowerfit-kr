param([int]$Port = 5173)
$ErrorActionPreference = 'Stop'
$Root = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\web'))
$listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Loopback, $Port)
$listener.Start()
$url = "http://127.0.0.1:$Port/"
Write-Host "[OK] Serving $Root"
Write-Host "[OK] Open $url"
Start-Process $url

$mime = @{
  '.html'='text/html; charset=utf-8'; '.js'='text/javascript; charset=utf-8'; '.css'='text/css; charset=utf-8';
  '.json'='application/json; charset=utf-8'; '.svg'='image/svg+xml'; '.png'='image/png'; '.ico'='image/x-icon';
  '.webmanifest'='application/manifest+json; charset=utf-8'; '.txt'='text/plain; charset=utf-8'; '.xml'='application/xml; charset=utf-8'
}

try {
  while ($true) {
    $client = $listener.AcceptTcpClient()
    try {
      $stream = $client.GetStream()
      $reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::ASCII, $false, 4096, $true)
      $requestLine = $reader.ReadLine()
      if ([string]::IsNullOrWhiteSpace($requestLine)) { $client.Close(); continue }
      while (($line = $reader.ReadLine()) -ne $null -and $line -ne '') { }
      $parts = $requestLine.Split(' ')
      $rawPath = if ($parts.Length -ge 2) { $parts[1] } else { '/' }
      $pathOnly = $rawPath.Split('?')[0]
      $decoded = [System.Uri]::UnescapeDataString($pathOnly).TrimStart('/')
      if ([string]::IsNullOrWhiteSpace($decoded)) { $decoded = 'index.html' }
      $candidate = [System.IO.Path]::GetFullPath((Join-Path $Root $decoded.Replace('/', [System.IO.Path]::DirectorySeparatorChar)))
      if (-not $candidate.StartsWith($Root, [System.StringComparison]::OrdinalIgnoreCase)) { throw 'Invalid path' }
      if (Test-Path $candidate -PathType Container) { $candidate = Join-Path $candidate 'index.html' }
      if (-not (Test-Path $candidate -PathType Leaf)) {
        $candidate = Join-Path $Root '404.html'
        $status = '404 Not Found'
      } else { $status = '200 OK' }
      $bytes = [System.IO.File]::ReadAllBytes($candidate)
      $ext = [System.IO.Path]::GetExtension($candidate).ToLowerInvariant()
      $contentType = if ($mime.ContainsKey($ext)) { $mime[$ext] } else { 'application/octet-stream' }
      $header = "HTTP/1.1 $status`r`nContent-Type: $contentType`r`nContent-Length: $($bytes.Length)`r`nCache-Control: no-cache`r`nConnection: close`r`n`r`n"
      $headerBytes = [System.Text.Encoding]::ASCII.GetBytes($header)
      $stream.Write($headerBytes, 0, $headerBytes.Length)
      $stream.Write($bytes, 0, $bytes.Length)
      $stream.Flush()
    } catch {
      try {
        $body = [System.Text.Encoding]::UTF8.GetBytes('Server error')
        $head = [System.Text.Encoding]::ASCII.GetBytes("HTTP/1.1 500 Internal Server Error`r`nContent-Length: $($body.Length)`r`nConnection: close`r`n`r`n")
        $client.GetStream().Write($head,0,$head.Length)
        $client.GetStream().Write($body,0,$body.Length)
      } catch { }
    } finally {
      $client.Close()
    }
  }
} finally {
  $listener.Stop()
}
