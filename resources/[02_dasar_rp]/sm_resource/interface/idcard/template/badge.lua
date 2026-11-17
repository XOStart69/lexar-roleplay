local baseConfig = {
    image = '',
    stamp = true,
    stamp_path = 'cap.png',
    signature = true,
    userProfile = true,
    isbadge = true,
}

local function getConfig(t)
    return tbl.map(baseConfig, function (value, key)
        if t[key] then
            value = t[key]
        end
        return value
    end)
end

local template = {}

template.lspdbadge = {
    config = getConfig({
        image = 'lspd.png',
    }),
    fields = {}
}

template.bcsobadge = {
    config = getConfig({
        image = 'bcso.png',
    }),
    fields = {}
}

template.dojbadge = {
    config = getConfig({
        image = 'doj.png',
    }),
    fields = {}
}

template.saspbadge = {
    config = getConfig({
        image = 'sasp.png',
    }),
    fields = {}
}

template.usmbadge = {
    config = getConfig({
        image = 'usm.png',
    }),
    fields = {}
}

return template