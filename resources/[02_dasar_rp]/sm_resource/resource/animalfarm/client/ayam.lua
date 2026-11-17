local catchzone
local isworking = false
local isAutoWorking = false
local isCatching = false
local currentMode = 'manual' --[[@as 'manual' | 'automatic']]

local catchCount = 0
local chickenEntity = {}
local proccessEntity = {}

local config = localmodule 'config.ayam'
local pedModule = require 'modules.pedHandle.client'
local blipModule = require 'modules.blipHandle.client'
local itemModule = require 'modules.items.client'

local catchcfg = config.catch
local proccesscfg = config.proccess
local packingcfg = config.packing

local CATCH_DISTANCE = 1.5
local CATCH_COOLDOWN = false
local AUTO_CHASE_SPEED = 2.0

---@return vector3
local function getRandomPos()
    assert(catchzone, 'Catch Zone belum dibuat, pastikan Catch Zone sudah dibuat menggunakan polygon')

    local points = catchcfg.polygon.points
    local minX, minY = points[1].x, points[1].y
    local maxX, maxY = minX, minY

    for i = 2, #points do
        local p = points[i]
        if p.x < minX then minX = p.x end
        if p.x > maxX then maxX = p.x end
        if p.y < minY then minY = p.y end
        if p.y > maxY then maxY = p.y end
    end

    for _ = 1, 100 do
        local rx = math.random() * (maxX - minX) + minX
        local ry = math.random() * (maxY - minY) + minY
        local point = vec3(rx, ry, points[1].z)

        if catchzone:contains(point) then
            return point
        end
    end

    local cx, cy = (minX + maxX) / 2, (minY + maxY) / 2
    return vec3(cx, cy, points[1].z)
end

---@return integer? index, number? distance
local function getNearestChicken()
    local playerCoords = GetEntityCoords(cache.ped)
    local nearestIndex, nearestDist

    for i = 1, #chickenEntity do
        local entity = chickenEntity[i]
        if DoesEntityExist(entity) then
            local chickenCoords = GetEntityCoords(entity)
            local chickenOutZone = not catchzone:contains(chickenCoords)

            if chickenOutZone then
                local coords = getRandomPos()
                SetEntityCoordsNoOffset(entity,
                    coords.x, coords.y, coords.z, true, true, false
                )
            end

            local dist = #(playerCoords - GetEntityCoords(entity))

            if not nearestDist or dist < nearestDist then
                nearestDist = dist
                nearestIndex = i
            end
        end
    end

    return nearestIndex, nearestDist
end

local function finishCatch()
    DoScreenFadeOut(500)
    Wait(500)

    isworking = true
    SetEntityCoordsNoOffset(
        cache.ped,
        catchcfg.playercoords.exit.x,
        catchcfg.playercoords.exit.y,
        catchcfg.playercoords.exit.z,
        false,
        false,
        true
    )

    Wait(500)
    DoScreenFadeIn(500)

    local cc = catchCount

    catchCount = 0
    isworking = false

    TriggerTokenEvent('af:finishcatch', cc)
end

local function catchChicken(chickenIndex)
    if CATCH_COOLDOWN then
        return
    end

    CATCH_COOLDOWN = true
    playerState.canEmote = false

    safecall.fun(function ()
        lib.playAnim(cache.ped, 'pickup_object', 'pickup_low', 8.0, -8.0, -1, 0, 0, false, false, false)
    end)

    local animDuration = (GetAnimDuration('pickup_object', 'pickup_low') * 1000) - 100

    Wait(animDuration)

    SetTimeout(2500, function ()
        CATCH_COOLDOWN = false
    end)

    if math.random() > catchcfg.chicken.chance then
        playerState.canEmote = true
        return lib.notify({
            description = 'Ayam nya lepas dari tangkapanmu!',
            type = 'error'
        })
    end

    catchCount += 1

    pcall(DeleteEntity, chickenEntity[chickenIndex])
    table.remove(chickenEntity, chickenIndex)

    lib.notify({ description = 'Ayam berhasil ditangkap', type = 'success' })

    if #chickenEntity < 1 then
        finishCatch()
    end

    playerState.canEmote = true
end

local function setupChicken()
    if not isworking then return end

    local model, count in catchcfg.chicken
    if not safecall.fun(lib.requestModel, model, 1500) then
        return
    end

    for i=1, count do
        local coords = getRandomPos()

        local chicken = CreatePed(
            4, model,
            coords.x, coords.y, coords.z, 0.0, false, false
        )
        TaskReactAndFleePed(chicken, cache.ped)
        SetEntityProofs(chicken, true, true, true, true, true, true, true, true)
        chickenEntity[#chickenEntity+1] = chicken
    end
    
    CreateThread(function ()
        while isworking and #chickenEntity > 0 do
            local index, dist = getNearestChicken()

            if index and dist then
                if currentMode == 'automatic' and not isCatching then
                    local chicken = chickenEntity[index]

                    if dist > CATCH_DISTANCE then
                        TaskGoToEntity(cache.ped, chicken, -1, CATCH_DISTANCE - 0.5, AUTO_CHASE_SPEED, 0, 0)

                        while isworking and currentMode == 'automatic' and not isCatching do
                            local newDist = #(GetEntityCoords(cache.ped) - GetEntityCoords(chicken))
                            if newDist <= CATCH_DISTANCE then break end
                            Wait(200)
                        end

                        ClearPedTasks(cache.ped)
                    end

                    if isworking and currentMode == 'automatic' and not isCatching and DoesEntityExist(chicken) then
                        isCatching = true
                        catchChicken(index)
                        isCatching = false
                    end
                elseif currentMode == 'manual' then
                    if IsControlJustPressed(0, 38) and dist <= CATCH_DISTANCE and not isCatching then -- E key
                        isCatching = true
                        catchChicken(index)
                        isCatching = false
                    end
                end
            end

            Wait(currentMode == 'manual' and 0 or 100)
        end
    end)
end

local function startWorking(already)
    DoScreenFadeOut(500)
    Wait(500)

    isworking = true
    SetEntityCoordsNoOffset(
        cache.ped,
        catchcfg.playercoords.enter.x,
        catchcfg.playercoords.enter.y,
        catchcfg.playercoords.enter.z,
        false,
        false,
        true
    )

    if not already then
        setupChicken()
    end

    Wait(500)
    DoScreenFadeIn(500)
    lib.notify({ description = 'Tangkap semua ayam!', duration = 8000 })
end

local function proccessChicken(index, auto)
    local data = proccesscfg[index]
    if not data then return end

    if not itemModule.checkRequired(data.items.remove) then
        isAutoWorking = false
        return
    end

    if proccessEntity.deadchick and DoesEntityExist(proccessEntity.deadchick) then
        pcall(DeleteEntity, proccessEntity.deadchick)
    end

    local coords, dict, clip, props in data.animation

    SetEntityCoordsNoOffset(
        cache.ped, coords.x, coords.y, coords.z, false, false, false
    )
    SetEntityHeading(cache.ped, coords.w)

    local knifeprop = props.knife
    local chickprop = props.chicken

    local model = safecall.fun(function ()
        return lib.requestModel(chickprop.model, 1500)
    end)

    if not model then return end

    isworking = true
    playerState.canEmote = false

    proccessEntity.deadchick = CreateObject(model, chickprop.pos.x, chickprop.pos.y, chickprop.pos.z, false, false, false)
    SetEntityRotation(proccessEntity.deadchick, chickprop.rot.x, chickprop.rot.y, chickprop.rot.z, chickprop.rotOrder, false)
    FreezeEntityPosition(proccessEntity.deadchick, true)

    local success = lib.progressBar({
        duration = math.random(10000, 15000),
        label = 'Memotong ayam...',
        canCancel = true,
        useWhileDead = false,
        disable = {
            move = true,
            combat = true,
            car = true
        },
        anim = {
            dict = dict,
            clip = clip
        },
        prop = knifeprop
    })

    isworking = false
    playerState.canEmote = true
    pcall(DeleteEntity, proccessEntity.deadchick)

    if success then
        proccessStatus = 'cutting_success'
        TriggerTokenEvent('af:cutting_success', index)
    end

    if success and auto and isAutoWorking then
        Wait(500)
        if isAutoWorking then
            proccessChicken(index, true)
        end
    else
        isAutoWorking = false
    end
end

local function packingChicken(index, auto)
    local dict, clip, props in packingcfg.animation

    if not itemModule.checkRequired(packingcfg.items.remove) then
        isAutoWorking = false
        return
    end

    isworking = true
    playerState.canEmote = false

    local success = lib.progressBar({
        duration = math.random(8000, 10000),
        label = 'Packing ayam...',
        canCancel = true,
        useWhileDead = false,
        disable = {
            move = true,
            combat = true,
            car = true
        },
        anim = {
            dict = dict,
            clip = clip
        },
        prop = { props.meat, props.box }
    })

    isworking = false
    playerState.canEmote = true

    if success then
        TriggerTokenEvent('af:packing_success', index)
    end

    if success and auto and isAutoWorking then
        Wait(500)
        if isAutoWorking then
            packingChicken(index, true)
        end
    else
        isAutoWorking = false
    end
end

CreateThread(function ()
    lib.registerContext({
        id = 'chicken_farm_info',
        title = 'Chicken Farm Information',
        menu = 'chicken_farmer_interaction',
        options = {
            {
                title = 'Chicken Farming Process',
                description = 'Tangkap ayam lalu proses menjadi produk',
                icon = 'fas fa-feather-alt',
                readOnly = true
            },
            {
                title = 'Processing Areas',
                description = 'Gunakan area pemrosesan untuk mengolah ayam',
                icon = 'fas fa-industry',
                readOnly = true
            }
        }
    })
    
    lib.registerContext({
        id = 'chicken_farmer_interaction',
        title = 'Chicken Farmer Services',
        options = {
            {
                title = 'Mulai Chicken Farming',
                description = 'Mulai peternakan ayam',
                icon = 'fas fa-feather-alt',
                onSelect = startWorking,
                canInteract = function ()
                    return not isworking
                end
            },
            {
                title = 'Chicken Farm Information',
                description = 'Pelajari tentang peternakan ayam',
                icon = 'fas fa-info-circle',
                onSelect = function()
                    lib.showContext('chicken_farm_info')
                end
            }
        }
    })

    if catchcfg.polygon then
        local info = [[
Tekan E untuk menangkap ayam
Tekan G untuk ganti mode (%s)
]]
        catchzone = lib.zones.poly(catchcfg.polygon)

        local function updateInfoUI()
            infoUI.show({
                id = 'chicken:catch',
                title = 'Catch info',
                description = info:format(currentMode)
            })
        end

        function catchzone:onEnter()
            if isworking then
                updateInfoUI()
            end
        end

        function catchzone:onExit()
            if isworking and #chickenEntity > 0 then
                startWorking(true)
            end

            infoUI.remove('chicken:catch')
        end

        lib.addKeybind({
            name = 'chicken_toggle_mode',
            description = 'Toggle mode tangkap ayam (manual/automatic)',
            defaultKey = 'G',
            onPressed = function ()
                if not isworking or not catchzone:contains(GetEntityCoords(cache.ped)) then return end

                if currentMode == 'manual' then
                    currentMode = 'automatic'
                else
                    currentMode = 'manual'
                    ClearPedTasks(cache.ped)
                end

                updateInfoUI()
                lib.notify({ description = 'Mode diubah ke: ' .. currentMode, type = 'info' })
            end
        })
    end

    lib.addKeybind({
        name = 'cancel_auto_work_animalfarm',
        description = 'Tekan X untuk batalkan auto kerja peternakan',
        defaultKey = 'X',
        onPressed = function ()
            if isAutoWorking then
                isAutoWorking = false
                lib.notify({ description = 'Auto kerja dihentikan!', type = 'info' })
            end
        end
    })

    if catchcfg.npc then
        local npcpoints = lib.points.new(catchcfg.npc.coords.xyz, 10, {
            entity = nil
        })

        catchcfg.npc.target = {
            {
                icon = 'fas fa-feather-alt',
                label = 'Mulai kerja chicken farmer',
                distance = 1.5,
                onSelect = function ()
                    lib.showContext('chicken_farmer_interaction')
                end,
                canInteract = function ()
                    return not isworking
                end
            },
        }

        function npcpoints:onEnter()
            if not (self.entity and self.entity:exists()) then
                self.entity = pedModule:new(catchcfg.npc)
            end
        end
        
        function npcpoints:onExit()
            if self.entity and self.entity:exists() then
                self.entity:remove()
            end
            self.entity = nil
        end
    end

    for i=1, #proccesscfg do
        local proccess = proccesscfg[i]

        if proccess.target then
            ox_target:addSphereZone({
                coords = proccess.target.coords,
                radius = proccess.target.radius,
                options = {
                    {
                        label = 'Proses ayam (Manual)',
                        icon = 'fas fa-circle-info',
                        distance = 1.5,
                        onSelect = function ()
                            proccessChicken(i, false)
                        end,
                        canInteract = function ()
                            return not isworking and not isAutoWorking
                        end
                    },
                    {
                        label = 'Proses ayam (Automatic)',
                        icon = 'fas fa-circle-info',
                        distance = 1.5,
                        onSelect = function ()
                            isAutoWorking = true
                            proccessChicken(i, true)
                        end,
                        canInteract = function ()
                            return not isworking and not isAutoWorking
                        end
                    }
                }
            })
        end
    end

    for i=1, #packingcfg.coords do
        local coords = packingcfg.coords[i]

        ox_target:addSphereZone({
            coords = coords.xyz,
            radius = 0.5,
            options = {
                {
                    label = 'Packing ayam (Manual)',
                    icon = 'fas fa-box-open',
                    distance = 1.5,
                    onSelect = function ()
                        packingChicken(i, false)
                    end,
                    canInteract = function ()
                        return not isworking and not isAutoWorking
                    end
                },
                {
                    label = 'Packing ayam (Automatic)',
                    icon = 'fas fa-box-open',
                    distance = 1.5,
                    onSelect = function ()
                        isAutoWorking = true
                        packingChicken(i, true)
                    end,
                    canInteract = function ()
                        return not isworking and not isAutoWorking
                    end
                }
            }
        })
    end

    if not config.blip then return end
    AddTextEntry("BLIP_CAT_" .. 25, "Animal Farmer")
    for _, blipdata in pairs(config.blip) do
        blipModule:new(blipdata)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        for i=1, #chickenEntity do
            local entity = chickenEntity[i]
            pcall(DeleteEntity, entity)
        end
    end
end)