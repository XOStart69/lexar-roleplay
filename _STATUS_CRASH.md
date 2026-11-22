# STATUS CRASH LEXAR - 2026-11-21

## TERBUKTI
- [OK] 5d_vu.ybn = penyebab 'Invalid fixup'. Sudah di-rename -> 5d_vu.ybn.off. JANGAN direstore.
- [OK] amb-roxwood 15 resource = nonaktif (backup: resources.cfg.roxwood.bak)
- [OK] Tidak ada salinan 5d_vu.ybn lain di disk. Tidak ada arsip sumber. Wajib rebuild di CodeWalker.
- [OK] fiv3devs_vu = hasil dekripsi escrow. Semua .ydr +178 byte vs asli. Sumber: A:\PENTEST\FiveVault\Output\Satu_Mimpi

## MASIH JALAN
- [OK] Pool via JSON di [Game] CitizenFX.ini -> PtFxAssetStore:8000, VehicleStruct:2048, TxdStore:60000, fwDynamicArchetypeComponent:40000, AnimStore:30000. Wajib launch _launch_pool.bat. Backup ini: CitizenFX.ini.bak.*
- [ ] modsoundveh2: ecoboostv6_game.dat & ecoboostv6_sounds.dat hilang. Sumber ada di A:\PENTEST\FiveVault\Output\Satu_Mimpi\modsoundveh2
- [ ] 175 duplicate archetype (jpx_ninja x76, Extra x87, vek_mansion, bzzz_camp, amb_rox_props, electric_charger)
- [ ] *.ybn masuk .gitignore -> collision nggak pernah ke-backup
