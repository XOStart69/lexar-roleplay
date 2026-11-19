return {
    -- Masa berlaku item (hari) sejak pertama kali di-use (di-bind ke pemilik).
    ExpireDays = 30,

    -- Nama item di ox_inventory.
    Item = 'outfitbag',

    BagProp = `prop_cs_heist_bag_02`,

    InteractDistance = 2.5,

    DropAnimTime = 1200,

    SpawnRadius = 40.0,

    -- Cooldown (menit) ganti baju berikutnya setelah berhasil pakai outfit. Client-side.
    ChangeCooldown = 15,

    ChangeOutfit = {
        dict = "clothingtie",
        anim = "try_tie_negative_a",
        duration = 3500,
        flag = 49,
    },

    BagAnim = {
        dict = "pickup_object",
        anim = "pickup_low",
        flag = 0,
    },

    Locale = {
        not_owner      = "Tas ini bukan milikmu.",
        expired        = "Tas outfit ini sudah kadaluarsa.",
        no_outfits     = "Kamu belum punya outfit tersimpan.",
        bag_placed     = "Tas outfit diletakkan.",
        bag_picked     = "Tas outfit diambil kembali.",
        already_placed = "Kamu sudah menaruh tas outfit.",
        in_vehicle     = "Tidak bisa memakai tas outfit di dalam kendaraan.",
        cooldown       = "Tunggu %s lagi untuk ganti baju.",
        outfit_changed = "Outfit berhasil dipakai.",
        open_label     = "Buka Tas Outfit",
        pickup_label   = "Ambil Tas",
    },
}
