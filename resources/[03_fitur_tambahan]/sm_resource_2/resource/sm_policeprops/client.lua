local config = localmodule 'config'
local infoui = exports.rhd_infoui

local Wait = Wait
local GetGameTimer = GetGameTimer
local GetEntityCoords = GetEntityCoords
local GetEntityHeading = GetEntityHeading
local DoesEntityExist = DoesEntityExist
local DeleteEntity = DeleteEntity
local GetEntityBoneIndexByName = GetEntityBoneIndexByName
local GetWorldPositionOfEntityBone = GetWorldPositionOfEntityBone
local SetVehicleTyreBurst = SetVehicleTyreBurst
local IsDisabledControlPressed = IsDisabledControlPressed
local IsDisabledControlJustPressed = IsDisabledControlJustPressed
local rad, sin, cos, abs = math.rad, math.sin, math.cos, math.abs

local groups = config.groups
local objects = config.objects
local spike = config.spike
local anim = config.anim
local gizmo = config.gizmo
local syncRadius = config.syncRadius
local SPIKE_KIND = 'spikestrip'
local INFO_ID = 'sm_policeprops:gizmo'
local HALF_SPIKE = spike.length * 0.5
local SPIKE_WIDTH = spike.width
local SPIKE_ZONE = spike.zoneRadius

local TIRES = {
    { bone = 'wheel_lf', index = 0 },
    { bone = 'wheel_rf', index = 1 },
    { bone = 'wheel_lm', index = 2 },
    { bone = 'wheel_rm', index = 3 },
    { bone = 'wheel_lr', index = 4 },
    { bone = 'wheel_rr', index = 5 },
}

---@type table<string, table>
local props = {}
local streaming = false
local placing = false
local spikeLoop = false

---@param kind string
---@return table?
local function kindConfig(kind)
    return kind == SPIKE_KIND and spike or objects[kind]
end

---@param groupName string
---@return boolean
local function hasAccess(groupName)
    local group = groups[groupName]
    local job = QBPlayerData.job
    if not group or not job then return false end
    if group.requireDuty and not job.onduty then return false end
    local minGrade = group.jobs[job.name]
    return minGrade ~= nil and (job.grade and job.grade.level or 0) >= minGrade
end

---@param duration number
---@param label string
---@return boolean
local function playProgress(duration, label)
    local ped = cache.ped
    lib.requestAnimDict(anim.dict)
    TaskPlayAnim(ped, anim.dict, anim.clip, 8.0, 8.0, -1, 16, 0, false, false, false)
    local done = lib.progressBar({
        duration = duration,
        label = label,
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
    })
    ClearPedTasks(ped)
    RemoveAnimDict(anim.dict)
    return done
end

local PLACE_ERRORS = {
    limit = 'Batas maksimum tercapai.',
    cooldown = 'Terlalu cepat, tunggu sebentar.',
    item = 'Item tidak ada di inventory.',
    access = 'Kamu tidak punya akses.',
}

---@param id string
local function pickup(id)
    if not playProgress(config.pickupDuration, 'Mengambil...') then return end
    local ok, err = lib.callback.await('sm_policeprops:pickup', false, id)
    if ok then
        lib.notify({ description = 'Berhasil diambil.', type = 'success' })
    elseif err == 'space' then
        lib.notify({ description = 'Inventory penuh.', type = 'error' })
    end
end

---@param prop table
local function despawn(prop)
    local entity = prop.entity
    prop.entity = nil
    if entity and DoesEntityExist(entity) then
        ox_target:removeLocalEntity(entity)
        DeleteEntity(entity)
    end
end

---@param prop table
local function spawn(prop)
    if prop.entity or prop.loading then return end
    local cfg = kindConfig(prop.kind)
    if not cfg then return end

    prop.loading = true
    local ok = pcall(lib.requestModel, cfg.model, 10000)
    prop.loading = false
    if not ok or props[prop.id] ~= prop or prop.entity then return end

    local entity = CreateObject(cfg.model, prop.x, prop.y, prop.z, false, false, false)
    SetModelAsNoLongerNeeded(cfg.model)
    if entity == 0 then return end

    if (prop.pitch or 0.0) ~= 0.0 or (prop.roll or 0.0) ~= 0.0 then
        SetEntityRotation(entity, prop.pitch, prop.roll, prop.heading, 2, true)
    else
        PlaceObjectOnGroundProperly(entity)
        SetEntityHeading(entity, prop.heading)
    end
    FreezeEntityPosition(entity, prop.kind == SPIKE_KIND or cfg.freeze == true)
    prop.entity = entity

    local groupName = cfg.group
    local id = prop.id
    ox_target:addLocalEntity(entity, {
        {
            name = 'sm_policeprops:pickup',
            icon = 'fas fa-hand-holding',
            label = 'Ambil ' .. cfg.label,
            distance = 2.5,
            canInteract = function() return hasAccess(groupName) end,
            onSelect = function() pickup(id) end,
        },
    })
end

local function startStreaming()
    if streaming then return end
    streaming = true

    CreateThread(function()
        local interval = config.streamInterval
        while next(props) do
            local origin = GetEntityCoords(cache.ped)
            for _, prop in pairs(props) do
                local dx, dy = prop.x - origin.x, prop.y - origin.y
                local inRange = dx * dx + dy * dy <= syncRadius * syncRadius
                if inRange and not prop.entity then
                    spawn(prop)
                elseif not inRange and prop.entity then
                    despawn(prop)
                end
            end
            Wait(interval)
        end
        streaming = false
    end)
end

---@param data table
local function register(data)
    local existing = props[data.id]
    if existing then despawn(existing) end

    local prop = {
        id = data.id,
        kind = data.kind,
        x = data.x, y = data.y, z = data.z,
        heading = data.heading, pitch = data.pitch, roll = data.roll,
        owner = data.owner,
    }
    props[data.id] = prop

    local origin = GetEntityCoords(cache.ped)
    if #(origin - vector3(prop.x, prop.y, prop.z)) <= syncRadius then
        CreateThread(function() spawn(prop) end)
    end
    startStreaming()
end

---@param id string
local function unregister(id)
    local prop = props[id]
    if not prop then return end
    props[id] = nil
    despawn(prop)
end

AddStateBagChangeHandler(nil, 'global', function(_, key, value)
    local id = key:match('^smprop:(.+)$')
    if not id then return end
    if value then
        register(value)
    else
        unregister(id)
    end
end)

CreateThread(function()
    local all = lib.callback.await('sm_policeprops:getAll', false)
    if not all then return end
    for i = 1, #all do
        register(all[i])
    end
end)

---@param groupName string
---@param isSpike boolean
---@return number
local function myCount(groupName, isSpike)
    local me, count = cache.serverId, 0
    for _, prop in pairs(props) do
        if prop.owner == me then
            if isSpike then
                if prop.kind == SPIKE_KIND then count = count + 1 end
            else
                local cfg = objects[prop.kind]
                if cfg and cfg.group == groupName then count = count + 1 end
            end
        end
    end
    return count
end

---@return boolean hit
---@return vector3 coords
local function cameraRay()
    local rot = GetGameplayCamRot(2)
    local from = GetGameplayCamCoord()
    local rx, rz = rad(rot.x), rad(rot.z)
    local horizontal = abs(cos(rx))
    local to = from + vector3(-sin(rz) * horizontal, cos(rz) * horizontal, sin(rx)) * gizmo.rayDistance
    local handle = StartExpensiveSynchronousShapeTestLosProbe(from.x, from.y, from.z, to.x, to.y, to.z, 1 + 16, cache.ped, 4)
    local _, hit, coords = GetShapeTestResult(handle)
    return hit == 1, coords
end

local POSITION_HINT = '[kbd]←[/kbd] [kbd]→[/kbd] Putar\n[kbd]↑[/kbd] [kbd]↓[/kbd] Naik/Turun\n[kbd]TAB[/kbd] Mode rotasi\n[kbd]ENTER[/kbd] Pasang  [kbd]DEL[/kbd] Batal'
local ROTATE_HINT = '[kbd]←[/kbd] [kbd]→[/kbd] Heading\n[kbd]↑[/kbd] [kbd]↓[/kbd] Pitch\n[kbd]Q[/kbd] [kbd]E[/kbd] Roll\n[kbd]TAB[/kbd] Mode posisi\n[kbd]ENTER[/kbd] Pasang  [kbd]DEL[/kbd] Batal'

---@param label string
---@param hint string
local function showHint(label, hint)
    infoui:show({ id = INFO_ID, title = label, icon = 'fa-solid fa-up-down-left-right', description = hint })
end

---@param kind string
local function placeObject(kind)
    local cfg = objects[kind]
    if not cfg or placing then return end
    if cache.vehicle then
        return lib.notify({ description = 'Keluar dari kendaraan dulu.', type = 'error' })
    end
    if not hasAccess(cfg.group) then
        return lib.notify({ description = groups[cfg.group].noAccess, type = 'error' })
    end
    if myCount(cfg.group, false) >= groups[cfg.group].maxPerPlayer then
        return lib.notify({ description = PLACE_ERRORS.limit, type = 'error' })
    end

    placing = true
    lib.requestModel(cfg.model, 10000)

    local ped = cache.ped
    local origin = GetEntityCoords(ped)
    local ghost = CreateObject(cfg.model, origin.x, origin.y, origin.z, false, false, false)
    SetModelAsNoLongerNeeded(cfg.model)
    SetEntityCollision(ghost, false, false)
    SetEntityAlpha(ghost, 180, false)

    local heading, pitch, roll, zOffset = GetEntityHeading(ped), 0.0, 0.0, 0.0
    local lastHit = origin
    local rotateMode = false
    local rotateSpeed, verticalSpeed, maxTilt = gizmo.rotateSpeed, gizmo.verticalSpeed, gizmo.maxTilt
    local result

    showHint(cfg.label, POSITION_HINT)

    while true do
        DisableAllControlActions(0)
        EnableControlAction(0, 1, true)
        EnableControlAction(0, 2, true)
        EnableControlAction(0, 245, true)

        if IsDisabledControlJustPressed(0, 37) then
            rotateMode = not rotateMode
            showHint(cfg.label, rotateMode and ROTATE_HINT or POSITION_HINT)
        end

        if IsDisabledControlPressed(0, 174) then heading = heading - rotateSpeed end
        if IsDisabledControlPressed(0, 175) then heading = heading + rotateSpeed end

        if rotateMode then
            if IsDisabledControlPressed(0, 172) then pitch = pitch + rotateSpeed end
            if IsDisabledControlPressed(0, 173) then pitch = pitch - rotateSpeed end
            if IsDisabledControlPressed(0, 44) then roll = roll + rotateSpeed end
            if IsDisabledControlPressed(0, 38) then roll = roll - rotateSpeed end
            pitch = pitch > maxTilt and maxTilt or pitch < -maxTilt and -maxTilt or pitch
            roll = roll > maxTilt and maxTilt or roll < -maxTilt and -maxTilt or roll
            SetEntityRotation(ghost, pitch, roll, heading, 2, true)
        else
            if IsDisabledControlPressed(0, 172) then zOffset = zOffset + verticalSpeed end
            if IsDisabledControlPressed(0, 173) then zOffset = zOffset - verticalSpeed end

            local hit, coords = cameraRay()
            if hit then lastHit = coords end
            SetEntityCoords(ghost, lastHit.x, lastHit.y, lastHit.z, false, false, false, false)
            PlaceObjectOnGroundProperly(ghost)
            if zOffset ~= 0.0 then
                local ground = GetEntityCoords(ghost)
                SetEntityCoords(ghost, ground.x, ground.y, ground.z + zOffset, false, false, false, false)
            end
            if pitch ~= 0.0 or roll ~= 0.0 then
                SetEntityRotation(ghost, pitch, roll, heading, 2, true)
            else
                SetEntityHeading(ghost, heading)
            end
        end

        if IsDisabledControlJustPressed(0, 191) then
            result = GetEntityCoords(ghost)
            break
        elseif IsDisabledControlJustPressed(0, 178) or IsDisabledControlJustPressed(0, 200) then
            break
        end

        Wait(0)
    end

    DeleteEntity(ghost)
    infoui:remove(INFO_ID)

    if result and playProgress(config.placeDuration, 'Memasang...') then
        local ok, err = lib.callback.await('sm_policeprops:place', false, kind, { x = result.x, y = result.y, z = result.z }, heading % 360.0, pitch, roll)
        if ok then
            lib.notify({ description = cfg.label .. ' terpasang.', type = 'success' })
        else
            lib.notify({ description = PLACE_ERRORS[err] or 'Gagal memasang.', type = 'error' })
        end
    end

    placing = false
end

local function placeSpike()
    if placing then return end
    if cache.vehicle then
        return lib.notify({ description = 'Keluar dari kendaraan dulu.', type = 'error' })
    end

    placing = true
    local ped = cache.ped
    local front = GetOffsetFromEntityInWorldCoords(ped, 0.0, spike.placeForward, 0.0)
    local found, groundZ = GetGroundZFor_3dCoord(front.x, front.y, front.z + 1.0, false)
    local heading = GetEntityHeading(ped)

    if playProgress(spike.placeDuration, 'Memasang...') then
        local ok, err = lib.callback.await('sm_policeprops:placeSpike', false, { x = front.x, y = front.y, z = found and groundZ or front.z }, heading)
        if ok then
            lib.notify({ description = spike.label .. ' terpasang.', type = 'success' })
        else
            lib.notify({ description = PLACE_ERRORS[err] or 'Gagal memasang.', type = 'error' })
        end
    end
    placing = false
end

RegisterNetEvent('sm_policeprops:client:place', placeObject)
RegisterNetEvent('sm_policeprops:client:useSpike', placeSpike)

RegisterNetEvent('sm_policeprops:client:burst', function(netId, tire)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if vehicle ~= 0 and DoesEntityExist(vehicle) then
        SetVehicleTyreBurst(vehicle, tire, false, 1000.0)
    end
end)

---@type table<string, number>
local burstSent = {}

local function checkSpikes(vehicle)
    local origin = GetEntityCoords(vehicle)
    local near = false
    local now = GetGameTimer()

    for id, prop in pairs(props) do
        if prop.kind == SPIKE_KIND then
            local dx, dy = prop.x - origin.x, prop.y - origin.y
            if dx * dx + dy * dy < SPIKE_ZONE * SPIKE_ZONE then
                near = true
                local h = rad(prop.heading)
                local fx, fy = -sin(h), cos(h)
                for i = 1, #TIRES do
                    local tire = TIRES[i]
                    local bone = GetEntityBoneIndexByName(vehicle, tire.bone)
                    if bone ~= -1 then
                        local pos = GetWorldPositionOfEntityBone(vehicle, bone)
                        local rx, ry, rz = pos.x - prop.x, pos.y - prop.y, pos.z - prop.z
                        local along = rx * fx + ry * fy
                        local px, py = rx - fx * along, ry - fy * along
                        if abs(along) < HALF_SPIKE and (px * px + py * py + rz * rz) < SPIKE_WIDTH * SPIKE_WIDTH then
                            local key = id .. ':' .. tire.index
                            if not burstSent[key] or now - burstSent[key] > spike.burstCooldown then
                                burstSent[key] = now
                                SetVehicleTyreBurst(vehicle, tire.index, false, 1000.0)
                                local netId = NetworkGetNetworkIdFromEntity(vehicle)
                                if netId ~= 0 then
                                    TriggerTokenEvent('sm_policeprops:server:burst', id, netId, tire.index)
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return near
end

lib.onCache('vehicle', function(vehicle)
    if not vehicle or spikeLoop then return end
    spikeLoop = true
    CreateThread(function()
        while cache.vehicle do
            Wait(checkSpikes(cache.vehicle) and 50 or 500)
        end
        spikeLoop = false
        table.wipe(burstSent)
    end)
end)

RegisterCommand('policetools', function()
    if not hasAccess('police') then
        return lib.notify({ description = groups.police.noAccess, type = 'error' })
    end
    if cache.vehicle then
        return lib.notify({ description = 'Keluar dari kendaraan dulu.', type = 'error' })
    end
    if placing then return end

    local count = myCount('police', false)
    local limit = groups.police.maxPerPlayer
    local options = {}
    for kind, cfg in pairs(objects) do
        if cfg.group == 'police' and not cfg.item then
            options[#options + 1] = {
                title = cfg.label,
                icon = cfg.icon,
                disabled = count >= limit,
                description = count >= limit and 'Batas tercapai' or nil,
                onSelect = function() placeObject(kind) end,
            }
        end
    end
    table.sort(options, function(a, b) return a.title < b.title end)

    lib.registerContext({ id = 'sm_policeprops_menu', title = ('Police Tools (%d/%d)'):format(count, limit), options = options })
    lib.showContext('sm_policeprops_menu')
end, false)

AddEventHandler('onClientResourceStop', function(resource)
    if resource ~= cache.resource then return end
    for _, prop in pairs(props) do
        despawn(prop)
    end
    infoui:remove(INFO_ID)
end)
