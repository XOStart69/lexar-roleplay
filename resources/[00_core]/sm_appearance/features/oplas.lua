local config = require "config.menu"
local editor = require "core.editor"
local shops = require "features.shops"

local oplas = {}

---@return table
local function menu()
    local conf = table.clone(config.default)

    conf.ped = true
    conf.headBlend = true
    conf.faceFeatures = true
    conf.headOverlays = true
    conf.components = true
    conf.props = true

    return conf
end

---@return boolean
local function busy()
    return editor.active()
        or cache.vehicle and true
        or IsPedFalling(cache.ped)
        or IsPedRagdoll(cache.ped)
        or IsPedDeadOrDying(cache.ped, true)
end

---@return boolean saved
function oplas.open()
    if busy() then
        lib.notify({ description = locale("oplas.busy"), type = "error" })

        return false
    end

    local conf = menu()

    local done = promise.new()
    local settled = false
    local opened = false

    ---@param saved boolean
    local function settle(saved)
        if settled then return end

        settled = true

        done:resolve(saved)
    end

    shops.clear()

    CreateThread(function()
        editor.open(conf, function(appearance)
            opened = true

            settle(appearance ~= nil)

            return appearance ~= nil
        end)

        if not editor.active() and not opened then
            settle(false)
        end
    end)

    return Citizen.Await(done)
end

return oplas
