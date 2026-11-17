local inventory = exports.ox_inventory

local makanan = require 'consumable.makanan'
local minuman = require 'consumable.minuman'
local alkohol = require 'consumable.alcohol'
local other = require 'consumable.other'

local function mergeTables(...)
    local tables = {...}
    local result = {}
    for _, tbl in ipairs(tables) do
        for key, value in pairs(tbl) do
            if type(key) == 'number' then
                result[#result + 1] = value
            else
                result[key] = value
            end
        end
    end
    return result
end

local usableItems = mergeTables(makanan, minuman, other, alkohol)

local function applyDrunkEffect(duration)
    Wait(100)
    DoScreenFadeOut(1)
    Wait(1000)

    SetTimecycleModifier("spectator5")
    SetPedMotionBlur(cache.ped, true)
    SetPedMovementClipset(cache.ped, "MOVE_M@DRUNK@SLIGHTLYDRUNK", true)
    SetPedIsDrunk(cache.ped, true)
    SetPedAccuracy(cache.ped, 0)
    ShakeGameplayCam("DRUNK_SHAKE", 5.0)
    SetPedConfigFlag(cache.ped, 100, true)

    DoScreenFadeIn(1)
    Wait(duration)
    DoScreenFadeOut(1)
    Wait(1000)

    DoScreenFadeIn(1000)
    ClearTimecycleModifier()
    ResetScenarioTypesEnabled()
    ResetPedMovementClipset(cache.ped, 0)
    ShakeGameplayCam("DRUNK_SHAKE", 0.0)
    SetPedIsDrunk(cache.ped, false)
    SetPedMotionBlur(cache.ped, false)
end

local activeProps = {}

---@param prop number
local function deleteProp(prop)
    activeProps[prop] = nil

    if not DoesEntityExist(prop) then return end

    DetachEntity(prop, true, true)
    DeleteEntity(prop)
end

---@param propName string
---@param placement number[]
---@param bone number?
---@param ped number?
---@return number?
local function spawnProp(propName, placement, bone, ped)
    ped = ped or cache.ped

    local model = joaat(propName)

    if not IsModelValid(model) or not lib.requestModel(model, 1000) then return end

    if not DoesEntityExist(ped) then
        SetModelAsNoLongerNeeded(model)
        return
    end

    local x, y, z, rx, ry, rz = table.unpack(placement)
    local coords = GetEntityCoords(ped)
    local prop = CreateObject(model, coords.x, coords.y, coords.z + 0.2, false, false, false)

    SetModelAsNoLongerNeeded(model)

    if not DoesEntityExist(prop) then return end

    SetEntityCollision(prop, false, false)
    SetEntityCompletelyDisableCollision(prop, false, false)

    AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, bone or 60309),
        x or 0.0, y or 0.0, z or 0.0,
        rx or 0.0, ry or 0.0, rz or 0.0,
        true, true, false, true, 1, true
    )

    activeProps[prop] = true

    return prop
end

local function handleProgress(itemConfig, itemData)
    local progress = itemConfig.progress
    if not progress then return true end

    local previousEmote = exports['sm_emotes']:IsPlayerInAnim()
    local progressLabel = progress.label:gsub("{itemname}", itemData?.label or "item")

    local animDict, animClip
    local spawnedProps = {}
    local emoteData

    if progress.anim then
        animDict = progress.anim.dict
        animClip = progress.anim.clip
    elseif progress.emote then
        emoteData = exports['sm_emotes']:getEmoteByCommand(progress.emote)
        if emoteData then
            animDict = emoteData.dict
            animClip = emoteData.anim
        end
    end

    local animFlag = previousEmote and 49 or (progress.anim?.flag or 49)

    if emoteData and emoteData.AnimationOptions then
        local opts = emoteData.AnimationOptions

        if opts.Prop or opts.SecondProp then
            LocalPlayer.state:set('consumableProp', progress.emote, true)
        end

        if opts.Prop and opts.PropPlacement and #opts.PropPlacement >= 5 then
            local prop = spawnProp(opts.Prop, opts.PropPlacement, opts.PropBone)

            if prop then
                spawnedProps[#spawnedProps + 1] = prop
            end
        end

        if opts.SecondProp and opts.SecondPropPlacement and #opts.SecondPropPlacement >= 5 then
            local prop = spawnProp(opts.SecondProp, opts.SecondPropPlacement, opts.SecondPropBone)

            if prop then
                spawnedProps[#spawnedProps + 1] = prop
            end
        end
    end

    local success = lib.progressBar({
        duration = progress.duration,
        label = progressLabel,
        useWhileDead = false,
        canCancel = true,
        anim = animDict and {
            dict = animDict,
            clip = animClip,
            flag = animFlag
        } or nil,
        prop = progress.prop and {
            model = progress.prop.model,
            bone = progress.prop.bone,
            pos = progress.prop.pos,
            rot = progress.prop.rot,
        } or nil
    })

    if animDict then
        StopAnimTask(cache.ped, animDict, animClip, 0)
    end

    for i = 1, #spawnedProps do
        deleteProp(spawnedProps[i])
    end

    if LocalPlayer.state.consumableProp then
        LocalPlayer.state:set('consumableProp', nil, true)
    end

    if previousEmote then
        ExecuteCommand('e ' .. previousEmote)
    end

    if success and progress.onSuccess then
        CreateThread(function()
            progress.onSuccess(itemData)
        end)
    elseif not success and progress.onFail then
        CreateThread(function()
            progress.onFail(itemData)
        end)
    end

    return success
end

local function handleHealthEffects(config)
    if config.addHealth then
        local currentHealth = GetEntityHealth(cache.ped)
        local newHealth = math.min(currentHealth + config.addHealth, 200)
        SetEntityHealth(cache.ped, newHealth)

        SetTimeout(1000, function()
            TriggerTokenEvent('ni_consumable:saveHealthArmour')
        end)
    end

    if config.removeHealth then
        local newHealth = math.max(cache.health - config.removeHealth, 0)
        SetEntityHealth(cache.ped, newHealth)

        SetTimeout(1000, function()
            TriggerTokenEvent('ni_consumable:saveHealthArmour')
        end)
    end
end

local function handleArmourEffects(config)
    if config.addArmour then
        local maxArmour = config.maxArmour or 95
        if maxArmour < config.addArmour then
            maxArmour = config.addArmour
        end

        local newArmour = math.min(cache.armour + config.addArmour, maxArmour)
        SetPedArmour(cache.ped, newArmour)

        SetTimeout(1000, function()
            TriggerTokenEvent('ni_consumable:saveHealthArmour')
        end)
    end

    if config.removeArmour then
        local newArmour = math.max(cache.armour - config.removeArmour, 0)
        SetPedArmour(cache.ped, newArmour)

        SetTimeout(1000, function()
            TriggerTokenEvent('ni_consumable:saveHealthArmour')
        end)
    end
end

local function handleStressEffects(config)
    if config.addStress then
        TriggerTokenEvent('sm_hud:server:addStress', config.addStress)
    end

    if config.removeStress then
        TriggerTokenEvent('sm_hud:server:removeStress', config.removeStress)
    end
end

local function handleDrunkEffects(config)
    if config.drunk then
        exports.sm_resource_2:setDrunk(config.drunk)
    end

    if config.removeDrunk then
        exports.sm_resource_2:removeDrunkTime(config.removeDrunk)
    end

    if config.status?.drunkEffect then
        local duration = config.status.drunkEffect
        local durationTime = type(duration) == 'table' and math.random(duration.min, duration.max)
            or type(duration) == 'number' and duration
            or math.random(10, 20)

        exports.sm_resource_2:setDrunk(durationTime)
    end
end

local function handleSpecialEffects(config, itemData)
    if config.animCoke then
        CreateThread(function()
            applyDrunkEffect(10000)
        end)
    end

    if config.animVaksin then
        CreateThread(function()
            applyDrunkEffect(60000)
        end)
    end

    if config.showImage then
        exports['ps-ui']:ShowImage(config.showImage)
    end

    if config.clearBlood then
        ClearPedBloodDamage(cache.ped)
    end

    if config.clientFunction then
        config.clientFunction(itemData)
    end
end

local function applyItemEffects(config, itemData)
    handleHealthEffects(config)
    handleArmourEffects(config)
    handleStressEffects(config)
    handleDrunkEffects(config)
    handleSpecialEffects(config, itemData)
end

for itemKey, itemConfig in pairs(usableItems) do
    RegisterNetEvent(('consumables:client:%s'):format(itemKey), function(customLabel)
        if source ~= 65535 then return end

        local responded = false

        local function respond(success)
            if responded then return end

            responded = true

            TriggerServerEvent(('consumables:server:response:%s'):format(itemKey), success)
        end

        local ok, err = pcall(function()
            local itemData = inventory:Items(itemKey)

            if type(customLabel) == 'string' and customLabel ~= '' and itemData then
                local labelled = {}
                for key, value in pairs(itemData) do labelled[key] = value end
                labelled.label = customLabel
                itemData = labelled
            end

            if itemConfig.validateClient and not itemConfig.validateClient(itemData) then
                return respond(false)
            end

            if not handleProgress(itemConfig, itemData) then
                return respond(false)
            end

            CreateThread(function()
                applyItemEffects(itemConfig, itemData)
            end)

            respond(true)
        end)

        if not ok then
            lib.print.error(('consumable %s gagal: %s'):format(itemKey, err))
            respond(false)
        end
    end)
end

local RENDER_DISTANCE = 5.0

local remoteProps = {}

---@param serverId number
local function removeRemoteProps(serverId)
    local props = remoteProps[serverId]

    if not props then return end

    for i = 1, #props do
        deleteProp(props[i])
    end

    remoteProps[serverId] = nil
end

---@param serverId number
---@param emote string
local function renderRemoteProps(serverId, emote)
    removeRemoteProps(serverId)

    local playerId = GetPlayerFromServerId(serverId)

    if playerId == -1 then return end

    local ped = GetPlayerPed(playerId)

    if ped <= 0 or not DoesEntityExist(ped) then return end

    if #(GetEntityCoords(cache.ped) - GetEntityCoords(ped)) > RENDER_DISTANCE then return end

    local emoteData = exports['sm_emotes']:getEmoteByCommand(emote)
    local opts = emoteData and emoteData.AnimationOptions

    if not opts then return end

    local props
    local amount = 0

    if opts.Prop and opts.PropPlacement and #opts.PropPlacement >= 5 then
        local prop = spawnProp(opts.Prop, opts.PropPlacement, opts.PropBone, ped)

        if prop then
            props = props or {}
            amount += 1
            props[amount] = prop
        end
    end

    if opts.SecondProp and opts.SecondPropPlacement and #opts.SecondPropPlacement >= 5 then
        local prop = spawnProp(opts.SecondProp, opts.SecondPropPlacement, opts.SecondPropBone, ped)

        if prop then
            props = props or {}
            amount += 1
            props[amount] = prop
        end
    end

    remoteProps[serverId] = props
end

AddStateBagChangeHandler('consumableProp', nil, function(bagName, _, value)
    local serverId = tonumber(bagName:gsub('player:', ''), 10)

    if not serverId or serverId == cache.serverId then return end

    if not value then
        return removeRemoteProps(serverId)
    end

    renderRemoteProps(serverId, value)
end)

RegisterNetEvent('onPlayerDropped', function(serverId)
    removeRemoteProps(serverId)
end)

local function clearAllProps()
    local props = {}
    local amount = 0

    for prop in pairs(activeProps) do
        amount += 1
        props[amount] = prop
    end

    for i = 1, amount do
        deleteProp(props[i])
    end

    table.wipe(remoteProps)

    if LocalPlayer.state.consumableProp then
        LocalPlayer.state:set('consumableProp', nil, true)
    end
end

RegisterNetEvent('QBCore:Client:OnPlayerUnload', clearAllProps)

lib.onCache('ped', clearAllProps)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    clearAllProps()

    pcall(function()
        exports['sm_emotes']:EmoteCancel(true)
    end)
end)