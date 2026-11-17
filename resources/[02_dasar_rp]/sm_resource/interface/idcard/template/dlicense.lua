---@type IDCARD_CONFIG
local config = {
    image = 'sima_background.png',
    stamp = true,
    stamp_path = 'ttd_cap.png',
    signature = true,
    userProfile = true,
    textColor = 'black',
    description = {
        { text = 'SURAT IZIN MENGEMUDI KENDARAAN RODA EMPAT', size = 'sm', bold = true },
    },
    outline = '#090C57'
}

---@type IDCARD_FIELD[]
local fields = {
    {
        id = 'card_id',
        kind = 'data',
        label = 'No. SIM',
        input = {
            type = 'text',
            label = 'No. SIM',
            required = true,
        }
    },
    {
        id = 'spacer_1',
        kind = 'spacer',
    },
    {
        kind = 'data',
        id = 'name',
        label = 'Nama',
        input = {
            type = 'text',
            label = 'Nama Lengkap',
            disabled = true,
            editable = true,
            generateFromServer = 'name'
        }
    },
    {
        kind = 'data',
        id = 'tanggal_lahir',
        label = 'Tanggal Lahir',
        input = {
            type = 'text',
            label = 'Tanggal Lahir',
            disabled = true,
            editable = true,
            generateFromServer = 'dob',
        }
    },
    {
        kind = 'data',
        id = 'kewarganegaraan',
        label = 'Kewarganegaraan',
        input = {
            type = 'text',
            label = 'Kewarganegaraan',
            disabled = true,
            generateFromServer = 'citizenship',
        }
    },
    {
        kind = 'data',
        id = 'createdate',
        label = 'Dikeluarkan',
        input = {
            type = 'date',
            label = 'Dikeluarkan',
            default = true,
            disabled = true
        }
    },
    {
        kind = 'data',
        id = 'expired',
        label = 'Berlaku hingga',
        input = {
            type = 'date',
            label = 'Berlaku Hingga',
            default = true,
            required = true
        }
    },
    {
        kind = 'data',
        id = 'createdby',
        label = 'Diterbitkan Oleh',
        input = {
            type = 'text',
            label = 'Diterbitkan Oleh',
            disabled = true,
            generateFromServer = 'releasedBy'
        }
    }
}

local function getConfig(t)
    return tbl.map(config, function (value, key)
        if t[key] then
            value = t[key]
        end
        return value
    end)
end

local template = {}


template.driver_license = {
    config = getConfig({
        image = 'driver_license.png',
        description = {
            { text = 'DRIVER LICENSE', size = 'md', bold = false }
        },
        outline = '#1ea8e3'
    }),
    fields = {
        {
            id = 'card_id',
            kind = 'data',
            label = 'ID',
            input = {
                type = 'text',
                label = 'ID',
                required = true,
            }
        },
        {
            id = 'spacer_1',
            kind = 'spacer',
        },
        {
            kind = 'data',
            id = 'name',
            label = 'Name',
            input = {
                type = 'text',
                label = 'Name',
                disabled = true,
                generateFromServer = 'name'
            }
        },
        {
            kind = 'data',
            id = 'tanggal_lahir',
            label = 'DOB',
            input = {
                type = 'text',
                label = 'DOB',
                disabled = true,
                generateFromServer = 'dob',
            }
        },
        {
            kind = 'data',
            id = 'createdby',
            label = 'Issued',
            input = {
                type = 'text',
                label = 'Issued',
                disabled = true,
                generateFromServer = 'releasedBy'
            }
        },
        {
            kind = 'data',
            id = 'expired',
            label = 'Expires',
            input = {
                type = 'date',
                label = 'Expires',
                default = true,
                required = true
            }
        },
    }
}

-- template.driver_license_a = {
--     config = config,
--     fields = fields
-- }

-- template.driver_license_c = {
--     config = getConfig({
--         image = 'simc_background.png',
--         description = {
--             { text = 'SURAT IZIN MENGEMUDI KENDARAAN RODA DUA', size = 'sm', bold = true },
--         },
--         outline = '#090C57'
--     }),
--     fields = fields
-- }

template.helicopter_license = {
    config = getConfig({
        image = 'heli_background.png',
        description = {
            { text = 'HELICOPTER PILOT LICENSE', size = 'md', bold = true }
        },
        outline = '#17D602'
    }),
    fields = fields
}

return template
