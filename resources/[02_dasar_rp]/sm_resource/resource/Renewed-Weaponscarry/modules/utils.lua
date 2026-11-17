local Slots = localmodule 'data.slots'
local Items = localmodule 'data.items'
local Utils = {}

-- Runtime tracking for occupied slot positions
local slotOccupancy = {}

function Utils.resetSlots()
    table.wipe(slotOccupancy)
end

---Normalizes item config from Items table
---@param itemName string
---@return { slotId: string, model?: string }?
function Utils.getItemSlotConfig(itemName)
    local config = Items[itemName]
    if not config then return nil end

    if type(config) == 'string' then
        return { slotId = config }
    end

    return config
end

---Gets the player's current job name for slot variant selection
---@return string
function Utils.getPlayerJob()
    local playerjob = QBPlayerData.job
    return playerjob?.name or 'default'
end

---Finds an open position within a named slot
---@param slotId string
---@return SlotConfig?
function Utils.findOpenSlot(slotId)
    local slotDef = Slots[slotId]
    if not slotDef then return nil end

    local job = Utils.getPlayerJob()
    local variant = slotDef[job] or slotDef.default
    if not variant then return nil end

    if not slotOccupancy[slotId] then
        slotOccupancy[slotId] = {}
    end

    local occupancy = slotOccupancy[slotId]
    local isArray = lib.array.isArray(variant)

    if not isArray then
        if not occupancy[1] then
            occupancy[1] = true
            return variant
        end

        return nil
    end

    for i = 1, #variant do
        if not occupancy[i] then
            occupancy[i] = true
            return variant[i]
        end
    end

    return nil
end

function Utils.removeEntities(data)
    for i = 1, #data do
        local entity = data[i]?.entity

        if entity then
            DeleteEntity(entity)
        end
    end
end

function Utils.hasFlashLight(components)
    if components and table.type(components) ~= 'empty' then
        for i = 1, #components do
            local component = components[i]

            if component:find('flashlight') then
                return true
            end
        end
    end

    return false
end

function Utils.checkFlashState(weapon)
    local flashState = LocalPlayer.state.flashState

    if flashState and flashState[weapon.serial] and Utils.hasFlashLight(weapon.components) then
        return true
    end

    return false
end

---@param hash number
---@param components string[]?
---@return number?
function Utils.hasVarMod(hash, components)
    if not components then return nil end

    for i = 1, #components do
        local component = ox_items[components[i]]
        local componentList = component?.client?.component

        if componentList and (component.type == 'skin' or component.type == 'upgrade') then
            for j = 1, #componentList do
                local weaponComponent = componentList[j]
                if DoesWeaponTakeWeaponComponent(hash, weaponComponent) then
                    return GetWeaponComponentTypeModel(weaponComponent)
                end
            end
        end
    end
end

---@param name string
---@param hash number
---@param components string[]?
---@return number?, number[], boolean
function Utils.getWeaponComponents(name, hash, components)
    local weaponComponents = {}
    local amount = 0
    local hadClip = false
    local varMod = Utils.hasVarMod(hash, components)

    for i = 1, components and #components or 0 do
        local weaponComp = ox_items[components[i]]
        local componentList = weaponComp?.client?.component

        if componentList then
            for j = 1, #componentList do
                local weaponComponent = componentList[j]
                if DoesWeaponTakeWeaponComponent(hash, weaponComponent) and varMod ~= weaponComponent then
                    amount += 1
                    weaponComponents[amount] = weaponComponent

                    if weaponComp.type == 'magazine' then
                        hadClip = true
                    end

                    break
                end
            end
        end
    end

    if not hadClip then
        amount += 1
        weaponComponents[amount] = joaat(('COMPONENT_%s_CLIP_01'):format(name:sub(8)))
    end


    return varMod, weaponComponents, hadClip
end

function Utils.getPedBone(config)
    local boneIndex = config.boneIndex or config.bone
    return {
        id = config.boneId,
        index = boneIndex,
    }
end

function Utils.formatData(itemData, itemConfig, ignoreSlot)
    local isWeapon = itemData.name:find('WEAPON_')
    local itemName = itemData.name:lower()
    local slotConfig = Utils.getItemSlotConfig(itemName)

    if not slotConfig and itemConfig then
        return {
            name = itemData.name,
            hash = isWeapon and joaat(itemData.name) or nil,
            components = isWeapon and itemData?.metadata?.components,
            tint = isWeapon and itemData?.metadata?.tint,
            serial = isWeapon and itemData?.metadata?.serial or 'unknown',
            model = itemConfig.model,
            pos = itemConfig.pos,
            rot = itemConfig.rot,
            bone = Utils.getPedBone(itemConfig),
        }
    end

    if slotConfig and not slotConfig.slotId then
        return {
            name = itemData.name,
            hash = isWeapon and joaat(itemData.name) or nil,
            components = isWeapon and itemData?.metadata?.components,
            tint = isWeapon and itemData?.metadata?.tint,
            serial = isWeapon and itemData?.metadata?.serial or 'unknown',
            model = slotConfig.model and joaat(slotConfig.model),
            pos = slotConfig.pos,
            rot = slotConfig.rot,
            bone = Utils.getPedBone(slotConfig),
        }
    end

    local slot = not ignoreSlot and slotConfig and Utils.findOpenSlot(slotConfig.slotId)

    if not ignoreSlot and not slot then
        return nil
    end

    return {
        name = itemData.name,
        hash = isWeapon and joaat(itemData.name) or nil,
        components = isWeapon and itemData?.metadata?.components,
        tint = isWeapon and itemData?.metadata?.tint,
        serial = isWeapon and itemData?.metadata?.serial or 'unknown',
        model = slotConfig and slotConfig.model and joaat(slotConfig.model),
        pos = slot?.pos,
        rot = slot?.rot,
        bone = Utils.getPedBone(slot),
    }
end


local ENTITY_TIMEOUT = 1000

function Utils.getEntityFromStateBag(bagName, keyName)

    if bagName:find('entity:') then
        local netId = tonumber(bagName:gsub('entity:', ''), 10)

        if not netId or not NetworkDoesEntityExistWithNetworkId(netId) then
            return 0
        end

        return NetworkGetEntityFromNetworkId(netId)
    elseif bagName:find('player:') then
        local serverId = tonumber(bagName:gsub('player:', ''), 10)

        if not serverId then return nil, 0 end

        local playerId = GetPlayerFromServerId(serverId)

        if playerId == -1 then
            return serverId, 0
        end

        local ped = GetPlayerPed(playerId)

        if ped > 0 then
            return serverId, ped
        end

        local ok, entity = pcall(lib.waitFor, function()
            local playerPed = GetPlayerPed(playerId)
            if playerPed > 0 then return playerPed end
        end, ('%s received invalid entity! (%s)'):format(keyName, bagName), ENTITY_TIMEOUT)

        return serverId, ok and entity or 0
    end

end

function Utils.AttachEntityToPlayer(item, entity, pedHandle)
    local pos, rot = item.pos, item.rot
    local itemBone = item.bone
    local boneValue = itemBone.index and GetPedBoneIndex(cache.ped, itemBone.index) or itemBone.id

    if pos and rot and boneValue then
        AttachEntityToEntity(entity, pedHandle, boneValue, pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, true, true, false, false, 2, true)
    end
end

local MODEL_TIMEOUT = 10000

local function createObject(item)
    local ok = pcall(lib.requestModel, item.model, MODEL_TIMEOUT)

    if not ok or not HasModelLoaded(item.model) then
        return 0
    end

    local Object = CreateObject(item.model, 0.0, 0.0, 0.0, false, false, false)
    SetModelAsNoLongerNeeded(item.model)

    return Object
end

local function createWeapon(item)
    local hash = item.hash

    if not hash or hash == 0 then return 0 end

    local ok = pcall(lib.requestWeaponAsset, hash, 5000, 31, 0)

    if ok and HasWeaponAssetLoaded(hash) then
        local hasLuxeMod, components, hadClip = Utils.getWeaponComponents(item.name, hash, item.components)

        if hasLuxeMod then
            local loaded = pcall(lib.requestModel, hasLuxeMod, MODEL_TIMEOUT)

            if not loaded or not HasModelLoaded(hasLuxeMod) then
                hasLuxeMod = nil
            end
        end

        local showDefault = true

        if hasLuxeMod and hadClip then
            showDefault = false
        end

        ---@diagnostic disable-next-line: redundant-parameter
        local weaponObject = CreateWeaponObject(hash, 0, 0.0, 0.0, 0.0, showDefault, 1.0, hasLuxeMod or 0, false, true)

        for i = 1, #components do
            GiveWeaponComponentToWeaponObject(weaponObject, components[i])
        end

        if item.tint then
            SetWeaponObjectTintIndex(weaponObject, item.tint)
        end

        if Utils.checkFlashState(item) then
            SetCreateWeaponObjectLightSource(weaponObject, true)
            Wait(0) -- We need to skip a frame before attaching the object for the lightsource to be created
        end

        if hasLuxeMod then
            SetModelAsNoLongerNeeded(hasLuxeMod)
        end

        RemoveWeaponAsset(hash)

        return weaponObject
    end

    return 0
end

function Utils.getEntity(payload)
    if payload?.model then
        return createObject(payload)
    elseif payload?.hash then
        return createWeapon(payload)
    end

    return 0
end


return Utils
