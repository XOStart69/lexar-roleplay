local config = require "config.shops"
local clientConfig = require "config.editor"
local menuConfig = require "config.menu"
local ped = require "core.ped"
local editor = require "core.editor"
local outfits = require "features.outfits"
local menuUI = require "features.menu"

local INTERACT_KEY = 38
local INFO_ID = "sm_appearance"
local DEFAULT_ICON = "fa-solid fa-shirt"

local SECTIONS = {
    clothing = { components = true, props = true },
    barber = { headOverlays = true },
    tattoo = { tattoos = true },
    surgeon = { headBlend = true, faceFeatures = true }
}

local shops = {}

---@param shopType string
---@return table?
function shops.menu(shopType)
    local sections = SECTIONS[shopType]

    if not sections then return end

    local menu = table.clone(menuConfig.default)

    for key, value in pairs(sections) do
        menu[key] = value
    end

    return menu
end

---@type { kind: string, index: number, info: table }?
local current

---@type boolean
local infoVisible = false

---@type string?
local openShop

---@type number
local billedTattoos = 0

---@type number[]
local blips = {}

---@param zone ShopZone
---@return boolean
local function permitted(zone)
    if not zone.job and not zone.gang and not zone.identifiers then return true end

    if zone.job and Framework.holdsJob(zone.job) then return true end
    if zone.gang and Framework.holdsGang(zone.gang) then return true end

    if zone.identifiers then
        local identifier = Framework.getState().identifier

        for i = 1, #zone.identifiers do
            if zone.identifiers[i] == identifier then return true end
        end
    end

    return false
end

---@param shopType string
function shops.open(shopType)
    local menu = shops.menu(shopType)

    if not menu or editor.active() then return end

    openShop = shopType
    billedTattoos = 0

    editor.open(menu, function(appearance)
        openShop = nil

        if not appearance then return end

        if shopType == "tattoo" and clientConfig.chargePerTattoo then return end

        return lib.callback.await("rhd_appearance:shops:charge", false, shopType)
    end)
end

function shops.clear()
    openShop = nil
    billedTattoos = 0
end

---@param a { drawable: number, texture: number }[]
---@param b { drawable: number, texture: number }[]
---@return boolean
local function wornAlike(a, b)
    if #a ~= #b then return false end

    for i = 1, #a do
        if a[i].drawable ~= b[i].drawable or a[i].texture ~= b[i].texture then return false end
    end

    return true
end

---@return boolean
function shops.unpaid()
    if not openShop then return false end

    local snapshot = editor.original()

    if not snapshot then return true end

    return not wornAlike(ped.getComponents(cache.ped), snapshot.components)
        or not wornAlike(ped.getProps(cache.ped), snapshot.props)
end

---@param list PedTattoos
---@return number
local function countTattoos(list)
    local total = 0

    for _, zone in pairs(list) do
        total += #zone
    end

    return total
end

---@param list PedTattoos
---@return boolean
function shops.allowTattoo(list)
    if openShop ~= "tattoo" or not clientConfig.chargePerTattoo then return true end

    local total = countTattoos(list)

    for _ = billedTattoos + 1, total do
        if not lib.callback.await("rhd_appearance:shops:chargeTattoo", false) then return false end

        billedTattoos += 1
    end

    billedTattoos = total

    return true
end

---@param kind string
---@param index number
local function activate(kind, index)
    if kind == "clothingRoom" then
        local room = config.clothingRooms[index]

        if permitted(room) then outfits.openJob(room) end
    elseif kind == "outfitRoom" then
        if permitted(config.outfitRooms[index]) then outfits.open() end
    else
        local store = config.stores[index]

        if permitted(store) then shops.open(store.type) end
    end
end

local function showInfo()
    if infoVisible or not current then return end

    infoVisible = true

    exports.sm_resource_1:infoShow(current.info)
end

local function hideInfo()
    if not infoVisible then return end

    infoVisible = false

    exports.sm_resource_1:infoRemove(INFO_ID)
end

---@param zone ShopZone
---@param kind string
local function onEnter(zone, kind, index)
    if not permitted(zone) then return end

    local kindKey = zone.type or kind
    local cost = config.costs[zone.type]
    local label = locale("shops." .. kindKey)

    current = {
        kind = kind,
        index = index,
        info = {
            id = INFO_ID,
            title = label,
            icon = config.icons[kindKey] or DEFAULT_ICON,
            description = cost and ("[kbd]E[/kbd] %s ($%d)"):format(label, cost)
                or ("[kbd]E[/kbd] %s"):format(label)
        }
    }

    showInfo()
end

local function onExit()
    current = nil

    hideInfo()
end

---@param zone ShopZone
---@return boolean
local function enabled(zone)
    local disabled = config.disabledTypes

    return not (zone.type and disabled and disabled[zone.type])
end

---@param list ShopZone[]
---@param kind string
local function buildZones(list, kind)
    for i = 1, #list do
        local zone = list[i]

        if not enabled(zone) then goto continue end

        local options = {
            debug = config.debug,
            onEnter = function() onEnter(zone, kind, i) end,
            onExit = onExit
        }

        if zone.points then
            options.points = zone.points

            lib.zones.poly(options)
        else
            options.coords = zone.coords
            options.size = zone.size or vec3(4, 4, 4)
            options.rotation = zone.rotation or 0.0

            lib.zones.box(options)
        end

        ::continue::
    end
end

---@param list ShopZone[]
---@param kind string
local function buildBlips(list, kind)
    for i = 1, #list do
        local zone = list[i]
        local settings = config.blips[zone.type or kind]
        local show = zone.showBlip

        if show == nil then show = settings and settings.show end
        if not enabled(zone) then show = false end

        if show and settings then
            local name = zone.type or kind
            local key = "rhd_appearance_blip_" .. name
            local blip = AddBlipForCoord(zone.coords.x, zone.coords.y, zone.coords.z)

            SetBlipSprite(blip, settings.sprite)
            SetBlipColour(blip, settings.color)
            SetBlipScale(blip, settings.scale)
            SetBlipDisplay(blip, 4)
            SetBlipAsShortRange(blip, true)
            AddTextEntry(key, locale("shops." .. name))
            BeginTextCommandSetBlipName(key)
            EndTextCommandSetBlipName(blip)

            blips[#blips + 1] = blip
        end
    end
end

local function interactLoop()
    while true do
        local wait = 500

        if current then
            wait = 0

            if editor.active() or menuUI.active() then
                hideInfo()
            else
                showInfo()

                if IsControlJustReleased(0, INTERACT_KEY) then
                    hideInfo()
                    activate(current.kind, current.index)
                end
            end
        end

        Wait(wait)
    end
end
CreateThread(function()
    local groups = {
        { list = config.stores, kind = "store" },
        { list = config.clothingRooms, kind = "clothingRoom" },
        { list = config.outfitRooms, kind = "outfitRoom" }
    }

    for i = 1, #groups do
        local group = groups[i]

        buildBlips(group.list, group.kind)
        buildZones(group.list, group.kind)
    end

    interactLoop()
end)

AddEventHandler("onResourceStop", function(resource)
    if resource ~= cache.resource then return end

    hideInfo()

    for i = 1, #blips do
        RemoveBlip(blips[i])
    end
end)

return shops
