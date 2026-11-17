
local compasActive = false

---@param heading number
local function getCardinal(heading)
    heading = heading % 360
    if heading < 22.5  or heading >= 337.5 then return 'N'
    elseif heading < 67.5  then return 'NW'
    elseif heading < 112.5 then return 'W'
    elseif heading < 157.5 then return 'SW'
    elseif heading < 202.5 then return 'S'
    elseif heading < 247.5 then return 'SE'
    elseif heading < 292.5 then return 'E'
    else return 'NE'
    end
end

local function hideCompas()
    if not compasActive then return end
    interface.send({ action = 'updateCompass', data = { visible = false } })
    compasActive = false
end

local function compassTick()
    local tick = 1500
    local settings = SM_HUD.settings
    local compasMode = settings.compassMode

    if not compasMode then
        hideCompas()
        return tick
    end

    if compasMode == 'inVehicle' and not cache.vehicle then
        hideCompas()
        return tick
    end

    if not playerState.isLoggedIn then
        hideCompas()
        return tick
    end

    tick = 500
    compasActive = true

    local coords = GetEntityCoords(cache.ped)
    local camRot = GetGameplayCamRot(2)
    local heading = camRot.z % 360.0
    local cardinal = getCardinal(heading)
    local streetHash, crossHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local streetName = GetStreetNameFromHashKey(streetHash) or ''
    local crossStreet = GetStreetNameFromHashKey(crossHash)  or ''

    local weather = 'CLEAR'
    if GetResourceState('Renewed-Weathersync') == 'started' then
        weather = GlobalState.weather?.weather or 'CLEAR'
    end

    interface.send({
        action = 'updateCompass',
        data = {
            visible = true,
            heading = heading,
            cardinal = cardinal,
            streetName = streetName,
            crossStreet = crossStreet,
            weather = weather,
        },
    })

    return tick
end

CreateThread(function()
    while true do
        Wait(compassTick())
    end
end)