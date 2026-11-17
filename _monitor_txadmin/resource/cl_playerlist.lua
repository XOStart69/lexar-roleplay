-- Prevent running if menu is disabled
if not TX_MENU_ENABLED then return end

-- =============================================
--  Client PlayerList handler
-- =============================================
-- SatuMimpi: two separate concerns
--  1. A lightweight roster (id -> name) kept in sync via setInitial + updatePlayer.
--     It powers `/tx <target>` and the online count, and is only pushed to the NUI
--     while the menu is open (join/leave churn no longer spams a closed menu).
--  2. The players tab pulls its detailed rows one page at a time (load-on-scroll)
--     via txsv:req:plist:getPage, replacing the full-detail list every 5s.

-- Optimizations
local tonumber = tonumber
local floor = math.floor

-- Variables & Consts
LOCAL_PLAYERLIST = {} -- available globally in tx, { [id:number] = name:string }
local rosterDirty = false
local rosterPushPending = false
local ROSTER_DEBOUNCE = 500
local vTypeMap = {
    [0] = "walking",
    [1] = "driving", --automobile
    [2] = "biking",
    [3] = "boating",
    [4] = "flying", --heli
    [5] = "flying", --plane
    [6] = "boating", --submarine
    [7] = "driving", --trailer
    [8] = "driving", --train
}


-- Sends the roster to react, only when the menu is open or forced
-- The playerlist is converted to an object array to save refactor time
function sendReactPlayerlist(force)
    if not force and not isMenuVisible then
        rosterDirty = true
        return
    end
    rosterDirty = false

    local upload = {}
    for pid, name in pairs(LOCAL_PLAYERLIST) do
        upload[#upload + 1] = {
            id = pid,
            name = name or "unknown",
            health = 0,
            dist = -1,
            vType = "unknown",
            admin = false
        }
    end
    sendMenuMessage('setPlayerList', upload)
end

--- Pushes the roster if it changed while the menu was closed
function flushReactPlayerlist()
    if rosterDirty then
        sendReactPlayerlist(true)
    end
end

-- Coalesce join/leave churn into at most one push per debounce window
local function scheduleRosterPush()
    if not isMenuVisible then
        rosterDirty = true
        return
    end
    if rosterPushPending then return end
    rosterPushPending = true
    SetTimeout(ROSTER_DEBOUNCE, function()
        rosterPushPending = false
        sendReactPlayerlist()
    end)
end


-- Triggered when the admin authenticates
-- Replaces current playerlist
RegisterNetEvent('txcl:plist:setInitial', function(payload)
    LOCAL_PLAYERLIST = {}
    if type(payload) == 'table' then
        for i = 1, #payload do
            local entry = payload[i]
            local id = tonumber(entry[1])
            if id then LOCAL_PLAYERLIST[id] = entry[2] end
        end
    end
    sendReactPlayerlist(true)
end)


-- Triggered on player join/leave
-- add/remove specific id to playerlist
RegisterNetEvent('txcl:plist:updatePlayer', function(id, data)
    local pid = tonumber(id)
    if not pid then return end
    if data == false then
        LOCAL_PLAYERLIST[pid] = nil
    else
        LOCAL_PLAYERLIST[pid] = data
    end
    scheduleRosterPush()
end)


-- Triggered by the players tab when it needs a page
-- data = { reqId, offset, limit, filter, sort, ids? }
RegisterSecureNuiCallback('reqPlayerPage', function(data, cb)
    local opts = type(data) == 'table' and data or {}
    local coords = GetEntityCoords(PlayerPedId())
    opts.cx = floor(coords.x)
    opts.cy = floor(coords.y)
    TriggerServerEvent('txsv:req:plist:getPage', opts.reqId or 0, opts)
    cb({})
end)


-- Return of "getPage"
--  items: array of tuples [id, name, health, vType, dist, admin]
--  total: amount of players matching the filter/search
--  offset: echoed request offset (0 = replace list, >0 = append)
RegisterNetEvent('txcl:plist:setPage', function(reqId, items, total, offset)
    local myID = GetPlayerServerId(PlayerId())
    local myPed = PlayerPedId()

    local players = {}
    for i = 1, #items do
        local it = items[i]
        local id = it[1]
        local health = it[3]

        -- NOTE: RedM doesn't save ped health data on server, so need to get locally
        if IS_REDM then
            if id == myID then
                health = GetPedHealthPercent(myPed)
            else
                local remotePlayer = GetPlayerFromServerId(id)
                if remotePlayer == -1 then
                    health = -1
                else
                    health = GetPedHealthPercent(GetPlayerPed(remotePlayer))
                end
            end
        end

        players[i] = {
            id = id,
            name = it[2] or "unknown",
            health = health,
            dist = it[5],
            vType = vTypeMap[it[4]] or "unknown",
            admin = it[6] == true,
        }
    end

    sendMenuMessage('setPlayerPage', {
        reqId = reqId,
        players = players,
        total = total,
        offset = offset,
    })
end)
