local config = require "config.menu"
local editor = require "core.editor"
local shops = require "features.shops"
local clothing = require "features.clothing"

local COOLDOWN = 5000
local CRUTCH_MODEL = `crutch`

local lastUse = 0

---@return boolean
local function busy()
    return editor.active()
        or GetGameTimer() - lastUse < COOLDOWN
        or cache.vehicle
        or IsPedFalling(cache.ped)
end

local handlers = {}

function handlers.reloadskin()
    if busy() then
        return lib.notify({ description = locale("commands.busy"), type = "error" })
    end

    lastUse = GetGameTimer()

    editor.load()
end

function handlers.clearstuckprops()
    if busy() then
        return lib.notify({ description = locale("commands.busy"), type = "error" })
    end

    lastUse = GetGameTimer()

    local objects = GetGamePool("CObject")
    local keepCrutch = LocalPlayer.state.healing_progress

    for i = 1, #objects do
        local object = objects[i]
        local isProtected = keepCrutch and GetEntityModel(object) == CRUTCH_MODEL

        if not isProtected and IsEntityAttachedToEntity(cache.ped, object) then
            SetEntityAsMissionEntity(object, true, true)
            DeleteEntity(object)
        end
    end
end

---@return table
local function fullMenu()
    local menu = table.clone(config.default)

    menu.ped = true
    menu.headBlend = true
    menu.faceFeatures = true
    menu.headOverlays = true
    menu.components = true
    menu.props = true
    menu.tattoos = true

    return menu
end

---@param menuType string?
function handlers.pedmenu(menuType)
    if editor.active() then return end

    local menu = menuType and shops.menu(menuType) or fullMenu()

    shops.clear()
    editor.open(menu)
end

function handlers.appearanceadmin()
    if editor.active() then return end

    local menu = table.clone(config.default)

    menu.admin = true

    shops.clear()
    editor.open(menu)
end

---@param itemName string
function handlers.clothing(itemName)
    if editor.active() then return end

    clothing.toggle(itemName, true)
end

function handlers.clothingreset()
    if editor.active() then return end

    clothing.reset(true)
end

RegisterNetEvent("rhd_appearance:command", function(name, data)
    if source == '' then return end
    local handler = handlers[name]

    if handler then handler(data) end
end)

return handlers
