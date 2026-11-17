local blacklist = require "server.blacklist"
local peds = require "server.peds"
local halfped = require "server.halfped"
local events = require "modules.events"

local sync = {}

local function ready()
    while not (blacklist.loaded() and peds.loaded() and halfped.loaded()) do
        Wait(50)
    end
end

---@param source number
function sync.push(source)
    CreateThread(function()
        ready()

        blacklist.publish(source)
        peds.publish(source)
        halfped.publish(source)
    end)
end

function sync.pushAll()
    local players = GetPlayers()

    for i = 1, #players do
        local target = tonumber(players[i])

        if target then sync.push(target) end
    end
end

events.on("playerLoaded", sync.push)

CreateThread(function()
    ready()
    sync.pushAll()
end)

return sync
