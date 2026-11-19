local events = require "modules.events"
local Net = require "modules.net"

require "server.storage.main"
require "server.storage.state"
require "server.storage.blacklist"
require "server.storage.peds"
require "server.storage.halfped"
require "server.storage.outfits"
require "server.validate"
require "server.blacklist"
require "server.peds"
require "server.halfped"
require "server.catalogue"
require "server.outfits"
require "server.items"
require "server.oplas"
require "server.shops"
require "server.sync"
require "server.admin"
require "server.commands"

---@type table<number, number>
local isolated = {}

---@param source number
---@return string?
local function identifier(source)
    return Framework.GetIdentifier(source)
end

lib.callback.register("rhd_appearance:getPlayerAces", function(source)
    local names = {}

    require("server.blacklist").aceNames(names)
    require("server.peds").aceNames(names)

    local aces = {}

    for name in pairs(names) do
        if IsPlayerAceAllowed(source, name) then
            aces[name] = true
        end
    end

    return aces
end)

lib.callback.register("rhd_appearance:get", function(source, model)
    local id = identifier(source)

    if not id then return end

    return Framework.GetAppearance(id, model)
end)

lib.callback.register("rhd_appearance:save", function(source, appearance)
    local id = identifier(source)

    if not id or not require("server.validate").appearance(appearance) then return false end
    if require("server.blacklist").blocks(source, appearance) then return false end

    Framework.SaveAppearance(id, appearance)

    return true
end)

lib.callback.register("rhd_appearance:character:isolate", function(source)
    if isolated[source] then return true end

    isolated[source] = GetPlayerRoutingBucket(source)

    SetPlayerRoutingBucket(source, 1000 + source)

    return true
end)

lib.callback.register("rhd_appearance:character:restore", function(source)
    local previous = isolated[source]

    if previous then
        SetPlayerRoutingBucket(source, previous)
        isolated[source] = nil
    end

    return true
end)

AddEventHandler("playerDropped", function()
    isolated[source] = nil
end)

lib.print.info("sm_appearance server siap")
