---@type IDCARD_CONFIG
local config = {
    image = 'casino_gold_member.png',
    stamp = false,
    stamp_path = 'ttd_cap.png',
    signature = false,
    userProfile = true,
    textColor = 'black',
    description = {},
    outline = '#f9b604'
}

---@type IDCARD_FIELD[]
local fields = {
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
        id = 'card_type',
        kind = 'data',
        label = 'Tipe Kartu',
        input = {
            type = 'text',
            label = 'Tipe Kartu',
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

local card = {}

local function getConfig(t)
    return tbl.map(config, function (value, key)
        if t[key] then
            value = t[key]
        end
        return value
    end)
end

card.casino_gold_member = {
    config = config,
    fields = fields
}

card.casino_platinum_member = {
    config = getConfig({
        image = 'casino_platinum_member.png',
        outline = '#e5e4e2'
    }),
    fields = fields
}

return card