--[[
    sm_bomb :: server
    Otoritas penuh: entity, kuota, umur bom, sesi defuse, eksekusi.
    Klien hanya kirim niat (timer, pin, posisi) - semuanya divalidasi ulang di sini.
]]

local config = localmodule 'config'

local BOMBS = config.bombs or {}
local DETONATOR = config.detonator or {}
local DEFUSE = config.defuse or {}

local MAX_PER_PLAYER = config.maxPerPlayer or 3
local MAX_GLOBAL = config.maxGlobal or 30
local TRIGGER_LIFETIME = config.triggerLifetime or 7200
local EXECUTOR_RANGE = config.executorRange or 300.0
local DETONATOR_RANGE = DETONATOR.range or 150.0
local DEFUSE_KIT = config.defuseKit or 'defuse_kit'
local DETONATOR_ITEM = DETONATOR.item or 'detonator'
local PIN_LENGTH = config.pinLength or 4
local PLACE_DISTANCE = (config.placeDistance or 4.0) + 2.0
local TIMER_MIN = (config.timer and config.timer.min) or 10
local TIMER_MAX = (config.timer and config.timer.max) or 3600

local ATTEMPTS = DEFUSE.attempts or 3
local FAIL_PENALTY = DEFUSE.failPenalty or 5
local IDLE_TIMEOUT = DEFUSE.idleTimeout or 180
local CODE_LENGTH = DEFUSE.codeLength or 4
local CODE_COLORS = DEFUSE.colors or 6

local bombs = {}
local byOwner = {}
local sessions = {}
local counter = 0

local function now()
    return GetCloudTimeAsInt()
end

local function bombCoords(bomb)
    if bomb.entity and DoesEntityExist(bomb.entity) then
        return GetEntityCoords(bomb.entity)
    end
    return bomb.coords
end

local function publish()
    local list = {}
    for id, bomb in pairs(bombs) do
        list[#list + 1] = { id = id, net = bomb.net, kind = bomb.kind, ends = bomb.ends }
    end
    GlobalState.smBombs = list
end

local function removeBomb(id, reason)
    local bomb = bombs[id]
    if not bomb then return end

    bombs[id] = nil

    if bomb.owner then
        byOwner[bomb.owner] = math.max((byOwner[bomb.owner] or 1) - 1, 0)
    end

    if bomb.entity and DoesEntityExist(bomb.entity) then
        DeleteEntity(bomb.entity)
    end

    for src, session in pairs(sessions) do
        if session.id == id then
            sessions[src] = nil
            TriggerClientEvent('sm_bomb:client:closeDefuse', src, reason or 'removed')
        end
    end

    publish()
end

local function explode(id)
    local bomb = bombs[id]
    if not bomb or bomb.done then return end
    bomb.done = true

    local coords = bombCoords(bomb)

    TriggerClientEvent('sm_bomb:client:explode', -1, {
        coords = coords,
        net = bomb.net,
        kind = bomb.kind,
        owner = bomb.ownerSrc,
    })
    TriggerClientEvent('sm_bomb:client:fx', -1, coords, bomb.scale or 1.0)

    removeBomb(id, 'exploded')
end

local function startLifecycle(id)
    CreateThread(function()
        while bombs[id] and not bombs[id].done do
            local bomb = bombs[id]
            if bomb.ends then
                if now() >= bomb.ends then
                    explode(id)
                    return
                end
                Wait(500)
            else
                if now() >= (bomb.expires or 0) then
                    removeBomb(id, 'removed')
                    return
                end
                Wait(1000)
            end
        end
    end)
end

local function kindOfItem(item)
    if item == DETONATOR_ITEM then return '__detonator' end
    for kind, cfg in pairs(BOMBS) do
        if (cfg.item or kind) == item then return kind end
    end
end

AddEventHandler('ox_inventory:usedItem', function(src, item, slot)
    local kind = kindOfItem(item)
    if not kind then return end
    if kind == '__detonator' then
        TriggerClientEvent('sm_bomb:client:detonator', src, slot)
        return
    end
    TriggerClientEvent('sm_bomb:client:place', src, slot, kind)
end)

lib.callback.register('sm_bomb:place', function(src, slot, kind, payload)
    local player = qb_ecore:GetPlayer(src)
    if not player then return false, 'Data pemain tidak siap.' end
    if cache and cache.vehicle then return false, 'Tidak bisa dari dalam kendaraan.' end

    local cfg = BOMBS[kind]
    if not cfg or type(payload) ~= 'table' then return false, 'Data bom tidak valid.' end

    local cid = player.PlayerData.citizenid
    if (byOwner[cid] or 0) >= MAX_PER_PLAYER then
        return false, ('Maksimal %d bom per orang.'):format(MAX_PER_PLAYER)
    end

    local total = 0
    for _ in pairs(bombs) do total = total + 1 end
    if total >= MAX_GLOBAL then return false, 'Batas bom server tercapai.' end

    local item = cfg.item or kind
    if (ox_inventory:GetItemCount(src, item) or 0) < 1 then return false, 'Bom tidak ada di tas.' end

    local ped = GetPlayerPed(src)
    local pcoords = GetEntityCoords(ped)
    local coords, vehNet, vehEnt

    if cfg.vehicle then
        vehNet = tonumber(payload.vehicle)
        if not vehNet then return false, 'Kendaraan tidak valid.' end
        vehEnt = NetworkGetEntityFromNetworkId(vehNet)
        if vehEnt == 0 or not DoesEntityExist(vehEnt) then return false, 'Kendaraan sudah hilang.' end
        coords = GetEntityCoords(vehEnt)
        if #(pcoords - coords) > 20.0 then return false, 'Kendaraan terlalu jauh.' end
    else
        local c = payload.coords
        if type(c) ~= 'table' then return false, 'Posisi bom kosong.' end
        coords = vector3(tonumber(c.x) or 0.0, tonumber(c.y) or 0.0, tonumber(c.z) or 0.0)
        if #(pcoords - coords) > PLACE_DISTANCE then return false, 'Terlalu jauh dari titik pasang.' end
    end

    local timer = 0
    if cfg.timer then
        timer = math.floor(tonumber(payload.timer) or 0)
        timer = math.min(math.max(timer, TIMER_MIN), TIMER_MAX)
    end

    local pin = tostring(payload.pin or '')
    if #pin ~= PIN_LENGTH or not pin:match('^%d+$') then return false, 'PIN tidak valid.' end

    local rot = payload.rot or {}
    local entity = CreateObject(GetHashKey(cfg.model), coords.x, coords.y, coords.z, true, true)
    if entity == 0 then return false, 'Gagal membuat bom.' end

    local net = NetworkGetNetworkIdFromEntity(entity)
    if net == 0 then
        DeleteEntity(entity)
        return false, 'Gagal sinkronisasi bom.'
    end

    SetEntityRotation(entity, tonumber(rot.x) or 0.0, tonumber(rot.y) or 0.0, tonumber(rot.z) or 0.0, 2, true)
    FreezeEntityPosition(entity, true)

    counter = counter + 1
    local id = tostring(counter)

    bombs[id] = {
        id = id,
        net = net,
        entity = entity,
        kind = kind,
        coords = coords,
        owner = cid,
        ownerSrc = src,
        pin = pin,
        scale = cfg.scale or 1.0,
        ends = cfg.timer and (now() + timer) or nil,
        expires = (not cfg.timer) and (now() + TRIGGER_LIFETIME) or nil,
    }

    byOwner[cid] = (byOwner[cid] or 0) + 1
    publish()
    startLifecycle(id)

    if vehEnt and payload.offset then
        TriggerClientEvent('sm_bomb:client:attach', -1, net, vehNet, payload.offset, rot)
    end

    ox_inventory:RemoveItem(src, item, 1, nil, slot)

    return true
end)

lib.callback.register('sm_bomb:detonate', function(src, slot)
    local player = qb_ecore:GetPlayer(src)
    if not player then return false, 'Data pemain tidak siap.' end

    if (ox_inventory:GetItemCount(src, DETONATOR_ITEM) or 0) < 1 then
        return false, 'Detonator tidak ada.'
    end

    local cid = player.PlayerData.citizenid
    local coords = GetEntityCoords(GetPlayerPed(src))
    local list = {}

    for id, bomb in pairs(bombs) do
        if bomb.owner == cid and not bomb.done then
            if #(coords - bombCoords(bomb)) <= DETONATOR_RANGE then
                list[#list + 1] = id
            end
        end
    end

    if #list == 0 then return false, 'Tidak ada bom dalam jangkauan.' end

    for i = 1, #list do explode(list[i]) end

    return true
end)

lib.callback.register('sm_bomb:open', function(src, id)
    local player = qb_ecore:GetPlayer(src)
    if not player then return false, 'Data pemain tidak siap.' end

    local bomb = bombs[id]
    if not bomb then return false, 'Bom sudah tidak ada.' end
    if sessions[src] then return false, 'Sesi lain masih berjalan.' end

    if (ox_inventory:GetItemCount(src, DEFUSE_KIT) or 0) < 1 then
        return false, 'Butuh defuse kit.'
    end

    if #(GetEntityCoords(GetPlayerPed(src)) - bombCoords(bomb)) > EXECUTOR_RANGE then
        return false, 'Kamu terlalu jauh dari bom.'
    end

    sessions[src] = {
        id = id,
        attempts = ATTEMPTS,
        touched = now(),
        code = nil,
        ready = false,
        decrypted = false,
    }

    return true, {
        length = CODE_LENGTH,
        colors = CODE_COLORS,
        attempts = ATTEMPTS,
        timer = bomb.ends,
        pinLength = PIN_LENGTH,
    }
end)

lib.callback.register('sm_bomb:close', function(src, id)
    local session = sessions[src]
    if session and session.id == id then
        sessions[src] = nil
    end
end)

lib.callback.register('sm_bomb:decryptStart', function(src, id)
    local session = sessions[src]
    if not session or session.id ~= id then return false, 'Sesi tidak ada.' end
    if not bombs[id] then return false, 'Bom sudah tidak ada.' end

    local stamp = now()
    if session.lockUntil and stamp < session.lockUntil then
        return false, 'Tunggu sebentar.', (session.lockUntil - stamp) * 1000
    end

    session.touched = stamp
    session.code = {}

    for i = 1, CODE_LENGTH do
        session.code[i] = math.random(1, CODE_COLORS)
    end

    session.ready = true
    session.decrypted = false

    return true, { length = CODE_LENGTH, colors = CODE_COLORS }
end)

lib.callback.register('sm_bomb:decryptSubmit', function(src, id, cells)
    local session = sessions[src]
    if not session or session.id ~= id then return false, 'Sesi tidak ada.' end
    if not session.ready or not session.code then return false, 'Mulai dekripsi dulu.' end
    if type(cells) ~= 'table' or #cells ~= CODE_LENGTH then return false, 'Jumlah sel salah.' end

    local bomb = bombs[id]
    if not bomb then return false, 'Bom sudah tidak ada.' end

    local guess = {}
    for i = 1, CODE_LENGTH do
        local v = math.floor(tonumber(cells[i]) or 0)
        if v < 1 or v > CODE_COLORS then return false, 'Warna tidak valid.' end
        guess[i] = v
    end

    local exact, near = 0, 0
    local usedCode, usedGuess = {}, {}

    for i = 1, CODE_LENGTH do
        if guess[i] == session.code[i] then
            exact = exact + 1
            usedCode[i] = true
            usedGuess[i] = true
        end
    end

    for i = 1, CODE_LENGTH do
        if not usedGuess[i] then
            for j = 1, CODE_LENGTH do
                if not usedCode[j] and guess[i] == session.code[j] then
                    near = near + 1
                    usedCode[j] = true
                    break
                end
            end
        end
    end

    session.touched = now()

    if exact == CODE_LENGTH then
        session.decrypted = true
        session.ready = false
        return true, { exact = exact, near = near }, { solved = true, attempts = session.attempts }
    end

    session.attempts = session.attempts - 1
    session.ready = false

    if session.attempts <= 0 then
        SetTimeout(400, function() explode(id) end)
        return true, { exact = exact, near = near }, { solved = false, attempts = 0, exploded = true }
    end

    return true, { exact = exact, near = near }, { solved = false, attempts = session.attempts }
end)

lib.callback.register('sm_bomb:pin', function(src, id, pin)
    local session = sessions[src]
    if not session or session.id ~= id then return false, 'Sesi tidak ada.' end

    local bomb = bombs[id]
    if not bomb then return false, 'Bom sudah tidak ada.' end
    if not session.decrypted then return false, 'Selesaikan dekripsi dulu.' end

    pin = tostring(pin or '')
    if #pin ~= PIN_LENGTH or not pin:match('^%d+$') then
        return false, ('PIN harus %d digit angka.'):format(PIN_LENGTH)
    end

    session.touched = now()

    if pin ~= bomb.pin then
        session.attempts = session.attempts - 1

        if bomb.ends then
            bomb.ends = math.max(bomb.ends - FAIL_PENALTY, now())
            publish()
        end

        if session.attempts <= 0 then
            SetTimeout(200, function() explode(id) end)
            return false, 'PIN salah. Bom meledak.', { attempts = 0 }
        end

        return false, ('PIN salah. Sisa %d percobaan.'):format(session.attempts), { attempts = session.attempts }
    end

    sessions[src] = nil
    removeBomb(id, 'defused')

    return true, nil, { attempts = session.attempts }
end)

CreateThread(function()
    while true do
        Wait(5000)
        local stamp = now()

        for src, session in pairs(sessions) do
            if stamp - session.touched > IDLE_TIMEOUT then
                sessions[src] = nil
                TriggerClientEvent('sm_bomb:client:closeDefuse', src, 'idle')
            end
        end
    end
end)

AddEventHandler('playerDropped', function()
    sessions[source] = nil
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for id in pairs(bombs) do
        local bomb = bombs[id]
        if bomb.entity and DoesEntityExist(bomb.entity) then
            DeleteEntity(bomb.entity)
        end
    end

    bombs = {}
    byOwner = {}
    sessions = {}
    GlobalState.smBombs = {}
end)

GlobalState.smBombs = GlobalState.smBombs or {}

print('^2[sm_bomb] server siap^7')