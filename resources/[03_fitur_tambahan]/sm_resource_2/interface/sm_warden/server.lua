--[[
    sm_warden :: server
    Pin otoritas: kartu kosong dipakai petugas untuk menerbitkan kartu atas nama warga,
    pemegang memakainya sebagai pin, dan semua orang di sekitar bisa melihatnya.
]]

local config = localmodule 'config'

local QBCore = exports['qb-core']:GetCoreObject()

local DEFAULT = config.placement
local MAX_OFFSET = config.maxOffset
local MIN_SCALE = config.minScale
local MAX_SCALE = config.maxScale
local MAX_NEARBY = config.maxNearby or 16
local SELECT_DISTANCE = config.selectDistance + 2.0
local SHOW_DISTANCE = config.showDistance + 1.0

local PIN_ITEMS = { [config.blankItem] = true }
local CARD_ITEMS = { [config.cardItem] = true, [config.sealCard] = true }

local worn = {}
local adjusting = {}

local function ply(src)
    return QBCore.Functions.GetPlayer(src)
end

local function fullName(player)
    local info = player.PlayerData.charinfo or {}
    return ('%s %s'):format(info.firstname or 'Warga', info.lastname or '')
end

local function notify(src, description, nType)
    lib.notify(src, { title = 'The Warden', description = description, type = nType or 'error' })
end

local function clamp(value, min, max)
    if value < min then return min end
    if value > max then return max end
    return value
end

local function wrap(value)
    while value > 180.0 do value = value - 360.0 end
    while value < -180.0 do value = value + 360.0 end
    return value
end

local function sanitize(source)
    local p = type(source) == 'table' and source or DEFAULT

    return {
        bone = DEFAULT.bone,
        x = clamp(tonumber(p.x) or DEFAULT.x, -MAX_OFFSET, MAX_OFFSET),
        y = clamp(tonumber(p.y) or DEFAULT.y, -MAX_OFFSET, MAX_OFFSET),
        z = clamp(tonumber(p.z) or DEFAULT.z, -MAX_OFFSET, MAX_OFFSET),
        rx = wrap(tonumber(p.rx) or DEFAULT.rx),
        ry = wrap(tonumber(p.ry) or DEFAULT.ry),
        rz = wrap(tonumber(p.rz) or DEFAULT.rz),
        scale = clamp(tonumber(p.scale) or DEFAULT.scale, MIN_SCALE, MAX_SCALE),
    }
end

local function slotItem(player, slot)
    local item = exports.ox_inventory:GetSlot(player.PlayerData.citizenid, tonumber(slot))
    if not item then return end
    return item
end

local function expired(item)
    local meta = item.metadata or {}
    return type(meta.expires) == 'number' and meta.expires < os.time()
end

local function nearbyList(src, coords)
    local players = QBCore.Functions.GetQBPlayers()
    local list = {}

    for sid, player in pairs(players) do
        if sid ~= src then
            local ped = GetPlayerPed(sid)
            if ped ~= 0 and DoesEntityExist(ped) then
                local target = GetEntityCoords(ped)
                if #(coords - target) <= SELECT_DISTANCE then
                    list[#list + 1] = {
                        id = sid,
                        citizenid = player.PlayerData.citizenid,
                        name = fullName(player),
                    }
                end
            end
        end

        if #list >= MAX_NEARBY then break end
    end

    return list
end

local function buildCard(item, holder)
    local meta = item.metadata or {}
    local name = item.name

    if config.accessCards[name] then
        return {
            image = name,
            owner = holder.PlayerData.citizenid,
            ownerName = fullName(holder),
        }
    end

    if name == config.sealCard then
        return {
            seal = true,
            faction = meta.faction or 'The Warden',
            signature = meta.signature or 'unknown',
            owner = meta.owner,
            ownerName = meta.ownerName,
            target = meta.target,
            targetName = meta.targetName,
            expires = meta.expires,
            placement = meta.placement,
        }
    end

    if name == config.cardItem then
        return {
            owner = meta.owner,
            ownerName = meta.ownerName,
            target = meta.target,
            targetName = meta.targetName,
            expires = meta.expires,
            placement = meta.placement,
        }
    end
end

lib.callback.register('sm_warden:nearby', function(src, ids)
    local player = ply(src)
    if not player or type(ids) ~= 'table' then return {} end

    local coords = GetEntityCoords(GetPlayerPed(src))
    local list = {}

    for i = 1, #ids do
        local sid = tonumber(ids[i])
        local other = sid and ply(sid)

        if other and sid ~= src then
            local ped = GetPlayerPed(sid)
            if ped ~= 0 and #(coords - GetEntityCoords(ped)) <= SELECT_DISTANCE then
                list[#list + 1] = {
                    id = sid,
                    citizenid = other.PlayerData.citizenid,
                    name = fullName(other),
                }
            end

            if #list >= MAX_NEARBY then break end
        end
    end

    return list
end)

lib.callback.register('sm_warden:wear', function(src, slot)
    local player = ply(src)
    if not player then return false, 'Data pemain tidak siap.' end
    if LocalPlayer then end

    local item = slotItem(player, slot)
    if not item or not CARD_ITEMS[item.name] then return false, 'Kartu tidak ada di slot itu.' end
    if expired(item) then return false, 'Kartu sudah kedaluwarsa.' end

    local meta = item.metadata or {}
    local citizenid = player.PlayerData.citizenid

    if meta.owner and meta.owner ~= citizenid and meta.target ~= citizenid then
        return false, 'Kartu ini bukan milikmu.'
    end

    worn[src] = tonumber(slot)

    local placement = sanitize(meta.placement)
    Player(src).state:set('wardenPin', placement, true)

    return true
end)

lib.callback.register('sm_warden:unwear', function(src)
    worn[src] = nil
    Player(src).state:set('wardenPin', nil, true)
    return true
end)

lib.callback.register('sm_warden:show', function(src, slot)
    local player = ply(src)
    if not player then return false, 'Data pemain tidak siap.' end

    local item = slotItem(player, slot)
    if not item then return false, 'Kartu tidak ada di slot itu.' end
    if expired(item) then return false, 'Kartu sudah kedaluwarsa.' end

    local card = buildCard(item, player)
    if not card then return false, 'Item itu bukan kartu.' end

    local coords = GetEntityCoords(GetPlayerPed(src))
    local players = QBCore.Functions.GetQBPlayers()
    local sent = 0

    for sid in pairs(players) do
        local ped = GetPlayerPed(sid)
        if ped ~= 0 and #(coords - GetEntityCoords(ped)) <= SHOW_DISTANCE then
            TriggerClientEvent('sm_warden:client:show', sid, card)
            sent = sent + 1
        end
    end

    if sent == 0 then return false, 'Tidak ada orang di sekitar.' end

    TriggerClientEvent('sm_warden:client:cardAnim', src)

    return true
end)

local function handCard(src, targetSrc, itemName, metadata)
    local player = ply(src)
    local target = ply(targetSrc)
    if not player or not target then return false, 'Pemain tidak ditemukan.' end

    if exports.ox_inventory:CanCarryItem(target.PlayerData.citizenid, itemName, 1) then
        if exports.ox_inventory:AddItem(target.PlayerData.citizenid, itemName, 1, metadata) then
            return true, target
        end
    end

    if exports.ox_inventory:CanCarryItem(player.PlayerData.citizenid, itemName, 1) then
        if exports.ox_inventory:AddItem(player.PlayerData.citizenid, itemName, 1, metadata) then
            return true, player
        end
    end

    return false, 'Tas penerima penuh.'
end

lib.callback.register('sm_warden:create', function(src, slot, target, days)
    local player = ply(src)
    if not player then return false, 'Data pemain tidak siap.' end

    local item = slotItem(player, slot)
    if not item or item.name ~= config.blankItem then return false, 'Butuh pin kosong.' end

    local targetSrc = tonumber(target)
    local other = targetSrc and ply(targetSrc)
    if not other then return false, 'Pilih pemain yang valid.' end

    local coords = GetEntityCoords(GetPlayerPed(src))
    if #(coords - GetEntityCoords(GetPlayerPed(other.PlayerData.source))) > SELECT_DISTANCE then
        return false, 'Pemain terlalu jauh.'
    end

    local amount = math.floor(tonumber(days) or config.minDays)
    amount = clamp(amount, config.minDays, config.maxDays)

    local expires = os.time() + amount * 86400

    local metadata = {
        label = ('The Warden - %s'):format(fullName(other)),
        cardType = 'warden',
        owner = other.PlayerData.citizenid,
        ownerName = fullName(other),
        target = other.PlayerData.citizenid,
        targetName = fullName(other),
        issuer = player.PlayerData.citizenid,
        issuerName = fullName(player),
        issued = os.time(),
        expires = expires,
        placement = sanitize(DEFAULT),
    }

    exports.ox_inventory:RemoveItem(player.PlayerData.citizenid, config.blankItem, 1, nil, tonumber(slot))

    local ok, holder = handCard(src, other.PlayerData.source, config.cardItem, metadata)
    if not ok then
        exports.ox_inventory:AddItem(player.PlayerData.citizenid, config.blankItem, 1)
        return false, holder
    end

    notify(holder.PlayerData.source, ('Kamu menerima The Warden dari %s.'):format(fullName(player)), 'success')

    return true
end)

lib.callback.register('sm_warden:sealCreate', function(src, slot, target)
    local player = ply(src)
    if not player then return false, 'Data pemain tidak siap.' end

    local item = slotItem(player, slot)
    if not item or item.name ~= config.sealMaker then return false, 'Butuh seal maker.' end

    local targetSrc = tonumber(target)
    local other = targetSrc and ply(targetSrc)
    if not other then return false, 'Pilih pemain yang valid.' end

    local coords = GetEntityCoords(GetPlayerPed(src))
    if #(coords - GetEntityCoords(GetPlayerPed(other.PlayerData.source))) > SELECT_DISTANCE then
        return false, 'Pemain terlalu jauh.'
    end

    local job = player.PlayerData.job
    local faction = job.label or job.name or 'The Warden'
    local signature = ('%s/%s'):format(player.PlayerData.citizenid, os.time())

    local metadata = {
        label = ('Seal of Protection - %s'):format(fullName(other)),
        cardType = 'seal',
        owner = other.PlayerData.citizenid,
        ownerName = fullName(other),
        target = other.PlayerData.citizenid,
        targetName = fullName(other),
        faction = faction,
        signature = signature,
        issuer = player.PlayerData.citizenid,
        issuerName = fullName(player),
        issued = os.time(),
        expires = os.time() + config.maxDays * 86400,
        placement = sanitize(DEFAULT),
    }

    exports.ox_inventory:RemoveItem(player.PlayerData.citizenid, config.sealMaker, 1, nil, tonumber(slot))

    local ok, holder = handCard(src, other.PlayerData.source, config.sealCard, metadata)
    if not ok then
        exports.ox_inventory:AddItem(player.PlayerData.citizenid, config.sealMaker, 1)
        return false, holder
    end

    notify(holder.PlayerData.source, ('Kamu menerima Seal of Protection dari %s.'):format(fullName(player)), 'success')

    return true
end)

lib.callback.register('sm_warden:place', function(src, edit)
    local player = ply(src)
    if not player then return false, 'Data pemain tidak siap.' end

    local slot = adjusting[src] or worn[src]
    if not slot then return false, 'Kamu tidak sedang memakai pin.' end

    local item = slotItem(player, slot)
    if not item or not CARD_ITEMS[item.name] then return false, 'Kartu tidak ada lagi.' end

    local meta = item.metadata or {}
    local placement = sanitize(edit)
    meta.placement = placement

    exports.ox_inventory:SetMetadata(player.PlayerData.citizenid, slot, meta)
    Player(src).state:set('wardenPin', placement, true)

    adjusting[src] = nil

    return true
end)

local function cardSlot(src)
    local player = ply(src)
    if not player then return end

    for slot = 1, 60 do
        local item = exports.ox_inventory:GetSlot(player.PlayerData.citizenid, slot)
        if item and CARD_ITEMS[item.name] then
            local meta = item.metadata or {}
            if (meta.owner == player.PlayerData.citizenid or meta.target == player.PlayerData.citizenid) and not expired(item) then
                return slot, item
            end
        end
    end
end

RegisterCommand(config.adjustCommand, function(src)
    if src == 0 then return end

    if adjusting[src] then
        return notify(src, 'Sedang mengatur posisi pin.')
    end

    local slot = cardSlot(src)
    if not slot then return notify(src, 'Kamu tidak punya kartu The Warden.') end

    adjusting[src] = slot
    TriggerClientEvent('sm_warden:client:adjust', src, sanitize(Player(src).state.wardenPin))
end, false)

local function registerUse(name, handler)
    pcall(function()
        exports.ox_inventory:RegisterUsableItem(name, function(_, item, inventory, slot)
            local src = inventory and tonumber(inventory.id or inventory.owner)
            if not src then return end

            handler(src, tonumber(slot) or tonumber(item and item.slot))
        end)
    end)
end

registerUse(config.blankItem, function(src, slot)
    if not slot then return end
    TriggerClientEvent('sm_warden:client:creator', src, slot)
end)

registerUse(config.sealMaker, function(src, slot)
    local player = ply(src)
    if not slot or not player then return end

    TriggerClientEvent('sm_warden:client:sealCreator', src, slot, {
        job = player.PlayerData.job.label or player.PlayerData.job.name,
        signature = ('%s/%s'):format(player.PlayerData.citizenid, os.time()),
    })
end)

registerUse(config.cardItem, function(src, slot)
    if not slot then return end
    TriggerClientEvent('sm_warden:client:menu', src, slot)
end)

registerUse(config.sealCard, function(src, slot)
    if not slot then return end
    TriggerClientEvent('sm_warden:client:menu', src, slot)
end)

AddEventHandler('playerDropped', function()
    worn[source] = nil
    adjusting[source] = nil
end)