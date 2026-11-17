local config = require "config.menu"
local ped = require "core.ped"
local editor = require "core.editor"
local shops = require "features.shops"

local character = {}

---@param gender string
local function applyInitialClothes(gender)
    local preset = config.newCharacter.clothes[gender]

    if not preset then return end

    local entity = preset.model and ped.setModel(preset.model) or cache.ped

    ped.setComponents(entity, preset.components or {})
    ped.setProps(entity, preset.props or {})

    if preset.hair then
        ped.setHair(entity, preset.hair)
    end
end

---@return boolean isolated
local function isolate()
    if not config.newCharacter.routingBucket then return false end

    return lib.callback.await("rhd_appearance:character:isolate", false) == true
end

---@param isolated boolean
local function restore(isolated)
    if isolated then
        lib.callback.await("rhd_appearance:character:restore", false)
    end
end

---@return table
local function createMenu()
    local menu = table.clone(config.default)

    for key, value in pairs(config.newCharacter.menu) do
        menu[key] = value
    end

    return menu
end

local function waitForSpot()
    local duration = config.newCharacter.countdown

    if not duration or duration <= 0 then return end

    SendNuiMessage(json.encode({
        action = "character_countdown",
        data = { duration = duration }
    }))

    Wait(duration)

    SendNuiMessage(json.encode({
        action = "character_countdown_hide",
        data = {}
    }))
end

---@param gender string?
---@param onSubmit fun()?
---@param onCancel fun()?
function character.create(gender, onSubmit, onCancel)
    if editor.active() then return end

    gender = gender or Framework.GetGender()

    waitForSpot()

    applyInitialClothes(gender)
    shops.clear()

    local isolated = isolate()

    editor.open(createMenu(), function(appearance)
        restore(isolated)

        if appearance then
            if onSubmit then onSubmit() end
        elseif onCancel then
            onCancel()
        end

        return true
    end)
end

return character
