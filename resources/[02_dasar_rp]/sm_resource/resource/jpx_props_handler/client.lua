local config = localmodule 'config'

local RENDER_DISTANCE = 25.0

local Players = {}
local inAnimation = false

local GetEntityCoords = GetEntityCoords
local DoesEntityExist = DoesEntityExist

---@param request fun(asset: any, timeout: number): any
---@param asset string|number
---@return any
local function load(request, asset)
    local ok, response = pcall(request, asset, 5000)

    if not ok then
        lib.print.warn(response)
    end

    return ok and response
end

---@param cfg table
---@param ped number
local function playEffect(cfg, ped)
    SetPtfxAssetNextCall(cfg.particleDictionary)

    return StartParticleFxNonLoopedOnPedBone(
        cfg.particleName, ped,
        cfg.xPos or 0.0, cfg.yPos or 0.0, cfg.zPos or 0.0,
        cfg.xRot or 0.0, cfg.yRot or 0.0, cfg.zRot or 0.0,
        cfg.Bone, cfg.scale or 1.0, false, false, false
    )
end

---@param entry table
---@param cfg table
---@param ped number
local function startEffects(entry, cfg, serverId)
    if not cfg.EffectBone then return end

    local effects = cfg.EffectBone
    local timed = cfg.EffectTime

    for i = 1, #effects do
        load(lib.requestNamedPtfxAsset, effects[i].particleDictionary)
    end

    local function currentPed()
        local playerId = GetPlayerFromServerId(serverId)
        local ped = playerId ~= -1 and GetPlayerPed(playerId) or 0

        return ped > 0 and DoesEntityExist(ped) and ped or nil
    end

    if timed then
        CreateThread(function()
            while entry.active do
                for i = 1, #effects do
                    if not entry.active then break end

                    local effect = effects[i]
                    local wait = effect.wait or 0

                    if wait > 0 then
                        Wait(wait)
                    end

                    local ped = entry.active and currentPed()

                    if ped then
                        playEffect(effect, ped)
                    end
                end

                if entry.active then
                    Wait(timed)
                end
            end
        end)

        return
    end

    for i = 1, #effects do
        local effect = effects[i]

        CreateThread(function()
            local wait = effect.wait or 1000

            while entry.active do
                local ped = currentPed()

                if ped then
                    playEffect(effect, ped)
                end

                Wait(wait)
            end
        end)
    end
end

---@param cfg table
---@param ped number
---@return number?
local function createProp(cfg, ped)
    local hash = load(lib.requestModel, cfg.Model)

    if not hash then return end

    if not DoesEntityExist(ped) then return end

    local coords = GetEntityCoords(ped)
    local prop = CreateObject(hash, coords.x, coords.y, coords.z, false, false, false)

    SetModelAsNoLongerNeeded(hash)

    if not DoesEntityExist(prop) then return end

    SetEntityCollision(prop, false, false)
    SetEntityCompletelyDisableCollision(prop, false, false)

    AttachEntityToEntity(
        prop, ped, GetPedBoneIndex(ped, cfg.Bone or 0),
        cfg.xPos, cfg.yPos, cfg.zPos,
        cfg.xRot, cfg.yRot, cfg.zRot,
        true, true, false, true, 0, true
    )

    return prop
end

---@param serverId number
local function removeProps(serverId)
    local worn = Players[serverId]

    if worn then
        for _, entry in pairs(worn) do
            entry.active = false

            for i = 1, #entry.props do
                local prop = entry.props[i]

                if DoesEntityExist(prop) then
                    DeleteEntity(prop)
                end
            end
        end

        Players[serverId] = nil
    end

    if serverId == cache.serverId and inAnimation then
        inAnimation = false
        ClearPedTasks(cache.ped)
    end
end

---@param serverId number
---@param ped number
---@param item string
local function wearItem(serverId, ped, item)
    local cfg = config[item]

    if not cfg then return end

    local entry = { active = true, props = {} }

    if cfg.Model then
        local prop = createProp(cfg, ped)

        if prop then
            entry.props[1] = prop
        end
    end

    startEffects(entry, cfg, serverId)

    if cfg.Link and lib.array.isArray(cfg.Link) then
        for i = 1, #cfg.Link do
            local linkCfg = config[cfg.Link[i]]

            if linkCfg then
                local linkProp = createProp(linkCfg, ped)

                if linkProp then
                    entry.props[#entry.props + 1] = linkProp
                    startEffects(entry, linkCfg, serverId)
                end
            end
        end
    end

    if serverId == cache.serverId and cfg.animationName and cfg.animDictionary then
        inAnimation = true
        lib.playAnim(ped, cfg.animDictionary, cfg.animationName, 2.0, 2.0, -1, 1, 0, false, false, false)
    end

    local worn = Players[serverId]

    if not worn then
        worn = {}
        Players[serverId] = worn
    end

    worn[item] = entry
end

---@param serverId number
local function skipRender(serverId)
    return serverId ~= cache.serverId and LocalPlayer.state.prophide == true
end

---@param serverId number
---@param ped number
---@param items table?
local function renderPlayer(serverId, ped, items)
    removeProps(serverId)

    if not items or skipRender(serverId) then return end

    local covered

    for item in pairs(items) do
        local cfg = config[item]
        local link = cfg and cfg.Link

        if link and lib.array.isArray(link) then
            for i = 1, #link do
                local target = link[i]

                if items[target] then
                    covered = covered or {}
                    covered[target] = true
                end
            end
        end
    end

    for item in pairs(items) do
        if not (covered and covered[item]) then
            wearItem(serverId, ped, item)
        end
    end
end

---@param ped number
---@return vector3
local function pedCoords(ped)
    local vehicle = GetVehiclePedIsIn(ped, false)

    return vehicle == 0 and GetEntityCoords(ped) or GetWorldPositionOfEntityBone(ped, 0)
end

---@param serverId number
---@return number ped 0 kalau ga ada atau kejauhan
local function getRenderablePed(serverId)
    local playerId = GetPlayerFromServerId(serverId)
    local ped = playerId ~= -1 and GetPlayerPed(playerId) or 0

    if ped <= 0 or not DoesEntityExist(ped) then return 0 end

    if serverId == cache.serverId then return ped end

    return #(pedCoords(cache.ped) - pedCoords(ped)) <= RENDER_DISTANCE and ped or 0
end

---@param serverId number
---@param items table?
local function sync(serverId, items)
    local ped = items and getRenderablePed(serverId) or 0

    if ped == 0 then
        return removeProps(serverId)
    end

    renderPlayer(serverId, ped, items)
end

---@param seen table<number, true>
local function removeUnseen(seen)
    local stale
    local amount = 0

    for serverId in pairs(Players) do
        if serverId ~= cache.serverId and not seen[serverId] then
            stale = stale or {}
            amount += 1
            stale[amount] = serverId
        end
    end

    for i = 1, amount do
        removeProps(stale[i])
    end
end

local function refreshAll()
    local seen = {}

    for _, playerId in ipairs(GetActivePlayers()) do
        local serverId = GetPlayerServerId(playerId)
        local items = Player(serverId).state.jpx_props

        seen[serverId] = true

        if items and not next(items) then
            items = nil
        end

        sync(serverId, items)
    end

    removeUnseen(seen)
end

AddStateBagChangeHandler('jpx_props', nil, function(bagName, _, value)
    local serverId = tonumber(bagName:gsub('player:', ''), 10)

    if not serverId then return end

    if value and not next(value) then
        value = nil
    end

    sync(serverId, value)
end)

AddStateBagChangeHandler('prophide', ('player:%s'):format(cache.serverId), refreshAll)

RegisterNetEvent('onPlayerDropped', function(serverId)
    removeProps(serverId)
end)

lib.onCache('ped', function()
    CreateThread(function()
        Wait(500)
        refreshAll()
    end)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    for serverId in pairs(Players) do
        removeProps(serverId)
    end
end)

local exportWrapper = require 'export_wrapper'

exportWrapper('jpx_props', 'clear', function()
    TriggerServerEvent('jpx_props_handler:clear')
end)
