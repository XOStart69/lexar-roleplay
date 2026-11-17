# Jalankan dari folder: A:\PENTEST\Serverku\Output\Lexar Roleplay
# Hasil ada di Desktop\kirim_ke_claude. Isinya hanya teks/kode kecil, bukan asset.

$root = (Get-Location).Path
$out  = Join-Path $env:USERPROFILE 'Desktop\kirim_ke_claude'
New-Item -ItemType Directory -Force -Path $out | Out-Null
$codeExt = '.lua','.json','.sql','.cfg'

# --- 1. pemakaian API core oleh resource lain (ringkas: nama + jumlah) ---
$rx = @'
QBCore\.(Functions|Player|Commands)\.\w+|exports\.(sm_core|qb-core):\w+|exports\[['"](sm_core|qb-core)['"]\]:\w+|QBCore:(Server|Client|Player):\w+
'@
$rx = $rx.Trim()
Get-ChildItem -Directory | Where-Object { $_.Name -match '^(sm_|rhd_|ox_inventory|lb-phone|Renewed)' } |
  ForEach-Object { Get-ChildItem $_.FullName -Recurse -File -Filter *.lua -ErrorAction SilentlyContinue } |
  Select-String -Pattern $rx -AllMatches |
  ForEach-Object { $_.Matches.Value } | Group-Object | Sort-Object Count -Descending |
  ForEach-Object { '{0,6}  {1}' -f $_.Count, $_.Name } |
  Out-File (Join-Path $out 'core_api_usage.txt') -Encoding utf8

# --- 2. ringkasan tiap resource sm_* (ada server dir? escrow?) ---
Get-ChildItem -Directory -Filter 'sm_*' | ForEach-Object {
  $lua = @(Get-ChildItem $_.FullName -Recurse -File -Filter *.lua -ErrorAction SilentlyContinue)
  '{0,-26} fxmanifest={1,-5} escrow={2,-5} server_dir={3,-5} lua_files={4}' -f $_.Name,
    (Test-Path (Join-Path $_.FullName 'fxmanifest.lua')),
    (Test-Path (Join-Path $_.FullName '.fxap')),
    (Test-Path (Join-Path $_.FullName 'server')), $lua.Count
} | Out-File (Join-Path $out 'sm_ringkasan.txt') -Encoding utf8

# --- 3. semua fxmanifest (dependensi + daftar script) jadi satu file ---
Get-ChildItem -Directory | ForEach-Object {
  $f = Join-Path $_.FullName 'fxmanifest.lua'
  if (-not (Test-Path $f)) { $f = Join-Path $_.FullName '__resource.lua' }
  if (Test-Path $f) { "===== $($_.Name) ====="; Get-Content $f -Raw; '' }
} | Out-File (Join-Path $out 'fxmanifests_all.txt') -Encoding utf8

# --- 4. zip kode prioritas (tanpa asset, webhook discord disamarkan) ---
function Pack-Code($names, $zipName) {
  $tmp = Join-Path $env:TEMP ('pack_' + [guid]::NewGuid().ToString('N'))
  foreach ($n in $names) {
    $src = Join-Path $root $n
    if (-not (Test-Path $src)) { Write-Host "skip (tidak ada): $n"; continue }
    Get-ChildItem $src -Recurse -File | Where-Object {
      $codeExt -contains $_.Extension.ToLower() -and $_.FullName -notmatch '\\(stream|node_modules|build)\\'
    } | ForEach-Object {
      $rel  = $_.FullName.Substring($root.Length).TrimStart('\')
      $dest = Join-Path $tmp $rel
      New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null
      $text = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
      if ($text) {
        $text = $text -replace 'https://(?:ptb\.|canary\.)?discord(?:app)?\.com/api/webhooks/[^\s''"]+', 'WEBHOOK_REDACTED'
        Set-Content -Path $dest -Value $text -NoNewline -Encoding utf8
      } else { Copy-Item $_.FullName $dest }
    }
  }
  $zip = Join-Path $out $zipName
  if (Test-Path $zip) { Remove-Item $zip }
  Compress-Archive -Path (Join-Path $tmp '*') -DestinationPath $zip
  Remove-Item $tmp -Recurse -Force
  '{0}: {1:N1} MB' -f $zipName, ((Get-Item $zip).Length / 1MB)
}

Pack-Code @('se_v2','ox_inventory') 'kode_infra.zip'
Pack-Code @('sm_character','sm_appearance','sm_resource','sm_resource_1','sm_resource_2','sm_resource_3') 'kode_sm_prioritas.zip'

Write-Host "`nSelesai. Kirim isi folder: $out"
