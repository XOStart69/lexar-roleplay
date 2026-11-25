--[[
    sm_restaurant :: server
    Per job restoran: stash baki (tray), toko bahan (`<job>-goods`, khusus karyawan),
    dan toko pembeli otomatis (`<job>-shop`) yang dipakai saat status toko "Tutup".
]]

local config = localmodule 'config'

local KVP = 'sm_restaurant:auto:'
local autoShop = {}

local function unique(items)
    local seen, out = {}, {}
    for i = 1, #(items or {}) do
        local item = items[i]
        if not seen[item.name] then
            seen[item.name] = true
            out[#out + 1] = { name = item.name, price = item.price }
        end
    end
    return out
end

CreateThread(function()
    for jobName, job in pairs(config.jobs) do
        autoShop[jobName] = GetResourceKvpInt(KVP .. jobName) == 1

        if job.tray and job.tray.id then
            exports.ox_inventory:RegisterStash(job.tray.id, job.label .. ' Tray', 30, 100000, false)
        end

        exports.ox_inventory:RegisterShop(jobName .. '-goods', {
            name = job.label .. ' - Bahan',
            groups = { [jobName] = job.minGrade or 0 },
            inventory = unique(job.marketItems),
        })

        exports.ox_inventory:RegisterShop(jobName .. '-shop', {
            name = job.label,
            inventory = unique(job.shopItems),
        })
    end
end)

lib.callback.register('sm_restaurant:isAutoShop', function(_, jobName)
    return autoShop[tostring(jobName)] == true
end)

lib.callback.register('sm_restaurant:setAutoShop', function(src, jobName, closed)
    jobName = tostring(jobName)
    local job = config.jobs[jobName]
    local player = qb_ecore:GetPlayer(src)
    if not job or not player then return false end
    if player.PlayerData.job.name ~= jobName then return false end

    autoShop[jobName] = closed == true
    SetResourceKvpInt(KVP .. jobName, closed == true and 1 or 0)

    return true
end)
