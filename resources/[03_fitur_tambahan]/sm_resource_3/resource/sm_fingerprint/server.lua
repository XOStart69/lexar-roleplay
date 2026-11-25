--[[
    sm_fingerprint :: server
    Item pemindai membuka scan di client. Hasil scan = identitas target.
]]

local ITEM = 'fingerprint_scanner'   -- SESUAIKAN dengan nama item di ox_inventory
local ALLOWED_JOBS = {               -- kosongkan tabel ini kalau semua orang boleh pakai
    police = true, sheriff = true, sapd = true, bcso = true, sasp = true, fbi = true,
}
local MAX_DISTANCE = 6.0

local function notify(src, message, kind)
    TriggerClientEvent('ox_lib:notify', src, { description = message, type = kind or 'error' })
end

local function jobAllowed(player)
    if next(ALLOWED_JOBS) == nil then return true end
    return ALLOWED_JOBS[player.PlayerData.job.name] == true
end

qb_ecore:CreateUseableItem(ITEM, function(src)
    local player = qb_ecore:GetPlayer(src)
    if not player then return end
    if not jobAllowed(player) then return notify(src, 'Kamu tidak tahu cara memakai alat ini.') end

    TriggerClientEvent('sm_fingerprint:client:scan', src)
end)

lib.callback.register('sm_fingerprint:server:scan', function(src, targetId)
    local player = qb_ecore:GetPlayer(src)
    targetId = tonumber(targetId)
    if not player or not targetId or targetId == src then return nil end
    if not jobAllowed(player) then return nil end
    if (exports.ox_inventory:GetItemCount(src, ITEM) or 0) < 1 then return nil end

    local target = qb_ecore:GetPlayer(targetId)
    if not target then return nil end

    local a, b = GetPlayerPed(src), GetPlayerPed(targetId)
    if a == 0 or b == 0 or #(GetEntityCoords(a) - GetEntityCoords(b)) > MAX_DISTANCE then return nil end

    local data = target.PlayerData
    local info = data.charinfo or {}
    local meta = data.metadata or {}

    return {
        source = targetId,
        citizenid = data.citizenid,
        charinfo = {
            firstname = info.firstname or '-',
            lastname = info.lastname or '-',
            birthdate = info.birthdate,
            gender = info.gender,
            nationality = info.nationality,
            phone = info.phone,
        },
        metadata = {
            fingerprint = meta.fingerprint or 'TIDAK ADA',
            bloodtype = meta.bloodtype,
        },
    }
end)
