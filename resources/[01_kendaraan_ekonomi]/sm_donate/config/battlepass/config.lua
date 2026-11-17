BattlePass = {}

BattlePass.RequiredXpForNextLevel = 1000
BattlePass.BPEndDate = { day = 1, month = 12, year = 2026 }
BattlePass.DailyTasksResetPeriod = 1
BattlePass.DefaultGarage = 'Garasi Kota'

BattlePass.Language = {
    openSpamProtectNotif = 'Anda tidak dapat membuka menu saat ini, mohon tunggu sebentar.',
    title1 = 'SatuMimpi',
    title2 = 'BATTLE PASS',
    collectedText = 'DIKUMPULKAN',
    dailyText = 'STANDARD',
    remainingText = 'Sisa',
    dayText = 'Hari',
    accountTypeText = 'Jenis Akun :',
    premiumBuyButtonText = 'LOCKED',
    redeemInfoText = 'Anda dapat mengaktifkannya dengan memasukkan kode premium Anda.',
    premiumCodeTitle = 'MASUKKAN KODE PREMIUM',
    acceptButtonText = 'TERIMA',
    premiumTasksText = 'PREMIUM TASK',
    upgradeAccountCongratTitle = 'SELAMAT!',
    upgradeAccountText = 'Akun Anda telah ditingkatkan ke PREMIUM',
    piece = 'pcs',
    moneySymbol = '$',
}

BattlePass.BattlePassTasks = {
    { taskId = 1, requiredcount = 10, rewardXP = 300, taskTitle = 'Tebang Kayu', taskDescription = 'Tebang 10 pohon untuk mendapatkan kayu mentah' },
    { taskId = 2, requiredcount = 10, rewardXP = 300, taskTitle = 'Proses Packing Kayu', taskDescription = 'Proses kayu terakhir' },
    { taskId = 3, requiredcount = 10, rewardXP = 300, taskTitle = 'Tanam Biji Cabai', taskDescription = 'Tanam 10 biji cabai di ladang pertanian' },
    { taskId = 4, requiredcount = 10, rewardXP = 300, taskTitle = 'Panen Cabai', taskDescription = 'Panen 10 cabai yang sudah matang dari ladang' },
    { taskId = 5, requiredcount = 10, rewardXP = 300, taskTitle = 'Tanam Biji Jagung', taskDescription = 'Tanam 10 biji jagung di area pertanian' },
    { taskId = 6, requiredcount = 10, rewardXP = 300, taskTitle = 'Panen Jagung', taskDescription = 'Panen 10 jagung yang sudah siap panen' },
    { taskId = 7, requiredcount = 10, rewardXP = 300, taskTitle = 'Dapatkan Hunting animal', taskDescription = 'Berburu dan dapatkan 10 daging hunting animal' },
    { taskId = 8, requiredcount = 10, rewardXP = 300, taskTitle = 'Dapatkan Hunting Skin', taskDescription = 'Kumpulkan 10 kulit hewan hasil berburu' },
}

BattlePass.DailyPremiumTasks = {
    { taskId = 1, requiredcount = 20, rewardXP = 700, taskTitle = 'Peras Susu', taskDescription = 'Peras susu dari sapi sebanyak 20 kali' },
    { taskId = 2, requiredcount = 20, rewardXP = 700, taskTitle = 'Proses Susu', taskDescription = 'Proses susu mentah menjadi susu siap jual' },
    { taskId = 3, requiredcount = 20, rewardXP = 700, taskTitle = 'Tanam Biji Tomat', taskDescription = 'Tanam 20 biji tomat di kebun premium' },
    { taskId = 4, requiredcount = 20, rewardXP = 700, taskTitle = 'Panen Tomat', taskDescription = 'Panen 20 tomat matang dari kebun' },
    { taskId = 5, requiredcount = 20, rewardXP = 700, taskTitle = 'Lebur Batu Bersih', taskDescription = 'Lebur 20 batu hasil tambang menjadi mineral' },
    { taskId = 6, requiredcount = 20, rewardXP = 700, taskTitle = 'Proses Recycle', taskDescription = 'Daur ulang 20 material untuk mendapat sumber daya' },
}

BattlePass.BattlePassItems = {
    { taskId = 1, requiredLevel = 1, rewards = {
        standart = { itemLabel = 'Recycle Package', itemName = 'recycle_package', type = 'item', count = 15, unique = false, image = 'nui://ox_inventory/web/images/recycle_package.png' },
        premium  = { itemLabel = 'Chicky Shooting', itemName = 'jpx_chicky_shooting', type = 'item', count = 1, unique = false, image = 'nui://ox_inventory/web/images/jpx_chicky_shooting.png' },
    } },
    { taskId = 2, requiredLevel = 2, rewards = {
        standart = { itemLabel = 'Homemade Milk', itemName = 'homemademilk', type = 'item', count = 10, unique = false, image = 'nui://ox_inventory/web/images/homemademilk.png' },
        premium  = { itemLabel = 'Premium Money', itemName = 'cash', type = 'money', count = 30000, unique = false, image = 'nui://ox_inventory/web/images/money.png' },
    } },
    { taskId = 3, requiredLevel = 3, rewards = {
        standart = { itemLabel = 'Biji Cabai', itemName = 'chili_seed', type = 'item', count = 25, unique = false, image = 'nui://ox_inventory/web/images/chili_seed.png' },
        premium  = { itemLabel = 'Premium Money', itemName = 'cash', type = 'money', count = 30000, unique = false, image = 'nui://ox_inventory/web/images/money.png' },
    } },
    { taskId = 4, requiredLevel = 4, rewards = {
        standart = { itemLabel = 'Premium Money', itemName = 'cash', type = 'money', count = 10000, unique = false, image = 'nui://ox_inventory/web/images/money.png' },
        premium  = { itemLabel = 'Premium Money', itemName = 'cash', type = 'money', count = 25000, unique = false, image = 'nui://ox_inventory/web/images/money.png' },
    } },
    { taskId = 5, requiredLevel = 5, rewards = {
        standart = { itemLabel = 'Cleaning Kit', itemName = 'cleaningkit', type = 'item', count = 3, unique = false, image = 'nui://ox_inventory/web/images/cleaningkit.png' },
        premium  = { itemLabel = 'Kerangka Tas', itemName = 'kerangka_tas', type = 'item', count = 7, unique = false, image = 'nui://ox_inventory/web/images/kerangka_tas.png' },
    } },
    { taskId = 6, requiredLevel = 6, rewards = {
        standart = { itemLabel = 'Bandage', itemName = 'bandage', type = 'item', count = 3, unique = false, image = 'nui://ox_inventory/web/images/bandage.png' },
        premium  = { itemLabel = 'Aksesoris Tas', itemName = 'aksesoris_tas', type = 'item', count = 7, unique = false, image = 'nui://ox_inventory/web/images/aksesoris_tas.png' },
    } },
    { taskId = 7, requiredLevel = 7, rewards = {
        standart = { itemLabel = 'Weapon Bottle', itemName = 'weapon_bottle', type = 'item', count = 1, unique = false, image = 'nui://ox_inventory/web/images/weapon_bottle.png' },
        premium  = { itemLabel = 'Kendaraan SMR25', itemName = 'smr25', type = 'vehicle', count = 1, unique = false, image = 'bpImages/smr25.png' },
    } },
    { taskId = 8, requiredLevel = 8, rewards = {
        standart = { itemLabel = 'Lockpick', itemName = 'lockpick', type = 'item', count = 4, unique = false, image = 'nui://ox_inventory/web/images/lockpick.png' },
        premium  = { itemLabel = 'Backpack', itemName = 'backpack', type = 'item', count = 1, unique = false, image = 'nui://ox_inventory/web/images/backpack.png' },
    } },
    { taskId = 9, requiredLevel = 9, rewards = {
        standart = { itemLabel = 'Premium Money', itemName = 'cash', type = 'money', count = 15000, unique = false, image = 'nui://ox_inventory/web/images/money.png' },
        premium  = { itemLabel = 'Chicky Flying', itemName = 'jpx_chicky_flying', type = 'item', count = 1, unique = false, image = 'nui://ox_inventory/web/images/jpx_chicky_flying.png' },
    } },
    { taskId = 10, requiredLevel = 10, rewards = {
        standart = { itemLabel = 'Paracetamol', itemName = 'paracetamol', type = 'item', count = 2, unique = false, image = 'nui://ox_inventory/web/images/paracetamol.png' },
        premium  = { itemLabel = 'Premium Money', itemName = 'cash', type = 'money', count = 15000, unique = false, image = 'nui://ox_inventory/web/images/money.png' },
    } },
    { taskId = 11, requiredLevel = 11, rewards = {
        standart = { itemLabel = 'Weapon Knuckle', itemName = 'weapon_knuckle', type = 'item', count = 1, unique = false, image = 'nui://ox_inventory/web/images/weapon_knuckle.png' },
        premium  = { itemLabel = 'Chicky Running', itemName = 'jpx_chicky_running', type = 'item', count = 1, unique = false, image = 'nui://ox_inventory/web/images/jpx_chicky_running.png' },
    } },
    { taskId = 12, requiredLevel = 12, rewards = {
        standart = { itemLabel = 'Hunting Skin', itemName = 'hunting_skin', type = 'item', count = 10, unique = false, image = 'nui://ox_inventory/web/images/hunting_skin.png' },
        premium  = { itemLabel = 'Voucher Rata Kanan', itemName = 'voucher_ratnan', type = 'item', count = 1, unique = false, image = 'nui://ox_inventory/web/images/voucher_ratnan.png' },
    } },
    { taskId = 13, requiredLevel = 13, rewards = {
        standart = { itemLabel = 'Paket Makanan', itemName = 'paketmakanan', type = 'item', count = 1, unique = false, image = 'nui://ox_inventory/web/images/paket_freshseafood.png' },
        premium  = { itemLabel = 'Skateboard', itemName = 'board_default', type = 'item', count = 1, unique = false, image = 'bpImages/board_default.png' },
    } },
    { taskId = 14, requiredLevel = 14, rewards = {
        standart = { itemLabel = 'Weapon Switchblade', itemName = 'weapon_switchblade', type = 'item', count = 1, unique = false, image = 'nui://ox_inventory/web/images/weapon_switchblade.png' },
        premium  = { itemLabel = 'Kendaraan SMGE6', itemName = 'smge6', type = 'vehicle', count = 1, unique = false, image = 'bpImages/smge6.png' },
    } },
}
