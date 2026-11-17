local updatingCoords = false
local mapsPed = PlayerPedId()
local lastCoords = vector3(0, 0, 0)

local function addLocation(name, location)
    if not name then
        return false
    end
    local coords
    if location then
        coords = vector2(location[2], location[1])
    else
        coords = GetEntityCoords(PlayerPedId())
    end
    local id = AwaitCallback("maps:addLocation", name, coords.x, coords.y)
    if not id then
        return false
    end
    local entry = {
        id = id,
        name = name,
        position = { coords.y, coords.x }
    }
    SavedLocations[#SavedLocations + 1] = entry
    return entry
end

local function updateCoordsLoop()
    mapsPed = PlayerPedId()
    lastCoords = GetEntityCoords(mapsPed)
    SendNUIAction("maps:updateCoords", {
        x = math.floor(lastCoords.x + 0.5),
        y = math.floor(lastCoords.y + 0.5)
    })
    while updatingCoords do
        local coords = GetEntityCoords(mapsPed)
        if phoneOpen then
            if #(lastCoords - coords) > 1.0 then
                lastCoords = coords
                SendNUIAction("maps:updateCoords", {
                    x = math.floor(coords.x + 0.5),
                    y = math.floor(coords.y + 0.5)
                })
            end
        end
        Wait(250)
    end
end

RegisterNUICallback("Maps", function(data, cb)
    local action = data.action
    debugprint("Maps:" .. (action or ""))
    if action == "getCurrentLocation" then
        local coords = GetEntityCoords(PlayerPedId())
        cb({ x = coords.x, y = coords.y })
    elseif action == "toggleUpdateCoords" then
        cb("ok")
        if updatingCoords == data.toggle then
            return
        end
        updatingCoords = data.toggle == true
        updateCoordsLoop()
    elseif action == "setWaypoint" then
        cb("ok")
        local x = tonumber(data.data.x)
        local y = tonumber(data.data.y)
        if not x or not y then
            return
        end
        SetNewWaypoint(x / 1, y / 1)
    elseif action == "getLocations" then
        cb(SavedLocations)
    elseif action == "addLocation" then
        cb(addLocation(data.name, data.location))
    elseif action == "renameLocation" then
        local name = data.name
        local result = name
        if name then
            result = AwaitCallback("maps:renameLocation", data.id, name)
        end
        if not result then
            return cb(false)
        end
        for i = 1, #SavedLocations do
            if SavedLocations[i].id == data.id then
                SavedLocations[i].name = name
                break
            end
        end
        cb(true)
    elseif action == "removeLocation" then
        local result = AwaitCallback("maps:removeLocation", data.id)
        if not result then
            return cb(false)
        end
        for i = 1, #SavedLocations do
            if SavedLocations[i].id == data.id then
                table.remove(SavedLocations, i)
                break
            end
        end
        cb(true)
    end
end)
