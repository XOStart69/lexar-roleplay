local storage = require "server.storage.peds"
local state = require "server.storage.state"
local validate = require "server.validate"
local cache = require "modules.cache"
local Net = require "modules.net"
local pedConfig = require "config.peds"

local SECTION = "peds"
local EVENT = "rhd_appearance:peds:data"

local ALL = "*"

local store = cache.new({ update = storage.update, remove = storage.remove })
local imported = false
local loaded = false

local peds = {}

---@return boolean
function peds.loaded()
    return loaded
end

---@param rule table
---@return boolean
local function unconditional(rule)
    return not (rule.jobs or rule.gangs or rule.aces or rule.identifiers)
end

---@param rule table
---@param model string
---@return boolean
local function covers(rule, model)
    local list = rule.models

    if #list == 1 and list[1] == ALL then return true end

    for i = 1, #list do
        if list[i] == model then return true end
    end

    return false
end

---@param fn fun(rule: table)
local function eachRule(fn)
    if not imported then
        local groups = pedConfig.groups

        for i = 1, #groups do
            fn(groups[i])
        end
    end

    local rows = store:all()

    for i = 1, #rows do
        fn(rows[i])
    end
end

---@param rule table
---@return string
local function fingerprint(rule)
    return json.encode({
        rule.label or "",
        rule.models,
        rule.jobs or false,
        rule.gangs or false,
        rule.aces or false,
        rule.identifiers or false
    })
end

---@param value any
---@return boolean
local function validModels(value)
    if type(value) ~= "table" or #value == 0 or #value > 2048 then return false end

    for i = 1, #value do
        local model = value[i]

        if model ~= ALL and not validate.model(model) then return false end
    end

    return true
end

---@param value any
---@return boolean
function peds.validRule(value)
    return type(value) == "table"
        and (value.label == nil or type(value.label) == "string" and #value.label <= 50)
        and validModels(value.models)
        and validate.requireJobs(value.jobs)
        and validate.requireJobs(value.gangs)
        and validate.strings(value.aces, 32)
        and validate.strings(value.identifiers, 64)
end

local function reload()
    store:load(storage.all())
    imported = state.synced()[SECTION] == true
    loaded = true
end

---@return PedGroup[]
local function pending()
    local seen = {}
    local rows = store:all()

    for i = 1, #rows do
        seen[fingerprint(rows[i])] = true
    end

    local groups = pedConfig.groups
    local missing = {}

    for i = 1, #groups do
        local group = groups[i]

        if not seen[fingerprint(group)] then
            missing[#missing + 1] = group
        end
    end

    return missing
end

---@param into table<string, true>
function peds.aceNames(into)
    eachRule(function(rule)
        local aces = rule.aces

        for i = 1, aces and #aces or 0 do
            into[aces[i]] = true
        end
    end)
end

---@return table
function peds.snapshot()
    return {
        mode = pedConfig.mode,
        rules = store:all(),
        imported = imported,
        pending = #pending()
    }
end

---@param source number
---@param rule table
---@return boolean
local function unlockedFor(source, rule)
    if rule.jobs and Framework.playerHoldsJob(source, rule.jobs) then return true end
    if rule.gangs and Framework.playerHoldsGang(source, rule.gangs) then return true end

    if rule.aces then
        for i = 1, #rule.aces do
            if IsPlayerAceAllowed(source --[[@as string]], rule.aces[i]) then return true end
        end
    end

    if rule.identifiers then
        local identifier = Framework.GetIdentifier(source)

        if identifier then
            for i = 1, #rule.identifiers do
                if rule.identifiers[i] == identifier then return true end
            end
        end
    end

    return false
end

---@param source number
---@param model string
---@return boolean
function peds.saveable(source, model)
    local allow = pedConfig.mode ~= "blacklist"
    local hit = false

    eachRule(function(rule)
        if hit then return end

        local holds = unconditional(rule) or unlockedFor(source, rule)

        if holds == allow and covers(rule, model) then hit = true end
    end)

    return allow == hit
end

---@return table
local function payload()
    local rows = store:all()
    local rules = table.create(#rows, 0)

    for i = 1, #rows do
        local rule = rows[i]

        rules[i] = {
            models = rule.models,
            jobs = rule.jobs,
            gangs = rule.gangs,
            aces = rule.aces,
            identifiers = rule.identifiers
        }
    end

    return { mode = pedConfig.mode, rules = rules, imported = imported }
end

---@param source number
function peds.publish(source)
    Net.emitLatentClient(EVENT, source, payload())
end

---@param rule PedRule
---@return boolean
function peds.save(rule)
    if rule.id then
        if type(rule.id) ~= "number" or not store:find(rule.id) then return false end

        store:update(rule.id, rule)

        return true
    end

    store:beforeInsert()

    local id = storage.insert(rule)

    if not id then return false end

    rule.id = id
    store:insert(rule)

    return true
end

---@param id number
function peds.remove(id)
    store:remove(id)
end

---@return { added: number }
function peds.sync()
    local missing = pending()

    store:beforeInsert()

    for i = 1, #missing do
        local rule = missing[i]
        local id = storage.insert(rule)

        if id then
            store:insert({
                id = id,
                label = rule.label,
                models = rule.models,
                jobs = rule.jobs,
                gangs = rule.gangs,
                aces = rule.aces,
                identifiers = rule.identifiers
            })
        end
    end

    state.mark(SECTION)

    imported = true

    return { added = #missing }
end

CreateThread(reload)

return peds
