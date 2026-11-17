local storage = require "server.storage.blacklist"
local state = require "server.storage.state"
local validate = require "server.validate"
local halfped = require "server.halfped"
local cache = require "modules.cache"
local Net = require "modules.net"
local configEntries = require "config.blacklist"
local constants = require "data.constants"
local shared = require "config.general"

local SECTION = "blacklist"
local EVENT = "rhd_appearance:blacklist:data"
local DECAL_COMPONENT = 10

local GENDERS = { male = true, female = true }
local CATEGORIES = { components = true, props = true, hair = true }

local GENDER_BY_MODEL = {
    [shared.freemodeModels.male] = "male",
    [shared.freemodeModels.female] = "female"
}

local SLOT_BY_ID = { components = {}, props = {} }

for name, slot in pairs(constants.SLOTS) do
    SLOT_BY_ID[slot.category][slot.id] = name
end

local store = cache.new({ update = storage.update, remove = storage.remove })
local imported = false
local loaded = false

local blacklist = {}

---@return boolean
function blacklist.loaded()
    return loaded
end

---@param value any
---@return boolean
local function validTextures(value)
    if value == nil then return true end
    if type(value) ~= "table" or #value > 64 then return false end

    for i = 1, #value do
        if not validate.number(value[i], 0, 255) then return false end
    end

    return true
end

---@param value any
---@return boolean
function blacklist.validEntry(value)
    return type(value) == "table"
        and GENDERS[value.gender] ~= nil
        and CATEGORIES[value.category] ~= nil
        and type(value.slot) == "string"
        and #value.slot <= 30
        and validate.number(value.drawable, 0, 4096)
        and validTextures(value.textures)
        and validate.requireJobs(value.jobs)
        and validate.requireJobs(value.gangs)
        and validate.strings(value.aces, 32)
        and validate.strings(value.citizenids, 64)
end

local function reload()
    store:load(storage.all())
    imported = state.synced()[SECTION] == true
    loaded = true
end

---@return BlacklistRow[]
local function flattenConfig()
    local flat = {}

    for gender, group in pairs(configEntries) do
        for category, slots in pairs(group) do
            local lists = category == "hair" and { [""] = slots } or slots

            for slot, entries in pairs(lists) do
                for i = 1, #entries do
                    local entry = entries[i]
                    local drawables = entry.drawables or {}

                    for j = 1, #drawables do
                        flat[#flat + 1] = {
                            gender = gender,
                            category = category,
                            slot = slot,
                            drawable = drawables[j],
                            textures = entry.textures,
                            jobs = entry.jobs,
                            gangs = entry.gangs,
                            aces = entry.aces,
                            citizenids = entry.identifiers or entry.citizenids
                        }
                    end
                end
            end
        end
    end

    return flat
end

---@param row table
---@return string
local function key(row)
    return ("%s/%s/%s/%d"):format(row.gender, row.category, row.slot, row.drawable)
end

---@return BlacklistRow[]
local function pending()
    local seen = {}
    local rows = store:all()

    for i = 1, #rows do
        seen[key(rows[i])] = true
    end

    local flat = flattenConfig()
    local missing = {}

    for i = 1, #flat do
        if not seen[key(flat[i])] then
            missing[#missing + 1] = flat[i]
        end
    end

    return missing
end

---@return BlacklistRow[]
function blacklist.entries()
    return store:all()
end

---@param into table<string, true>
function blacklist.aceNames(into)
    local rows = store:all()

    for i = 1, #rows do
        local aces = rows[i].aces

        for j = 1, aces and #aces or 0 do
            into[aces[j]] = true
        end
    end

    if imported then return end

    local flat = flattenConfig()

    for i = 1, #flat do
        local aces = flat[i].aces

        for j = 1, aces and #aces or 0 do
            into[aces[j]] = true
        end
    end
end

---@return { imported: boolean, pending: number }
function blacklist.syncState()
    return { imported = imported, pending = #pending() }
end

---@return table
local function payload()
    local rows = store:all()
    local entries = {}

    for i = 1, #rows do
        local row = rows[i]
        local key = row.gender .. "/" .. row.category .. "/" .. row.slot
        local list = entries[key]

        if not list then
            list = {}
            entries[key] = list
        end

        list[#list + 1] = {
            drawables = { row.drawable },
            textures = row.textures,
            jobs = row.jobs,
            gangs = row.gangs,
            aces = row.aces,
            identifiers = row.citizenids
        }
    end

    return { entries = entries, imported = imported }
end

---@param source number
function blacklist.publish(source)
    Net.emitLatentClient(EVENT, source, payload())
end

---@param row table
---@param source number
---@param identifier string?
---@return boolean
local function unlockedFor(row, source, identifier)
    if row.jobs and Framework.playerHoldsJob(source, row.jobs) then return true end
    if row.gangs and Framework.playerHoldsGang(source, row.gangs) then return true end

    if row.aces then
        for i = 1, #row.aces do
            if IsPlayerAceAllowed(source --[[@as string]], row.aces[i]) then return true end
        end
    end

    local ids = row.citizenids

    if ids and identifier then
        for i = 1, #ids do
            if ids[i] == identifier then return true end
        end
    end

    return false
end

---@param row table
---@param drawable number
---@param texture number
---@return boolean
local function rowBlocks(row, drawable, texture)
    if row.drawable ~= drawable then return false end

    local textures = row.textures

    if not textures or #textures == 0 then return true end

    for i = 1, #textures do
        if textures[i] == texture then return true end
    end

    return false
end

---@param gender string
---@param category string
---@param slot string
---@return table[]
local function rowsFor(gender, category, slot)
    local rows = {}
    local stored = store:all()

    for i = 1, #stored do
        local row = stored[i]

        if row.gender == gender and row.category == category and row.slot == slot then
            rows[#rows + 1] = row
        end
    end

    if imported then return rows end

    local group = configEntries[gender]

    if not group then return rows end

    ---@type BlacklistEntry[]
    local entries = (category == "hair" and group.hair or group[category] and group[category][slot]) or {}

    for i = 1, #entries do
        local entry = entries[i]
        local drawables = entry.drawables or {}

        for j = 1, #drawables do
            rows[#rows + 1] = {
                drawable = drawables[j],
                textures = entry.textures,
                jobs = entry.jobs,
                gangs = entry.gangs,
                aces = entry.aces,
                citizenids = entry.identifiers or entry.citizenids
            }
        end
    end

    return rows
end

---@param source number
---@param appearance table
---@return string? slot
function blacklist.blocks(source, appearance)
    local gender = GENDER_BY_MODEL[appearance.model]

    if not gender then return end

    local identifier = Framework.GetIdentifier(source)

    ---@param category string
    ---@param slot string
    ---@param drawable number
    ---@param texture number
    ---@return boolean
    local function blocked(category, slot, drawable, texture)
        local rows = rowsFor(gender, category, slot)

        for i = 1, #rows do
            local row = rows[i]

            if rowBlocks(row, drawable, texture) and not unlockedFor(row, source, identifier) then
                return true
            end
        end

        return false
    end

    local components = appearance.components or {}

    for i = 1, #components do
        local piece = components[i]
        local slot = SLOT_BY_ID.components[piece.component_id]

        if slot then
            if blocked("components", slot, piece.drawable, piece.texture) then return slot end

            if piece.component_id == DECAL_COMPONENT
                and halfped.blockedFor(identifier, gender, piece.drawable) then
                return slot
            end
        end
    end

    local props = appearance.props or {}

    for i = 1, #props do
        local piece = props[i]
        local slot = SLOT_BY_ID.props[piece.prop_id]

        if slot and piece.drawable >= 0 and blocked("props", slot, piece.drawable, piece.texture) then
            return slot
        end
    end
end

---@param entry BlacklistRow
---@return boolean
function blacklist.save(entry)
    if entry.id then
        if type(entry.id) ~= "number" or not store:find(entry.id) then return false end

        store:update(entry.id, entry)

        return true
    end

    store:beforeInsert()

    local id = storage.save(entry)

    if not id then return false end

    entry.id = id
    store:insert(entry)

    return true
end

---@param id number
function blacklist.remove(id)
    store:remove(id)
end

---@return { added: number }
function blacklist.sync()
    local missing = pending()

    store:beforeInsert()

    for i = 1, #missing do
        local row = missing[i]
        local id = storage.save(row)

        if id then
            row.id = id
            store:insert(row)
        end
    end

    state.mark(SECTION)

    imported = true

    return { added = #missing }
end

CreateThread(reload)

return blacklist
