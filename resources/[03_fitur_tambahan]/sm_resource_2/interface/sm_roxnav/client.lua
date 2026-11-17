local hasFrame = interface.init(false)

local KVP_ENABLED = 'sm_roxnav:enabled'
local COMMAND = 'roxnav'
local FORCE_CLOSE_EVENT = 'sm_roxnav:client:forceClose'
local EDITS_STATE_KEY = 'roxnavEdits'
local EDITS_JITTER = 8000

local ACTIVE_TICK = 66
local IDLE_TICK = 1000
local SLOW_EVERY = 8
local POS_EPSILON = 0.15
local HEADING_EPSILON = 0.6

local MINIMAP_WIDTH = 0.1638
local MINIMAP_HEIGHT = 0.183
local BASE_ASPECT = 16 / 9
local DEFAULT_POSITION = { x = 0.008, y = 0.021 }

local BOUNDS_MIN_X, BOUNDS_MAX_X = -6306.8, 1157.4
local BOUNDS_MIN_Y, BOUNDS_MAX_Y = 5447.4, 9553.6

local BASE_LAND = {
    [843] = true, [844] = true, [845] = true, [846] = true, [847] = true, [848] = true, [849] = true, [850] = true,
    [879] = true, [880] = true, [881] = true, [882] = true,
    [910] = true, [911] = true, [912] = true, [913] = true, [914] = true,
}

local Wait = Wait
local GetEntityCoords = GetEntityCoords
local GetEntityHeading = GetEntityHeading
local GetEntitySpeed = GetEntitySpeed
local GetGameplayCamRot = GetGameplayCamRot
local IsRadarHidden = IsRadarHidden
local IsPauseMenuActive = IsPauseMenuActive
local IsWaypointActive = IsWaypointActive
local GetFirstBlipInfoId = GetFirstBlipInfoId
local DoesBlipExist = DoesBlipExist
local GetBlipInfoIdCoord = GetBlipInfoIdCoord
local GetAspectRatio = GetAspectRatio
local GetGameTimer = GetGameTimer
local mrandom = math.random
local mfloor = math.floor
local mabs = math.abs
local mmin = math.min
local mmax = math.max

local enabled = GetResourceKvpInt(KVP_ENABLED) ~= 1
local active = false
local panelOpen = false
local editorOpen = false
local mounted = false
local ready = false
local shown = false

local edits = { version = -1, list = {} }
local editsSyncAt = false

local rect = {}
local position = { x = 0.0, y = 0.0, h = 0.0, ph = 0.0, spd = 0.0, veh = false }
---@type { x: number, y: number }|false
local waypoint = false
local lastX, lastY, lastH, lastPh = 0.0, 0.0, 0.0, 0.0

---@param action string
---@param data? any
local function send(action, data)
    if ready then
        interface.send({ action = action, data = data })
    end
end

---@param x number
---@param y number
---@return boolean
local function isRoxwood(x, y)
    if x < BOUNDS_MIN_X or x > BOUNDS_MAX_X or y < BOUNDS_MIN_Y or y > BOUNDS_MAX_Y then
        return false
    end
    local gridX = mfloor((x + 8192) / 512)
    local gridY = mfloor((y + 8192) / 512)
    if gridY > 31 then
        return true
    end
    return not BASE_LAND[gridY * 32 + gridX]
end

---@return boolean changed
local function readRect()
    local ok, saved = pcall(function()
        return exports.sm_resource:GetMinimapPosition()
    end)
    local pos = ok and type(saved) == 'table' and saved or DEFAULT_POSITION
    local ratio = BASE_ASPECT / GetAspectRatio(false)
    local width = MINIMAP_WIDTH * ratio
    local x = mmin(mmax(tonumber(pos.x) or DEFAULT_POSITION.x, 0.0), 1.0 - MINIMAP_WIDTH) * ratio
    local y = mmin(mmax(tonumber(pos.y) or DEFAULT_POSITION.y, 0.0), 1.0 - MINIMAP_HEIGHT)

    if rect.x == x and rect.y == y and rect.w == width then
        return false
    end
    rect = { x = x, y = y, w = width, h = MINIMAP_HEIGHT }
    return true
end

---@return boolean changed
local function readWaypoint()
    ---@type { x: number, y: number }|false
    local coords = false
    if IsWaypointActive() then
        local blip = GetFirstBlipInfoId(8)
        if DoesBlipExist(blip) then
            local c = GetBlipInfoIdCoord(blip)
            coords = { x = c.x, y = c.y }
        end
    end

    if not coords and not waypoint then
        return false
    end
    if coords and waypoint and mabs(coords.x - waypoint.x) < 1.0 and mabs(coords.y - waypoint.y) < 1.0 then
        return false
    end
    waypoint = coords
    return true
end

local function readPosition()
    local ped = cache.ped
    local coords = GetEntityCoords(ped)
    local camHeading = GetGameplayCamRot(2).z
    local pedHeading = GetEntityHeading(cache.vehicle or ped)

    position.x = coords.x
    position.y = coords.y
    position.h = camHeading
    position.ph = pedHeading
    position.spd = GetEntitySpeed(cache.vehicle or ped)
    position.veh = cache.vehicle and true or false

    if mabs(coords.x - lastX) < POS_EPSILON and mabs(coords.y - lastY) < POS_EPSILON
        and mabs(camHeading - lastH) < HEADING_EPSILON and mabs(pedHeading - lastPh) < HEADING_EPSILON then
        return false
    end
    lastX, lastY, lastH, lastPh = coords.x, coords.y, camHeading, pedHeading
    return true
end

local function syncEdits()
    local data = lib.callback.await('sm_roxnav:edits', false)
    if type(data) ~= 'table' or type(data.list) ~= 'table' then return end
    edits = data
    send('edits', edits)
end

local function syncState()
    send('state', {
        enabled = enabled,
        active = active,
        shown = shown,
        panel = panelOpen,
        editor = editorOpen,
        rect = rect,
        waypoint = waypoint,
        position = position,
    })
end

local function updateMount()
    local want = hasFrame and (active or panelOpen or editorOpen)
    if want and not mounted then
        mounted = true
        interface.show()
    elseif not want and mounted then
        SetTimeout(150, function()
            if not mounted or active or panelOpen or editorOpen then return end
            mounted = false
            ready = false
            interface.hide()
        end)
    end
end

---@param state boolean
local function setActive(state)
    if active == state then return end
    active = state
    if state then
        readRect()
        readWaypoint()
        readPosition()
    else
        shown = false
    end
    syncState()
    updateMount()
end

---@param state boolean
local function setEnabled(state)
    enabled = state
    SetResourceKvpInt(KVP_ENABLED, state and 2 or 1)
    if not state then
        setActive(false)
    end
    syncState()
end

local function closeAll()
    if not panelOpen and not editorOpen then return end
    panelOpen = false
    editorOpen = false
    interface.focus(false, false)
    syncState()
    updateMount()
end

local function openPanel()
    if not hasFrame or panelOpen or editorOpen then return end
    panelOpen = true
    if ready then
        syncState()
        interface.focus(true, true)
    else
        updateMount()
    end
end

local function openEditor()
    if not hasFrame or editorOpen then return end
    panelOpen = false
    editorOpen = true
    readPosition()
    if ready then
        syncState()
        interface.focus(true, true)
    else
        updateMount()
    end
    syncEdits()
end

---@param result any
---@return table
local function applyResult(result)
    if type(result) ~= 'table' then
        lib.notify({ title = 'Editor Jalan', description = 'Server tidak menjawab', type = 'error' })
        return { ok = false }
    end
    if not result.ok then
        lib.notify({ title = 'Editor Jalan', description = result.error or 'Gagal menyimpan', type = 'error' })
        return { ok = false }
    end
    if type(result.edits) == 'table' then
        edits = result.edits
        send('edits', edits)
    end
    return { ok = true }
end

if hasFrame then
    interface.callback('ready', function(_, cb)
        ready = true
        cb({})
        syncState()
        send('edits', edits)
        if panelOpen or editorOpen then
            interface.focus(true, true)
        end
    end)

    interface.callback('addPath', function(data, cb)
        if not editorOpen or type(data) ~= 'table' then return cb({ ok = false }) end
        cb(applyResult(lib.callback.await('sm_roxnav:addPath', false, data.points)))
    end)

    interface.callback('toggleSegment', function(data, cb)
        if not editorOpen or type(data) ~= 'table' then return cb({ ok = false }) end
        cb(applyResult(lib.callback.await('sm_roxnav:toggleSegment', false, data)))
    end)

    interface.callback('toggle', function(data, cb)
        cb({})
        setEnabled(type(data) == 'table' and data.enabled == true)
    end)

    interface.callback('exit', function(_, cb)
        cb({})
        closeAll()
    end)
end

RegisterCommand(COMMAND, openPanel, false)

RegisterNetEvent('sm_roxnav:client:editor', openEditor)

AddEventHandler(FORCE_CLOSE_EVENT, closeAll)

CreateThread(function()
    local slowCounter = 0
    while true do
        local sleep = IDLE_TICK

        if enabled and hasFrame and playerState.isLoggedIn then
            local coords = GetEntityCoords(cache.ped)
            setActive(isRoxwood(coords.x, coords.y))
        else
            setActive(false)
        end

        if active then
            sleep = ACTIVE_TICK

            local visible = not IsRadarHidden() and not IsPauseMenuActive()
            if visible ~= shown then
                shown = visible
                send('shown', shown)
            end

            if shown and readPosition() then
                send('position', position)
            end

            slowCounter = slowCounter + 1
            if slowCounter >= SLOW_EVERY then
                slowCounter = 0
                if readWaypoint() then
                    send('waypoint', waypoint)
                end
                if readRect() then
                    send('rect', rect)
                end
                local editsVersion = GlobalState[EDITS_STATE_KEY]
                if editsVersion and editsVersion ~= edits.version then
                    local now = GetGameTimer()
                    if not editsSyncAt then
                        editsSyncAt = edits.version < 0 and now or now + mrandom(0, EDITS_JITTER)
                    elseif now >= editsSyncAt then
                        editsSyncAt = false
                        syncEdits()
                    end
                end
            end
        end

        Wait(sleep)
    end
end)
