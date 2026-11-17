local scene = {}
local entities = {}

local progressTimer = require 'modules.scaleformsUI.timerBars.bars.progressTimerBar'

local function clearEntities()
    for _, entity in pairs(entities) do
        pcall(DeleteEntity, entity)
    end
    entities = {}
end

---@param second number
---@param onFinish function
local function startExplosionTimer(second, onFinish)
    ---@diagnostic disable-next-line: undefined-field
    local explosionTimer = progressTimer:new(
        "Explosion in", {r = 112, g = 25, b = 25, a = 255}, {r = 224, g = 50, b = 50, a = 255}, 0, 0
    )

    local timeInMs = second * 1000
    explosionTimer:setPercentage(1.0)
    explosionTimer:setEnabled(true)

    local interval = 0

    CreateThread(function()
        local startTime = GetGameTimer()
        local finished = false

        while explosionTimer.enabled do
            local currentTime = GetGameTimer()
            local elapsed = currentTime - startTime
            local progress = math.max(0.0, 1.0 - (elapsed / timeInMs))
            
            explosionTimer:setPercentage(progress)
            explosionTimer:draw(interval)
    
            if progress <= 0.0 then
                break
            end
            
            Wait(0)
        end

        if explosionTimer.enabled and not finished then
            finished = true
            explosionTimer:setEnabled(false)
            
            if onFinish and type(onFinish) == 'function' then
                onFinish()
            end
        end
    end)
end

function scene.plantBomb(data)
    local coords = data.coords
    local minigame = data.minigame

    clearEntities()

    lib.requestAnimDict('anim@heists@ornate_bank@thermal_charge', 1500)
    lib.requestModel("hei_p_m_bag_var22_arm_s", 1500)
    lib.requestModel("prop_bomb_01", 1500)

    SetEntityCoords(cache.ped, coords.x, coords.y, coords.z, false, false, false, false)
    SetEntityHeading(cache.ped, coords.w)
    
    Wait(100)
    local pcoords = GetEntityCoords(cache.ped)
    local protation = GetEntityRotation(cache.ped, 2)

    local bagscene = NetworkCreateSynchronisedScene(coords.x, coords.y, coords.z, protation.x, protation.y, protation.z, 2, false, false, 1065353216, 0, 1.3)
    entities.bag = CreateObject('hei_p_m_bag_var22_arm_s', coords.x, coords.y, coords.z,  true,  true, false)
    SetEntityCollision(entities.bag, false, true)

    NetworkAddPedToSynchronisedScene(cache.ped, bagscene, "anim@heists@ornate_bank@thermal_charge", "thermal_charge", 1.5, -4.0, 1, 16, 1148846080, 0)
    NetworkAddEntityToSynchronisedScene(entities.bag, bagscene, "anim@heists@ornate_bank@thermal_charge", "bag_thermal_charge", 4.0, -8.0, 1)

    NetworkStartSynchronisedScene(bagscene)
    Wait(1500)

    local x, y, z = table.unpack(pcoords)
    entities.bomba = CreateObject("prop_bomb_01", x, y, z + 0.2,  true,  true, true)
    AttachEntityToEntity(entities.bomba, cache.ped, GetPedBoneIndex(cache.ped, 28422), 0, 0, 0, 0, 0, 200.0, true, true, false, true, 1, true)

    Wait(3000)
    pcall(DeleteEntity, entities.bag)
    entities.bag = nil

    DetachEntity(entities.bomba, true, true)
    FreezeEntityPosition(entities.bomba, true)
    NetworkStopSynchronisedScene(bagscene)
    
    if minigame and type(minigame) == 'function' and not minigame() then
        pcall(DeleteEntity, entities.bomba)
        ClearPedTasks(cache.ped)
        return false
    end

    local p = promise.new()
    startExplosionTimer(5, function ()
        pcall(DeleteEntity, entities.bomba)
        entities.bomba = nil

        AddExplosion(coords.x, coords.y, coords.z, 33, 1.0, true, false, 1.0)
        p:resolve(true)
    end)

    return Citizen.Await(p)
end

function scene.latopHackStart(data)
    local coords = data.coords

    local useCard = data.card
    local minigame = data.minigame
    local animDict = lib.requestAnimDict("anim@heists@ornate_bank@hack")

    clearEntities()

    lib.requestModel("hei_prop_hst_laptop")
    lib.requestModel("hei_p_m_bag_var22_arm_s")
    if useCard then lib.requestModel("hei_prop_heist_card_hack_02") end

    SetEntityCoords(cache.ped, coords.x, coords.y, coords.z, false, false, false, false)
    SetEntityHeading(cache.ped, coords.w)

    Wait(100)
    FreezeEntityPosition(cache.ped, true)
    playerState:set('inv_busy', true, true)
    ox_target:disableTargeting(true)

    local pcoords = GetEntityCoords(cache.ped)
    local protation = GetEntityRotation(cache.ped, 2)

    local netScene = NetworkCreateSynchronisedScene(coords.x, coords.y, coords.z, protation.x, protation.y, protation.z, 2, false, false, 1065353216, 0, 1.0)
    entities.bag = CreateObject(`hei_p_m_bag_var22_arm_s`, pcoords.x, pcoords.y, pcoords.z, true, true, false)
    entities.laptop = CreateObject(`hei_prop_hst_laptop`, pcoords.x, pcoords.y, pcoords.z, true, true, false)
    entities.card = useCard and CreateObject(joaat('hei_prop_heist_card_hack_02'), pcoords.x, pcoords.y, pcoords.z, true, true, false)

    NetworkAddPedToSynchronisedScene(cache.ped, netScene, animDict, "hack_enter", 1.5, -4.0, 1, 16, 1148846080, 0)
    NetworkAddEntityToSynchronisedScene(entities.bag, netScene, animDict, "hack_enter_bag", 4.0, -8.0, 1)
    NetworkAddEntityToSynchronisedScene(entities.laptop, netScene, animDict, "hack_enter_laptop", 4.0, -8.0, 1)

    if entities.card then
        NetworkAddEntityToSynchronisedScene(entities.card, netScene, animDict, "hack_enter_card", 4.0, -8.0, 1)
    end

    local netScene2 = NetworkCreateSynchronisedScene(coords.x, coords.y, coords.z, protation.x, protation.y, protation.z, 2, false, true, 1065353216, 0, 1.0)
    NetworkAddPedToSynchronisedScene(cache.ped, netScene2, animDict, "hack_loop", 1.5, -4.0, 1, 16, 1148846080, 0)
    NetworkAddEntityToSynchronisedScene(entities.bag, netScene2, animDict, "hack_loop_bag", 4.0, -8.0, 1)
    NetworkAddEntityToSynchronisedScene(entities.laptop, netScene2, animDict, "hack_loop_laptop", 4.0, -8.0, 1)

    if entities.card then
        NetworkAddEntityToSynchronisedScene(entities.card, netScene2, animDict, "hack_loop_card", 4.0, -8.0, 1)
    end

    local netScene3 = NetworkCreateSynchronisedScene(coords.x, coords.y, coords.z, protation.x, protation.y, protation.z, 2, false, false, 1065353216, 0, 1.0)
    NetworkAddPedToSynchronisedScene(cache.ped, netScene3, animDict, "hack_exit", 1.5, -4.0, 1, 16, 1148846080, 0)
    NetworkAddEntityToSynchronisedScene(entities.bag, netScene3, animDict, "hack_exit_bag", 4.0, -8.0, 1)
    NetworkAddEntityToSynchronisedScene(entities.laptop, netScene3, animDict, "hack_exit_laptop", 4.0, -8.0, 1)

    if entities.card then
        NetworkAddEntityToSynchronisedScene(entities.card, netScene3, animDict, "hack_exit_card", 4.0, -8.0, 1)
    end

    NetworkStartSynchronisedScene(netScene)
    Wait(GetAnimDuration(animDict, "hack_enter") * 1000 - 100)
    NetworkStartSynchronisedScene(netScene2)

    local success = true

    if minigame and type(minigame) == 'function' then
        success = minigame()
    end

    playerState:set('inv_busy', false, true)
    NetworkStartSynchronisedScene(netScene3)
    Wait(GetAnimDuration(animDict, "hack_exit") * 1000 - 100)

    clearEntities()
    FreezeEntityPosition(cache.ped, false)
    ox_target:disableTargeting(false)

    return success
end

function scene.grabFromCashRegister()
    local cashModel = 'prop_anim_cash_note'
    local animDict = "oddjobs@shop_robbery@rob_till"

    lib.requestModel(cashModel, 1500)
    lib.requestAnimDict(animDict, 1500)

    local pcoords = GetEntityCoords(cache.ped)
    local protation = GetEntityRotation(cache.ped, 0)

    local sceneObject = GetClosestObjectOfType(pcoords.x, pcoords.y, pcoords.z, 2.0, joaat('prop_till_01'), 0, 0, 0)
    local scenePos = GetOffsetFromEntityInWorldCoords(sceneObject, -0.025120, -0.712561, -0.089709)
    local sceneRot = GetEntityRotation(sceneObject)
    
    local cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    local camOffset = vector3(-0.025120, 0.812561, 0.559709)
    local camCoords = GetOffsetFromEntityInWorldCoords(sceneObject, camOffset.x, camOffset.y, camOffset.z)
    local camRotation = vector3(-20.0, 0.0, GetEntityHeading(sceneObject) + 180)

    SetCamActive(cam, true)
    RenderScriptCams(true, true, 1500, true, false)
    SetCamCoord(cam, camCoords.x, camCoords.y, camCoords.z)
    SetCamRot(cam, camRotation.x, camRotation.y, camRotation.z)

    local scene1 = NetworkCreateSynchronisedScene(scenePos.x, scenePos.y, scenePos.z, sceneRot.x, sceneRot.y, sceneRot.z, 2, false, false, 1065353216, 0, 0.8)
    NetworkAddPedToSynchronisedScene(cache.ped, scene1, animDict, "enter", 1.5, -4.0, 1, 16, 1148846080, 0)

    local scene2 = NetworkCreateSynchronisedScene(scenePos.x, scenePos.y, scenePos.z, sceneRot.x, sceneRot.y, sceneRot.z, 2, false, true, 1065353216, 0, 0.8)
    NetworkAddPedToSynchronisedScene(cache.ped, scene2, animDict, "loop", 1.5, -4.0, 1, 16, 1148846080, 0)

    local scene3 = NetworkCreateSynchronisedScene(scenePos.x, scenePos.y, scenePos.z, sceneRot.x, sceneRot.y, sceneRot.z, 2, false, false, 1065353216, 0, 0.8)
    NetworkAddPedToSynchronisedScene(cache.ped, scene3, animDict, "exit", 1.5, -4.0, 1, 16, 1148846080, 0)

    entities.money1 = CreateObject(cashModel, pedCo, 1, 1, 0)
    entities.money2 = CreateObject(cashModel, pedCo, 1, 1, 0)
    AttachEntityToEntity(entities.money1, cache.ped, GetPedBoneIndex(cache.ped, 18905), 0.13, 0.04, -0.02, -44.0, 0.0, 0.0, true, true, false, false, 1, true)
    AttachEntityToEntity(entities.money2, cache.ped, GetPedBoneIndex(cache.ped, 57005), 0.16, 0.04, -0.02, 36.0, 16.0, 27.0, true, true, false, false, 1, true)

    NetworkStartSynchronisedScene(scene1)
    Wait(1000)
    NetworkStartSynchronisedScene(scene2)
    Wait(55000)
    NetworkStartSynchronisedScene(scene3)
    Wait(1000)

    DetachEntity(entities.money1, 0, 0)
    DetachEntity(entities.money2, 0, 0)
    DeleteObject(entities.money1)
    DeleteObject(entities.money2)
    RenderScriptCams(false, true, 1500, true, false)
    DestroyCam(cam, false)

    entities.money1 = nil
    entities.money2 = nil

    return true
end

function scene.grabMoneyFromTrolley(data)
    local pc = GetEntityCoords(cache.ped)
    local tc = data.coords
    local tm = joaat('hei_prop_hei_cash_trolly_01')

    local bagModel = joaat('hei_p_m_bag_var22_arm_s')
    local grabModel = 'hei_prop_heist_cash_pile'
    local animDict = 'anim@heists@ornate_bank@grab_cash'

    lib.requestAnimDict(animDict)
    lib.requestModel('hei_p_m_bag_var22_arm_s')

    local sceneObject = GetClosestObjectOfType(tc.x, tc.y, tc.z, 2.0, tm, false, false, false)

    if sceneObject == 0 then
        return false
    end

    local controlTimeout = GetGameTimer() + 2000
    while not NetworkHasControlOfEntity(sceneObject) and GetGameTimer() < controlTimeout do
        NetworkRequestControlOfEntity(sceneObject)
        Wait(50)
    end
    local hasControl = NetworkHasControlOfEntity(sceneObject)

    local bag = CreateObject(bagModel, pc.x, pc.y, pc.z, true, true, false)

    local animData = {
        {'intro', 'bag_intro'},
        {'grab', 'bag_grab', 'cart_cash_dissapear'},
        {'exit', 'bag_exit'}
    }

    local sc = GetEntityCoords(sceneObject)
    local sr = GetEntityRotation(sceneObject)

    local sceneData = {}

    ox_target:disableTargeting(true)
    FreezeEntityPosition(cache.ped, true)

    for i = 1, #animData do
        sceneData[i] = NetworkCreateSynchronisedScene(sc.x, sc.y, sc.z, sr.x, sr.y, sr.z, 2, true, false, 1065353216, 0, 1.3)
        NetworkAddPedToSynchronisedScene(cache.ped, sceneData[i], animDict, animData[i][1], 1.5, -4.0, 1, 16, 1148846080, 0)
        NetworkAddEntityToSynchronisedScene(bag, sceneData[i], animDict, animData[i][2], 4.0, -8.0, 1)
        if i == 2 and hasControl then
            NetworkAddEntityToSynchronisedScene(sceneObject, sceneData[i], animDict, "cart_cash_dissapear", 4.0, -8.0, 1)
        end
    end

    local p = promise.new()
    local function CashAppear()
        local mc = GetEntityCoords(cache.ped)

        lib.requestModel(grabModel)
        local grabobj = CreateObject(grabModel, mc.x, mc.y, mc.z, true, false, false)

        FreezeEntityPosition(grabobj, true)
        SetEntityInvincible(grabobj, true)
        SetEntityNoCollisionEntity(grabobj, cache.ped, false)
        SetEntityVisible(grabobj, false, false)
        AttachEntityToEntity(grabobj, cache.ped, GetPedBoneIndex(cache.ped, 60309), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 0, true)
        local startedGrabbing = GetGameTimer()

        CreateThread(function()
            while GetGameTimer() - startedGrabbing < 37000 do
                Wait(1)
                DisableControlAction(0, 73, true)
                if HasAnimEventFired(cache.ped, joaat("CASH_APPEAR")) then
                    if not IsEntityVisible(grabobj) then
                        SetEntityVisible(grabobj, true, false)
                    end
                end
                if HasAnimEventFired(cache.ped, joaat("RELEASE_CASH_DESTROY")) then
                    if IsEntityVisible(grabobj) then
                        SetEntityVisible(grabobj, false, false)
                    end
                end
            end

            p:resolve(true)
            DeleteObject(grabobj)
        end)
    end

    NetworkStartSynchronisedScene(sceneData[1])
    Wait(1750)
    CashAppear()
    NetworkStartSynchronisedScene(sceneData[2])
    Wait(37000)
    NetworkStartSynchronisedScene(sceneData[3])
    Wait(2000)
    DeleteObject(bag)
    ClearPedTasks(cache.ped)

    ox_target:disableTargeting(false)
    FreezeEntityPosition(cache.ped, false)

    return Citizen.Await(p)
end

function scene.plantThermite(data)
    local coords = data.coords
    local minigame = data.minigame

    clearEntities()

    lib.requestAnimDict("anim@heists@ornate_bank@thermal_charge")
    lib.requestModel("hei_p_m_bag_var22_arm_s")
    lib.requestModel("hei_prop_heist_thermite")

    SetEntityCoords(cache.ped, coords.x, coords.y, coords.z, false, false, false, false)
    SetEntityHeading(cache.ped, coords.w)

    Wait(100)
    local pcoords = GetEntityCoords(cache.ped)
    local protation = GetEntityRotation(cache.ped, 2)

    clearEntities()
    ox_target:disableTargeting(true)
    FreezeEntityPosition(cache.ped, true)

    local bagscene = NetworkCreateSynchronisedScene(coords.x, coords.y, coords.z, protation.x, protation.y, protation.z, 2, false, false, 1065353216, 0, 1.3)
    entities.bag = CreateObject('hei_p_m_bag_var22_arm_s', coords.x, coords.y, coords.z,  true,  true, false)

    SetEntityCollision(entities.bag, false, true)
    entities.charge = CreateObject('hei_prop_heist_thermite', pcoords.x, pcoords.y, pcoords.z + 0.2,  true,  true, true)

    SetEntityCollision(entities.charge, false, true)
    AttachEntityToEntity(entities.charge, cache.ped, GetPedBoneIndex(cache.ped, 28422), 0, 0, 0, 0, 0, 200.0, true, true, false, true, 1, true)
    
    NetworkAddPedToSynchronisedScene(cache.ped, bagscene, "anim@heists@ornate_bank@thermal_charge", "thermal_charge", 1.5, -4.0, 1, 16, 1148846080, 0)
    NetworkAddEntityToSynchronisedScene(entities.bag, bagscene, "anim@heists@ornate_bank@thermal_charge", "bag_thermal_charge", 4.0, -8.0, 1)
    NetworkStartSynchronisedScene(bagscene)

    Wait(5000)
    DetachEntity(entities.charge, true, true)
    FreezeEntityPosition(entities.charge, true)

    pcall(DeleteEntity, entities.bag)
    entities.bag = nil

    NetworkStopSynchronisedScene(bagscene)
    
    if minigame and type(minigame) == 'function' and not minigame() then
        pcall(DeleteEntity, entities.charge)
        ClearPedTasks(cache.ped)
        FreezeEntityPosition(cache.ped, false)
        ox_target:disableTargeting(false)
        return false
    end

    local p = promise.new()

    CreateThread(function()
        Wait(18500)

        pcall(DeleteEntity, entities.charge)
        entities.charge = nil

        p:resolve(true)
    end)

    ThermiteParticleSync(entities.charge)
    lib.requestAnimDict("anim@heists@ornate_bank@thermal_charge")
    TaskPlayAnim(cache.ped, "anim@heists@ornate_bank@thermal_charge", "cover_eyes_intro", 8.0, 8.0, 1000, 36, 1, false, false, false)
    TaskPlayAnim(cache.ped, "anim@heists@ornate_bank@thermal_charge", "cover_eyes_loop", 8.0, 8.0, 3000, 49, 1, false, false, false)

    local startTime = GetGameTimer()
    repeat
        if not IsEntityPlayingAnim(cache.ped, "anim@heists@ornate_bank@thermal_charge", "cover_eyes_loop", 3) then
            TaskPlayAnim(cache.ped, "anim@heists@ornate_bank@thermal_charge", "cover_eyes_loop", 8.0, 8.0, 3000, 49, 1, false, false, false)
        end
        Wait(0)
    until GetGameTimer() - startTime > 18000

    ox_target:disableTargeting(false)
    FreezeEntityPosition(cache.ped, false)

    return Citizen.Await(p)
end

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        for _, entity in pairs(entities) do
            pcall(DeleteEntity, entity)
        end
    end
end)

-- local adjustmentX = 0.0
-- local adjustmentY = 0.0
-- local adjustmentZ = 0.0

-- local function getCoordsParticlePrefix(coords)
--     local sc = lib.scaleform:new({
--         name = 'instructional_buttons',
--         fullScreen = true
--     })

--     sc:callMethod('CLEAR_ALL')
--     sc:callMethod('SET_CLEAR_SPACE', {200})
--     sc:callMethod('SET_DATA_SLOT', {0, GetControlInstructionalButton(2, 73, true), 'Finish'})
--     sc:callMethod('SET_DATA_SLOT', {1, GetControlInstructionalButton(2, 175, true), GetControlInstructionalButton(2, 174, true), 'Y Axis'})
--     sc:callMethod('SET_DATA_SLOT', {2, GetControlInstructionalButton(2, 172, true), GetControlInstructionalButton(2, 173, true), 'X Axis'})
--     sc:callMethod('SET_DATA_SLOT', {3, GetControlInstructionalButton(2, 44, true), GetControlInstructionalButton(2, 20, true), 'Z Axis'})
--     sc:callMethod('DRAW_INSTRUCTIONAL_BUTTONS')
--     sc:callMethod('SET_BACKGROUND_COLOUR', {0, 0, 0, 80})
--     sc:startDrawing()
    
--     local adjusting = true
--     local moveSpeed = 0.01
--     local currentEffect = nil
    
--     lib.requestNamedPtfxAsset('scr_ornate_heist')
    
--     local function updateParticle()
--         if currentEffect then
--             StopParticleFxLooped(currentEffect, false)
--         end
--         SetPtfxAssetNextCall("scr_ornate_heist")
--         currentEffect = StartParticleFxLoopedAtCoord(
--             "scr_heist_ornate_thermal_burn",
--             coords.x + adjustmentX,
--             coords.y + adjustmentY,
--             coords.z + adjustmentZ,
--             0.0, 0.0, 0.0, 1.0,
--             false, false, false, false
--         )
--     end
    
--     updateParticle()
    
--     CreateThread(function()
--         while adjusting do
--             DisableControlAction(0, 73, true)
--             DisableControlAction(0, 172, true)
--             DisableControlAction(0, 173, true)
--             DisableControlAction(0, 174, true)
--             DisableControlAction(0, 175, true)
--             DisableControlAction(0, 44, true)
--             DisableControlAction(0, 20, true)
            
--             if IsDisabledControlPressed(0, 175) then
--                 adjustmentY = adjustmentY + moveSpeed
--                 updateParticle()
--             end
            
--             if IsDisabledControlPressed(0, 174) then
--                 adjustmentY = adjustmentY - moveSpeed
--                 updateParticle()
--             end
            
--             if IsDisabledControlPressed(0, 172) then
--                 adjustmentX = adjustmentX + moveSpeed
--                 updateParticle()
--             end
            
--             if IsDisabledControlPressed(0, 173) then
--                 adjustmentX = adjustmentX - moveSpeed
--                 updateParticle()
--             end
            
--             if IsDisabledControlPressed(0, 44) then
--                 adjustmentZ = adjustmentZ + moveSpeed
--                 updateParticle()
--             end
            
--             if IsDisabledControlPressed(0, 20) then
--                 adjustmentZ = adjustmentZ - moveSpeed
--                 updateParticle()
--             end
            
--             if IsDisabledControlPressed(0, 73) then
--                 adjusting = false
--                 if currentEffect then
--                     StopParticleFxLooped(currentEffect, false)
--                 end
--                 sc:dispose()
--                 lib.setClipboard(string.format('%.4f, %.4f, %.4f', adjustmentX, adjustmentY, adjustmentZ))
--                 lib.notify({
--                     description = string.format('Saved: X=%.2f Y=%.2f Z=%.2f', adjustmentX, adjustmentY, adjustmentZ),
--                     type = 'success'
--                 })
--             end
            
--             SetTextFont(4)
--             SetTextProportional(true)
--             SetTextScale(0.35, 0.35)
--             SetTextColour(255, 255, 255, 255)
--             SetTextDropshadow(0, 0, 0, 0, 255)
--             SetTextEdge(1, 0, 0, 0, 255)
--             SetTextDropShadow()
--             SetTextOutline()
--             SetTextEntry("STRING")
--             AddTextComponentString(string.format(
--                 '~y~Adjustment:~w~ X=~b~%.4f~w~ Y=~b~%.4f~w~ Z=~b~%.4f~w~\n~y~Final:~w~ %.2f, %.2f, %.2f',
--                 adjustmentX, adjustmentY, adjustmentZ,
--                 coords.x + adjustmentX, coords.y + adjustmentY, coords.z + adjustmentZ
--             ))
--             DrawText(0.015, 0.70)
            
--             Wait(0)
--         end
--     end)
    
--     while adjusting do
--         Wait(100)
--     end
    
--     return adjustmentX, adjustmentY, adjustmentZ
-- end


return scene