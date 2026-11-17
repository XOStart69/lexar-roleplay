local blacklist = require "server.blacklist"
local peds = require "server.peds"
local halfped = require "server.halfped"
local pedsCatalogue = require "server.catalogue"
local sync = require "server.sync"
local config = require "config.general"
local halfpedConfig = require "config.halfped"
local Net = require "modules.net"

local EVENT = "rhd_appearance:admin:data"

local admin = {}

---@param source number
---@return boolean
local function isAdmin(source)
    return IsPlayerAceAllowed(source, config.adminAce)
end

---@return table
local function snapshot()
    return {
        allowed = true,
        entries = blacklist.entries(),
        blacklistSync = blacklist.syncState(),
        peds = peds.snapshot(),
        pedCatalogue = pedsCatalogue.all(),
        halfPeds = halfped.all(),
        access = halfped.allAccess(),
        disabledFace = halfpedConfig.disabledFace
    }
end

---@param source number
---@return boolean sent
function admin.push(source)
    if not isAdmin(source) then return false end

    Net.emitLatentClient(EVENT, source, snapshot())

    return true
end

---@param name string
---@param handler fun(source: number, data: any): any
local function action(name, handler)
    lib.callback.register(name, function(source, data)
        if not isAdmin(source) then return false end

        local result = handler(source, data)

        if result then
            admin.push(source)
            sync.push(source)
        end

        return result
    end)
end

action("rhd_appearance:admin:blacklist:save", function(_, entry)
    if not blacklist.validEntry(entry) then return false end

    return blacklist.save(entry)
end)

action("rhd_appearance:admin:blacklist:delete", function(_, id)
    if type(id) ~= "number" then return false end

    blacklist.remove(id)

    return true
end)

action("rhd_appearance:admin:blacklist:sync", function()
    return blacklist.sync()
end)

action("rhd_appearance:admin:peds:save", function(_, rule)
    if not peds.validRule(rule) then return false end

    return peds.save(rule)
end)

action("rhd_appearance:admin:peds:delete", function(_, id)
    if type(id) ~= "number" then return false end

    peds.remove(id)

    return true
end)

action("rhd_appearance:admin:peds:sync", function()
    return peds.sync()
end)

action("rhd_appearance:admin:catalogue:save", function(_, list)
    return pedsCatalogue.save(list)
end)

action("rhd_appearance:admin:halfped:register", function(_, data)
    if not halfped.validPed(data) then return false end

    return halfped.register(data)
end)

action("rhd_appearance:admin:halfped:remove", function(_, id)
    if type(id) ~= "number" then return false end

    halfped.remove(id)

    return true
end)

action("rhd_appearance:admin:halfped:grant", function(_, data)
    if not halfped.validGrant(data) then return false end

    return halfped.grant(data)
end)

action("rhd_appearance:admin:halfped:revoke", function(_, id)
    if type(id) ~= "number" then return false end

    halfped.revoke(id)

    return true
end)

return admin
