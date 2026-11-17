local config = require "config.editor"
local menus = require "config.menu"
local customAnimations = require "config.animation"
local ped = require "core.ped"
local camera = require "core.camera"
local settings = require "core.settings"
local clothing = require "features.clothing"
local items = require "features.items"
local admin = require "features.admin"
local events = require "modules.events"
local forced = require "features.forced"

local STATS_HOLD = 1000

local TRY_ON_ANIMATIONS = {
    {
        components = { 3, 5, 8, 9, 10, 11, 33 },
        dict = "clothingshirt",
        clips = {
            "try_shirt_positive_a",
            "try_shirt_positive_b",
            "try_shirt_positive_c",
            "try_shirt_positive_d"
        }
    },
    {
        components = { 4 },
        dict = "clothingtrousers",
        clips = {
            "try_trousers_positive_a",
            "try_trousers_positive_b",
            "try_trousers_positive_c",
            "try_trousers_positive_d"
        }
    },
    {
        components = { 6 },
        dict = "clothingshoes",
        clips = {
            "try_shoes_positive_a",
            "try_shoes_positive_b",
            "try_shoes_positive_c",
            "try_shoes_positive_d"
        }
    }
}

---@type PedAppearance?
local original
---@type table?
local menuConfig
---@type fun(appearance: PedAppearance|boolean?)?
local finish
---@type number?
local heading

---@class EditorSession
---@field target number
---@field original PedAppearance

---@type EditorSession?
local session

---@type { health: number, armour: number }?
local savedStats
local statsDepth = 0

local playingTryOn = false
local animToken = 0

local editor = {}

local function backupStats()
    statsDepth += 1

    if savedStats then return end

    savedStats = {
        health = GetEntityHealth(cache.ped),
        armour = GetPedArmour(cache.ped)
    }
end

local function restoreStats()
    if statsDepth > 0 then
        statsDepth -= 1

        if statsDepth > 0 then return end
    end

    local previous = savedStats

    savedStats = nil

    if not previous then return end

    SetEntityMaxHealth(cache.ped, 200)

    local deadline = GetGameTimer() + STATS_HOLD

    repeat
        SetEntityHealth(cache.ped, previous.health)
        SetPedArmour(cache.ped, previous.armour)
        Wait(0)
    until GetGameTimer() >= deadline

    SetPlayerHealthRechargeMultiplier(cache.playerId, 0.0)
    SetPlayerHealthRechargeLimit(cache.playerId, 0.0)
end

---@param entity number
---@return boolean
local function animDisabled(entity)
    local list = config.disableAnimForPeds

    if #list == 0 then return false end

    local model = GetEntityModel(entity)

    for i = 1, #list do
        if model == joaat(list[i]) then return true end
    end

    return false
end

---@param componentId number
---@return table?
local function animationFor(componentId)
    for i = 1, #TRY_ON_ANIMATIONS do
        local animation = TRY_ON_ANIMATIONS[i]

        for j = 1, #animation.components do
            if animation.components[j] == componentId then
                return animation
            end
        end
    end
end

---@param entity number
---@param clearTasks boolean?
function editor.idle(entity, clearTasks)
    if not editor.active() or session or animDisabled(entity) then return end

    if clearTasks then
        ClearPedTasksImmediately(entity)
    end

    local dict = ped.gender(entity) == "male" and "move_m@generic" or "move_f@generic"

    lib.playAnim(entity, dict, "idle", 1.0, -1.0, -1, 1)
end

---@param entity number
---@param componentId number
function editor.tryOn(entity, componentId)
    if not editor.active() or session or playingTryOn or animDisabled(entity) then return end

    local animation = animationFor(componentId)

    if not animation then return end

    local clip = animation.clips[math.random(1, #animation.clips)]
    local current = animToken

    ClearPedTasks(entity)
    lib.playAnim(entity, animation.dict, clip, 1.0, -1.0, -1, 0)

    playingTryOn = true

    CreateThread(function()
        Wait(GetAnimDuration(animation.dict, clip) * 1000)

        if current == animToken then
            editor.idle(entity)
        end

        playingTryOn = false
    end)
end

---@return boolean
function editor.active()
    return menuConfig ~= nil
end

---@return { name: string, keyboard: string }[]
function editor.animations()
    local names = {}

    for name in pairs(customAnimations) do
        names[#names + 1] = name
    end

    table.sort(names)

    local result = table.create(#names, 0)

    for i = 1, #names do
        result[i] = { name = names[i], keyboard = customAnimations[names[i]].keyboard }
    end

    return result
end

---@param name string
---@return boolean
function editor.playAnimation(name)
    local animation = customAnimations[name]

    if not animation or not editor.active() or session or animDisabled(cache.ped) then return false end

    local current = animToken

    ClearPedTasks(cache.ped)
    lib.playAnim(cache.ped, animation.dict, animation.name, 1.0, -1.0, -1, 0)

    CreateThread(function()
        Wait(GetAnimDuration(animation.dict, animation.name) * 1000)

        if current == animToken then editor.idle(cache.ped) end
    end)

    return true
end

---@return table?
function editor.config()
    if not menuConfig then return end

    local conf = table.clone(menuConfig)

    conf.automaticFade = config.automaticFade

    return conf
end

---@return PedAppearance?
function editor.original()
    return original
end

---@return number?
function editor.heading()
    return heading
end

---@return EditorSession?
function editor.session()
    return session
end

---@param appearance PedAppearance
---@return boolean saved
function editor.save(appearance)
    if forced.active() then return false end

    local saved = lib.callback.await("rhd_appearance:save", false, appearance) == true

    if not saved then
        lib.notify({ description = locale("notify.saveFailed"), type = "error" })
    end

    return saved
end

---@param appearance PedAppearance
---@return boolean saved
function editor.commit(appearance)
    if not editor.save(appearance) then return false end

    original = appearance

    return true
end

function editor.load()
    local data = lib.callback.await("rhd_appearance:get", false)

    if not data then return end

    if not events.emit("onReloadskin", cache.ped, data) then return end

    backupStats()
    ped.applyToPlayer(data, true)

    if settings.repair(cache.ped, data) then
        ped.setComponents(cache.ped, data.components)
        ped.setProps(cache.ped, data.props)
    end

    items.reapply()
    forced.apply()
    restoreStats()

    events.emit("onReloadskinDone", cache.ped, data)
end

---@param conf table?
---@param cb? fun(appearance: PedAppearance|boolean?): boolean?
---@param barber EditorSession?
---@return boolean opened
function editor.open(conf, cb, barber)
    if editor.active() then return false end

    if not events.emit("onClothingMenuOpen", cache.ped, conf or menus.default) then return false end

    repeat Wait(0) until IsScreenFadedIn() and not IsPlayerTeleportActive() and not IsPlayerSwitchInProgress()

    if editor.active() then return false end

    clothing.closeRail()
    clothing.reset(false)

    session = barber
    original = barber and barber.original or ped.get(cache.ped)
    heading = not barber and GetEntityHeading(cache.ped) or nil
    menuConfig = conf or menus.default
    finish = cb

    if barber then
        camera.orbit(barber.target)
    else
        backupStats()
        camera.start()
    end

    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    RenderScriptCams(true, false, 0, true, true)
    SetEntityInvincible(cache.ped, config.invincibleDuringCustomization)

    if not barber then
        TaskStandStill(cache.ped, -1)
        editor.idle(cache.ped, true)
    end

    if config.hideRadar then DisplayRadar(false) end

    SendNuiMessage(json.encode({
        action = "appearance_display",
        data = { asynchronous = config.asynchronousLoading }
    }))

    CreateThread(function()
        while editor.active() do
            events.emit("onClothingMenuTick", cache.ped)
            Wait(0)
        end
    end)

    clothing.push()

    return true
end

---@param appearance PedAppearance|boolean?
function editor.close(appearance)
    if not editor.active() then return end

    clothing.reset(false)

    local restore = original
    local previousHeading = heading
    local cb = finish
    local barber = session

    original = nil
    heading = nil
    menuConfig = nil
    finish = nil
    session = nil
    animToken += 1
    playingTryOn = false

    RenderScriptCams(false, false, 0, true, true)
    camera.stop()
    SetNuiFocus(false, false)

    if config.hideRadar then DisplayRadar(true) end

    SetEntityInvincible(cache.ped, false)

    SendNuiMessage(json.encode({
        action = "appearance_hide",
        data = {}
    }))

    if barber then
        settings.reset()
        admin.reset()

        if cb then cb(appearance) end

        events.emit("onClothingMenuClose", cache.ped, nil)

        return
    end

    if not appearance and restore then
        ped.applyToPlayer(restore, true)
        items.reapply()
    end

    if previousHeading then
        SetEntityHeading(cache.ped, previousHeading)
    end

    ClearPedTasksImmediately(cache.ped)

    restoreStats()
    settings.reset()
    admin.reset()

    local keep = appearance ~= nil

    if cb then
        local decision = cb(appearance)

        if decision ~= nil then keep = decision end
    end

    if keep then
        editor.save((appearance or ped.get(cache.ped)) --[[@as PedAppearance]])
    elseif appearance and restore then
        backupStats()
        ped.applyToPlayer(restore, true)
        items.reapply()
        restoreStats()
    end

    events.emit("onClothingMenuClose", cache.ped, appearance)
end

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
    end
end)

return editor
