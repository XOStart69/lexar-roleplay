local config = require "data.clothing"
local halfped = require "features.halfped"
local TOGGLE_INTERVAL = require("config.clothing").interval

local DECAL_COMPONENT = 10

---@class ClothingAnim
---@field dict string
---@field clip string
---@field flag number
---@field duration number

local GENDER_MODELS = {
    [`mp_m_freemode_01`] = "male",
    [`mp_f_freemode_01`] = "female"
}

local RESET_ANIM = {
    dict = "clothingtie",
    clip = "try_tie_negative_a",
    flag = 51,
    duration = 1200
}

---@type table<number|string, table>
local stored = {}

---@type table<string, number>
local lastVariation = {}

---@type table<string, number>
local lastToggle = {}

local cooldown = false
local railOpen = false

local clothing = {}

---@param key string
---@return boolean
local function throttled(key)
    local now = GetGameTimer()

    if lastToggle[key] and now - lastToggle[key] < TOGGLE_INTERVAL then return true end

    lastToggle[key] = now

    return false
end

---@param propId number
---@return string
local function propKey(propId)
    return "prop_" .. propId
end

---@param itemName string
---@return (number|string)[]
local function slotKeys(itemName)
    local item = config[itemName]
    local keys = {}

    if not item then return keys end

    local components = item.components

    if components then
        if components.id then
            keys[#keys + 1] = components.id
        else
            for i = 1, #components do
                keys[#keys + 1] = components[i].componentId
            end
        end
    end

    if item.props then
        keys[#keys + 1] = propKey(item.props.id)
    end

    return keys
end

---@param itemName string
---@return boolean
local function isSwap(itemName)
    local item = config[itemName]

    if not item then return false end

    return (item.components and item.components.variation ~= nil)
        or (item.props and item.props.variation ~= nil)
end

---@param componentId number
---@param drawable number
---@param texture number?
local function setComponent(componentId, drawable, texture)
    SetPedComponentVariation(cache.ped, componentId, drawable, texture or 0, 0)
end

---@param propId number
---@param index number
---@param texture number?
local function setProp(propId, index, texture)
    if index == -1 then
        ClearPedProp(cache.ped, propId)
    else
        SetPedPropIndex(cache.ped, propId, index, texture or 0, true)
    end
end

---@param componentId number
---@return table
local function componentState(componentId)
    return {
        id = componentId,
        drawable = GetPedDrawableVariation(cache.ped, componentId),
        texture = GetPedTextureVariation(cache.ped, componentId),
        type = "component"
    }
end

---@param propId number
---@return table
local function propState(propId)
    return {
        id = propId,
        prop = GetPedPropIndex(cache.ped, propId),
        texture = GetPedPropTextureIndex(cache.ped, propId),
        type = "prop"
    }
end

---@return "male"|"female"|"custom"
function clothing.gender()
    return GENDER_MODELS[GetEntityModel(cache.ped)] or "custom"
end

---@param itemName string
---@return boolean
function clothing.hidden(itemName)
    if isSwap(itemName) then return false end

    local keys = slotKeys(itemName)

    return #keys > 0 and stored[keys[1]] ~= nil
end

---@param itemName string
---@param gender string
---@return boolean
local function atDefault(itemName, gender)
    local item = config[itemName]
    local components = item.components

    if components then
        local slot = components.id and components or components[1]
        local target = components.id and slot.drawable or slot.drawableId
        local off = target and (target[gender] or target.custom or 0) or 0

        return componentState(components.id or slot.componentId).drawable == off
    end

    if item.props then
        local target = item.props.drawable
        local off = target and (target[gender] or target.custom or -1) or -1

        return propState(item.props.id).prop == off
    end

    return false
end

---@param components table
---@param gender string
---@param restoring boolean
local function applyComponents(components, gender, restoring)
    local list = components.id and { components } or components

    for i = 1, #list do
        local entry = list[i]
        local componentId = entry.componentId or entry.id

        if restoring then
            local previous = stored[componentId]

            if previous then
                setComponent(componentId, previous.drawable, previous.texture)
            end

            stored[componentId] = nil
        elseif componentId ~= DECAL_COMPONENT or not halfped.wearingGranted(cache.ped) then
            stored[componentId] = componentState(componentId)

            local target = entry.drawableId or entry.drawable
            local texture = entry.textureId

            setComponent(componentId, target and (target[gender] or target.custom or 0) or 0,
                texture and texture[gender] or 0)
        end
    end
end

---@param props table
---@param gender string
---@param restoring boolean
local function applyProps(props, gender, restoring)
    local key = propKey(props.id)

    if restoring then
        local previous = stored[key]

        if previous then
            setProp(props.id, previous.prop, previous.texture)
        end

        stored[key] = nil

        return
    end

    stored[key] = propState(props.id)

    local target = props.drawable

    if not target then return end

    setProp(props.id, target[gender] or target.custom or -1, props.textureId and props.textureId[gender] or 0)
end

---@param itemName string
---@param hide boolean
---@param gender string
---@return boolean changed
local function setHidden(itemName, hide, gender)
    local item = config[itemName]

    if not item or isSwap(itemName) then return false end
    if clothing.hidden(itemName) == hide then return false end
    if hide and atDefault(itemName, gender) then return false end

    if item.components then applyComponents(item.components, gender, not hide) end
    if item.props then applyProps(item.props, gender, not hide) end

    return true
end

---@param itemName string
---@param gender string
---@return boolean
local function swap(itemName, gender)
    local item = config[itemName]
    local slot = item.components or item.props
    local isComponent = item.components ~= nil
    local slotId = slot.id
    local current = isComponent and componentState(slotId).drawable or propState(slotId).prop
    local target = slot.variation[gender] and slot.variation[gender][current] or lastVariation[itemName]

    if not target then
        lib.notify({ description = locale("clothing.noVariation"), type = "error" })

        return false
    end

    lastVariation[itemName] = current

    if isComponent then
        setComponent(slotId, target, componentState(slotId).texture)
    else
        setProp(slotId, target, propState(slotId).texture)
    end

    return true
end

local function restoreVariations()
    for itemName, previous in pairs(lastVariation) do
        local item = config[itemName]
        local slot = item and (item.components or item.props)

        if slot and slot.variation then
            local isComponent = item.components ~= nil
            local state = isComponent and componentState(slot.id) or propState(slot.id)
            local current = isComponent and state.drawable or state.prop

            if previous ~= current then
                if isComponent then
                    setComponent(slot.id, previous, state.texture)
                else
                    setProp(slot.id, previous, state.texture)
                end
            end
        end
    end
end

---@param anim ClothingAnim|ClothingAnim[]|nil
---@param restoring boolean
---@return ClothingAnim?
local function animationFor(anim, restoring)
    if not anim then return end

    if anim[1] then
        return restoring and anim[2] or anim[1]
    end

    return anim
end

---@param anim ClothingAnim?
---@param apply fun()
local function run(anim, apply)
    if not anim then return apply() end

    cooldown = true

    CreateThread(function()
        lib.requestAnimDict(anim.dict)

        local flag = cache.vehicle and 51 or anim.flag or 0

        TaskPlayAnim(cache.ped, anim.dict, anim.clip, 3.0, 3.0, anim.duration or -1, flag, 0, false, false, false)

        Wait(math.max((anim.duration or 0) - 200, 200))

        apply()

        cooldown = false
    end)
end

---@return table<string, { hidden: boolean, swap: boolean, available: boolean }>
function clothing.status()
    local gender = clothing.gender()
    local status = {}

    for itemName in pairs(config) do
        local swapItem = isSwap(itemName)
        local hidden = clothing.hidden(itemName)

        status[itemName] = {
            hidden = hidden,
            swap = swapItem,
            available = swapItem and gender ~= "custom" or (not swapItem and (hidden or not atDefault(itemName, gender)))
        }
    end

    return status
end

function clothing.push()
    SendNuiMessage(json.encode({
        action = "clothing_status",
        data = clothing.status()
    }))
end

---@return boolean
function clothing.busy()
    return cooldown
end

---@return boolean
function clothing.anyHidden()
    return next(stored) ~= nil
end

---@param kind "component"|"prop"
---@param slotId number
---@return boolean cleared
function clothing.forget(kind, slotId)
    local key = kind == "prop" and propKey(slotId) or slotId
    local cleared = false

    for itemName in pairs(config) do
        local keys = slotKeys(itemName)
        local owns = false

        for i = 1, #keys do
            if keys[i] == key then
                owns = true
                break
            end
        end

        if owns then
            for i = 1, #keys do
                local previous = stored[keys[i]]

                if previous then
                    if keys[i] ~= key then
                        if previous.type == "prop" then
                            setProp(previous.id, previous.prop, previous.texture)
                        else
                            setComponent(previous.id, previous.drawable, previous.texture)
                        end
                    end

                    stored[keys[i]] = nil
                    cleared = true
                end
            end

            lastVariation[itemName] = nil
        end
    end

    return cleared
end

---@param itemName string
---@param animate boolean?
---@return boolean
function clothing.toggle(itemName, animate)
    if cooldown then return false end

    local item = config[itemName]

    if not item then return false end
    if throttled(itemName) then return false end

    local gender = clothing.gender()

    if isSwap(itemName) then
        if gender == "custom" then
            lib.notify({ description = locale("clothing.noVariation"), type = "error" })

            return false
        end

        run(animate and animationFor(item.anim, true) or nil, function()
            if swap(itemName, gender) then clothing.push() end
        end)

        return true
    end

    local hidden = clothing.hidden(itemName)

    if not hidden and atDefault(itemName, gender) then
        lib.notify({ description = locale("clothing.notWorn", locale("clothing." .. itemName)), type = "error" })

        return false
    end

    run(animate and animationFor(item.anim, not hidden) or nil, function()
        if setHidden(itemName, not hidden, gender) then clothing.push() end
    end)

    return true
end

---@param items string[]
---@return boolean changed
function clothing.toggleGroup(items)
    if cooldown then return false end
    if throttled(table.concat(items, ",")) then return false end

    local gender = clothing.gender()
    local hide = true

    for i = 1, #items do
        if clothing.hidden(items[i]) then
            hide = false
            break
        end
    end

    local changed = false

    for i = 1, #items do
        if setHidden(items[i], hide, gender) then changed = true end
    end

    if changed then clothing.push() end

    return changed
end

---@return boolean
function clothing.railOpen()
    return railOpen
end

function clothing.closeRail()
    if not railOpen then return end

    railOpen = false

    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)

    SendNuiMessage(json.encode({
        action = "clothing_hide",
        data = {}
    }))
end

function clothing.openRail()
    if railOpen then return end

    railOpen = true

    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)

    SendNuiMessage(json.encode({
        action = "clothing_display",
        data = clothing.status()
    }))

    CreateThread(function()
        while railOpen do
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            Wait(0)
        end
    end)
end

---@param animate boolean?
function clothing.reset(animate)
    if not clothing.anyHidden() and next(lastVariation) == nil then return end

    local function restore()
        for key, previous in pairs(stored) do
            if previous.type == "prop" then
                setProp(previous.id, previous.prop, previous.texture)
            else
                setComponent(previous.id, previous.drawable, previous.texture)
            end

            stored[key] = nil
        end

        restoreVariations()

        lastVariation = {}

        clothing.push()
    end

    run(animate and RESET_ANIM or nil, restore)
end

return clothing
