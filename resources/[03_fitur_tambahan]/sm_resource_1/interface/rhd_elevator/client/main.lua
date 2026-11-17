local elevatorId
local floorsTextInfo = false

local config = localmodule 'config.client'

if not interface.init(false) then
    return lib.print.error('Failed to initialize interface')
end

local frameToken = 0

local function openFrame()
    frameToken += 1
    interface.show()
end

local function closeFrame()
    frameToken += 1
    local token = frameToken

    SetTimeout(400, function()
        if token == frameToken then
            interface.hide()
        end
    end)
end

---@param groups string|string[]|table<string, number>
---@return boolean
local function filterGroups(groups)
    local playerJob = QBPlayerData.job

    if not groups then
        return true
    end

    local _lt = type(groups)
    local jobname, jobtype = playerJob.name, playerJob.type

    if _lt == "string" then
        return (jobname == groups) or (jobtype == groups)
    elseif _lt == "table" then
        if lib.array.isArray(groups) then
            return lib.table.contains(groups, jobname)
        else
            local gradeLevel = groups[jobname] or groups[jobtype]
            return gradeLevel and playerJob.grade.level >= gradeLevel
        end
    end

    return false
end

---@param eid string
local function prepareElevator(eid)
    local myCoords = GetEntityCoords(cache.ped)
    local floorsConfig = config[eid]

    local floors = {}
    for i=1, #floorsConfig do
        local floor = floorsConfig[i]
        local currentFloor = false
        local isAuthorize = filterGroups(floor.groups)

        local distance = #(myCoords - floor.coords.xyz)

        if distance < 2.5 then
            currentFloor = true
        end

        local disable = currentFloor or floor.groups and not isAuthorize

        floors[#floors+1] = {
            floorId = i,
            label = floor.label,
            disable = disable
        }
    end

    openFrame()
    interface.send({
        action = 'openElevator',
        data = {
            floors = floors
        }
    })
    interface.focus(true, true)
end

---@param floorId number
local function executeElevator(eId, floorId)
    if not eId then
        return
    end

    local floor = config[eId]

    if not floor then
        return
    end

    if not floor[floorId] then
        return
    end

    local destination = floor[floorId]
    local isInVehicle = destination.allowVehicle and cache.vehicle

    local liftReady = lib.progressBar({
        label = 'Waiting elevator...',
        duration = 5000,
        useWhileDead = false,
        canCancel = true,
        disable = {
            combat = true,
            move = true,
            car = true
        },
        anim = not isInVehicle and {
            dict = 'anim@apt_trans@elevator',
            clip = 'elev_1'
        } or nil
    })

    if not liftReady then
        return
    end

    if not isInVehicle then
        StopAnimTask(cache.ped, "anim@apt_trans@elevator", "elev_1", 1.0)
    end
    DoScreenFadeOut(500)
    Wait(1000)
    if isInVehicle then
        SetPedCoordsKeepVehicle(cache.ped, destination.coords.x, destination.coords.y, destination.coords.z)
        SetVehicleOnGroundProperly(cache.vehicle)
        SetEntityHeading(cache.vehicle, destination.coords.w)
    else
        SetEntityCoords(cache.ped, destination.coords.x, destination.coords.y, destination.coords.z, false, false, false, false)
        SetEntityHeading(cache.ped, destination.coords.w)
    end
    Wait(1000)
    DoScreenFadeIn(600)
end

interface.callback('selectFloor', function (data, cb)
    cb('ok')
    interface.focus(false, false)
    closeFrame()
    if not elevatorId then
        return
    end

    executeElevator(elevatorId, data.floorId)
    elevatorId = nil
end)

interface.callback('closeElevator', function (data, cb)
    cb('ok')
    elevatorId = nil
    interface.focus(false, false)
    closeFrame()
end)

local function setUpPoints(coords, eId)
    local points = lib.points.new(coords.xyz, 1.5)
    
    function points:onExit()
        if floorsTextInfo then
            infoUI.remove('elevator_information')
            floorsTextInfo = false
        end
    end

    function points:nearby()
        if self.currentDistance < 1.5 then
            if not floorsTextInfo then
                local description = [[
                [kbd]E[/kbd] untuk menggunakan elevator
                ]]
                infoUI.show({
                    id = 'elevator_information',
                    title = 'Elevator',
                    icon = 'fa-solid fa-building',
                    description = description,
                })
                floorsTextInfo = true
            end

            if IsControlJustPressed(0, 51) then
                elevatorId = eId
                prepareElevator(eId)
            end
        end
    end
end

CreateThread(function ()
    for eId, floors in pairs(config) do
        lib.array.forEach(floors, function (floor)
            setUpPoints(floor.coords, eId)
        end)
    end
end)