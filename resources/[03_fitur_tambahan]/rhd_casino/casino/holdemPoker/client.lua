local currentCam
local activeTable
local buyinAmountCB

local cacheEntities = {}
local pokerConfig = require 'casino.holdemPoker.config'
local pokerTables = pokerConfig.pokerTables
local pokerTableModel = joaat('pokerasztal')
local enterAnim = { 'sit_enter_left_side', 'sit_enter_right_side' }
local spawnDealer = require 'modules.dealers'
local pokerTablesLoaded = false
local pokerTablesLoading = false

---@param key string
---@param value any
local function setCefVariable(key, value)
    SendNUIMessage({ action = 'setVariable', key = key, value = value })
end

local function loadPokerTable()
    if pokerTablesLoaded or pokerTablesLoading then return end
    pokerTablesLoading = true
    cacheEntities.tables = cacheEntities.tables or {}
    cacheEntities.dealerPeds = cacheEntities.dealerPeds or {}
    lib.requestAnimDict(pokerConfig.dealerAnimDictShared, 25000)
    lib.requestAnimDict(pokerConfig.playerAnimDictShared, 25000)

    for i = 1, #pokerTables do
        local v = pokerTables[i]
        if not cacheEntities.tables[v.id] then
            lib.requestModel(pokerTableModel, 25000)
            local obj = CreateObjectNoOffset(pokerTableModel, v.coords.x, v.coords.y, v.coords.z, false, false, false)
            SetEntityRotation(obj, 0.0, 0.0, v.coords.w, 2, true)
            SetModelAsNoLongerNeeded(pokerTableModel)
            PlaceObjectOnGroundProperly(obj)
            cacheEntities.tables[v.id] = obj

            local outfitPool = v.dealerOutfit
            local outfit = outfitPool[math.random(1, #outfitPool)]
            local dealerPos = GetOffsetFromEntityInWorldCoords(obj, -1.0, 0.0, 0.0)
            local dealerPed = spawnDealer[outfit](vector4(dealerPos.x, dealerPos.y, v.coords.z - 1.0, v.coords.w + 270.0))
            Wait(0)

            local scenePos = GetObjectOffsetFromCoords(v.coords.x, v.coords.y, v.coords.z, v.coords.w, -0.3, 0.0, 0.0)
            local scene = CreateSynchronizedScene(scenePos.x, scenePos.y, scenePos.z, 0.0, 0.0, v.coords.w + 90.0, 2)
            TaskSynchronizedScene(
                dealerPed, scene,
                pokerConfig.dealerAnimDictShared, 'idle',
                1000.0, -2.0, -1.0, 33, 1000.0, 0
            )
            NetworkStartSynchronisedScene(scene)
            cacheEntities.dealerPeds[v.id] = dealerPed
        end
    end
    pokerTablesLoaded = true
    pokerTablesLoading = false
end

---@param index integer
---@param offsetVec vector3
---@param headingOffset number
---@return vector3|nil, number|nil
local function calculateChairCoords(index, offsetVec, headingOffset)
    local tableEntity = cacheEntities.tables[index]
    if not DoesEntityExist(tableEntity) then return end

    local tableCoords = GetEntityCoords(tableEntity)
    local tableHeading = GetEntityHeading(tableEntity)
    local worldPos = GetObjectOffsetFromCoords(
        tableCoords.x, tableCoords.y, tableCoords.z, tableHeading,
        offsetVec.x, offsetVec.y, offsetVec.z
    )
    return worldPos, tableHeading + headingOffset
end

local function unloadPokerTables()
    if not pokerTablesLoaded and not pokerTablesLoading then return end
    pokerTablesLoading = false
    pokerTablesLoaded = false

    for i = 1, #pokerTables do
        local v = pokerTables[i]
        if cacheEntities.tables?[v.id] then
            DeleteEntity(cacheEntities.tables[v.id])
            cacheEntities.tables[v.id] = nil
        end
        if cacheEntities.dealerPeds?[v.id] then
            DeleteEntity(cacheEntities.dealerPeds[v.id])
            cacheEntities.dealerPeds[v.id] = nil
        end
    end
end

---@param index integer
---@param chairOffset vector3
---@param chairHeading number
local function sitDownClient(index, chairOffset, chairHeading)
    local tableEntity = cacheEntities.tables[index]
    if not DoesEntityExist(tableEntity) then return end

    local chairPos, chairFacing = calculateChairCoords(index, chairOffset, chairHeading)
    if not (chairPos and chairFacing) then return end

    ---@cast chairPos vector3
    ---@cast chairFacing number
    setCefVariable('joined', true)
    SetPlayerControl(cache.ped, false, 0)

    local enterScene = NetworkCreateSynchronisedScene(
        chairPos.x, chairPos.y, chairPos.z,
        0.0, 0.0, chairFacing,
        2, true, false, 1.0, 0.0, 1.0
    )
    local enterAnimName = enterAnim[math.random(1, #enterAnim)]
    NetworkAddPedToSynchronisedScene(
        cache.ped, enterScene, pokerConfig.playerAnimDictShared, enterAnimName, 2.0, -2.0, 13, 16, 2.0, 0)
    NetworkStartSynchronisedScene(enterScene)
    Wait(4000)

    if activeTable ~= index or IsEntityDead(cache.ped) then
        ClearPedTasksImmediately(cache.ped)
        return
    end

    local activeScene = NetworkCreateSynchronisedScene(
        chairPos.x, chairPos.y, chairPos.z,
        0.0, 0.0, chairFacing,
        2, true, false, 1.0, 0.0, 1.0
    )
    NetworkAddPedToSynchronisedScene(
        cache.ped, activeScene, pokerConfig.playerAnimDictShared, 'idle_cardgames', 2.0, -2.0, 13, 16, 1000.0, 0)
    NetworkStartSynchronisedScene(activeScene)
    SetPlayerControl(cache.ped, true, 0)
end

---@param index integer
---@param chairOffset vector3
---@param chairFacing number
local function standUpClient(index, chairOffset, chairFacing)
    local seatCoords, seatHeading = calculateChairCoords(index, chairOffset, chairFacing)
    if not (seatCoords and seatHeading) then return end

    local exitScene = NetworkCreateSynchronisedScene(
        seatCoords.x, seatCoords.y, seatCoords.z,
        0.0, 0.0, seatHeading,
        2, true, false, 1.0, 0.0, 1.0
    )
    NetworkAddPedToSynchronisedScene(
        cache.ped, exitScene, pokerConfig.playerAnimDictShared, 'sit_exit_left', 2.0, -2.0, 13, 16, 2.0, 0)
    NetworkStartSynchronisedScene(exitScene)
    Wait(4000)

    TriggerServerEvent('AquiverTexasPoker:standUp', index)
    NetworkStopSynchronisedScene(exitScene)
end

---@param index integer
---@param state boolean
local function openTable(index, state)
    if state then
        if currentCam and DoesCamExist(currentCam) then
            DestroyCam(currentCam, false)
        end

        local tableEntity = cacheEntities.tables[index]
        if not DoesEntityExist(tableEntity) then return end

        local tableCoords = GetEntityCoords(tableEntity)
        local camPos = tableCoords + vector3(0.0, 0.0, 2.5)
        currentCam = CreateCamWithParams(
            'DEFAULT_SCRIPTED_CAMERA',
            camPos.x, camPos.y, camPos.z,
            -90.0, 0.0, GetEntityHeading(tableEntity) + 90.0,
            90.0, true, 2
        )
        SetCamActive(currentCam, true)
        RenderScriptCams(true, true, 900, true, false)

        if not pokerConfig.AntiCheatRadarDebug then
            DisplayRadar(false)
        end

        setCefVariable('opened', true)
        pcall(function()
            local hud = exports.sm_hud
            hud:setComponentVisible('compass', false)
            hud:setComponentVisible('information', false)
            hud:setComponentVisible('healthArmor', false)
        end)
    else
        RenderScriptCams(false, true, 900, false, false)

        if currentCam and DoesCamExist(currentCam) then
            DestroyCam(currentCam, false)
        end

        if not pokerConfig.AntiCheatRadarDebug then
            DisplayRadar(true)
        end
        
        pcall(function()
            local hud = exports.sm_hud
            hud:setComponentVisible('compass', true)
            hud:setComponentVisible('information', true)
            hud:setComponentVisible('healthArmor', true)
        end)
    end

    activeTable = state and index or nil
end

AddEventHandler('rhd_casino:client:forceLeave', function()
    if not activeTable then return end

    SetNuiFocus(false, false)
    setCefVariable('opened', false)
    setCefVariable('joined', false)
    shared.hideVoiceInfo()
    openTable(activeTable, false)
    ClearPedTasksImmediately(cache.ped)
end)

useAreaHooks(function(inArea)
    if inArea then
        pcall(function()
            lib.requestAnimDict(pokerConfig.dealerAnimDictShared, 25000)
            lib.requestAnimDict(pokerConfig.playerAnimDictShared, 25000)
        end)
        loadPokerTable()
    else
        unloadPokerTables()
    end
end)

target:addModel(pokerTableModel, {
    {
        label = 'Play Holdem Poker',
        icon = 'fa-solid fa-diamond',
        distance = 1.6,
        canInteract = function() return not activeTable end,
        onSelect = function(data)
            local entity = data.entity
            local tableCoords = GetEntityCoords(entity)
            local tableIndex = lib.array.findIndex(pokerTables, function(val)
                return #(tableCoords - val.coords.xyz) < 1.5
            end)
            if not tableIndex then return end

            local canJoin = lib.callback.await('rhd_casino_holdemPoker:canJoin', false, tableIndex)
            if not canJoin then return end

            openTable(tableIndex, true)
        end,
    },
})

RegisterNUICallback('rhd_casino_holdemPoker:state', function(data, cb)
    cb('ok')
    if not activeTable then return end

    local tableIndex = activeTable
    SetNuiFocus(data.state, data.state)

    if not data.state then
        openTable(activeTable, false)
    end

    TriggerServerEvent('rhd_casino_holdemPoker:state', tableIndex, data.state)
end)

RegisterNUICallback('rhd_casino_holdemPoker:server', function(data, cb)
    cb('ok')
    if not activeTable then return end

    TriggerServerEvent(data.eventName, data.args)
end)

RegisterNUICallback('rhd_casino_holdemPoker:setBuyInAmount', function (data, cb)
    cb('ok')

    if buyinAmountCB then
        buyinAmountCB:resolve(data.amount)
        buyinAmountCB = nil
    end
end)

lib.callback.register('rhd_casino_holdemPoker:getBuyInAmount', function (index)
    if buyinAmountCB then
        return false
    end

    local CasinoTable = lib.array.find(pokerTables, function (val)
        return val.id == index
    end)

    if not CasinoTable then return false end

    local minBuyIn = CasinoTable.buyIn or 20
    local maxBuyIn = CasinoTable.maxBuyIn or minBuyIn * 10

    buyinAmountCB = promise.new()
    SendNUIMessage({
        action = "getBuyInAmount",
        data = {
            min = minBuyIn,
            max = maxBuyIn,
        }
    })
    SetNuiFocus(true, true)

    return Citizen.Await(buyinAmountCB)
end)

RegisterNetEvent('rhd_casino_holdemPoker:standUpClient', function(index, chairOffset, chairHeading)
    if source == '' then return end
    standUpClient(index, chairOffset, chairHeading)
    PlaySoundFrontend(-1, 'FocusOut', 'HintCamSounds', false)
    shared.hideVoiceInfo()
end)

RegisterNetEvent('rhd_casino_holdemPoker:sitDownClient', function(index, chairOffset, chairHeading)
    if source == '' then return end
    sitDownClient(index, chairOffset, chairHeading)
    shared.showVoiceInfo()
end)

RegisterNetEvent('rhd_casino_holdemPoker:notify', function(message)
    if source == '' then return end
    SendNUIMessage({ action = 'PokerNotify', msg = message })
end)

RegisterNetEvent('rhd_casino_holdemPoker:showRebuyModal', function()
    if source == '' then return end
    SendNUIMessage({ action = 'showRebuyModal' })
end)

RegisterNetEvent('rhd_casino_holdemPoker:playSound', function(sound, volume)
    if source == '' then return end
    SendNUIMessage({ action = 'PlaySound', sound = sound, volume = volume })
end)

RegisterNetEvent('rhd_casino_holdemPoker:setVariables', function(key, val)
    if source == '' then return end
    setCefVariable(key, val)
end)

RegisterNetEvent('rhd_casino_holdemPoker:updateCards', function(cards)
    if source == '' then return end
    SendNUIMessage({ action = 'mycards', d = cards })
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    unloadPokerTables()
end)
