param(
    [string]$Source,
    [string]$Dest
)

if (-not $Source) { $Source = $PSScriptRoot }
if (-not $Dest) {
    $leaf = (Split-Path $Source -Leaf) -replace '[\[\]]',''
    $Dest = Join-Path (Split-Path $Source -Parent) "_zips_$leaf"
}

if (-not (Test-Path -LiteralPath $Source)) { Write-Host "Path tidak ada: $Source"; exit 1 }

Add-Type -AssemblyName System.IO.Compression.FileSystem
New-Item -ItemType Directory -Force -Path $Dest | Out-Null

$folders = @(Get-ChildItem -LiteralPath $Source -Directory | Where-Object { $_.FullName -ne $Dest })
if ($folders.Count -eq 0) { Write-Host "Tidak ada folder di $Source"; return }

Write-Host "Sumber : $Source"
Write-Host "Tujuan : $Dest`n"

$i = 0
foreach ($f in $folders) {
    $i++
    $zip = Join-Path $Dest ($f.Name + ".zip")
    Write-Host "[$i/$($folders.Count)] $($f.Name)"
    if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip -Force }
    [System.IO.Compression.ZipFile]::CreateFromDirectory(
        $f.FullName,
        $zip,
        [System.IO.Compression.CompressionLevel]::Optimal,
        $true
    )
}

Write-Host "`nSelesai: $i zip di $Dest" -ForegroundColor Green