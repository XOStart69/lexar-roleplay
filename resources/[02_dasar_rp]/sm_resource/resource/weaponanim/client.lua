local config = localmodule 'config.shared'

local Wait = Wait
local joaat = joaat
local pcall = pcall
local CreateThread = CreateThread
local GetEntitySpeed = GetEntitySpeed
local SetPedWeaponMovementClipset = SetPedWeaponMovementClipset
local ResetPedWeaponMovementClipset = ResetPedWeaponMovementClipset
local GetWeapontypeGroup = GetWeapontypeGroup

local clipHold = config.clipset.hold
local clipIdle = config.clipset.idle
local interval = config.interval
local walkSpeed = config.walkSpeed
local blend = config.blend
local ktwrJobs = config.ktwr.jobs
local ktwrBlend = config.ktwr.blend
local ktwrStyles = config.ktwr.styles

---@param groupList table<string, string>
---@param overrideList table<string, string|false>
---@return fun(weapon: number|false): string|false
local function createResolver(groupList, overrideList)
    local byGroup = {}
    for name, value in pairs(groupList) do
        byGroup[joaat(name)] = value
    end

    local byWeapon = {}
    for name, value in pairs(overrideList) do
        byWeapon[joaat(name)] = value
    end

    return function(weapon)
        if not weapon then return false end

        local value = byWeapon[weapon]
        if value == nil then
            value = byGroup[GetWeapontypeGroup(weapon)] or false
            byWeapon[weapon] = value
        end

        return value
    end
end

local getStyle = createResolver(config.groups, config.overrides)
local getKtwr = createResolver(config.ktwr.groups, config.ktwr.overrides)

local selected = {}

---@param category string
---@return string
local function ktwrClipset(category)
    if not selected[category] then
        selected[category] = ktwrStyles[category][1].id
    end

    return ('sm_ktwr_%s_%s'):format(category, selected[category])
end

local active
local preferred
local currentWeapon = cache.weapon
local activeMode
local activeKtwr
local applied
local loaded = {}

---@param clipset string|false
---@return boolean
local function loadClipset(clipset)
    if not clipset or loaded[clipset] then return true end

    local ok = pcall(lib.requestAnimSet, clipset, 5000)
    loaded[clipset] = ok

    return ok
end

---@return boolean
local function isCrouched()
    local ok, result = pcall(emotemenu.IsPlayerCrouched, emotemenu)
    return ok and result or false
end

---@return boolean
local function hasKtwrJob()
    local job = QBPlayerData.job
    return job and ktwrJobs[job.name] or false
end

local function stop()
    if not active then return end

    active = nil
    activeMode = nil
    activeKtwr = nil

    if applied then
        applied = nil
        ResetPedWeaponMovementClipset(cache.ped, 0.0)
    end
end

local loopId = 0

local function styleLoop()
    loopId = loopId + 1
    local id = loopId

    while active and id == loopId do
        if active == 'ktwr' and not hasKtwrJob() then
            stop()
            break
        end

        if cache.vehicle or isCrouched() then
            applied = nil
        else
            local clip, speed

            if active == 'ktwr' then
                clip, speed = activeKtwr, ktwrBlend
            else
                clip, speed = clipHold, blend[activeMode]

                if clipIdle and activeMode == 'twohand' and GetEntitySpeed(cache.ped) < walkSpeed then
                    clip = clipIdle
                end
            end

            if clip ~= applied then
                SetPedWeaponMovementClipset(cache.ped, clip, speed)
                applied = clip
            end
        end

        Wait(interval)
    end
end

---@param style string
---@param weapon number
---@return boolean
local function isAvailable(style, weapon)
    if style == 'ktwr' then
        return getKtwr(weapon) and hasKtwrJob() or false
    end

    return getStyle(weapon) and true or false
end

---@param style string
---@param weapon number
local function start(style, weapon)
    CreateThread(function()
        local category = style == 'ktwr' and getKtwr(weapon)
        local ktwr = category and ktwrClipset(category) or nil
        local ok

        if ktwr then
            ok = loadClipset(ktwr)
        else
            ok = loadClipset(clipHold) and loadClipset(clipIdle)
        end

        if not ok or currentWeapon ~= weapon then return end

        local running = active ~= nil

        active = style
        activeMode = getStyle(weapon)
        activeKtwr = ktwr
        applied = nil

        if not running then
            styleLoop()
        end
    end)
end

lib.onCache('weapon', function(weapon)
    currentWeapon = weapon
    stop()

    if preferred and weapon and isAvailable(preferred, weapon) then
        start(preferred, weapon)
    end
end)

lib.onCache('ped', function()
    applied = nil
end)

---@param style string?
---@param weapon number
local function applyStyle(style, weapon)
    preferred = style

    if style then
        start(style, weapon)
    else
        stop()
    end
end

---@param message string
local function notifyStyle(message)
    lib.notify({ description = ('Gaya pegang senjata: %s'):format(message), type = 'info' })
end

---@param weapon number
---@param category string
local function cycleKtwr(weapon, category)
    local list = ktwrStyles[category]
    local index = 0

    if active == 'ktwr' then
        for i = 1, #list do
            if list[i].id == selected[category] then
                index = i
                break
            end
        end
    elseif active == 'jerrycan' then
        index = #list + 1
    end

    index = index + 1

    if index <= #list then
        local style = list[index]
        selected[category] = style.id
        applyStyle('ktwr', weapon)
        notifyStyle(('KTWR %s'):format(style.label))
    elseif index == #list + 1 and getStyle(weapon) then
        applyStyle('jerrycan', weapon)
        notifyStyle('weapon anim')
    else
        applyStyle(nil, weapon)
        notifyStyle('default')
    end
end

lib.addKeybind({
    name = 'weaponanim_toggle',
    description = 'Ganti gaya pegang senjata',
    defaultKey = config.key,
    onPressed = function()
        local weapon = currentWeapon
        if not weapon or cache.vehicle then return end

        local category = hasKtwrJob() and getKtwr(weapon)

        if category then
            cycleKtwr(weapon, category)
            return
        end

        if not getStyle(weapon) then return end

        if active then
            applyStyle(nil, weapon)
            notifyStyle('default')
        else
            applyStyle('jerrycan', weapon)
            notifyStyle('weapon anim')
        end
    end,
})

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end
    stop()
end)
