# rapihin.ps1 - inventaris + pengelompokan resource ke folder [kategori]
# Jalankan dari folder resources.
#   Cek saja (aman, tidak memindah apa pun):  .\rapihin.ps1
#   Pindahkan beneran:                         .\rapihin.ps1 -Apply
# Hasil cek: Desktop\inventaris_resource.csv
# FiveM tetap menemukan resource di dalam folder [kategori], jadi baris 'ensure' tidak perlu diubah.
param([switch]$Apply)
$root = (Get-Location).Path
$groups = [ordered]@{
  '[00_core]' = @('mapmanager','spawnmanager','sessionmanager','baseevents','PolyZone','oxmysql','ox_lib','se_v2','sm_core','ox_inventory','ox_target','ox_doorlock','queue','pma-voice','sm_appearance','sm_character','sm_playergroup','sm_admin','sm_loadingscreen','sm_chatheme','sm_nui_browser','sm_radialmenu','sm_resource_assets','sm_resource_assets_2')
  '[01_kendaraan_ekonomi]' = @('rhd_interact','rhd_garage_sm','sm_vehicleshop','sm_custom','vehiclehandler','modkendaraansmrp','modsoundveh2','Renewed-Banking','sm_donate','sm_gudang','sm_consumable','sm_barbershop','sm_clothing_a','sm_clothing_b','sm_clothing_c','sm_clothing_d','sm_clothing_e','sm_clothing_f','sm_clothing_g','sm_clothing_h','sm_clothing_i','sm_clothing_j','sm_clothing_k','sm_clothing_l','sm_clothing_m','sm_clothing_n','sm_clothing_o','sm_clothingwl','sm_clothingwl2','sm_clothingwl3','sm_skinpack2025','sm_mod-peds','sm_mod_tatto')
  '[02_dasar_rp]' = @('sm_resource','sm_diagnosis','sm_hospital','sm_pdtablet','sm_dutylog','lb-phone','lb-phoneprop','Renewed-Weathersync','xsound','interact-sound','mm_radio','netprops','map_postals','sm_emotes','sm_media_notify','sm_megaphones','sm_interior')
  '[03_fitur_tambahan]' = @('sm_resource_1','sm_resource_2','sm_resource_3','sm_mp_worker','sm_racingtablet','sm_gamesapp','sm_seatcreator','sm_sentinel','rhd_casino','pokerasztal','casino_assets','uj_casino','uj_casino_ipl','satu_media')
  '[04_senjata_escrow]' = @('sm_weapon1','sm_weapon2','sm_weapon3','sm_weapon4','sm_weapon5','sm_weapon6','sm_weapon7','sm_weapon8','SM_SENJATA','sm_bus_mod','sm_tekno_mod','jpx_cakecaaa_weapon','jpx_cakecaaa_fashion','xtxvxtx_csgo_mele_weapons','xtxvxtx_dragon_katanas','xtxvxtx_katana_2','xtxvxtx_plasma_swords')
  '[05_map_mlo]' = @('sm_ymap','sm_cayo','sm_mod_maps','sm_wiwang_motel_v2','bob74_ipl','tstudio_cayo_bridge','25senorahp_ext_rsm','25senorahp_int_rsm','BUAHAHAY','Covington_mechanic','Marlowe_Drive','Surgee06','amb-roxwood','amb-roxwood-enviro','amb-roxwood-interiors','amb-roxwood-interiors2','amb-roxwood-map','amb-roxwood-map-unlocked','amb-roxwood-map2','amb-roxwood-map3','amb-roxwood-map4','amb-roxwood-mapdata','amb-roxwood-patches','amb-roxwood-placeholder','amb-roxwood-props','amb-roxwood-traffic','amb-roxwood-ycd-anims','cfx-gabz-catcafe','cfx-kreak-digtech','cfx-kreak-harmony','cfx-nteam-driveincinema','cfx_chuz_sandy_shores_boat_house','chy_kedai_satumimpi','energy_odriscollranch','fiv3devs_vu','fortZancudo','hane_sandy_sheriff','komplek','lodstudios_vanilla_unicorn_paleto_bay','pf_vinewoodmotorsv3','rfc_courthouse_mlo','rfc_los_santos_customs','tiutoxico_creche','wiwang_hotel_ne_jk_v02_Reception','wiwang_hotel_ne_jk_v02_Rooms','wwm_wolfy')
  '[06_rumah_mansion]' = @('CHUY_Mansion_Rome_new','KawaiiSpace_BathroomFurniturePack','KawaiiSpace_BedroomFurniturePack','KawaiiSpace_FitnessPack','KawaiiSpace_FurniturePack','KawaiiSpace_MediumFurniturePack','KawaiiSpace_PartyEssentials','bcs_housing','brofx_mansion_06','brofx_mansion_12','brofx_mansion_17','brofx_mansion_20','brofx_villa_05','chy_mansion_Horizon_tolkanan','crestview_Mansion','deverux_mansion','housing_pack','housing_pack_V2','mansion','max_shellspack','maximum_housingprops','molo_home','nino_mansion','penguinanim','starmansion')
}
$rows = @()
foreach ($g in $groups.Keys) {
  foreach ($n in $groups[$g]) {
    $p = Join-Path $root $n
    if (-not (Test-Path -LiteralPath $p)) { $rows += [pscustomobject]@{Grup=$g;Resource=$n;Status='TIDAK ADA';GB='';Lua='';ServerLua='';Manifest='';Escrow=''}; continue }
    $files = @(Get-ChildItem -LiteralPath $p -Recurse -File -ErrorAction SilentlyContinue)
    $lua = @($files | Where-Object { $_.Extension -eq '.lua' })
    $srv = @($lua | Where-Object { $_.FullName -match '\\server\\' -or $_.Name -match '^server' })
    $rows += [pscustomobject]@{
      Grup=$g; Resource=$n; Status='ok'
      GB=[math]::Round((($files | Measure-Object Length -Sum).Sum)/1GB,2)
      Lua=$lua.Count; ServerLua=$srv.Count
      Manifest=((Test-Path -LiteralPath (Join-Path $p 'fxmanifest.lua')) -or (Test-Path -LiteralPath (Join-Path $p '__resource.lua')))
      Escrow=(Test-Path -LiteralPath (Join-Path $p '.fxap'))
    }
  }
}
$known = $groups.Values | ForEach-Object { $_ }
Get-ChildItem -LiteralPath $root -Directory | Where-Object { $_.Name -notmatch '^\[' -and $known -notcontains $_.Name } | ForEach-Object {
  $rows += [pscustomobject]@{Grup='(belum dikelompokkan)';Resource=$_.Name;Status='ok';GB='';Lua='';ServerLua='';Manifest='';Escrow=''}
}
$csv = Join-Path $env:USERPROFILE 'Desktop\inventaris_resource.csv'
$rows | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8
$rows | Where-Object { $_.Status -eq 'ok' -and $_.Lua -ne '' } | Group-Object Grup | ForEach-Object {
  '{0,-24} resource={1,3}  GB={2,7:N2}  lua={3,5}  server_lua={4,4}' -f $_.Name, $_.Count, ($_.Group | Measure-Object GB -Sum).Sum, ($_.Group | Measure-Object Lua -Sum).Sum, ($_.Group | Measure-Object ServerLua -Sum).Sum
}
Write-Host ("Tidak ada di disk: " + (@($rows | Where-Object Status -eq 'TIDAK ADA').Count))
Write-Host "CSV: $csv"
if ($Apply) {
  foreach ($g in $groups.Keys) {
    $dest = Join-Path $root $g
    New-Item -ItemType Directory -Force -Path $dest | Out-Null
    foreach ($n in $groups[$g]) {
      $src = Join-Path $root $n
      if (Test-Path -LiteralPath $src) { Move-Item -LiteralPath $src -Destination $dest }
    }
  }
  Write-Host 'Selesai dipindah. Baris ensure di server.cfg tidak perlu diubah.'
} else {
  Write-Host 'Mode cek saja. Tambahkan -Apply untuk memindahkan.'
}