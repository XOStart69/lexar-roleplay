local config = require "config.blacklist"
local shared = require "config.general"
local pedConfig = require "config.peds"
local constants = require "data.constants"
local catalogue = require "data.tattoos"
local pedModels = require "data.peds"
local ped = require "core.ped"
local halfped = require "features.halfped"
local items = require "modules.items"
local wardrobe = require "features.items"
local Net = require "modules.net"

local HAIR_COMPONENT = 2
local DECAL_COMPONENT = 10

local GENDER_BY_MODEL = {
    [shared.freemodeModels.male] = "male",
    [shared.freemodeModels.female] = "female"
}

local COMPONENT_SLOTS = {}
local PROP_SLOTS = {}

for name, slot in pairs(constants.SLOTS) do
    if slot.category == "components" then
        COMPONENT_SLOTS[slot.id] = name
    else
        PROP_SLOTS[slot.id] = name
    end
end

local HEAD_BLEND_FIELDS = {
    "shapeFirst", "shapeSecond", "shapeThird",
    "skinFirst", "skinSecond", "skinThird",
    "shapeMix", "skinMix", "thirdMix"
}

local HAIR_COLORED = { beard = true, eyebrows = true, chestHair = true }
local MAKEUP_COLORED = { makeUp = true, blush = true, lipstick = true }

local RANGES = constants.RANGES

---@param group table<string, RangeSetting>
---@param names string[]
---@return table<string, RangeSetting>
local function rangesFor(group, names)
    local values = table.create(0, #names)

    for i = 1, #names do
        local name = names[i]

        values[name] = group[name] or RANGES.default
    end

    return values
end

local HEAD_BLEND = rangesFor(RANGES.headBlend, HEAD_BLEND_FIELDS)
local FACE_FEATURES = rangesFor(RANGES.faceFeatures, constants.FACE_FEATURES)

---@type string[]?
local allowedAces

---@type table<string, BlacklistEntry[]>?
local stored

---@type { hair: number[][], makeUp: number[][] }?
local palette

---@type string[]?
local allowedModels

---@type { mode: string, rules: PedRule[], imported: boolean }?
local pedRules

---@type { entries: table<string, BlacklistEntry[]>, imported: boolean }?
local blacklistData

---@type { mode: string, rules: PedRule[], imported: boolean }?
local pedData

local configImported = false

local EMPTY = {}

local settings = {}

RegisterNetEvent("rhd_appearance:blacklist:data", function(data)
    if source == '' then return end

    blacklistData = data
    stored = nil
end)

RegisterNetEvent("rhd_appearance:peds:data", function(data)
    if source == '' then return end

    pedData = data
    pedRules = nil
    allowedModels = nil
end)

---@return table<string, BlacklistEntry[]>
local function storedEntries()
    if stored then return stored end

    local data = Net.awaitPush(function() return blacklistData end)

    if not data then return EMPTY end

    stored = data.entries or EMPTY
    configImported = data.imported == true

    return stored
end

---@param gender string
---@param category string
---@param slot string
---@return BlacklistEntry[]
local function entriesFor(gender, category, slot)
    local extra = storedEntries()[gender .. "/" .. category .. "/" .. slot]
    local group = not configImported and config[gender] or EMPTY
    local base = (category == "hair" and group.hair or group[category] and group[category][slot]) or EMPTY
    local owned = category ~= "hair" and items.entries(gender, slot) or nil

    if not extra and not owned then return base end

    local result = table.create(#base + (extra and #extra or 0) + (owned and #owned or 0), 0)

    table.move(base, 1, #base, 1, result)

    if extra then
        table.move(extra, 1, #extra, #result + 1, result)
    end

    if owned then
        table.move(owned, 1, #owned, #result + 1, result)
    end

    return result
end

---@return string[]
local function aces()
    if not allowedAces then
        allowedAces = lib.callback.await("rhd_appearance:getPlayerAces", false) or {}
    end

    return allowedAces
end

---@param list any[]
---@param value any
---@return boolean
local function contains(list, value)
    for i = 1, #list do
        if list[i] == value then return true end
    end

    return false
end

---@param list any[]
---@param values any[]
---@return boolean
local function containsAny(list, values)
    for i = 1, #list do
        if contains(values, list[i]) then return true end
    end

    return false
end

---@param entry BlacklistEntry
---@return boolean
local function unlocked(entry)
    local state = Framework.getState()

    if entry.jobs and Framework.holdsJob(entry.jobs) then return true end
    if entry.gangs and Framework.holdsGang(entry.gangs) then return true end
    if entry.aces and containsAny(entry.aces, aces()) then return true end
    local ids = entry.identifiers or entry.citizenids

    if ids and state.identifier and contains(ids, state.identifier) then return true end

    return false
end

---@return BlacklistSettings
local function noBlacklist()
    return { drawables = {}, textures = {} }
end

---@param entries BlacklistEntry[]
---@param drawable number
---@return BlacklistSettings
local function blacklistOf(entries, drawable)
    local result = noBlacklist()

    for i = 1, #entries do
        local entry = entries[i]

        if not unlocked(entry) and entry.drawables then
            local restrictsTextures = entry.textures and #entry.textures > 0

            for j = 1, #entry.drawables do
                local blocked = entry.drawables[j]

                if not restrictsTextures then
                    result.drawables[#result.drawables + 1] = blocked
                elseif blocked == drawable then
                    for k = 1, #entry.textures do
                        result.textures[#result.textures + 1] = entry.textures[k]
                    end
                end
            end
        end
    end

    return result
end

---@param blacklist BlacklistSettings
---@param componentId number
---@param gender string
local function appendHalfPedBlacklist(blacklist, componentId, gender)
    if componentId ~= DECAL_COMPONENT then return end

    local blocked = halfped.blockedDecals(gender)

    for i = 1, #blocked do
        blacklist.drawables[#blacklist.drawables + 1] = blocked[i]
    end
end

---@param gender string
---@return table<string, RangeSetting>
local function headBlendFor(gender)
    local face = halfped.disabledFace(gender)

    if not face or halfped.hasAnyAccess(gender) then return HEAD_BLEND end

    local values = table.create(0, #HEAD_BLEND_FIELDS)

    for i = 1, #HEAD_BLEND_FIELDS do
        local name = HEAD_BLEND_FIELDS[i]
        local range = HEAD_BLEND[name]

        if face >= range.min and face <= range.max then
            values[name] = { min = range.min, max = range.max, factor = range.factor, blacklist = { face } }
        else
            values[name] = range
        end
    end

    return values
end

---@return { hair: number[][], makeUp: number[][] }
local function colors()
    if not palette then
        palette = { hair = {}, makeUp = {} }

        for i = 0, GetNumHairColors() - 1 do
            palette.hair[i + 1] = { GetPedHairRgbColor(i) }
        end

        for i = 0, GetNumMakeupColors() - 1 do
            palette.makeUp[i + 1] = { GetPedMakeupRgbColor(i) }
        end
    end

    return palette
end

---@return table
local function headOverlays()
    local items = colors()
    local overlays = constants.HEAD_OVERLAYS
    local values = table.create(0, #overlays)

    for i = 1, #overlays do
        local name = overlays[i]

        values[name] = {
            style = { min = 0, max = GetPedHeadOverlayNum(i - 1) - 1 },
            opacity = RANGES.overlayOpacity
        }

        if HAIR_COLORED[name] then
            values[name].color = { items = items.hair }
        elseif MAKEUP_COLORED[name] then
            values[name].color = { items = items.makeUp }
        end
    end

    return values
end

---@param entity number
---@return table
local function tattoos(entity)
    local key = ped.gender(entity) == "male" and "hashMale" or "hashFemale"
    local items = {}

    for zone, list in pairs(catalogue) do
        items[zone] = {}

        for i = 1, #list do
            if list[i][key] ~= "" then
                items[zone][#items[zone] + 1] = list[i]
            end
        end
    end

    return { items = items, opacity = RANGES.tattooOpacity }
end

---@param entry table
---@return boolean
local function unconditional(entry)
    return not (entry.jobs or entry.gangs or entry.aces or entry.identifiers)
end

---@return { mode: string, rules: PedRule[], imported: boolean }
local function pedState()
    if not pedRules then
        pedRules = Net.awaitPush(function() return pedData end)
            or { mode = pedConfig.mode, rules = EMPTY, imported = false }
    end

    return pedRules
end

---@return string[]
local function models()
    if allowedModels then return allowedModels end

    local state = pedState()
    local allow = state.mode ~= "blacklist"
    local rules = state.rules or EMPTY
    local groups = state.imported and EMPTY or pedConfig.groups
    local touched = {}
    local everything = false

    local function collect(rule)
        ---@diagnostic disable-next-line: param-type-mismatch
        local holds = unconditional(rule) or unlocked(rule)

        if holds ~= allow then return end

        local list = rule.models

        if #list == 1 and list[1] == "*" then
            everything = true

            return
        end

        for i = 1, #list do
            touched[list[i]] = true
        end
    end

    for i = 1, #groups do collect(groups[i]) end
    for i = 1, #rules do collect(rules[i]) end

    allowedModels = {}

    if allow and everything then
        table.move(pedModels, 1, #pedModels, 1, allowedModels)

        return allowedModels
    end

    if allow then
        for i = 1, #pedModels do
            if touched[pedModels[i]] then
                allowedModels[#allowedModels + 1] = pedModels[i]
            end
        end

        return allowedModels
    end

    if everything then return allowedModels end

    for i = 1, #pedModels do
        if not touched[pedModels[i]] then
            allowedModels[#allowedModels + 1] = pedModels[i]
        end
    end

    return allowedModels
end

---@param entity number
---@param componentId number
---@return table
function settings.component(entity, componentId)
    local drawable = GetPedDrawableVariation(entity, componentId)
    local slot = COMPONENT_SLOTS[componentId]
    local gender = ped.gender(entity)
    local freemode = ped.isFreemode(entity)

    local blacklist = slot and freemode
        and blacklistOf(entriesFor(gender, "components", slot), drawable)
        or noBlacklist()

    appendHalfPedBlacklist(blacklist, componentId, gender)

    return {
        component_id = componentId,
        drawable = {
            min = 0,
            max = GetNumberOfPedDrawableVariations(entity, componentId) - 1
        },
        texture = {
            min = 0,
            max = GetNumberOfPedTextureVariations(entity, componentId, drawable) - 1
        },
        blacklist = blacklist,
        locked = slot ~= nil and wardrobe.holds(slot)
    }
end

---@param entity number
---@param propId number
---@return table
function settings.prop(entity, propId)
    local drawable = GetPedPropIndex(entity, propId)
    local slot = PROP_SLOTS[propId]

    return {
        prop_id = propId,
        drawable = {
            min = -1,
            max = GetNumberOfPedPropDrawableVariations(entity, propId) - 1
        },
        texture = {
            min = -1,
            max = GetNumberOfPedPropTextureVariations(entity, propId, drawable) - 1
        },
        blacklist = slot and ped.isFreemode(entity)
            and blacklistOf(entriesFor(ped.gender(entity), "props", slot), drawable)
            or noBlacklist(),
        locked = slot ~= nil and wardrobe.holds(slot)
    }
end

---@type table<string, number>
local fadeCeiling = {}

---@param gender string
---@return number
local function hairFadeMax(gender)
    local cached = fadeCeiling[gender]

    if cached then return cached end

    local highest = -1

    for index in pairs(constants.HAIR_DECORATIONS[gender] or EMPTY) do
        if index > highest then highest = index end
    end

    fadeCeiling[gender] = highest

    return highest
end

---@class HairBlacklist
---@field drawables number[]
---@field textures table<string, number[]>

---@param blocked HairBlacklist
---@param style number
---@return BlacklistSettings
local function hairBlacklistFor(blocked, style)
    return {
        drawables = blocked.drawables or {},
        textures = blocked.textures and blocked.textures[tostring(style)] or {}
    }
end

---@param entity number
---@param style number?
---@param blocked HairBlacklist?
---@return table
function settings.hair(entity, style, blocked)
    local items = colors()

    style = style or GetPedDrawableVariation(entity, HAIR_COMPONENT)

    local blacklist

    if blocked then
        blacklist = hairBlacklistFor(blocked, style)
    elseif ped.isFreemode(entity) then
        blacklist = blacklistOf(entriesFor(ped.gender(entity), "hair", ""), style)
    else
        blacklist = noBlacklist()
    end

    return {
        style = {
            min = 0,
            max = GetNumberOfPedDrawableVariations(entity, HAIR_COMPONENT) - 1
        },
        color = { items = items.hair },
        highlight = { items = items.hair },
        texture = {
            min = 0,
            max = GetNumberOfPedTextureVariations(entity, HAIR_COMPONENT, style) - 1
        },
        fade = {
            min = -1,
            max = hairFadeMax(ped.gender(entity))
        },
        blacklist = blacklist
    }
end

---@param entity number
---@return HairBlacklist
function settings.hairBlacklist(entity)
    local result = { drawables = {}, textures = {} }

    if not ped.isFreemode(entity) then return result end

    local entries = entriesFor(ped.gender(entity), "hair", "")

    for i = 1, #entries do
        local entry = entries[i]

        if not unlocked(entry) and entry.drawables then
            local restrictsTextures = entry.textures and #entry.textures > 0

            for j = 1, #entry.drawables do
                local blocked = entry.drawables[j]

                if restrictsTextures then
                    local key = tostring(blocked)
                    local list = result.textures[key] or {}

                    for k = 1, #entry.textures do
                        list[#list + 1] = entry.textures[k]
                    end

                    result.textures[key] = list
                else
                    result.drawables[#result.drawables + 1] = blocked
                end
            end
        end
    end

    return result
end

---@param entity number
---@return table
function settings.all(entity)
    local components = table.create(#constants.COMPONENTS, 0)

    for i = 1, #constants.COMPONENTS do
        components[i] = settings.component(entity, constants.COMPONENTS[i])
    end

    local props = table.create(#constants.PROPS, 0)

    for i = 1, #constants.PROPS do
        props[i] = settings.prop(entity, constants.PROPS[i])
    end

    return {
        ped = { model = { items = models() } },
        components = components,
        props = props,
        headBlend = headBlendFor(ped.gender(entity)),
        faceFeatures = FACE_FEATURES,
        headOverlays = headOverlays(),
        hair = settings.hair(entity),
        eyeColor = RANGES.eyeColor,
        tattoos = tattoos(entity)
    }
end

function settings.reset()
    allowedAces = nil
    allowedModels = nil
    pedRules = nil
    stored = nil
end

---@param gender string
---@param category string
---@param slot string
---@param componentId number?
---@param drawable number
---@param texture number
---@return boolean drawableBlocked
---@return boolean textureBlocked
local function pieceState(gender, category, slot, componentId, drawable, texture)
    local result = blacklistOf(entriesFor(gender, category, slot), drawable)

    if componentId then
        appendHalfPedBlacklist(result, componentId, gender)
    end

    return contains(result.drawables, drawable), contains(result.textures, texture)
end

---@param gender string
---@param category string
---@param slot string
---@param componentId number?
---@param drawable number
---@param texture number
---@return boolean
local function pieceBlocked(gender, category, slot, componentId, drawable, texture)
    local drawableBlocked, textureBlocked = pieceState(gender, category, slot, componentId, drawable, texture)

    return drawableBlocked or textureBlocked
end

---@alias ClothingLook { model: string, components: PedComponent[]?, props: PedProp[]? }

---@param appearance ClothingLook
---@param handle fun(gender: string, category: string, slot: string, componentId: number?, piece: table): boolean?
---@return string? slot
local function walk(appearance, handle)
    local gender = GENDER_BY_MODEL[appearance.model]

    if not gender then return end

    local components = appearance.components or {}

    for i = 1, #components do
        local piece = components[i]
        local slot = COMPONENT_SLOTS[piece.component_id]

        if slot and handle(gender, "components", slot, piece.component_id, piece) then
            return slot
        end
    end

    local props = appearance.props or {}

    for i = 1, #props do
        local piece = props[i]
        local slot = PROP_SLOTS[piece.prop_id]

        if slot and piece.drawable >= 0 and handle(gender, "props", slot, nil, piece) then
            return slot
        end
    end
end

local SLOT_LABELS = { shirts = "shirt" }

---@param slot string
---@return string
function settings.label(slot)
    local entry = constants.SLOTS[slot]

    if not entry then return slot end

    return locale(("UI.%s.%s"):format(entry.category, SLOT_LABELS[slot] or slot))
end

---@param appearance ClothingLook
---@return string? slot
function settings.blocked(appearance)
    return walk(appearance, function(gender, category, slot, componentId, piece)
        return pieceBlocked(gender, category, slot, componentId, piece.drawable, piece.texture)
    end)
end

---@param entity number
---@param appearance ClothingLook
---@return boolean changed
function settings.repair(entity, appearance)
    local changed = false

    ---@param piece table
    ---@param drawable number
    ---@return number count
    local function textureCount(piece, drawable)
        return piece.prop_id
            and GetNumberOfPedPropTextureVariations(entity, piece.prop_id, drawable)
            or GetNumberOfPedTextureVariations(entity, piece.component_id, drawable)
    end

    walk(appearance, function(gender, category, slot, componentId, piece)
        local drawableBlocked, textureBlocked = pieceState(gender, category, slot, componentId,
            piece.drawable, piece.texture)

        if not drawableBlocked and not textureBlocked then return end

        local isProp = category == "props"

        if not drawableBlocked then
            local count = textureCount(piece, piece.drawable)

            for step = 1, count do
                local candidate = (piece.texture + step) % count
                local _, blocked = pieceState(gender, category, slot, componentId, piece.drawable, candidate)

                if not blocked then
                    piece.texture = candidate
                    changed = true

                    return
                end
            end
        end

        local count = isProp
            and GetNumberOfPedPropDrawableVariations(entity, piece.prop_id)
            or GetNumberOfPedDrawableVariations(entity, piece.component_id)

        for step = 1, count do
            local candidate = (piece.drawable + step) % count

            if not pieceState(gender, category, slot, componentId, candidate, 0) then
                piece.drawable = candidate
                piece.texture = 0
                changed = true

                for texture = 0, textureCount(piece, candidate) - 1 do
                    local _, blocked = pieceState(gender, category, slot, componentId, candidate, texture)

                    if not blocked then
                        piece.texture = texture
                        break
                    end
                end

                return
            end
        end

        piece.drawable = isProp and -1 or 0
        piece.texture = isProp and -1 or 0
        changed = true
    end)

    return changed
end

return settings
