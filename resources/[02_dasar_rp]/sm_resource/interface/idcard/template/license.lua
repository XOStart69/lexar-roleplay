---@type IDCARD_CONFIG
local config = {
    image = 'hunting_background.png',
    stamp = true,
    stamp_path = 'ttd_cap.png',
    signature = true,
    userProfile = true,
    textColor = 'black',
    description = {
        { text = 'AUTHORIZED TO HUNT WILDLIFE', size = 'md', bold = true }
    },
    outline = '#D60202'
}

---@type IDCARD_FIELD[]
local fields = {
    {
        id = 'card_id',
        kind = 'data',
        label = 'License No',
        input = {
            type = 'text',
            label = 'License No',
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
            generateFromServer = 'dob',
        }
    },
    {
        kind = 'data',
        id = 'kewarganegaraan',
        label = 'kewarganegaraan',
        input = {
            type = 'text',
            label = 'kewarganegaraan',
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

template.huntinglicense = {
    config = config,
    fields = fields
}

template.weaponlicense = {
    config = getConfig({
        image = 'weapon_background.png',
        description = {
            { text = 'AUTHORIZED TO CARRY FIREARMS', size = 'md', bold = false }
        },
    }),
    fields = fields
}

return template