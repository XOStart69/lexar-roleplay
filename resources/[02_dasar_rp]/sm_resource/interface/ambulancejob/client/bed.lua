local currentBed = nil
local currentBedIndex = nil

local bedlist = localmodule 'data.bed'

local function leaveBed()
    if not playerState.inMedicBed or not currentBed then
        return
    end

    ClearPedTasks(cache.ped)

    SetEntityCollision(cache.ped, true, true)
    FreezeEntityPosition(cache.ped, false)

    local bed_data = currentBedIndex and bedlist[currentBedIndex]
    local wakeX, wakeY, wakeZ, wakeH

    if bed_data and bed_data.model then
        local configCoords = bed_data.coords
        local object = GetClosestObjectOfType(configCoords.x, configCoords.y, configCoords.z, 1.5, joaat(bed_data.model), false, false, false)

        if object and DoesEntityExist(object) then
            local objPos = GetEntityCoords(object)
            local objHeading = (GetEntityHeading(object) + 180.0) % 360.0
            local _, max = GetModelDimensions(joaat(bed_data.model))

            wakeX = objPos.x
            wakeY = objPos.y
            wakeZ = objPos.z + max.z - 1.52
            wakeH = objHeading + 90.0
        end
    end

    if not wakeX then
        wakeX = currentBed.x
        wakeY = currentBed.y
        wakeZ = currentBed.z - 1.5
        wakeH = currentBed.w + 90.0
    end

    SetEntityCoords(cache.ped, wakeX, wakeY, wakeZ, false, false, false, true)
    SetEntityHeading(cache.ped, wakeH)

    local dict = "switch@franklin@bed"
    local anim = "sleep_getup_rubeyes"

    lib.playAnim(cache.ped, dict, anim, 100.0, 1.0, -1, 8, -1, false, false, false)

    Wait(4000)

    ClearPedTasks(cache.ped)
    infoUI.remove('ambulance:bed')

    currentBed = nil
    currentBedIndex = nil

    playerState.canEmote = true
    playerState.inMedicBed = false

    TriggerTokenEvent('ambulance:bed:leave')
end

local function sleepInBed(index, check, reviveTime, isTreatment)
    local inuse = lib.callback.await('ambulance:bed:isUse', 1500, index)

    if check and inuse then
        return lib.notify({
            description = 'Tidak bisa berbaring disini.',
            type = 'error'
        })
    end

    local bed_data = bedlist[index]
    local is_revive = reviveTime and type(reviveTime) == 'number' and reviveTime > 0

    local object
    local coords = bed_data.coords

    if is_revive then
        DoScreenFadeOut(400)
        Wait(1500)
    end

    if bed_data.model then
        object = GetClosestObjectOfType(coords.x, coords.y, coords.z, 1.5, joaat(bed_data.model), false, false, false)

        if object and DoesEntityExist(object) then
            FreezeEntityPosition(object, true)

            local objPos = GetEntityCoords(object)
            local objHeading = (GetEntityHeading(object) + 180.0) % 360.0
            local min, max = GetModelDimensions(joaat(bed_data.model))
            local bedHeight = max.z - min.z
            coords = vec(objPos.x, objPos.y, objPos.z + bedHeight - 0.9, objHeading)
        end
    else
        coords = vec(coords.x, coords.y, coords.z, coords.w)
    end

    currentBed = coords
    currentBedIndex = index

    playerState.canEmote = false
    playerState.inMedicBed = true

    SetEntityCollision(cache.ped, false, true)
    FreezeEntityPosition(cache.ped, true)

    SetEntityCoords(cache.ped, currentBed.x, currentBed.y, currentBed.z, false, false, false, true)
    SetEntityHeading(cache.ped, currentBed.w)

    Wait(100)

    if IsPedDeadOrDying(cache.ped) then
        local pos = GetEntityCoords(cache.ped)
        NetworkResurrectLocalPlayer(pos.x, pos.y, pos.z, GetEntityHeading(cache.ped), true, false)
    end

    ClearPedTasks(cache.ped)
    Wait(50)

    local anim, dict

    if bed_data.interact == 'target' then
        dict = "anim@gangops@morgue@table@"
        anim = "body_search"
    else
        dict = "anim@gangops@morgue@table@"
        anim = "body_search"
    end

    lib.playAnim(cache.ped, dict, anim, 8.0, -8.0, -1, 1, 0.0, false, false, false)

    if is_revive then
        Wait(1500)
        DoScreenFadeIn(400)
        playerState.inMedicRevive = true

        infoUI.show({
            id = 'ambulance:bed',
            title = 'Bed Information',
            description = 'Kamu sedang di obati...',
            icon = 'fas fa-bed'
        })

        local start = GetGameTimer()

        repeat
            Wait(50)
        until GetGameTimer() - start > reviveTime

        if isTreatment then
            TriggerTokenEvent('ambulance:treatment:heal')
            lib.notify({ description = 'Luka kamu telah diobati!', type = 'success' })
        else
            TriggerTokenEvent('ambulance:reviveplayer', cache.serverId)
            lib.notify({ description = 'Kamu telah diobati..', type = 'success' })
        end
    end

    infoUI.show({
        id = 'ambulance:bed',
        title = 'Bed Information',
        description = 'Tekan E untuk bangun',
        icon = 'fas fa-bed'
    })

    CreateThread(function()
        while playerState.inMedicBed do
            DisableControlAction(0, 38, false)
            if IsControlJustPressed(0, 38) or IsDisabledControlJustPressed(0, 38) then
                leaveBed()
                break
            end
            Wait(10)
        end
    end)
end

RegisterNetEvent('ambulance:bed:send_checkin', function(args)
    if source == '' then return end

    local index, time, isTreatment = table.unpack(args)
    sleepInBed(index, false, time, isTreatment)
end)

CreateThread(function ()
    for i=1, #bedlist do
        local val = bedlist[i]
        local bedindex = i
        local coords = val.coords

        if val.model and type(val.model) == 'string' then
            coords = vec(coords.x, coords.y, coords.z, coords.w)
        end

        if val.interact == 'interact' then
            exports.rhd_interact:addCoords({
                coords = vec(coords.x, coords.y, coords.z),
                options = {
                    {
                        label = "Tidur",
                        icon = "fa-solid fa-bed",
                        distance = 2.0,
                        onSelect = function(data)
                            sleepInBed(bedindex, true)
                        end,
                        canInteract = function()
                            return not playerState.inMedicBed
                        end
                    }
                }
            })
            goto next
        end

        ox_target:addSphereZone({
            coords = vec(coords.x, coords.y, coords.z),
            radius = 1.0,
            options = {
                {
                    label = 'Tidur',
                    icon = 'fas fa-bed',
                    canInteract = function ()
                        return not playerState.inMedicBed
                    end,
                    onSelect = function ()
                        sleepInBed(bedindex, true)
                    end
                }
            }
        })

        ::next::
    end
end)

RegisterNetEvent('ambulance:bed:transferPatient', function (index)
    if source == '' then return end
    if type(index) ~= 'number' or not bedlist[index] then return end
    if playerState.inMedicBed then return end

    if exports['sm_resource_1']:releaseFromStretcher() then
        Wait(100)
    end

    sleepInBed(index, false)
end)

exports('getBedList', function ()
    return bedlist
end)
