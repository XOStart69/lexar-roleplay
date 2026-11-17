local storage = require "server.storage.outfits"
local validate = require "server.validate"
local peds = require "server.peds"
local blacklist = require "server.blacklist"
local config = require "config.outfits"

local CODE_PATTERN = "...."

local outfits = {}

---@param source number
---@return string?
local function identifierOf(source)
    return Framework.GetIdentifier(source)
end

---@return string
local function uniqueCode()
    local code

    repeat
        code = lib.string.random(CODE_PATTERN, config.codeLength)
    until not storage.byCode(code)

    return code
end

---@param identifier string
---@param name string
---@param outfit table
---@return boolean
local function copyOutfit(identifier, name, outfit)
    local components = json.decode(outfit.components)
    local props = json.decode(outfit.props)

    return storage.add(identifier, name, outfit.model, components, props) ~= nil
end

function outfits.get(source)
    local identifier = identifierOf(source)

    if not identifier then return {} end

    return storage.all(identifier)
end

function outfits.save(source, name, model, components, props)
    local identifier = identifierOf(source)

    if not identifier
        or not validate.outfitName(name)
        or not validate.model(model)
        or not peds.saveable(source, model)
        or not validate.slots(components, "component_id")
        or not validate.slots(props, "prop_id")
        or blacklist.blocks(source, { model = model, components = components, props = props }) then
        return false
    end

    if storage.byName(identifier, name) then return false end

    return storage.add(identifier, name, model, components, props) ~= nil
end

function outfits.update(source, id, model, components, props)
    local identifier = identifierOf(source)

    if not identifier
        or type(id) ~= "number"
        or not validate.model(model)
        or not peds.saveable(source, model)
        or not validate.slots(components, "component_id")
        or not validate.slots(props, "prop_id")
        or blacklist.blocks(source, { model = model, components = components, props = props }) then
        return false
    end

    local outfit = storage.byId(id)

    if not outfit or outfit.citizenid ~= identifier then return false end

    storage.update(id, model, components, props)

    return true
end

function outfits.remove(source, id)
    local identifier = identifierOf(source)

    if not identifier or type(id) ~= "number" then return false end

    local outfit = storage.byId(id)

    if not outfit or outfit.citizenid ~= identifier then return false end

    storage.delete(id)

    return true
end

function outfits.generateCode(source, id)
    local identifier = identifierOf(source)

    if not identifier or type(id) ~= "number" then return end

    local outfit = storage.byId(id)

    if not outfit or outfit.citizenid ~= identifier then return end

    local existing = storage.codeOf(id)

    if existing then return existing.code end

    local code = uniqueCode()

    return storage.addCode(id, code) and code or nil
end

function outfits.import(source, name, code)
    local identifier = identifierOf(source)

    if not identifier or not validate.outfitName(name) or type(code) ~= "string" then return false end

    local entry = storage.byCode(code)

    if not entry then return false end

    local outfit = storage.byId(entry.outfitid)

    if not outfit then return false end

    if outfit.citizenid == identifier then return false end
    if storage.byName(identifier, name) then return false end

    return copyOutfit(identifier, name, outfit)
end

for name, fn in pairs(outfits) do
    lib.callback.register("rhd_appearance:outfits:" .. (name == "remove" and "delete" or name), fn)
end

return outfits
