local houseLoot = {}
local house = nil

local noise = require 'resource.illegal_activity.houserobbery.utils.noise'
local config = require 'resource.illegal_activity.houserobbery.config.client'
local sharedConfig = require 'resource.illegal_activity.houserobbery.config.shared'
local entityHandler = require 'modules.entityStateHandler.client'

local function handleHousePickup(pickupId)
    if not sharedConfig.houses[house].pickups[pickupId].isOpened then
        local canStart = lib.callback.await('mad-houserobbery:server:checkPickup', false, house, pickupId)
        if not canStart then return end
        if lib.progressBar({
            duration = math.random(4000, 8000),
            label = sharedConfig.lang["rob"],
            useWhileDead = false,
            canCancel = true,
            disable = { car = true, move = true, combat = true, mouse = false },
            anim = { dict = 'missexile3', clip = 'ex03_dingy_search_case_base_michael', flag = 1 },
        }) then
            TriggerServerEvent('mad-houserobbery:server:pickupFinished', house, pickupId)
        else
            TriggerServerEvent('mad-houserobbery:server:pickupCancelled', house, pickupId)
        end
    end
end

local function handleHouseLoot(lootId)
    if not sharedConfig.houses[house].opened then return end
    if not sharedConfig.houses[house].loot[lootId].isOpened then
        local canStart = lib.callback.await('mad-houserobbery:server:checkLoot', false, house, lootId)
        if not canStart then return end
        if lib.progressBar({
            duration = math.random(4000, 8000),
            label = sharedConfig.lang["rob"],
            useWhileDead = false,
            canCancel = true,
            disable = { car = true, move = true, combat = true, mouse = false },
            anim = { dict = 'missexile3', clip = 'ex03_dingy_search_case_base_michael', flag = 1 },
        }) then
            TriggerServerEvent('mad-houserobbery:server:lootFinished', house, lootId)
        else
            TriggerServerEvent('mad-houserobbery:server:lootCancelled', house, lootId)
        end
    end
end

local function setupLoot(houseId)
    for k, v in pairs(sharedConfig.houses[houseId].loot) do
        houseLoot[#houseLoot + 1] = k
        exports.ox_target:addSphereZone({
            coords = v.coords.xyz,
            radius = 0.3,
            debug = false,
            options = {{
                name = "houselootingtarget" .. k,
                onSelect = function() handleHouseLoot(k) end,
                canInteract = function() return not sharedConfig.houses[houseId].loot[k].isOpened end,
                icon = "fas fa-solid fa-question",
                label = sharedConfig.lang["search"],
                distance = 1.5,
            }},
        })
    end
    for k, v in pairs(sharedConfig.houses[houseId].pickups) do
        houseLoot[#houseLoot + 1] = k
        exports.ox_target:addSphereZone({
            coords = v.coords.xyz,
            radius = 0.3,
            debug = false,
            options = {{
                name = "housepickuptarget" .. k,
                onSelect = function()
                    if LocalPlayer.state.carry_loop then
                        return lib.notify({ title = 'Perampokan Rumah', description = sharedConfig.lang["alreadycarry"], type = 'error' })
                    end
                    handleHousePickup(k)
                end,
                canInteract = function() return not sharedConfig.houses[houseId].pickups[k].isOpened end,
                icon = "fas fa-solid fa-question",
                label = sharedConfig.lang["search"],
                distance = 1.5,
            }},
        })
        local pickupProp = sharedConfig.houses[houseId].pickups[k]
        Wait(100)
        if sharedConfig.houses[houseId].pickups[k].isOpened then
            local entity = GetClosestObjectOfType(pickupProp.coords.x, pickupProp.coords.y, pickupProp.coords.z, 3.0, joaat(pickupProp.prop), false, false, false)
            local timeout = 0
            while not DoesEntityExist(entity) and timeout < 100 do
                Wait(50)
                entity = GetClosestObjectOfType(pickupProp.coords.x, pickupProp.coords.y, pickupProp.coords.z, 3.0, joaat(pickupProp.prop), false, false, false)
                timeout = timeout + 1
            end
            if DoesEntityExist(entity) then SetEntityVisible(entity, false, false) end
        end
    end
end

RegisterNetEvent("houserobbery:client:removeLoot", function(interiorId)
    if house ~= interiorId then return end
    if #houseLoot == 0 then return end
    for _, k in pairs(houseLoot) do
        exports.ox_target:removeZone("houselootingtarget" .. k)
        exports.ox_target:removeZone("housepickuptarget" .. k)
    end
    house = nil
    houseLoot = {}
end)

RegisterNetEvent('mad-houserobbery:client:syncLoot', function(houseIndex, lootData, pickupData)
    if house ~= houseIndex then return end
    sharedConfig.houses[houseIndex].loot = lootData
    sharedConfig.houses[houseIndex].pickups = pickupData
end)

local function handleHouseEntrance(houseIndex)
    local target = sharedConfig.houses[houseIndex]
    if not target then return end
    local isOpen = target.opened
    if isOpen and IsControlJustReleased(0, 38) then
        lib.requestAnimDict('anim@heists@keycard@')
        TaskPlayAnim(cache.ped, 'anim@heists@keycard@', 'exit', 5.0, 1.0, -1, 16, 0, false, false, false)
        house = houseIndex
        TriggerServerEvent('mad-houserobbery:server:enterHouse', houseIndex)
        RemoveAnimDict('anim@heists@keycard@')
    end
    if not lib.isTextUIOpen() and isOpen then
        lib.showTextUI(sharedConfig.lang["enter"], { position = 'left-center' })
    end
end

local function handleHouseExits()
    if not lib.isTextUIOpen() then
        lib.showTextUI(sharedConfig.lang["leave"], { position = 'left-center' })
    end
    if IsControlJustReleased(0, 38) then
        lib.requestAnimDict('anim@heists@keycard@')
        TaskPlayAnim(cache.ped, 'anim@heists@keycard@', 'exit', 5.0, 1.0, -1, 16, 0, false, false, false)
        TriggerServerEvent('mad-houserobbery:server:leaveHouse', false)
        TriggerEvent("houserobbery:client:removeLoot", house)
        RemoveAnimDict('anim@heists@keycard@')
        noise.stop()
    end
end

local function createInfoLocation(index)
    local selected = sharedConfig.houses[index]
    local blip = AddBlipForCoord(selected.coords.x, selected.coords.y, selected.coords.z)
    SetBlipSprite(blip, sharedConfig.houseInfoSystem.blipSprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, sharedConfig.houseInfoSystem.blipScale)
    SetBlipColour(blip, sharedConfig.houseInfoSystem.blipColor)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(sharedConfig.houseInfoSystem.blipName .. " #" .. index)
    EndTextCommandSetBlipName(blip)

    local radiusBlip = AddBlipForRadius(selected.coords.x, selected.coords.y, selected.coords.z, 50.0)
    SetBlipHighDetail(radiusBlip, true)
    SetBlipColour(radiusBlip, 1)
    SetBlipAlpha(radiusBlip, 80)

    SetNewWaypoint(selected.coords.x, selected.coords.y)
    local points = lib.points.new(selected.coords.xyz, 25)

    function points:nearby()
        DrawMarker(1, self.coords.x, self.coords.y, self.coords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 0.5, 255, 0, 0, 150, false, true, 2, false, false, false, false)
        if self.currentDistance < 10.0 then
            local onScreen, _x, _y = World3dToScreen2d(self.coords.x, self.coords.y, self.coords.z)
            if onScreen then
                SetTextScale(0.35, 0.35)
                SetTextFont(4)
                SetTextColour(255, 255, 255, 215)
                SetTextEntry("STRING")
                SetTextCentre(true)
                AddTextComponentString("🏠 Use Lockpick to Rob #" .. index)
                DrawText(_x, _y)
            end
        end
    end

    lib.notify({ title = 'Informasi Diterima', description = 'Lokasi rumah target telah ditandai di peta (30 detik)', type = 'success' })
    lib.notify({ title = 'Peringatan Penting', description = 'Lokasi rumah target selalu berubah setiap pembelian informasi!', type = 'inform', duration = 8000 })

    SetTimeout(sharedConfig.houseInfoSystem.blipDuration, function()
        if DoesBlipExist(blip) then RemoveBlip(blip) end
        if DoesBlipExist(radiusBlip) then RemoveBlip(radiusBlip) end
        lib.notify({ title = 'Blip Kedaluwarsa', description = 'Lokasi rumah target telah dihapus dari peta (marker masih aktif)', type = 'inform' })
    end)

    SetTimeout(300000, function() points:remove() end)
end

local function setupHouses()
    for i = 1, #sharedConfig.houses do
        local houseIndex = i
        local point = lib.points.new({
            coords = sharedConfig.houses[i].coords.xyz,
            distance = config.debugPoints and 50 or 1.6,
            interior = sharedConfig.houses[i].interior
        })
        function point:onExit() lib.hideTextUI() end
        function point:nearby() handleHouseEntrance(houseIndex) end
    end
    for i = 1, #sharedConfig.interiors do
        local point = lib.points.new({
            coords = sharedConfig.interiors[i].exit.xyz,
            distance = 1.6,
        })
        function point:onExit() lib.hideTextUI() end
        function point:nearby() handleHouseExits() end
    end
end

CreateThread(function()
    for i = 1, #sharedConfig.houses do
        local state = GlobalState['hr:' .. i]
        if state then
            sharedConfig.houses[i].opened = state.opened
            sharedConfig.houses[i].isAlarmTriggered = state.isAlarmTriggered
        end
        AddStateBagChangeHandler('hr:' .. i, 'global', function(_, _, value)
            if not value then return end
            sharedConfig.houses[i].opened = value.opened
            sharedConfig.houses[i].isAlarmTriggered = value.isAlarmTriggered
        end)
    end
    setupHouses()
end)

RegisterNetEvent('mad-houserobbery:client:enterHouse', function(id, lootData, pickupData)
    sharedConfig.houses[id].loot = lootData
    sharedConfig.houses[id].pickups = pickupData
    setupLoot(id)
    house = id
    if not house or sharedConfig.houses[house].isAlarmTriggered then return end
    noise.start(function(level)
        if sharedConfig.houses[house].isAlarmTriggered then return true end
        if level >= 100 then
            TriggerServerEvent("houserobbery:server:syncAlarmTriggered", house)
            TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 20, 'houseAlarm', 0.4)
            return true
        end
    end)
end)

RegisterNetEvent("mad-houserobbery:client:syncprops", function(houseIndex, pickupIndex)
    local pickupProp = sharedConfig.houses[houseIndex].pickups[pickupIndex]
    local entity = GetClosestObjectOfType(pickupProp.coords.x, pickupProp.coords.y, pickupProp.coords.z, 3.0, joaat(pickupProp.prop), false, false, false)
    if DoesEntityExist(entity) then SetEntityVisible(entity, false, false) end
end)

AddEventHandler('gameEventTriggered', function(name, args)
    if name ~= 'CEventNetworkEntityDamage' then return end
    if house == nil then return end
    local victim = args[1]
    local isDead = args[6] == 1
    if not victim or victim ~= cache.ped then return end
    if not isDead then return end
    Wait(10000)
    TriggerServerEvent('mad-houserobbery:server:leaveHouse', true)
    TriggerEvent("houserobbery:client:removeLoot", house)
    noise.stop()
end)

RegisterNetEvent("houserobbery:client:npcAnim", function(netid)
    if source == '' then return end
    lib.requestAnimDict('timetable@tracy@sleep@')
    local entity = NetworkGetEntityFromNetworkId(netid)
    lib.waitFor(function()
        if DoesEntityExist(entity) then return true end
    end, "entity does not exist", 15000)
    TaskPlayAnim(entity, 'timetable@tracy@sleep@', 'base', 8.0, -8.0, -1, 1, 0, false, false, false)
end)

lib.callback.register('houserobbery:getdisptachdata', function()
    return exports.tk_dispatch:getPlayerData()
end)

lib.callback.register('mad-houserobbery:client:startSkillcheck', function(difficulty)
    lib.requestAnimDict('veh@break_in@0h@p_m_one@')
    TaskPlayAnim(cache.ped, 'veh@break_in@0h@p_m_one@', 'std_force_entry_rds', 3.0, 3.0, -1, 17, 0, false, false, false)
    local success = lib.skillCheck(difficulty)
    ClearPedTasks(cache.ped)
    RemoveAnimDict('veh@break_in@0h@p_m_one@')
    return success
end)

lib.callback.register('mad-houserobbery:client:checkTime', function()
    local currentHour = GetClockHours()
    return currentHour >= config.startHours or currentHour <= config.endHours
end)

entityHandler.entityStateHandler('houserobbery:initNpc', function(entity, _, value)
    if not value then return end
    ClearPedTasks(entity)
    SetPedDropsWeaponsWhenDead(entity, false)
    GiveWeaponToPed(entity, `WEAPON_PISTOL`, 250, false, true)
    SetPedMaxHealth(entity, 100)
    SetPedArmour(entity, 200)
    SetCanAttackFriendly(entity, false, true)
    SetPedCombatAttributes(entity, 46, true)
    SetPedCombatAttributes(entity, 0, false)
    SetPedCombatAbility(entity, 100)
    TaskCombatPed(entity, cache.ped, 0, 0)
    SetPedAsCop(entity, true)
    SetPedRelationshipGroupHash(entity, `HATES_PLAYER`)
    SetPedAccuracy(entity, 60)
    SetPedFleeAttributes(entity, 0, false)
    SetPedKeepTask(entity, true)
    TaskGoToEntity(entity, cache.ped, 10000, 1.0, 100, 1073741824, 0)
    Entity(entity).state:set('houserobbery:initNpc', false, true)
    Wait(1000)
end)

_ENV.houserobbery = {
    createInfoLocation = createInfoLocation
}