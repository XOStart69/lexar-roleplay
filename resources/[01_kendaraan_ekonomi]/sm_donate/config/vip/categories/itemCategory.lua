local preCategory =  {
    label = "Voucher",
    pageValue = "item-menu",
    categoryType = "item",
    items = {
        {
            id = 1,
            label = "Voucher Rata Kanan",
            itemName = "voucher_ratnan",
            itemType = "item",
            itemCount = 1,
            price = 1600,
            filter = "Voucher",
            description = "Upgrade kendaraan kamu ke performa maksimal! Voucher ini akan mengupgrade Engine, Brakes, Transmission, Suspension, Armor, dan Turbo ke level tertinggi. Voucher hanya bisa digunakan 1 kali dan tidak bisa dijual kembali.",
            discount = {
                state = false,
                newPrice = 1500,
            },
            itemImg = "./itemImages/voucher_ratnan.png",
        },
        {
            id = 2,
            label = "Voucher Custom Plat",
            itemName = "voucher_plat",
            itemType = "item",
            itemCount = 1,
            price = 1600,
            filter = "Voucher",
            description = "Personalisasi plat nomor kendaraan kamu! Maksimal 8 karakter (A-Z, 0-9). Voucher hanya bisa digunakan 1 kali untuk 1 kendaraan dan tidak bisa dijual kembali.",
            discount = {
                state = false,
                newPrice = 1000,
            },
            itemImg = "./itemImages/voucher_plat.png",
        },
        {
            id = 3,
            label = "Voucher SatuMimpi Pass",
            itemName = "voucher_pass",
            itemType = "item",
            itemCount = 1,
            price = 6000,
            filter = "Voucher",
            description = "Aktifkan SatuMimpi Pass Premium! Dapatkan akses ke semua fitur premium, task eksklusif, dan reward spesial. Berlaku selama periode battlepass. Voucher hanya bisa digunakan 1 kali.",
            discount = {
                state = false,
                newPrice = 2000,
            },
            itemImg = "./itemImages/voucher_pass.png",
        },
        {
            id = 5,
            label = "Voucher VVIP",
            itemName = "voucher_vvip",
            itemType = "item",
            itemCount = 1,
            price = 6000,
            filter = "Voucher",
            description = "Upgrade akun kamu menjadi VVIP selama 30 hari! Dapatkan semua benefit VIP PLUS akses area ultra eksklusif, priority support, dan privilege maksimal. Voucher hanya bisa digunakan 1 kali dan tidak dapat di-stack.",
            discount = {
                state = false,
                newPrice = 7500,
            },
            itemImg = "./itemImages/voucher_vvip.png",
        },
    },
},

Citizen.Wait(10)

if Settings.Debug then
    Settings.DebugPrint("Item Category Preloaded", json.encode(preCategory))
end

table.insert(AK4Y.Categories, preCategory)
