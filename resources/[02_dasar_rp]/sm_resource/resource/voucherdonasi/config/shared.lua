return {
    items = {
        voucher_ratnan = {
            label = 'Voucher Rata Kanan',
            type = 'performance',
            progressDuration = 5000,
            progressLabel = 'Upgrading Vehicle...'
        },
        voucher_plat = {
            label = 'Voucher Custom Plat',
            type = 'plate',
            progressDuration = 3000,
            progressLabel = 'Installing Custom Plate...'
        },
        voucher_pass = {
            label = 'Voucher SatuMimpi Pass',
            type = 'battlepass'
        },
        -- voucher_vip = {
        --     label = 'Voucher VIP',
        --     type = 'vip',
        --     duration = 30
        -- },
        voucher_vvip = {
            label = 'Voucher VVIP',
            type = 'vip',
            duration = 30
        },
        fakeplate = {
            label = 'Fake Plate',
            type = 'fakeplate',
            progressDuration = 4000,
            progressLabel = 'Installing Fake Plate...'
        },
        originalplate = {
            label = 'Plat Asli',
            type = 'originalplate',
            progressDuration = 4000,
            progressLabel = 'Restoring Original Plate...'
        }
    },
    plate = {
        minLength = 1,
        maxLength = 8,
        pattern = '^[A-Z0-9]+$'
    },
    fakeplate = {
        randomLength = 6,
        chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    },
    webhook = 'YOUR_DISCORD_WEBHOOK_URL_HERE',
    messages = {
        notInVehicle = 'Anda harus berada di dalam kendaraan!',
        notDriver = 'Anda harus menjadi pengemudi!',
        notOwned = 'Ini bukan kendaraan Anda!',
        mustExitVehicle = 'Anda harus keluar dari kendaraan terlebih dahulu!',
        noVehicleFound = 'Tidak ada kendaraan di sekitar Anda!',
        plateExists = 'Nomor plat ini sudah digunakan!',
        invalidPlate = 'Format plat tidak valid! Gunakan 1-8 karakter (A-Z, 0-9)',
        alreadyHasPass = 'Anda sudah memiliki SatuMimpi Pass aktif!',
        alreadyHasVIP = 'Anda sudah memiliki status VIP/VVIP aktif!',
        databaseError = 'Terjadi kesalahan pada database!',
        vehicleUpgraded = 'Kendaraan berhasil ditingkatkan ke performa maksimum!',
        plateInstalled = 'Plat nomor kustom berhasil dipasang!',
        passActivated = 'SatuMimpi Pass berhasil diaktifkan!',
        vipActivated = 'Status VIP berhasil diaktifkan!',
        vvipActivated = 'Status VVIP berhasil diaktifkan!',
        fakeplateInstalled = 'Fake plate berhasil dipasang!',
        fakeplateRestored = 'Plat asli berhasil dipulihkan!',
        alreadyFakeplated = 'Kendaraan ini sudah menggunakan fake plate!',
        notFakeplateItem = 'Item ini bukan plat asli kendaraan Anda!'
    }
}