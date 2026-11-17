local heistZone
local playerstatus = 'none'
local laserObjects = {}

local cfg = localmodule 'config'
local location = localmodule 'data.location'
local rewards = localmodule 'data.rewards'

local itemModule = require 'modules.items.client'
local sceneModule = require 'resource.illegal_activity.utils.scene'
local laserModule = require 'resource.illegal_activity.utils.laser'

---@param itemName string
---@return boolean
local function consumeItem(itemName)
    return lib.callback.await('jawel_robbery:consumeItem', false, itemName) == true
end

local function resetState()
    for i = 1, #location.vitrine do
        local v = location.vitrine[i]
        v.looted = false
        v.inUse = false
        CreateModelSwap(v.objPos.x, v.objPos.y, v.objPos.z, 0.3, joaat(v.newModel), joaat(v.oldModel), true)
    end

    for i = 1, #location.painting do
        local v = location.painting[i]
        v.looted = false
        v.inUse = false

        local object = GetClosestObjectOfType(v.objectPos.x, v.objectPos.y, v.objectPos.z, 1.0, joaat(v.object), false, false, false)
        if object and object ~= 0 then
            pcall(DeleteEntity, object)
        end
    end

    location.robbed = false
    location.start.inUse = false
    location.glass_cutting.looted = false
    location.glass_cutting.inUse = false
    location.glass_cutting.globalObject = nil
    location.glass_cutting.globalItem = nil
    location.laser.laser_disabled = false
    location.laser.inUse = false
    location.locker.looted = false
    location.locker.inUse = false
    playerstatus = 'none'

    local objectsToDelete = {
        'h4_prop_h4_glass_disp_01a', 'h4_prop_h4_glass_disp_01b',
        'h4_prop_h4_diamond_01a', 'h4_prop_h4_diamond_disp_01a',
        'h4_prop_h4_art_pant_01a', 'h4_prop_h4_necklace_01a',
        'h4_prop_h4_neck_disp_01a', 'h4_prop_h4_t_bottle_02b'
    }

    for _, model in ipairs(objectsToDelete) do
        local object = GetClosestObjectOfType(-617.4622, -227.4347, 37.057, 2.0, joaat(model), false, false, false)
        if object and object ~= 0 then
            pcall(DeleteEntity, object)
        end
    end
    
    for _, laser in pairs(laserObjects) do
        if laser then laser:setActive(false) end
    end
    StopAlarm("JEWEL_STORE_HEIST_ALARMS", true)
end

local function setupVangelico(rewardIndex)
    local glassCfg = location.glass_cutting
    local reward = rewards.glass_cutting[rewardIndex]

    lib.requestModel(reward.object.model, 1500)
    lib.requestModel(reward.displayObj.model, 1500)
    lib.requestModel('h4_prop_h4_glass_disp_01a', 1500)

    local glass = CreateObject(joaat('h4_prop_h4_glass_disp_01a'), glassCfg.displayPos.x, glassCfg.displayPos.y, glassCfg.displayPos.z, true, true, false)
    SetEntityHeading(glass, glassCfg.displayHeading)

    local rewardObj = CreateObject(joaat(reward.object.model), glassCfg.rewardPos.x, glassCfg.rewardPos.y, glassCfg.rewardPos.z + 0.195, true, true, false)
    SetEntityHeading(rewardObj, reward.object.rot)

    local rewardDisp = CreateObject(joaat(reward.displayObj.model), glassCfg.rewardPos.x, glassCfg.rewardPos.y, glassCfg.rewardPos.z, true, true, false)
    SetEntityRotation(rewardDisp, reward.displayObj.rot.x, reward.displayObj.rot.y, reward.displayObj.rot.z)

    glassCfg.globalObject = reward.object.model
    glassCfg.globalItem = reward.item

    for i = 1, #location.painting do
        local v = location.painting[i]
        lib.requestModel(v.object, 1500)
        local obj = CreateObjectNoOffset(joaat(v.object), v.objectPos.x, v.objectPos.y, v.objectPos.z, true, false, false)
        SetEntityRotation(obj, 0.0, 0.0, v.objHeading, 2, true)
    end
end

local function start()
    if location.start.inUse then
        return lib.notify({
            title = cfg.NotificationTitle,
            description = 'Seseorang sedang memulai heist!',
            type = 'error'
        })
    end

    -- Job availability dicek server-side di 'jawel_robbery:canheist' (on-duty aware).
    local canheist = lib.callback.await('jawel_robbery:canheist', 1500)
    if not canheist then return end

    local thermite = itemModule.checkRequired('pipe_bomb')
    if not thermite then return end

    location.start.inUse = true
    TriggerTokenEvent('jawel_robbery:setInUse', 'start', nil, true)
    playerstatus = 'none'

    local success = sceneModule.plantThermite({
        coords = location.start.coords,
        minigame = function ()
            local passed = bl_ui.pathFind(3, {
                numberOfNodes = 5,
                duration = 35000
            })

            if not passed then
                TriggerTokenEvent('jawel_robbery:itemFailed', cfg.RequiredItemEntry)
                return false
            end

            return consumeItem(cfg.RequiredItemEntry)
        end
    })

    if not success then
        location.start.inUse = false
        TriggerTokenEvent('jawel_robbery:setInUse', 'start', nil, false)

        return
    end

    playerstatus = 'thermite_success'

    TriggerTokenEvent('jawel_robbery:start')
end

local function lootVitrine(index)
    local vitrine = location.vitrine[index]
    if not vitrine or vitrine.looted then return end

    if vitrine.inUse then
        return lib.notify({
            title = cfg.NotificationTitle,
            description = 'Vitrine ini sedang dirampok orang lain!',
            type = 'error'
        })
    end

    local weaponIndex = array.findIndex(cfg.WeaponsToBreak, function (weapon)
        return cache.weapon == joaat(weapon)
    end)

    if not weaponIndex then
        return lib.notify({
            title = cfg.NotificationTitle,
            description = 'Anda memerlukan senjata yang tepat untuk memecahkan kaca!',
            type = 'error'
        })
    end

    vitrine.inUse = true
    TriggerTokenEvent('jawel_robbery:setInUse', 'vitrine', index, true)

    playerState:set('inv_busy', true, true)
    TriggerTokenEvent('jawel_robbery:syncLoot', index)

    local animDict = 'missheist_jewel'
    local ptfxAsset = "scr_jewelheist"
    local particleFx = "scr_jewel_cab_smash"

    lib.requestAnimDict(animDict, 1500)
    lib.requestNamedPtfxAsset(ptfxAsset, 1500)

    local anims = {'smash_case_necklace', 'smash_case_d', 'smash_case_e', 'smash_case_f'}
    local selected = anims[math.random(1, #anims)]
    local rot = GetEntityRotation(cache.ped)
    local coords = vitrine.coordsAnim

    local scene = NetworkCreateSynchronisedScene(coords.x, coords.y, coords.z - 1, rot.x, rot.y, rot.z, 2, true, false, 1065353216, 0, 1.3)
    NetworkAddPedToSynchronisedScene(cache.ped, scene, animDict, selected, 2.0, 4.0, 1, 0, 1148846080, 0)
    NetworkStartSynchronisedScene(scene)

    TriggerTokenEvent("jawel_robbery:smashSync", index)
    PlaySoundFromCoord(-1, "Glass_Smash", coords.x, coords.y, coords.z, 0, true, 0)

    SetPtfxAssetNextCall(ptfxAsset)
    StartNetworkedParticleFxNonLoopedAtCoord(particleFx, vitrine.objPos.x, vitrine.objPos.y, vitrine.objPos.z + 0.3, 0.0, 0.0, 0.0, 2.0, false, false, false)

    Wait(GetAnimDuration(animDict, selected) * 1000 - 1000)
    ClearPedTasks(cache.ped)

    playerstatus = 'looting_vitrine'
    TriggerTokenEvent("jawel_robbery:lootVitrine")

    playerState:set('inv_busy', false, true)
end

local function stealPainting(sceneId)
    local painting = location.painting[sceneId]
    if not painting or painting.looted then return end

    if painting.inUse then
        return lib.notify({
            title = cfg.NotificationTitle,
            description = 'Lukisan ini sedang dicuri orang lain!',
            type = 'error'
        })
    end

    if cache.weapon ~= joaat('weapon_knife') then
        return lib.notify({
            title = cfg.NotificationTitle,
            description = 'Anda memerlukan knife untuk mencuri lukisan!',
            type = 'error'
        })
    end

    painting.inUse = true
    TriggerTokenEvent('jawel_robbery:setInUse', 'painting', sceneId, true)

    playerState:set('inv_busy', true, true)
    TriggerTokenEvent("jawel_robbery:syncLootPainting", sceneId)

    local pedCo = GetEntityCoords(cache.ped)
    local animDict = "anim_heist@hs3f@ig11_steal_painting@male@"
    local sceneObject = GetClosestObjectOfType(painting.objectPos.x, painting.objectPos.y, painting.objectPos.z, 1.0, joaat(painting.object), false, false, false)
    local scenePos = painting.scenePos
    local sceneRot = painting.sceneRot

    lib.requestAnimDict(animDict, 1500)

    local sceneObjects = {}
    for k, v in pairs(cfg.ArtHeist.objects) do
        lib.requestModel(v, 1500)
        sceneObjects[k] = CreateObject(joaat(v), pedCo.x, pedCo.y, pedCo.z, true, true, false)
    end

    local scenes = {}
    for i = 1, 10 do
        scenes[i] = NetworkCreateSynchronisedScene(scenePos.x, scenePos.y, scenePos.z - 1.0, sceneRot.x, sceneRot.y, sceneRot.z, 2, true, false, 1065353216, 0, 1065353216)
        NetworkAddPedToSynchronisedScene(cache.ped, scenes[i], animDict, 'ver_01_' .. cfg.ArtHeist.animations[i][1], 4.0, -4.0, 1033, 0, 1000.0, 0)
        NetworkAddEntityToSynchronisedScene(sceneObject, scenes[i], animDict, 'ver_01_' .. cfg.ArtHeist.animations[i][3], 1.0, -1.0, 1148846080)
        NetworkAddEntityToSynchronisedScene(sceneObjects[1], scenes[i], animDict, 'ver_01_' .. cfg.ArtHeist.animations[i][4], 1.0, -1.0, 1148846080)
        NetworkAddEntityToSynchronisedScene(sceneObjects[2], scenes[i], animDict, 'ver_01_' .. cfg.ArtHeist.animations[i][5], 1.0, -1.0, 1148846080)
    end

    local cam = CreateCam("DEFAULT_ANIMATED_CAMERA", true)
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 3000, true, false)
    FreezeEntityPosition(cache.ped, true)

    NetworkStartSynchronisedScene(scenes[1])
    PlayCamAnim(cam, 'ver_01_top_left_enter_cam_ble', animDict, scenePos.x, scenePos.y, scenePos.z - 1.0, sceneRot.x, sceneRot.y, sceneRot.z, 0, 2)
    Wait(3000)

    NetworkStartSynchronisedScene(scenes[2])
    PlayCamAnim(cam, 'ver_01_cutting_top_left_idle_cam', animDict, scenePos.x, scenePos.y, scenePos.z - 1.0, sceneRot.x, sceneRot.y, sceneRot.z, 0, 2)

    NetworkStartSynchronisedScene(scenes[3])
    PlayCamAnim(cam, 'ver_01_cutting_top_left_to_right_cam', animDict, scenePos.x, scenePos.y, scenePos.z - 1.0, sceneRot.x, sceneRot.y, sceneRot.z, 0, 2)
    Wait(3000)

    NetworkStartSynchronisedScene(scenes[4])
    PlayCamAnim(cam, 'ver_01_cutting_top_right_idle_cam', animDict, scenePos.x, scenePos.y, scenePos.z - 1.0, sceneRot.x, sceneRot.y, sceneRot.z, 0, 2)

    NetworkStartSynchronisedScene(scenes[5])
    PlayCamAnim(cam, 'ver_01_cutting_right_top_to_bottom_cam', animDict, scenePos.x, scenePos.y, scenePos.z - 1.0, sceneRot.x, sceneRot.y, sceneRot.z, 0, 2)
    Wait(3000)

    NetworkStartSynchronisedScene(scenes[6])
    PlayCamAnim(cam, 'ver_01_cutting_bottom_right_idle_cam', animDict, scenePos.x, scenePos.y, scenePos.z - 1.0, sceneRot.x, sceneRot.y, sceneRot.z, 0, 2)

    NetworkStartSynchronisedScene(scenes[7])
    PlayCamAnim(cam, 'ver_01_cutting_bottom_right_to_left_cam', animDict, scenePos.x, scenePos.y, scenePos.z - 1.0, sceneRot.x, sceneRot.y, sceneRot.z, 0, 2)
    Wait(3000)

    NetworkStartSynchronisedScene(scenes[9])
    PlayCamAnim(cam, 'ver_01_cutting_left_top_to_bottom_cam', animDict, scenePos.x, scenePos.y, scenePos.z - 1.0, sceneRot.x, sceneRot.y, sceneRot.z, 0, 2)
    Wait(1500)

    NetworkStartSynchronisedScene(scenes[10])
    RenderScriptCams(false, false, 0, true, false)
    DestroyCam(cam, false)
    Wait(7500)

    ClearPedTasks(cache.ped)
    FreezeEntityPosition(cache.ped, false)
    RemoveAnimDict(animDict)

    for _, v in pairs(sceneObjects) do
        DeleteObject(v)
    end
    DeleteObject(sceneObject)

    playerstatus = 'looting_painting'
    TriggerTokenEvent("jawel_robbery:lootPainting")

    playerState:set('inv_busy', false, true)
end

local function cutGlass()
    local glassCfg = location.glass_cutting
    if not glassCfg.globalObject then return end

    if glassCfg.inUse then
        return lib.notify({
            title = cfg.NotificationTitle,
            description = 'Kaca sedang dipotong orang lain!',
            type = 'error'
        })
    end

    glassCfg.inUse = true
    TriggerTokenEvent('jawel_robbery:setInUse', 'glass_cutting', nil, true)

    if not consumeItem(cfg.RequiredItemCutGlass) then
        glassCfg.inUse = false
        TriggerTokenEvent('jawel_robbery:setInUse', 'glass_cutting', nil, false)
        return
    end

    playerState:set('inv_busy', true, true)
    TriggerTokenEvent("jawel_robbery:syncLootOverheat")

    local pedCo = GetEntityCoords(cache.ped)
    local animDict = 'anim@scripted@heist@ig16_glass_cut@male@'
    local displayPos = glassCfg.displayPos
    local sceneObject = GetClosestObjectOfType(displayPos.x, displayPos.y, displayPos.z, 1.0, joaat('h4_prop_h4_glass_disp_01a'), false, false, false)
    local scenePos = GetEntityCoords(sceneObject)
    local sceneRot = GetEntityRotation(sceneObject)
    local globalObj = GetClosestObjectOfType(displayPos.x, displayPos.y, displayPos.z, 5.0, joaat(glassCfg.globalObject), false, false, false)

    lib.requestAnimDict(animDict, 1500)
    RequestScriptAudioBank('DLC_HEI4/DLCHEI4_GENERIC_01', false)

    local cam = CreateCam("DEFAULT_ANIMATED_CAMERA", true)
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 3000, true, false)

    local sceneObjects = {}
    for k, v in pairs(cfg.Overheat.objects) do
        lib.requestModel(v, 1500)
        sceneObjects[k] = CreateObject(joaat(v), pedCo.x, pedCo.y, pedCo.z, true, true, false)
    end

    local newObj = CreateObject(joaat('h4_prop_h4_glass_disp_01b'), GetEntityCoords(sceneObject), true, true, false)
    SetEntityHeading(newObj, GetEntityHeading(sceneObject))

    local netScenes = {}
    for i = 1, #cfg.Overheat.animations do
        netScenes[i] = NetworkCreateSynchronisedScene(scenePos.x, scenePos.y, scenePos.z, sceneRot.x, sceneRot.y, sceneRot.z, 2, true, false, 1065353216, 0, 1.3)
        NetworkAddPedToSynchronisedScene(cache.ped, netScenes[i], animDict, cfg.Overheat.animations[i][1], 4.0, -4.0, 1033, 0, 1000.0, 0)
        NetworkAddEntityToSynchronisedScene(sceneObjects[1], netScenes[i], animDict, cfg.Overheat.animations[i][2], 1.0, -1.0, 1148846080)
        NetworkAddEntityToSynchronisedScene(sceneObjects[2], netScenes[i], animDict, cfg.Overheat.animations[i][3], 1.0, -1.0, 1148846080)

        if i ~= 5 then
            NetworkAddEntityToSynchronisedScene(sceneObject, netScenes[i], animDict, cfg.Overheat.animations[i][4], 1.0, -1.0, 1148846080)
        else
            NetworkAddEntityToSynchronisedScene(newObj, netScenes[i], animDict, cfg.Overheat.animations[i][4], 1.0, -1.0, 1148846080)
        end
    end

    local sound1 = GetSoundId()
    local sound2 = GetSoundId()

    NetworkStartSynchronisedScene(netScenes[1])
    PlayCamAnim(cam, 'enter_cam', animDict, scenePos.x, scenePos.y, scenePos.z, sceneRot.x, sceneRot.y, sceneRot.z, 0, 2)
    Wait(GetAnimDuration(animDict, 'enter') * 1000)

    NetworkStartSynchronisedScene(netScenes[2])
    PlayCamAnim(cam, 'idle_cam', animDict, scenePos.x, scenePos.y, scenePos.z, sceneRot.x, sceneRot.y, sceneRot.z, 0, 2)
    Wait(GetAnimDuration(animDict, 'idle') * 1000)

    NetworkStartSynchronisedScene(netScenes[3])
    PlaySoundFromEntity(sound1, "StartCutting", sceneObjects[2], 'DLC_H4_anims_glass_cutter_Sounds', true, 80)

    lib.requestNamedPtfxAsset('scr_ih_fin', 1500)
    UseParticleFxAssetNextCall('scr_ih_fin')
    local fire1 = StartParticleFxLoopedOnEntity('scr_ih_fin_glass_cutter_cut', sceneObjects[2], 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1065353216, false, false, false, 1065353216, 1065353216, 1065353216, false)
    PlayCamAnim(cam, 'cutting_loop_cam', animDict, scenePos.x, scenePos.y, scenePos.z, sceneRot.x, sceneRot.y, sceneRot.z, 0, 2)
    Wait(GetAnimDuration(animDict, 'cutting_loop') * 1000)
    StopSound(sound1)
    StopParticleFxLooped(fire1, false)

    NetworkStartSynchronisedScene(netScenes[4])
    PlaySoundFromEntity(sound2, "Overheated", sceneObjects[2], 'DLC_H4_anims_glass_cutter_Sounds', true, 80)
    UseParticleFxAssetNextCall('scr_ih_fin')
    local fire2 = StartParticleFxLoopedOnEntity('scr_ih_fin_glass_cutter_overheat', sceneObjects[2], 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1065353216, false, false, false)
    PlayCamAnim(cam, 'overheat_react_01_cam', animDict, scenePos.x, scenePos.y, scenePos.z, sceneRot.x, sceneRot.y, sceneRot.z, 0, 2)
    Wait(GetAnimDuration(animDict, 'overheat_react_01') * 1000)
    StopSound(sound2)
    StopParticleFxLooped(fire2, false)

    DeleteObject(sceneObject)
    NetworkStartSynchronisedScene(netScenes[5])
    Wait(2000)
    DeleteObject(globalObj)

    PlayCamAnim(cam, 'success_cam', animDict, scenePos.x, scenePos.y, scenePos.z, sceneRot.x, sceneRot.y, sceneRot.z, 0, 2)
    Wait(GetAnimDuration(animDict, 'success') * 1000 - 2000)
    DeleteObject(sceneObjects[1])
    DeleteObject(sceneObjects[2])
    ClearPedTasks(cache.ped)
    RenderScriptCams(false, false, 0, true, false)
    DestroyCam(cam, false)

    playerstatus = 'looting_glass'
    TriggerTokenEvent("jawel_robbery:lootOverHeat")

    playerState:set('inv_busy', false, true)
end

local function hackLasers()
    if location.laser.inUse then
        return lib.notify({
            title = cfg.NotificationTitle,
            description = 'Seseorang sedang hack laser!',
            type = 'error'
        })
    end

    location.laser.inUse = true
    TriggerTokenEvent('jawel_robbery:setInUse', 'laser', nil, true)

    local success = exports.bl_ui:waveMatch(2, {
        duration = 75000,
    })

    if success then
        TriggerTokenEvent("jawel_robbery:syncLasersObj")
        lib.notify({
            title = cfg.NotificationTitle,
            description = 'Sistem laser berhasil di-hack!',
            type = 'success'
        })
    else
        location.laser.inUse = false
        TriggerTokenEvent('jawel_robbery:setInUse', 'laser', nil, false)
        lib.notify({
            title = cfg.NotificationTitle,
            description = 'Gagal hack sistem laser!',
            type = 'error'
        })
    end
end

local function lootLocker()
    if location.locker.looted then
        return lib.notify({
            title = cfg.NotificationTitle,
            description = 'Locker sudah dirampok!',
            type = 'error'
        })
    end

    if location.locker.inUse then
        return lib.notify({
            title = cfg.NotificationTitle,
            description = 'Locker sedang digunakan orang lain!',
            type = 'error'
        })
    end

    local hasLockpick = exports.ox_inventory:Search('count', cfg.RequiredItemLockpick) > 0
    if not hasLockpick then
        return lib.notify({
            title = cfg.NotificationTitle,
            description = 'Anda memerlukan lockpick!',
            type = 'error'
        })
    end

    location.locker.inUse = true
    TriggerTokenEvent('jawel_robbery:setInUse', 'locker', nil, true)
    Wait(200)

    playerState:set('inv_busy', true, true)

    local success = exports["sm_sidejob"]:startLockpick("lockpick", 3, 5)

    if success and not consumeItem(cfg.RequiredItemLockpick) then
        location.locker.inUse = false
        TriggerTokenEvent('jawel_robbery:setInUse', 'locker', nil, false)
        playerState:set('inv_busy', false, true)
        return
    end

    if success then
        TriggerTokenEvent("jawel_robbery:syncLockerLoot")
        Wait(200)

        local progressSuccess = lib.progressBar({
            duration = 10000,
            label = 'Mengambil isi locker...',
            useWhileDead = false,
            canCancel = false,
            disable = { car = true, move = true, combat = true },
            anim = { dict = 'anim@gangops@facility@servers@', clip = 'hotwire' }
        })

        if progressSuccess then
            playerstatus = 'looting_locker'
            TriggerTokenEvent("jawel_robbery:giveLockerReward")
        end
    else
        location.locker.inUse = false
        TriggerTokenEvent('jawel_robbery:setInUse', 'locker', nil, false)

        TriggerTokenEvent('jawel_robbery:itemFailed', cfg.RequiredItemLockpick)
    end

    playerState:set('inv_busy', false, true)
end

local function playAlarm()
    while not PrepareAlarm("JEWEL_STORE_HEIST_ALARMS") do
        Wait(100)
    end

    StartAlarm("JEWEL_STORE_HEIST_ALARMS", true)
    Wait(cfg.AlarmTime)
    StopAlarm("JEWEL_STORE_HEIST_ALARMS", true)
end

lib.callback.register('jawel_robbery:getstate', function()
    local status = playerstatus
    playerstatus = 'none'
    return status
end)

lib.callback.register('jawel_robbery:getdispatchdata', function()
    return exports.tk_dispatch:getPlayerData()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if heistZone then heistZone:remove() end
        resetState()
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if heistZone then heistZone:remove() end
    end
end)

RegisterNetEvent('jawel_robbery:clear', function()
    if source == '' then return end
    resetState()
end)

RegisterNetEvent('jawel_robbery:setupVangelico', function(index)
    if source == '' then return end

    setupVangelico(index)
end)

AddStateBagChangeHandler('jawel_robbery_state', 'global', function (bagName, key, value)
    if not value then return end

    if value.action == 'start' then
        location.robbed = true

        playAlarm()
    elseif value.action == 'vitrine_loot' then
        local v = location.vitrine[value.index]
        if v then v.looted = true end

    elseif value.action == 'vitrine_swap' then
        local v = location.vitrine[value.index]
        if v then
            CreateModelSwap(v.objPos.x, v.objPos.y, v.objPos.z, 0.3, joaat(v.oldModel), joaat(v.newModel), true)
        end

    elseif value.action == 'painting_loot' then
        local v = location.painting[value.index]
        if v then v.looted = true end

    elseif value.action == 'glass_cutting_loot' then
        location.glass_cutting.looted = true

    elseif value.action == 'locker_loot' then
        location.locker.looted = true
        location.locker.inUse = false

    elseif value.action == 'set_in_use' then
        local loc = location[value.locationType]
        if loc then
            if value.index then
                if loc[value.index] then
                    loc[value.index].inUse = value.value
                end
            else
                loc.inUse = value.value
            end
        end

    elseif value.action == 'laser_disabled' then
        location.laser.laser_disabled = true
        for i = 11, #laserObjects do
            if laserObjects[i] then
                laserObjects[i]:setActive(false)
            end
        end
    elseif value.action == 'reset_heist' then
        resetState()
    end
end)

CreateThread(function()
    local laserpoints = lib.points.new(location.laser)

    function laserpoints:onEnter()
        if not location.robbed or location.laser.laser_disabled then
            return
        end

        for _, laser in pairs(laserObjects) do
            if laser then laser:setActive(true) end
        end
    end

    function laserpoints:onExit()
        for _, laser in pairs(laserObjects) do
            if laser then laser:setActive(false) end
        end
    end

    ox_target:addSphereZone({
        coords = location.start.coords,
        size = location.start.radius,
        options = {
            {
                icon = "fas fa-user-secret",
                label = "Mulai Heist Vangelico",
                distance = 2.5,
                onSelect = start,
                canInteract = function ()
                    return not location.robbed and not location.start.inUse
                end
            }
        }
    })

    for _ = 1, 10 do
        laserObjects[#laserObjects+1] = laserModule:new(
            vector3(-622.158, -235.901, 41.046),
            {
                vector3(-625.716, -230.125, 37.057), vector3(-631.682, -233.77, 37.057),
                vector3(-628.212, -233.587, 37.057), vector3(-620.451, -236.097, 37.057),
                vector3(-617.267, -232.82, 37.057), vector3(-616.224, -235.566, 37.057),
                vector3(-623.9, -235.294, 37.057), vector3(-627.887, -238.428, 37.057),
                vector3(-628.27, -234.794, 37.057), vector3(-628.694, -230.641, 37.057),
                vector3(-623.634, -232.243, 37.057), vector3(-625.033, -237.254, 37.057),
                vector3(-627.593, -235.515, 37.057)
            },
            {
                travelTimeBetweenTargets = {3.0, 3.0},
                waitTimeAtTargets = {0.0, 0.0},
                randomTargetSelection = true
            }
        )
    end

    local objectLaserConfigs = {
        {
            from = {vector3(-617.662, -226.87, 41.912), vector3(-618.014, -227.122, 41.911), vector3(-618.299, -227.324, 41.911)},
            to = {vector3(-617.662, -226.87, 37.057), vector3(-618.014, -227.122, 37.057), vector3(-618.299, -227.324, 37.057)}
        },
        {
            from = {vector3(-616.939, -227.734, 41.889), vector3(-617.346, -228.013, 41.889), vector3(-617.769, -228.334, 41.889)},
            to = {vector3(-616.939, -227.734, 37.057), vector3(-617.346, -228.013, 37.057), vector3(-617.769, -228.334, 37.057)}
        }
    }

    for _, val in ipairs(objectLaserConfigs) do
        laserObjects[#laserObjects+1] = laserModule:new(
            val.from, val.to,
            { travelTimeBetweenTargets = {3.0, 3.0}, waitTimeAtTargets = {0.0, 0.0}, randomTargetSelection = true }
        )
    end

    for i = 1, #location.vitrine do
        local val = location.vitrine[i]

        ox_target:addBoxZone({
            coords = val.coords,
            size = vec3(1.7, 1.7, 2.0),
            options = {
                {
                    icon = "fas fa-hammer",
                    label = "Hancurkan Vitrine",
                    onSelect = function()
                        if val.looted then
                            return lib.notify({
                                title = cfg.NotificationTitle,
                                description = 'Vitrine ini sudah dirampok!',
                                type = 'error'
                            })
                        end
                        lootVitrine(i)
                    end,
                    canInteract = function ()
                        return location.robbed
                    end
                }
            }
        })
    end

    for i = 1, #location.painting do
        local val = location.painting[i]

        ox_target:addBoxZone({
            coords = val.objectPos,
            size = vec3(1.7, 1.7, 2.0),
            options = {
                {
                    icon = "fas fa-palette",
                    label = "Curi Lukisan",
                    onSelect = function()
                        if val.looted then
                            return lib.notify({
                                title = cfg.NotificationTitle,
                                description = 'Lukisan ini sudah dicuri!',
                                type = 'error'
                            })
                        end
                        stealPainting(i)
                    end,
                    canInteract = function ()
                        return location.robbed
                    end
                }
            }
        })
    end

    local glassCutPos = location.glass_cutting.displayPos
    ox_target:addBoxZone({
        coords = vec3(glassCutPos.x, glassCutPos.y, glassCutPos.z + 1),
        size = vec3(1.7, 1.7, 2.0),
        options = {
            {
                icon = "fas fa-cut",
                label = "Potong Kaca",
                onSelect = function()
                    if location.glass_cutting.looted then
                        return lib.notify({
                            title = cfg.NotificationTitle,
                            description = 'Sudah dirampok!',
                            type = 'error'
                        })
                    end

                    if not location.laser.laser_disabled then
                        return lib.notify({
                            title = cfg.NotificationTitle,
                            description = 'Laser masih aktif!',
                            type = 'error'
                        })
                    end

                    local hasCutter = exports.ox_inventory:Search('count', cfg.RequiredItemCutGlass) > 0
                    if not hasCutter then
                        return lib.notify({
                            title = cfg.NotificationTitle,
                            description = 'Anda memerlukan glass cutter!',
                            type = 'error'
                        })
                    end

                    cutGlass()
                end,
                canInteract = function ()
                    return location.robbed
                end
            }
        }
    })

    ox_target:addBoxZone({
        coords = vec3(-631.01, -230.75, 38.06),
        size = vec3(1.7, 1.7, 2.0),
        options = {
            {
                icon = "fas fa-laptop",
                label = "Hack Sistem Laser",
                onSelect = function()
                    if location.laser.laser_disabled then
                        return lib.notify({
                            title = cfg.NotificationTitle,
                            description = 'Laser sudah dimatikan!',
                            type = 'error'
                        })
                    end
                    hackLasers()
                end,
                canInteract = function ()
                    return location.robbed
                end
            }
        }
    })

    ox_target:addBoxZone({
        coords = location.locker.coords,
        size = vec3(1.5, 1.5, 2.0),
        options = {
            {
                icon = "fas fa-lock",
                label = "Buka Locker",
                onSelect = lootLocker,
                canInteract = function ()
                    return location.robbed
                end
            }
        }
    })
end)
