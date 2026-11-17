LEXAR ROLEPLAY - REBUILD v1
===========================

Isi paket
---------
sm_core/server/**      -> salin ke folder sm_core milik kamu (sejajar dengan fxmanifest.lua)
sql/01_sm_core.sql     -> impor ke database baru (tabel players + bans)
server.cfg             -> template, isi nilai GANTI_...
resources.cfg          -> daftar ensure otomatis dari 178 folder kamu
collect_for_claude.ps1 -> kumpulkan file kecil untuk dikirim balik (jalankan dari folder Lexar Roleplay)

Cara pasang
-----------
1. Siapkan MariaDB/MySQL, buat database 'lexar', impor sql/01_sm_core.sql, lalu ox_inventory/setup/install.sql.
2. Salin sm_core/server ke A:\...\Lexar Roleplay\sm_core\server
3. Taruh server.cfg + resources.cfg di folder server (satu level dengan folder resource-mu atau sesuaikan path).
4. Jalankan server, lihat console: error pertama biasanya menunjuk file/baris yang kurang.

Yang SUDAH pasti benar (dibaca dari sm_core.zip)
------------------------------------------------
- Semua nama fungsi/event/metadata yang dipanggil client + shared + config.lua
- Daftar command (locale/en.lua) dan event client qb_event_client:*
- Struktur job/gang, PlayerDefaults, UpdateInterval/FullSaveEvery

Yang ASUMSI (belum bisa diverifikasi tanpa resource lain)
---------------------------------------------------------
- Alur login karakter: core mengikuti qb-core (QBCore.Player.Login -> PlayerLoaded). Cara sm_character memanggilnya belum dilihat.
- Event/hook yang dipanggil sm_* ke core di luar yang ada di core_api_usage.txt (nanti dicek).
- Pemetaan AddItem/RemoveItem dll ke ox_inventory (method.lua), sinkron uang cash <-> item.
- Siklus simpan ringan menyimpan money + position + metadata (config bilang "metadata only"; money ikut supaya tidak hilang saat crash).
- 'QBCore:Server:SetMetaData' dari client dibatasi ke hunger/thirst/stress (qb-core asli mengizinkan apa saja dari client = celah).
- PayCheckSociety=true belum didukung.
- Kode sudah lolos cek sintaks Lua, tapi BELUM dijalankan di FXServer.

Catatan lisensi
---------------
Resource berbayar (yang punya file .fxap) hanya bisa jalan kalau di-download lewat akun Cfx.re yang sama dengan
sv_licenseKey server baru. Kalau license key beda akun, unduh ulang dari portal Cfx.re akun tersebut.
Folder 'monitor' tidak boleh dicopy ke resources (bawaan txAdmin).
