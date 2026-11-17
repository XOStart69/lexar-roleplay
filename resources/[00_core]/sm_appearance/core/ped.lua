local shared = require "config.general"
local config = require "config.editor"
local constants = require "data.constants"
local pedModels = require "data.peds"

local MALE = joaat(shared.freemodeModels.male)
local FEMALE = joaat(shared.freemodeModels.female)

local HAIR_ZONE = "ZONE_HAIR"
local HAIR_COMPONENT = 2
local NO_FADE = -1
local PED_SWAP_TIMEOUT <const> = 3000
local PRELOAD_TIMEOUT <const> = 5000

local LOCKED_COMPONENTS = { [0] = true, [2] = true }

local SECOND_COLOR = { blush = true, lipstick = true, makeUp = true }

local GET_PED_HEAD_BLEND_DATA = 0x2746BD9D88C5C5D0

---@type table<number, string>?
local modelsByHash

---@type PedTattoos
local worn = {}

---@type number
local hairFade = NO_FADE

local ped = {}

---@param value number
---@return number
local function round(value)
    return tonumber(("%.1f"):format(value)) --[[@as number]]
end

---@param value any
---@return number
local function ratio(value)
    return math.min(1, tonumber(tostring(value):sub(1, 4)) or 0)
end

---@return table<number, string>
local function modelIndex()
    if not modelsByHash then
        modelsByHash = table.create(0, #pedModels)

        for i = 1, #pedModels do
            modelsByHash[joaat(pedModels[i])] = pedModels[i]
        end
    end

    return modelsByHash
end

---@param entity number
---@return boolean
function ped.isFreemode(entity)
    local model = GetEntityModel(entity)

    return model == MALE or model == FEMALE
end

---@param entity number
---@return string "male"|"female"
function ped.gender(entity)
    local model = GetEntityModel(entity)

    if model == MALE then return "male" end
    if model == FEMALE then return "female" end

    return IsPedMale(entity) and "male" or "female"
end

---@param entity number
---@return string
function ped.getModel(entity)
    return modelIndex()[GetEntityModel(entity)] or shared.freemodeModels.male
end

---@param name string|number
---@param force boolean?
---@return number entity
function ped.setModel(name, force)
    local hash = type(name) == "string" and joaat(name) or name --[[@as number]]

    if not IsModelInCdimage(hash) then return cache.ped end

    if not force and GetEntityModel(cache.ped) == hash then return cache.ped end

    local previous = cache.ped

    lib.requestModel(hash, 10000)
    SetPlayerModel(cache.playerId, hash)
    SetModelAsNoLongerNeeded(hash)

    local synced = pcall(lib.waitFor, function()
        local current = PlayerPedId()

        return current ~= 0 and current ~= previous and cache.ped == current or nil
    end, nil, PED_SWAP_TIMEOUT)

    if not synced then
        cache.ped = PlayerPedId()
    end

    Wait(0)

    if ped.isFreemode(cache.ped) then
        SetPedDefaultComponentVariation(cache.ped)

        if hash == FEMALE then
            SetPedHeadBlendData(cache.ped, 45, 21, 0, 20, 15, 0, 0.3, 0.1, 0.0, false)
        else
            SetPedHeadBlendData(cache.ped, 0, 0, 0, 0, 0, 0, 0.0, 0.0, 0.0, false)
        end
    end

    worn = {}

    return cache.ped
end

---@param entity number
---@return PedComponent[]
function ped.getComponents(entity)
    local list = table.create(#constants.COMPONENTS, 0)

    for i = 1, #constants.COMPONENTS do
        local id = constants.COMPONENTS[i]

        list[i] = {
            component_id = id,
            drawable = GetPedDrawableVariation(entity, id),
            texture = GetPedTextureVariation(entity, id)
        }
    end

    return list
end

---@param entity number
---@param component PedComponent
function ped.setComponent(entity, component)
    if not component.component_id then return end
    if ped.isFreemode(entity) and LOCKED_COMPONENTS[component.component_id] then return end

    SetPedComponentVariation(entity, component.component_id, component.drawable, component.texture, 0)
end

---@param entity number
---@param list PedComponent[]
function ped.setComponents(entity, list)
    for i = 1, #list do
        ped.setComponent(entity, list[i])
    end
end

---@param entity number
---@return PedProp[]
function ped.getProps(entity)
    local list = table.create(#constants.PROPS, 0)

    for i = 1, #constants.PROPS do
        local id = constants.PROPS[i]

        list[i] = {
            prop_id = id,
            drawable = GetPedPropIndex(entity, id),
            texture = GetPedPropTextureIndex(entity, id)
        }
    end

    return list
end

---@param entity number
---@param prop PedProp
function ped.setProp(entity, prop)
    if prop.drawable == -1 then
        return ClearPedProp(entity, prop.prop_id)
    end

    SetPedPropIndex(entity, prop.prop_id, prop.drawable, prop.texture, false)
end

---@param entity number
---@param list PedProp[]
function ped.setProps(entity, list)
    for i = 1, #list do
        ped.setProp(entity, list[i])
    end
end

---@param entity number
---@return PedHeadBlend
function ped.getHeadBlend(entity)
    local shapeFirst, shapeSecond, shapeThird, skinFirst, skinSecond, skinThird, shapeMix, skinMix, thirdMix =
        Citizen.InvokeNative(GET_PED_HEAD_BLEND_DATA, entity,
            Citizen.PointerValueIntInitialized(0), Citizen.PointerValueIntInitialized(0),
            Citizen.PointerValueIntInitialized(0), Citizen.PointerValueIntInitialized(0),
            Citizen.PointerValueIntInitialized(0), Citizen.PointerValueIntInitialized(0),
            Citizen.PointerValueFloatInitialized(0), Citizen.PointerValueFloatInitialized(0),
            Citizen.PointerValueFloatInitialized(0))

    return {
        shapeFirst = shapeFirst,
        shapeSecond = shapeSecond,
        shapeThird = shapeThird,
        skinFirst = skinFirst,
        skinSecond = skinSecond,
        skinThird = skinThird,
        shapeMix = ratio(shapeMix),
        skinMix = ratio(skinMix),
        thirdMix = ratio(thirdMix or 0)
    }
end

---@param entity number
---@param blend PedHeadBlend
function ped.setHeadBlend(entity, blend)
    if not ped.isFreemode(entity) then return end

    SetPedHeadBlendData(entity,
        blend.shapeFirst, blend.shapeSecond, blend.shapeThird,
        blend.skinFirst, blend.skinSecond, blend.skinThird,
        (blend.shapeMix or 0) + 0.0, (blend.skinMix or 0) + 0.0, (blend.thirdMix or 0) + 0.0,
        false)
end

---@param entity number
---@return PedFaceFeatures
function ped.getFaceFeatures(entity)
    local features = constants.FACE_FEATURES
    local values = table.create(0, #features)

    for i = 1, #features do
        values[features[i]] = round(GetPedFaceFeature(entity, i - 1))
    end

    return values
end

---@param entity number
---@param values PedFaceFeatures
function ped.setFaceFeatures(entity, values)
    local features = constants.FACE_FEATURES

    for i = 1, #features do
        SetPedFaceFeature(entity, i - 1, (values[features[i]] or 0) + 0.0)
    end
end

---@param entity number
---@return PedHeadOverlays
function ped.getHeadOverlays(entity)
    local overlays = constants.HEAD_OVERLAYS
    local values = table.create(0, #overlays)

    for i = 1, #overlays do
        local _, style, _, color, secondColor, opacity = GetPedHeadOverlayData(entity, i - 1)

        if style == 255 then
            style = 0
            opacity = 0
        else
            opacity = round(opacity)
        end

        values[overlays[i]] = {
            style = style,
            opacity = opacity,
            color = color,
            secondColor = secondColor
        }
    end

    return values
end

---@param entity number
---@param values PedHeadOverlays
function ped.setHeadOverlays(entity, values)
    local overlays = constants.HEAD_OVERLAYS

    for i = 1, #overlays do
        local name = overlays[i]
        local overlay = values[name]

        if overlay then
            SetPedHeadOverlay(entity, i - 1, overlay.style, (overlay.opacity or 0) + 0.0)

            if overlay.color then
                SetPedHeadOverlayColor(entity, i - 1, SECOND_COLOR[name] and 2 or 1, overlay.color, overlay.secondColor)
            end
        end
    end
end

---@param entity number
---@return number
function ped.getEyeColor(entity)
    local value = GetPedEyeColor(entity)

    return value < #constants.EYE_COLORS and value or 0
end

---@param entity number
---@param value number
function ped.setEyeColor(entity, value)
    SetPedEyeColor(entity, value)
end

---@param entity number
---@param style number
local function applyFade(entity, style)
    local decoration = constants.HAIR_DECORATIONS[ped.gender(entity)][style]

    if decoration then
        AddPedDecorationFromHashes(entity, decoration[1], decoration[2])
    end
end

---@param entity number
---@param tattoo Tattoo
---@param male boolean
local function addTattoo(entity, tattoo, male)
    local hash = male and tattoo.hashMale or tattoo.hashFemale

    for _ = 1, (tattoo.opacity or 0.1) * 10 do
        AddPedDecorationFromHashes(entity, joaat(tattoo.collection), joaat(hash))
    end
end

---@return PedTattoos
function ped.getTattoos()
    return worn
end

---@param entity number
---@param style number? hair drawable to pick the fade for, defaults to the one currently worn
function ped.applyTattoos(entity, style)
    local male = ped.gender(entity) == "male"

    ClearPedDecorations(entity)

    if config.automaticFade then
        worn[HAIR_ZONE] = {}

        applyFade(entity, style or GetPedDrawableVariation(entity, HAIR_COMPONENT))
    elseif hairFade ~= NO_FADE then
        worn[HAIR_ZONE] = {}

        applyFade(entity, hairFade)
    end

    for zone in pairs(worn) do
        for i = 1, #worn[zone] do
            addTattoo(entity, worn[zone][i], male)
        end
    end
end

---@param entity number
---@param list PedTattoos
function ped.setTattoos(entity, list)
    worn = list or {}

    ped.applyTattoos(entity)
end

---@param entity number
---@param list PedTattoos
---@param tattoo Tattoo
function ped.previewTattoo(entity, list, tattoo)
    local male = ped.gender(entity) == "male"

    ClearPedDecorations(entity)
    addTattoo(entity, tattoo, male)

    for zone in pairs(list) do
        for i = 1, #list[zone] do
            local other = list[zone][i]

            if other.name ~= tattoo.name then
                addTattoo(entity, other, male)
            end
        end
    end

    if config.automaticFade then
        applyFade(entity, GetPedDrawableVariation(entity, HAIR_COMPONENT))
    elseif hairFade ~= NO_FADE then
        applyFade(entity, hairFade)
    end
end

---@param entity number
---@return PedHair
function ped.getHair(entity)
    return {
        style = GetPedDrawableVariation(entity, HAIR_COMPONENT),
        color = GetPedHairColor(entity),
        highlight = GetPedHairHighlightColor(entity),
        texture = GetPedTextureVariation(entity, HAIR_COMPONENT),
        fade = hairFade
    }
end

---@param entity number
---@param value PedHair
function ped.setHair(entity, value)
    SetPedComponentVariation(entity, HAIR_COMPONENT, value.style, value.texture, 0)
    SetPedHairTint(entity, value.color, value.highlight)

    hairFade = value.fade or NO_FADE

    if ped.isFreemode(entity) then
        ped.applyTattoos(entity, value.style)
    end
end

---@param entity number
---@return PedAppearance
function ped.get(entity)
    return {
        model = ped.getModel(entity),
        headBlend = ped.getHeadBlend(entity),
        faceFeatures = ped.getFaceFeatures(entity),
        headOverlays = ped.getHeadOverlays(entity),
        components = ped.getComponents(entity),
        props = ped.getProps(entity),
        hair = ped.getHair(entity),
        tattoos = ped.getTattoos(),
        eyeColor = ped.getEyeColor(entity)
    }
end

---@param entity number
---@param appearance PedAppearance
function ped.apply(entity, appearance)
    if appearance.components then ped.setComponents(entity, appearance.components) end
    if appearance.props then ped.setProps(entity, appearance.props) end
    if appearance.headBlend then ped.setHeadBlend(entity, appearance.headBlend) end
    if appearance.faceFeatures then ped.setFaceFeatures(entity, appearance.faceFeatures) end
    if appearance.headOverlays then ped.setHeadOverlays(entity, appearance.headOverlays) end
    if appearance.eyeColor then ped.setEyeColor(entity, appearance.eyeColor) end

    worn = appearance.tattoos or {}

    if appearance.hair then
        ped.setHair(entity, appearance.hair)
    else
        ped.applyTattoos(entity)
    end
end

---@param entity number
---@param list PedComponent[]?
local function preloadComponents(entity, list)
    if not list then return end

    local freemode = ped.isFreemode(entity)

    for i = 1, #list do
        local component = list[i]

        if not (freemode and LOCKED_COMPONENTS[component.component_id]) then
            SetPedPreloadVariationData(entity, component.component_id, component.drawable, component.texture)
        end
    end

    local deadline = GetGameTimer() + PRELOAD_TIMEOUT

    while DoesEntityExist(entity) and not HasPedPreloadVariationDataFinished(entity) and GetGameTimer() < deadline do
        Wait(0)
    end
end

---@param appearance PedAppearance
---@return number entity
function ped.applyToPlayer(appearance, force)
    local entity = ped.setModel(appearance.model, force)

    preloadComponents(entity, appearance.components)

    local current = cache.ped

    ped.apply(current, appearance)

    if DoesEntityExist(entity) then
        ReleasePedPreloadVariationData(entity)
    end

    return current
end

return ped
