---@type IDCARD_CONFIG
local config = {
    image = 'ktp_background.png',
    stamp = true,
    stamp_path = 'ttd_cap.png',
    signature = true,
    userProfile = true,
    textColor = 'black',
    description = {
        { text = 'KTP ini disahkan oleh:', size = 'sm', bold = false },
        { text = 'KEPALA DINAS KEPENDUDUKAN', size = 'md', bold = true },
    },
    outline = '#4DFFCD'
}

---@type IDCARD_FIELD[]
local fields = {
    {
        id = 'card_id',
        kind = 'data',
        label = 'NIK',
        input = {
            type = 'text',
            label = 'NIK',
            disabled = true,
            generateFromServer = 'citizenid',
        }
    },
    {
        id = 'spacer_1',
        kind = 'spacer',
    },
    {
        id = 'name',
        kind = 'data',
        label = 'Nama Lengkap',
        input = {
            type = 'text',
            label = 'Nama Lengkap',
            disabled = true,
            editable = true,
            generateFromServer = 'name',
        }
    },
    {
        id = 'ttl',
        kind = 'data',
        label = 'Tempat / Tgl Lahir',
        input = {
            type = 'text',
            label = 'Tempat / Tanggal Lahir',
            disabled = true,
            editable = true,
            generateFromServer = 'dob',
        }
    },
    {
        id = 'gender',
        kind = 'data',
        label = 'Jenis Kelamin',
        input = {
            type = 'text',
            label = 'Jenis Kelamin',
            disabled = true,
            generateFromServer = 'gender',
        }
    },
    {
        id = 'bloodType',
        kind = 'data',
        label = 'Golongan Darah',
        input = {
            type = 'text',
            label = 'Golongan Darah',
            disabled = true,
            generateFromServer = 'bloodType',
        }
    },
    {
        id = 'expired',
        kind = 'data',
        label = 'Berlaku Hingga',
        input = {
            type = 'date',
            label = 'Berlaku Hingga',
            default = true,
            required = true,
        }
    },
}

return {
    ktp = {
        config = config,
        fields = fields
    }
}