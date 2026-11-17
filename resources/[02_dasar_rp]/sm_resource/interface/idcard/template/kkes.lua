
---@type IDCARD_CONFIG
local config = {
    image = 'kartukes_background.png',
    stamp = true,
    stamp_path = 'ttd_cap.png',
    signature = true,
    userProfile = true,
    textColor = 'black',
    description = {
        { text = 'DINAS KESEHATAN', size = 'sm', bold = true },
    },
    outline = '#23DBE8'
}

---@type IDCARD_FIELD[]
local fields = {
    {
        id = 'card_id',
        kind = 'data',
        label = 'Card No',
        input = {
            type = 'text',
            label = 'Card No',
        }
    },
    {
        id = 'name',
        kind = 'data',
        label = 'Nama',
        input = {
            type = 'text',
            label = 'Nama',
            disabled = true,
            editable = true,
            generateFromServer = 'name',
        }
    },
    {
        id = 'ttl',
        kind = 'data',
        label = 'Tanggal Lahir',
        input = {
            type = 'text',
            label = 'Tempat / Tanggal Lahir',
            disabled = true,
            editable = true,
            generateFromServer = 'dob',
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
            editable = true,
            generateFromServer = 'bloodType',
        }
    },
    {
        id = 'citizenship',
        kind = 'data',
        label = 'Kewarganegaraan',
        input = {
            type = 'text',
            label = 'Kewarganegaraan',
            disabled = true,
            generateFromServer = 'citizenship',
        }
    },
    {
        id = 'createdate',
        kind = 'data',
        label = 'Dibuat',
        input = {
            type = 'date',
            label = 'Dibuat',
            default = true,
            editable = true,
            disabled = true
        }
    },
    {
        id = 'expired',
        kind = 'data',
        label = 'Expired',
        input = {
            type = 'date',
            label = 'Expired Date',
            default = true,
            editable = true,
            required = true
        }
    },
    {
        id = 'medic_notes',
        kind = 'data',
        label = 'Medic Note',
        input = {
            type = 'text',
            label = 'Medic Note',
        },
    },
    {
        id = 'createdby',
        kind = 'data',
        label = 'Dibuat oleh',
        input = {
            type = 'text',
            label = 'Dibuat oleh',
            disabled = true,
            generateFromServer = 'releasedBy'
        }
    }
}

return {
    kartu_kesehatan = {
        config = config,
        fields = fields
    }
}