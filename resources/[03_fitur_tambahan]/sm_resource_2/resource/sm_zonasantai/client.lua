local config = localmodule 'config'
local exportWrapper = require 'export_wrapper'
local infoui = exports.rhd_infoui

local Wait = Wait
local DisableControlAction = DisableControlAction
local DisablePlayerFiring = DisablePlayerFiring

local INFO_ID = 'sm_zonasantai'
local INTERVAL = config.interval * 1000
local CONTROL_RELOAD, CONTROL_JUMP, CONTROL_MELEE = 45, 22, 140

---@type table?
local currentZone
local relaxToken = 0

local function startRelaxTimer()
    relaxToken = relaxToken + 1
    local token = relaxToken

    CreateThread(function()
        while token == relaxToken do
            Wait(INTERVAL)
            if token ~= relaxToken or not currentZone then break end
            TriggerTokenEvent('sm_zonasantai:relax')
        end
    end)
end

---@param zone table
local function enterZone(zone)
    currentZone = zone
    infoui:show({ id = INFO_ID, title = 'Zona Santai', icon = 'fa-solid fa-leaf', description = zone.name })
    startRelaxTimer()
end

---@param zone table
local function exitZone(zone)
    if currentZone ~= zone then return end
    currentZone = nil
    relaxToken = relaxToken + 1
    infoui:remove(INFO_ID)
end

for i = 1, #config.zones do
    local zone = config.zones[i]
    local noJump, noFire = zone.noJump, zone.noFire

    lib.zones.poly({
        points = zone.points,
        thickness = zone.thickness,
        onEnter = function() enterZone(zone) end,
        onExit = function() exitZone(zone) end,
        inside = function()
            DisableControlAction(0, CONTROL_RELOAD, true)
            if noJump then
                DisableControlAction(0, CONTROL_JUMP, true)
            end
            if noFire then
                DisableControlAction(0, CONTROL_MELEE, true)
                DisablePlayerFiring(cache.playerId, true)
            end
        end,
    })
end

exportWrapper('sm_sidejob', 'isInsidePrier', function()
    return currentZone ~= nil
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == cache.resource and currentZone then
        infoui:remove(INFO_ID)
    end
end)
