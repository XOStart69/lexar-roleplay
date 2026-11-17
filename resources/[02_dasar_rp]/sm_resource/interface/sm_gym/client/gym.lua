if not interface.init(false) then return end

local minigameZone = 'mid'
local minigameCounter = 0
local minigameBusy = false

local inZone
local config = localmodule 'config.gym'
local pedModule = require 'modules.pedHandle.client'
local blipModule = require 'modules.blipHandle.client'

local inWorkOut = false
local gymPropEntities = {}
local gymWorkOutProps = {}

local targetModelCreated = {}

local function handleCounter()
    minigameCounter += 1
    if minigameCounter % 10 == 0 then
        minigameCounter = 0
        TriggerTokenEvent('sm_gym:server:add')
    end
    TriggerTokenEvent('sm_hud:server:removeStress', config.stressReduction or 1)
end

local function clearWorkOutProps()
    if #gymWorkOutProps > 0 then
        for i = 1, #gymWorkOutProps do
            local prop = gymWorkOutProps[i]
            if DoesEntityExist(prop) then
                DeleteObject(prop)
            end
        end
        gymWorkOutProps = {}
    end
end

local function stopWorkout(anim)
    inWorkOut = false
    minigameBusy = false
    minigameCounter = 0

    interface.send({
        action = 'setMinigame',
        data = { status = false }
    })
    interface.hide()

    TaskPlayAnim(cache.ped, anim.exit.dict, anim.exit.clip, 8.0, -8.0, -1, 0, 0.0, false, false, false)

    if #gymWorkOutProps > 0 then
        Wait(5000)
        clearWorkOutProps()
    end

    FreezeEntityPosition(cache.ped, false)

    repeat
        Wait(100)
    until not IsEntityPlayingAnim(cache.ped, anim.exit.dict, anim.exit.clip, 1)
    ClearPedTasks(cache.ped)
end

local function startAnimThread(animData)
    local anim = animData.anim
    local idle = anim.idle
    local start = anim.start
    local enter = anim.enter

    if enter then
        TaskPlayAnim(cache.ped, enter.dict, enter.clip, 8.0, -8.0, -1, 1, 0.0, false, false, false)
        Wait(enter.time or 2000)
    end

    TaskPlayAnim(cache.ped, idle.dict, idle.clip, 8.0, -8.0, -1, 1, 0.0, false, false, false)

    interface.show()
    interface.send({
        action = 'setMinigame',
        data = {
            key = 'H',
            count = minigameCounter,
            status = true
        }
    })

    while inWorkOut do
        DisableControlAction(0, 74, true)
        DisableControlAction(0, 58, true)

        if IsDisabledControlJustPressed(0, 74) and not minigameBusy then
            minigameBusy = true
            if minigameZone == 'green' then
                handleCounter()
                interface.send({
                    action = 'setMinigame',
                    data = { count = minigameCounter }
                })
                CreateThread(function ()
                    FreezeEntityPosition(cache.ped, not animData.FreezePedOnWorkOut)
                    TaskPlayAnim(cache.ped, start.dict, start.clip, 8.0, -8.0, -1, 1, 0.0, false, false, false)
                    Wait(start.time or 2000)
                    if inWorkOut then
                        FreezeEntityPosition(cache.ped, true)
                        TaskPlayAnim(cache.ped, idle.dict, idle.clip, 8.0, -8.0, -1, 1, 0.0, false, false, false)
                    end
                    minigameBusy = false
                end)
            elseif minigameZone == 'red' then
                CreateThread(function ()
                    if animData.clearWorkOutPropsFirst then
                        clearWorkOutProps()
                    end
                    stopWorkout(anim)
                end)
            else
                minigameBusy = false
            end
        elseif IsDisabledControlJustPressed(0, 58) then
            CreateThread(function ()
                if animData.clearWorkOutPropsFirst then
                    clearWorkOutProps()
                end
                stopWorkout(anim)
            end)
        end

        Wait(0)
    end
end

local function startGymAnim(animData)
    local gymProp = animData.gymProp
    local model = gymProp?.model
    local offset = animData.offset
    local anim = animData.anim

    if inWorkOut then
        return lib.notify({
            title = 'Gym',
            description = 'Kamu sedang berolahraga.',
            type = 'error'
        })
    end

    local isMember = lib.callback.await('sm_gym:server:checkMember', 500, inZone)

    if not isMember then
        return
    end


    local offsetHeading = offset?.heading or 180.0

    FreezeEntityPosition(cache.ped, true)

    if model then
        local pcoords = GetEntityCoords(cache.ped)
        local closestObj = GetClosestObjectOfType(pcoords.x, pcoords.y, pcoords.z, 1.2, joaat(model), gymProp?.mission_entity or false, 0, 0)

        if not (closestObj and DoesEntityExist(closestObj)) then
            return lib.notify({
                title = 'Gym',
                description = 'Tidak ada alat olahraga di dekatmu.',
                type = 'error'
            })
        end

        local offsetHeight = offset?.height or 0.0
        local offsetX = offset?.x or 0.0
        local offsetY = offset?.y or 0.0
        local closestObjOffset = GetOffsetFromEntityInWorldCoords(closestObj, offsetX, offsetY, offsetHeight)

        SetEntityCoordsNoOffset(cache.ped, closestObjOffset.x, closestObjOffset.y, closestObjOffset.z)
        SetEntityHeading(cache.ped, GetEntityHeading(closestObj) + offsetHeading) 
    elseif animData.playerCoords then
        local coords = animData.playerCoords
        SetEntityCoordsNoOffset(cache.ped, coords.x, coords.y, coords.z)
        SetEntityHeading(cache.ped, coords.w)
    end

    for k, v in pairs(anim) do
        lib.requestAnimDict(v.dict, 1500)
    end

    if animData.prop then
        for i=1, #animData.prop do
            local propData = animData.prop[i]
            local propModel = propData.model
            local boneIndex = propData.boneIndex
            local boneId = propData.boneId
            local pos = propData.pos
            local rot = propData.rot

            lib.requestModel(propModel, 1500)

            local pedBone = boneId or GetPedBoneIndex(cache.ped, boneIndex)
            local propEntity = CreateObject(propModel, 0.0, 0.0, 0.0, false, true, false)
            AttachEntityToEntity(propEntity, cache.ped, pedBone, pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, true, true, false, true, 1, true)
            SetModelAsNoLongerNeeded(propModel)
            table.insert(gymWorkOutProps, propEntity)
        end
    end

    inWorkOut = true

    if anim.idle then
        startAnimThread(animData)
    else

    end
end

local cmdAction = {}
function setupCmdAction(action, data)

    if cmdAction[action] then
        return
    end

    cmdAction[action] = function ()
        if not inZone then
            return lib.notify({
                title = 'Gym',
                description = 'Kamu tidak berada di area gym.',
                type = 'error'
            })
        end

        if inWorkOut then
            return lib.notify({
                title = 'Gym',
                description = 'Kamu sedang berolahraga.',
                type = 'error'
            })
        end

        return startGymAnim(data)
    end
end

local function setupGymInteract(animData)
    for i=1, #animData do
        local data = animData[i]
        local model = data.gymProp?.model

        if model then
            if not targetModelCreated[model] then
                targetModelCreated[model] = true
                ox_target:addModel(model, {
                    {
                        icon = 'fas fa-circle-info',
                        label = 'Gunakan alat',
                        onSelect = function ()
                            startGymAnim(data)
                        end,
                        canInteract = function ()
                            return inZone and not inWorkOut
                        end,
                        distance = 1.5
                    }
                })
            end
        elseif data.interact then
            for z=1, #data.interact do
                local interact = data.interact[z]
                interact.options = {
                    {
                        icon = 'fas fa-circle-info',
                        label = interact.label or 'Gunakan alat',
                        onSelect = function ()
                            startGymAnim(data)
                        end,
                        canInteract = function ()
                            return inZone and not inWorkOut
                        end,
                        distance = 1.5
                    }
                }
                if interact.type == 'box' then
                    ox_target:addBoxZone(interact)
                elseif interact.type == 'poly' then
                    ox_target:addPolyZone(interact)
                end
            end
        elseif data.command then
            setupCmdAction(data.command, data)
        end
    end
end

local function setupGymProps(animData)
    for i=1, #animData do
        local data = animData[i]
        local model = data.gymProp?.model
        local propCoords = data.gymProp?.coords

        if model and propCoords then
            model = type(model) == 'string' and joaat(model) or model

            pcall(lib.requestModel, model, 15000)
            array.forEach(propCoords, function (coords)
                local propEntity = CreateObject(model, coords.x, coords.y, coords.z, false, true, false)
                FreezeEntityPosition(propEntity, true)
                SetEntityHeading(propEntity, coords.w)
                SetModelAsNoLongerNeeded(model)
                SetEntityLodDist(propEntity, 40)
                table.insert(gymPropEntities, propEntity)
            end)
        end
    end
end

interface.callback('minigameZone', function (data, cb)
    minigameZone = data.zone
    cb('ok')
end)

RegisterCommand('gym', function (_, args)
    local action = args[1]
    if cmdAction[action] then
        cmdAction[action]()
    end
end)

CreateThread(function ()
    for k, v in pairs(config.location) do
        if v.polygon then
            local zones = lib.zones.poly(v.polygon)
            local animData = v.anim_data

            if v.blip then
                v.blip.coords = zones.coords
                blipModule:new(v.blip)
            end

            setupGymInteract(animData)
            setupGymProps(animData)

            function zones:onEnter()
                inZone = k

                infoUI.show({
                    id = 'gym_minigame:help',
                    title = 'Gym Information',
                    icon = 'fas fa-dumbbell',
                    description = [[
                    [center]**MINIGAME**[/center]
                    [center]Tekan [kbd]H[/kbd] pada area hijau[/center]
                    [center]untuk mendapatkan poin gym[/center]

                    [center]Tekan [kbd]G[/kbd] jika ingin berhenti[/center]
                    
                    [center]**COMMAND**[/center]
                    [center]Jika ingin melakukan pushup atau situp,[/center]
                    [center]kamu bisa menggunakan command berikut:[/center]
                    [center][kbd]/gym pushup[/kbd] untuk pushup[/center]
                    [center][kbd]/gym situp[/kbd] untuk situp[/center]
                    
                    [center]**NOTE**[/center]
                    [center]Pastikan kamu berada di area gym.[/center]
                    ]]
                })

                if v.ped and not self.pedHandle then
                    v.ped.target = {
                        {
                            label = 'Daftar Member',
                            icon = 'fas fa-id-card',
                            onSelect = function ()
                                local input = lib.inputDialog('Pendaftaran Member', {
                                    {type = 'select', label = 'Pilih paket', default = v.price[1].value, options = array.map(v.price, function (item)
                                        return { value = item.value, label = item.label .. ' - $ ' .. item.price }
                                    end)},
                                })

                                if not input then return end
                                
                                TriggerTokenEvent('sm_gym:server:registerMember', { k, input[1] })
                            end,
                            canInteract = function ()
                                return inZone and not inWorkOut
                            end,
                        }
                    }

                    self.pedHandle = pedModule:new(v.ped)
                end
            end

            function zones:onExit()
                inZone = nil
                infoUI.remove('gym_minigame:help')

                if self.pedHandle then
                    self.pedHandle:remove()
                    self.pedHandle = nil
                end
            end
        end
    end
end)

AddEventHandler('onResourceStop', function (resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    for i=1, #gymPropEntities do
        local propEntity = gymPropEntities[i]
        if DoesEntityExist(propEntity) then
            DeleteObject(propEntity)
        end
    end

    for i=1, #gymWorkOutProps do
        local propEntity = gymWorkOutProps[i]
        if DoesEntityExist(propEntity) then
            DeleteObject(propEntity)
        end
    end
end)