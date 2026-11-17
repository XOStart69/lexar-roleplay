local spawnedPeds = {}
local activeZones = {}

local in_selling = false
local is_in_transaction = false
local has_active_session = false

local sell_count = 0
local sell_message = 'I need %sx %s. I am paying $%s.'
local sell_transaction = {}

local location_blip = {}
local location_busy = {}
local location_data = {}
local location_timeout = nil

local sell_cooldown_end = nil
local sell_cooldown_duration = 10 * 60
local sell_session_timer = nil

local cfg = localmodule 'config' ---@type Drugsell_Config
local dialog = localmodule 'utils.npc_dialog' ---@type fun(entity: integer, message: string): boolean
local area = localmodule 'data.area'

local currentBlip

local pedmodule = require 'modules.pedHandle.client'
local blipmodule = require 'modules.blipHandle.client'

local function getSidewalkPosition(center, radius)
    for _ = 1, 30 do
        local offsetX = math.random() * radius * 2 - radius
        local offsetY = math.random() * radius * 2 - radius

        local x = center.x + offsetX
        local y = center.y + offsetY
        local z = center.z

        local found, sideCoords = GetPointOnRoadSide(x, y, z, 0)

        if found and sideCoords then
            return sideCoords, math.random(0, 360) * 1.0
        end

        local safeFound, safeCoords = GetSafeCoordForPed(x, y, z, true, 0)

        if safeFound and safeCoords then
            return safeCoords, math.random(0, 360) * 1.0
        end
    end

    return nil, nil
end

local function getRuralPosition(center, radius, saZone)
    for _ = 1, 30 do
        local offsetX = math.random() * radius * 2 - radius
        local offsetY = math.random() * radius * 2 - radius

        local x = center.x + offsetX
        local y = center.y + offsetY
        local z = center.z

        local found, groundZ = GetGroundZFor_3dCoord(x, y, z + 5.0, false)
        if found then z = groundZ end

        local candidate = vec3(x, y, z)
        if saZone and saZone:contains(candidate) then
            return candidate, math.random(0, 360) * 1.0
        end
    end

    return nil, nil
end

local function sellAnim(pedEntity, onGive)
    if not (pedEntity and DoesEntityExist(pedEntity)) then
        if onGive and type(onGive) == "function" then onGive() end
        return
    end

    TaskTurnPedToFaceEntity(pedEntity, cache.ped, 1000)
    Wait(1000)

    local dict1 = "mp_common"

    RequestAnimDict(dict1)
    local timeout = 0
    while not HasAnimDictLoaded(dict1) and timeout < 3000 do
        Wait(100)
        timeout = timeout + 100
    end

    if not HasAnimDictLoaded(dict1) then
        if onGive and type(onGive) == "function" then onGive() end
        return
    end

    TaskPlayAnim(cache.ped, dict1, "givetake1_a", 8.0, -8.0, 2000, 0, 0, false, 0, false)
    TaskPlayAnim(pedEntity, dict1, "givetake1_b", 8.0, -8.0, 2000, 0, 0, false, 0, false)

    Wait(2000)

    ClearPedTasksImmediately(cache.ped)
    ClearPedTasks(pedEntity)

    RemoveAnimDict(dict1)

    if onGive and type(onGive) == "function" then
        onGive()
    end
end

local function getTotalPedCount(wrapperIndex)
    local peds = spawnedPeds[wrapperIndex]
    if not peds then return 0 end

    local count = 0
    array.forEach(peds, function(ped)
        if DoesEntityExist(ped) then
            count = count + 1
        end
    end)

    return count
end

local function removePedFromList(wrapperIndex, ped)
    local parray = spawnedPeds[wrapperIndex]
    if not parray then return end

    for i = #parray, 1, -1 do
        if parray[i] == ped then
            table.remove(parray, i)
            break
        end
    end
end

local function watchPedDeath(ped, wrapperIndex)
    local netId = NetworkGetNetworkIdFromEntity(ped)

    CreateThread(function()
        while DoesEntityExist(ped) and not IsEntityDead(ped) do
            Wait(500)
        end

        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end

        sell_transaction[netId] = nil
        removePedFromList(wrapperIndex, ped)
    end)
end

local marker_thread_active = false

local function startMarkerThread()
    if marker_thread_active then return end
    marker_thread_active = true

    local mk = cfg.marker

    CreateThread(function()
        while in_selling do
            local pcoords = RHDCache.coords.xyz
            local drew = false

            for _, parray in pairs(spawnedPeds) do
                for i = 1, #parray do
                    local ped = parray[i]

                    if DoesEntityExist(ped) and not IsEntityDead(ped) then
                        local state = Entity(ped).state
                        local drugsell = state and state.drugsell

                        if drugsell and drugsell.available
                            and drugsell.owner == QBPlayerData.citizenid
                            and not state.busy then

                            local coords = GetEntityCoords(ped)
                            if #(pcoords - coords) <= mk.drawDistance then
                                DrawMarker(
                                    mk.type,
                                    coords.x, coords.y, coords.z + mk.height,
                                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                                    mk.size.x, mk.size.y, mk.size.z,
                                    mk.color.r, mk.color.g, mk.color.b, mk.color.a,
                                    false, true, 2, nil, nil, false
                                )
                                drew = true
                            end
                        end
                    end
                end
            end

            Wait(drew and 0 or 500)
        end

        marker_thread_active = false
    end)
end

local function getPolyBounds(points)
    local minX, maxX = math.huge, -math.huge
    local minY, maxY = math.huge, -math.huge
    local avgZ = 0.0

    for _, p in ipairs(points) do
        minX = math.min(minX, p.x)
        maxX = math.max(maxX, p.x)
        minY = math.min(minY, p.y)
        maxY = math.max(maxY, p.y)
        avgZ = avgZ + p.z
    end

    avgZ = avgZ / #points
    local cx = (minX + maxX) / 2
    local cy = (minY + maxY) / 2
    local rx = (maxX - minX) / 2
    local ry = (maxY - minY) / 2

    return vec3(cx, cy, avgZ), math.max(rx, ry)
end

local function spawnPed(wrapperIndex, spawnAreaZones)
    if not spawnedPeds[wrapperIndex] then
        spawnedPeds[wrapperIndex] = {}
    end

    if getTotalPedCount(wrapperIndex) >= cfg.maxPeds then return end

    local areaData = area[wrapperIndex]
    if not areaData or not areaData.spawnArea then return end

    local saIndex = math.random(#areaData.spawnArea)
    local sa = areaData.spawnArea[saIndex]
    local saZone = spawnAreaZones[saIndex]

    local center, radius = getPolyBounds(sa.points)

    local spawnCoords, heading

    if areaData.roxwood then
        spawnCoords, heading = getRuralPosition(center, radius, saZone)
    else
        for _ = 1, 30 do
            local coords, hdg = getSidewalkPosition(center, radius)
            if coords and saZone and saZone:contains(coords) then
                spawnCoords = coords
                heading = hdg
                break
            end
        end
    end

    if not spawnCoords then return end

    local dist = #(RHDCache.coords.xyz - spawnCoords.xyz)
    if dist < 15.0 then return end

    local model = cfg.customer_ped[math.random(#cfg.customer_ped)]

    local loadedModel = safecall.fun(function()
        return lib.requestModel(model, 15000)
    end)

    if not loadedModel then return end

    local ped = CreatePed(4, loadedModel, spawnCoords.x, spawnCoords.y, spawnCoords.z, heading or 0.0, true, true)
    SetModelAsNoLongerNeeded(loadedModel)
    SetEntityAsMissionEntity(ped, true, true)

    local networked = NetworkGetEntityIsNetworked(ped)
    if not networked then
        NetworkRegisterEntityAsNetworked(ped)
    end

    local netId = NetworkGetNetworkIdFromEntity(ped)
    SetNetworkIdCanMigrate(netId, false)

    local npc_data = {
        owner = QBPlayerData.citizenid,
        index = wrapperIndex,
        available = true,
        scam = math.random() < cfg.selling.scammer_chance,
    }

    sell_transaction[netId] = {
        count = math.random(5, 10),
        price = math.random(cfg.selling.price.min, cfg.selling.price.max)
    }

    Entity(ped).state:set('drugsell', npc_data, true)

    SetPedFleeAttributes(ped, 0, false)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCombatAttributes(ped, 46, true)
    SetPedConfigFlag(ped, 118, true)

    if areaData.roxwood then
        CreateThread(function()
            local sa = areaData.spawnArea[saIndex]
            local center, radius = getPolyBounds(sa.points)
            while DoesEntityExist(ped) and not IsPedDeadOrDying(ped) do
                local state = Entity(ped).state
                local drugsell = state and state.drugsell
                if drugsell and not drugsell.available then
                    break
                end

                if state and not state.busy then
                    local targetCoords, heading = getRuralPosition(center, radius, saZone)
                    if targetCoords then
                        TaskGoStraightToCoord(ped, targetCoords.x, targetCoords.y, targetCoords.z, 1.0, -1, heading or 0.0, 0.0)
                        
                        local timer = 0
                        while DoesEntityExist(ped) and not IsPedDeadOrDying(ped) and not state.busy and timer < 15000 do
                            local pedCoords = GetEntityCoords(ped)
                            if #(pedCoords - targetCoords) < 1.5 then
                                break
                            end
                            Wait(500)
                            timer = timer + 500
                        end
                    else
                        Wait(5000)
                    end
                else
                    Wait(1000)
                end
            end
        end)
    else
        TaskWanderStandard(ped, 10.0, 10)
    end

    spawnedPeds[wrapperIndex][#spawnedPeds[wrapperIndex] + 1] = ped

    watchPedDeath(ped, wrapperIndex)
end

local function getItemListForZone(wrapperIndex)
    local areaData = area[wrapperIndex]
    if areaData and areaData.roxwood then
        return cfg.roxwoodDrugsItem
    end
    return cfg.drugsItem
end

local function resetSellingState()
    if sell_session_timer then
        ClearTimeout(sell_session_timer)
        sell_session_timer = nil
    end

    if currentBlip then
        currentBlip:remove()
        currentBlip = nil
    end

    if location_blip then
        for _, blip in pairs(location_blip) do
            if blip then blip:remove() end
        end
    end

    if location_timeout then
        ClearTimeout(location_timeout)
        location_timeout = nil
    end

    in_selling = false
    is_in_transaction = false
    has_active_session = false
    sell_count = 0
    sell_cooldown_end = nil
    table.wipe(location_busy)
    table.wipe(location_blip)
    location_data = {}
end

local function startSelling(areaType)
    if has_active_session then
        return lib.notify({
            description = 'Kamu masih dalam sesi penjualan aktif.',
            type = 'error',
            duration = 5000
        })
    end

    local filteredArea = {}
    for i = 1, #area do
        local a = area[i]
        if areaType == 'roxwood' and a.roxwood then
            filteredArea[#filteredArea + 1] = { index = i, data = a }
        elseif areaType == 'normal' and not a.roxwood then
            filteredArea[#filteredArea + 1] = { index = i, data = a }
        end
    end

    if #filteredArea == 0 then
        return lib.notify({ description = 'Tidak ada lokasi tersedia.', type = 'error' })
    end

    local chosen = filteredArea[math.random(#filteredArea)]
    local areablip = chosen.data.blip

    if not areablip then return end

    currentBlip = blipmodule:new(areablip)
    SetNewWaypoint(areablip.coords.x, areablip.coords.y)

    in_selling = true
    has_active_session = true
    sell_count = 0
    sell_cooldown_end = GetCloudTimeAsInt() + sell_cooldown_duration

    startMarkerThread()

    lib.notify({
        description = ('Kamu sekarang aktif berjualan. Lokasi sudah di set di GPS! Kamu tidak bisa berhenti selama %d menit.'):format(sell_cooldown_duration / 60),
        type = 'inform',
        duration = 12000
    })

    sell_session_timer = SetTimeout(sell_cooldown_duration * 1000, function()
        sell_cooldown_end = nil
        sell_session_timer = nil
        lib.notify({
            description = 'Kamu sekarang bisa berhenti berjualan kapan saja.',
            type = 'inform',
            duration = 8000
        })
    end)
end

local function openZoneContext()
    lib.registerContext({
        id = 'drugsell_zone_select',
        title = 'Pilih Lokasi Jualan',
        options = {
            {
                title = 'Roxwood',
                description = 'Jual blue paradise & K2 di area Roxwood',
                icon = 'fas fa-map-marker-alt',
                onSelect = function()
                    startSelling('roxwood')
                end
            },
            {
                title = 'Kota / Sandy Shores',
                description = 'Jual narkoba di area kota dan Sandy Shores',
                icon = 'fas fa-city',
                onSelect = function()
                    startSelling('normal')
                end
            },
        }
    })

    lib.showContext('drugsell_zone_select')
end

local function sellDrugs(targetPed)
    if is_in_transaction then return end

    local state = Entity(targetPed).state
    local netId = NetworkGetNetworkIdFromEntity(targetPed)

    if not state.drugsell or not state.drugsell.available or not sell_transaction[netId] then
        return lib.notify({ description = 'Orang ini tidak tertarik', type = 'error' })
    end

    -- Job availability dicek server-side di callback 'drugsell:sell' (on-duty aware).

    is_in_transaction = true
    state:set('busy', true, true)

    ClearPedTasks(targetPed)
    Wait(500)

    TaskTurnPedToFaceEntity(targetPed, cache.ped, 1000)
    Wait(1500)
    TaskStandStill(targetPed, -1)

    local playerCoords = GetEntityCoords(cache.ped)
    TaskGoToEntity(targetPed, cache.ped, -1, 1.0, 1.0, 0, 0)

    local timeout = 0
    while #(GetEntityCoords(targetPed) - playerCoords) > 2.0 and timeout < 8000 do
        Wait(100)
        timeout = timeout + 100
    end

    Wait(500)
    TaskTurnPedToFaceEntity(targetPed, cache.ped, 1000)
    Wait(1500)
    TaskStandStill(targetPed, -1)

    CreateThread(function()
        Wait(2000)
        PlayPedAmbientSpeechNative(targetPed, 'GENERIC_HI', 'SPEECH_PARAMS_FORCE_NORMAL')
    end)

    local temp_data = sell_transaction[netId]
    local drugsell_data = state.drugsell
    local itemList = getItemListForZone(drugsell_data.index)

    local availableItems = {}
    local totalWeight = 0

    for _, drugItem in ipairs(itemList) do
        local itemCount = ox_inventory:GetItemCount(drugItem.item)
        if itemCount > 0 then
            local maxCount = math.min(temp_data.count, itemCount)
            totalWeight = totalWeight + drugItem.weight
            availableItems[#availableItems + 1] = {
                item = drugItem.item,
                weight = totalWeight,
                maxCount = maxCount
            }
        end
    end

    local carriedItem = nil
    local carriedCount = nil

    if #availableItems > 0 then
        local roll = math.random() * totalWeight
        for _, entry in ipairs(availableItems) do
            if roll <= entry.weight then
                carriedItem = entry.item
                carriedCount = entry.maxCount
                break
            end
        end
    end

    local function cleanup(ped)
        is_in_transaction = false
        state:set('busy', false, true)

        if GetFollowPedCamViewMode() ~= 0 then
            SetFollowPedCamViewMode(0)
        end

        ClearPedTasksImmediately(cache.ped)
        ClearPedTasksImmediately(ped)

        local areaData = area[drugsell_data.index]
        local pedCoords = GetEntityCoords(ped)

        if areaData and areaData.roxwood then
            local targetCoords = getRuralPosition(pedCoords, 15.0, nil)
            if targetCoords then
                TaskGoStraightToCoord(ped, targetCoords.x, targetCoords.y, targetCoords.z, 1.0, -1, 0.0, 0.0)
            end
        else
            TaskWanderStandard(ped, 10.0, 10)
        end
    end

    if not carriedItem then
        lib.notify({ description = 'Kamu tidak memiliki barang untuk dijual', type = 'error', duration = 5000 })
        cleanup(targetPed)
        return
    end

    temp_data.item = carriedItem
    temp_data.count = carriedCount

    local itemLabel = (ox_items[temp_data.item] and ox_items[temp_data.item].label) or temp_data.item
    local dialogMessage = sell_message:format(temp_data.count, itemLabel, temp_data.count * temp_data.price)

    if not dialog(targetPed, dialogMessage) then
        cleanup(targetPed)
        return
    end

    if ox_inventory:GetItemCount(temp_data.item) < temp_data.count then
        lib.notify({
            description = ('Kamu tidak memiliki %sx %s'):format(temp_data.count, itemLabel),
            type = 'error',
            duration = 12000
        })
        cleanup(targetPed)
        return
    end

    local newdata = state.drugsell

    sellAnim(targetPed, function()
        local success = lib.callback.await('drugsell:sell', false, netId)

        if newdata.scam then
            lib.notify({ description = 'Ternyata dia penipu! Dia kabur dengan barangmu!', type = 'error' })

            newdata.available = false
            is_in_transaction = false
            state:set('busy', false, true)
            state:set('drugsell', newdata, true)

            if GetFollowPedCamViewMode() ~= 0 then
                SetFollowPedCamViewMode(0)
            end

            ClearPedTasksImmediately(cache.ped)
            ClearPedTasksImmediately(targetPed)

            CreateThread(function()
                local ped = targetPed
                local timeout = 15
                while timeout > 0 and DoesEntityExist(ped) and not IsPedDeadOrDying(ped) do
                    if not IsPedFleeing(ped) then
                        local fromCoords = GetEntityCoords(ped)
                        TaskSmartFleeCoord(ped, fromCoords.x, fromCoords.y, fromCoords.z, 500.0, -1, false, false)
                    end
                    Wait(1000)
                    timeout = timeout - 1
                end
                
                if DoesEntityExist(ped) then
                    NetworkFadeOutEntity(ped, true, false)
                    Wait(1000)
                    DeleteEntity(ped)
                end
            end)

            return
        end

        if success then
            newdata.available = false
            state:set('drugsell', newdata, true)
            sell_count += 1
            lib.notify({ description = 'Berhasil menjual barang', type = 'success' })
            
            CreateThread(function()
                Wait(7000)
                if DoesEntityExist(targetPed) then
                    NetworkFadeOutEntity(targetPed, true, false)
                    Wait(1000)
                    DeleteEntity(targetPed)
                end
            end)
        end

        if sell_count >= cfg.selling.maxSell then
            resetSellingState()
            lib.notify({ description = 'Kamu telah mencapai batas penjualan. Kembali ke banda untuk request penjualan lagi.', type = 'warning' })
        end

        cleanup(targetPed)
    end)
end

local function cleanupAllPeds()
    for _, parray in pairs(spawnedPeds) do
        array.forEach(parray, function(val)
            pcall(DeleteEntity, val)
        end)
    end
end

lib.callback.register('drugsell:sell', function(netId)
    local sell_data = sell_transaction[netId]
    sell_transaction[netId] = nil

    if sell_data then
        sell_data.locations = safecall.fun(function()
            local playerData = exports.tk_dispatch:getPlayerData()
            return playerData and playerData.location
        end)
    end

    return in_selling and sell_data
end)

CreateThread(function()
    Wait(1000)

    for wrapperIndex = 1, #area do
        local areaData = area[wrapperIndex]
        if not areaData or not areaData.wrapper or not areaData.spawnArea then goto continue end

        local spawnAreaZones = {}

        for saIdx = 1, #areaData.spawnArea do
            local sa = areaData.spawnArea[saIdx]
            spawnAreaZones[saIdx] = lib.zones.poly({
                points = sa.points,
                thickness = sa.thickness,
            })
        end

        local wrapper = lib.zones.poly({
            points = areaData.wrapper.points,
            thickness = areaData.wrapper.thickness,
            entered = false,
        })

        function wrapper:setupPedThread()
            CreateThread(function()
                while self.entered do
                    if in_selling and getTotalPedCount(wrapperIndex) < cfg.maxPeds then
                        spawnPed(wrapperIndex, spawnAreaZones)
                    end

                    Wait(cfg.spawnInterval)
                end
            end)
        end

        function wrapper:onEnter()
            self.entered = true
            self:setupPedThread()
        end

        function wrapper:onExit()
            SetTimeout(1500, function()
                if self.entered then return end

                local parray = spawnedPeds[wrapperIndex]
                if parray then
                    for i = #parray, 1, -1 do
                        pcall(DeleteEntity, parray[i])
                        table.remove(parray, i)
                    end
                end
            end)

            self.entered = false
        end

        function wrapper:inside()
            local parray = spawnedPeds[wrapperIndex]
            if not parray then return end

            for i = #parray, 1, -1 do
                local entity = parray[i]
                local pcoords = GetEntityCoords(entity)
                local distance = #(RHDCache.coords.xyz - pcoords)

                local remove = not DoesEntityExist(entity) or IsEntityDead(entity) or
                    not in_selling or distance > cfg.despawnDistance

                if remove then
                    pcall(DeleteEntity, entity)
                    table.remove(parray, i)
                end
            end
        end

        activeZones[wrapperIndex] = {
            wrapper = wrapper,
            spawnAreas = spawnAreaZones,
        }

        ::continue::
    end

    ox_target:addGlobalPed({
        {
            label = 'Jual Barang',
            icon = 'fas fa-hand-holding',
            onSelect = function(data)
                if not DoesEntityExist(data.entity) then return end
                sellDrugs(data.entity)
            end,
            canInteract = function(entity)
                if not entity or not DoesEntityExist(entity) then return false end

                local entityState = Entity(entity).state
                if not entityState then return false end

                local drugsell = entityState.drugsell
                if not drugsell then return false end

                return drugsell.available == true
                    and drugsell.owner == QBPlayerData.citizenid
                    and not IsEntityDead(entity)
                    and not entityState.busy
            end
        }
    })

    local start_point = cfg.start
    local sp = lib.points.new(start_point.coords.xyz, 50, {
        ped = nil
    })

    function sp:onEnter()
        if not self.ped then
            self.ped = pedmodule:new({
                model = start_point.ped,
                coords = start_point.coords,
                target = {
                    {
                        label = 'Start drug dealing',
                        onSelect = function()
                            if not lib.callback.await('drugsell:canStart', false) then return end

                            if has_active_session then
                                return lib.notify({
                                    description = 'Kamu masih dalam sesi penjualan aktif.',
                                    type = 'error',
                                    duration = 5000
                                })
                            end

                            openZoneContext()
                        end,
                        distance = 1.5,
                        canInteract = function()
                            return not in_selling
                        end
                    },
                    {
                        label = 'Stop drug dealing',
                        onSelect = function()
                            if sell_cooldown_end and GetCloudTimeAsInt() < sell_cooldown_end then
                                local remaining = sell_cooldown_end - GetCloudTimeAsInt()
                                local mins = math.floor(remaining / 60)
                                local secs = remaining % 60
                                return lib.notify({
                                    description = ('Kamu tidak bisa berhenti sekarang. Tunggu %d:%02d lagi.'):format(mins, secs),
                                    type = 'error',
                                    duration = 5000
                                })
                            end

                            resetSellingState()

                            lib.notify({
                                description = 'Kamu berhenti berjualan barang terlarang.',
                                type = 'inform',
                                duration = 5000
                            })
                        end,
                        distance = 1.5,
                        canInteract = function()
                            return in_selling
                        end
                    }
                }
            })
        end
    end

    function sp:onExit()
        if self.ped and self.ped:exists() then
            self.ped:remove()
            self.ped = nil
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        cleanupAllPeds()
        for _, zoneData in pairs(activeZones) do
            if zoneData.wrapper then
                zoneData.wrapper:remove()
            end
            if zoneData.spawnAreas then
                for _, saZone in pairs(zoneData.spawnAreas) do
                    saZone:remove()
                end
            end
        end
    end
end)