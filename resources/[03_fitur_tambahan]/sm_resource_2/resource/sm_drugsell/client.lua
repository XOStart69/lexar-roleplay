local config = localmodule 'config'
local interact = exports.rhd_interact

local Wait = Wait
local DoesEntityExist = DoesEntityExist

local MENU_ID = 'sm_drugsell:menu'
local IMAGE_PATH = 'nui://ox_inventory/web/images/%s.png'
local DICT = 'mp_common'
local PED = config.ped
local ACCESS = config.access
local HALF_DURATION = config.sellDuration // 2

local dealer
local inRange = false
local selling = false

---@param description string
---@param kind? string
local function notify(description, kind)
    lib.notify({ description = description, type = kind or 'error' })
end

---@return boolean
local function hasAccess()
    return qbLib.checkGroup(QBPlayerData.job, ACCESS)
end

---@param name string
---@return table?
local function itemData(name)
    local items = ox_inventory:Items()
    return items and items[name]
end

local function playSellAnim()
    local ped = dealer
    if not (ped and DoesEntityExist(ped)) then
        return Wait(config.sellDuration)
    end

    TaskTurnPedToFaceEntity(cache.ped, ped, 500)
    Wait(500)

    lib.playAnim(cache.ped, DICT, 'givetake1_a', 8.0, -8.0, HALF_DURATION, 0)
    lib.playAnim(ped, DICT, 'givetake1_b', 8.0, -8.0, HALF_DURATION, 0)
    Wait(HALF_DURATION)

    if DoesEntityExist(ped) then
        lib.playAnim(ped, DICT, 'givetake2_a', 8.0, -8.0, HALF_DURATION, 0)
    end
    lib.playAnim(cache.ped, DICT, 'givetake2_b', 8.0, -8.0, HALF_DURATION - 500, 0)
    Wait(HALF_DURATION - 500)

    RemoveAnimDict(DICT)
end

---@param name string
local function sell(name)
    if selling then return end
    selling = true

    local ok, reason = lib.callback.await('sm_drugsell:start', false, name)
    if not ok then
        selling = false
        if reason then notify(reason) end
        return
    end

    playSellAnim()

    local success, count, reward = lib.callback.await('sm_drugsell:finish', false)
    if success then
        local item = itemData(name)
        notify(('Menjual %dx %s seharga $%s.'):format(count, item and item.label or name, lib.math.groupdigits(reward)), 'success')
    end

    selling = false
end

local function openMenu()
    local options = {}

    for i = 1, #config.items do
        local name = config.items[i].name
        local item = itemData(name)
        options[i] = {
            title = ('Jual %s'):format(item and item.label or name),
            icon = item and item.client and item.client.image or IMAGE_PATH:format(name),
            onSelect = function() sell(name) end,
        }
    end

    lib.registerContext({ id = MENU_ID, title = 'Bandar', options = options })
    lib.showContext(MENU_ID)
end

local options = {
    {
        name = 'sm_drugsell',
        label = 'Jual Drugs',
        icon = 'fa-solid fa-hand-holding-dollar',
        distance = config.interactDistance,
        canInteract = hasAccess,
        onSelect = openMenu,
    },
}

local function despawnDealer()
    local ped = dealer
    dealer = nil
    if not ped then return end

    interact:removeLocalEntity(ped)
    if DoesEntityExist(ped) then
        DeleteEntity(ped)
    end
end

local point = lib.points.new({
    coords = PED.coords.xyz,
    distance = PED.streamDistance,
})

function point:onEnter()
    inRange = true
    if dealer then return end

    CreateThread(function()
        local model = joaat(PED.model)
        if not pcall(lib.requestModel, model, 15000) then return end
        if dealer or not inRange then
            SetModelAsNoLongerNeeded(model)
            return
        end

        local coords = PED.coords
        local ped = CreatePed(0, model, coords.x, coords.y, coords.z, coords.w, false, false)
        SetModelAsNoLongerNeeded(model)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)

        dealer = ped
        interact:addLocalEntity(ped, options)
    end)
end

function point:onExit()
    inRange = false
    despawnDealer()
end

AddEventHandler('onResourceStop', function(resource)
    if resource == cache.resource then
        despawnDealer()
    end
end)
