-- Daftar item yang bisa membuka browser. Tambah baris di sini kalau ada item lain.
local targets = {
    pol_mdt = { url = 'https://polmdt.gate-smrp.site', title = 'MDT Police', anim = true },
}

local function open(source, entry)
    if not entry then return false end

    TriggerClientEvent('sm_nui_browser:open', source, entry.url, entry.title, entry.anim)

    return true
end

local function use(source, itemName)
    return open(source, targets[itemName])
end

exports('use', use)

exports('register', function(itemName, url, title, anim)
    if type(itemName) ~= 'string' or type(url) ~= 'string' then return end

    targets[itemName] = { url = url, title = title, anim = anim }
end)

return targets
