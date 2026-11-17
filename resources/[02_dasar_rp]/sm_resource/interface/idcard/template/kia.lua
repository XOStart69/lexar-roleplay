---@type IDCARD_CONFIG
local config = {
    image = 'kia_background.png',
    stamp = true,
    stamp_path = 'ttd_cap.png',
    signature = true,
    userProfile = true,
    textColor = 'black',
    description = {
        { text = 'KIA ini disahkan oleh:', size = 'sm', bold = false },
        { text = 'KEPALA DINAS KEPENDUDUKAN', size = 'md', bold = true },
    },
    outline = '#F76DAB'
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
        id = 'profileImage',
        kind = 'profileURL',
        label = 'Foto',
        input = {
            type = 'text',
            label = 'URL Foto Profil',
            required = true,
        }
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
    kia = {
        config = config,
        fields = fields
    }
}