local Wait = Wait
local CreateThread = CreateThread
local PlayerPedId = PlayerPedId
local DoesEntityExist = DoesEntityExist
local GetAnimDuration = GetAnimDuration
local GetGameTimer = GetGameTimer
local NetworkCreateSynchronisedScene = NetworkCreateSynchronisedScene
local NetworkAddPedToSynchronisedScene = NetworkAddPedToSynchronisedScene
local NetworkAddEntityToSynchronisedScene = NetworkAddEntityToSynchronisedScene
local NetworkStartSynchronisedScene = NetworkStartSynchronisedScene
local NetworkStopSynchronisedScene = NetworkStopSynchronisedScene
local NetworkGetEntityFromNetworkId = NetworkGetEntityFromNetworkId
local NetworkDoesNetworkIdExist = NetworkDoesNetworkIdExist
local GetOffsetFromEntityInWorldCoords = GetOffsetFromEntityInWorldCoords
local GetEntityHeading = GetEntityHeading
local SetEntityCoords = SetEntityCoords
local SetEntityHeading = SetEntityHeading
local ClearPedTasks = ClearPedTasks
local FreezeEntityPosition = FreezeEntityPosition
local DoScreenFadeOut = DoScreenFadeOut
local DoScreenFadeIn = DoScreenFadeIn
local CreateCam = CreateCam
local SetCamActive = SetCamActive
local RenderScriptCams = RenderScriptCams
local PlayCamAnim = PlayCamAnim
local DestroyCam = DestroyCam
local UseParticleFxAsset = UseParticleFxAsset
local StartNetworkedParticleFxLoopedOnEntity = StartNetworkedParticleFxLoopedOnEntity
local StartNetworkedParticleFxNonLoopedOnEntity = StartNetworkedParticleFxNonLoopedOnEntity
local StartParticleFxLoopedOnPedBone = StartParticleFxLoopedOnPedBone
local StopParticleFxLooped = StopParticleFxLooped
local AttachEntityToEntity = AttachEntityToEntity
local DetachEntity = DetachEntity
local GetPedBoneIndex = GetPedBoneIndex
local CreateObject = CreateObject
local DeleteEntity = DeleteEntity
local SetEntityAsMissionEntity = SetEntityAsMissionEntity
local SetModelAsNoLongerNeeded = SetModelAsNoLongerNeeded
local GetEntityCoords = GetEntityCoords
local pairs, pcall = pairs, pcall

local SELECT = 'missfbi3_weapon_select'
local TROLLEY = 'missfbi3_weapon_select_trolley'
local WRENCH = 'missfbi3_wrench'
local WATER = 'missfbi3_waterboard'
local TOOTH = 'missfbi3_toothpull'
local ELECTRIC = 'missfbi3_electrocute'
local SYRINGE = 'MISSFBI3_SYRINGE'
local TOOTH_MODEL = `prop_ld_tooth`

local KIT_A = {
    false,
    'Trolley', 'weapon_bench_toothpull_trolley',
    'Jerrycan', 'weapon_bench_toothpull_can',
    'Battery', 'weapon_bench_toothpull_battery',
    'Clip1', 'weapon_bench_toothpull_clip1',
    'Clip2', 'weapon_bench_toothpull_clip2',
}
local KIT_B = {
    false,
    'Pliers', 'weapon_bench_toothpull_pliers',
    'Syringe', 'weapon_bench_toothpull_syringe',
    'Wrench', 'weapon_bench_toothpull_wrench',
}
local KIT_CHAIR = { false, 'Chair', 'weapon_select_electrocute_chair' }
local VICTIM_SEAT = { 'weapon_select_electrocute_victim', 'Chair', 'weapon_select_electrocute_chair' }

---@param prefix string
---@param tool string
---@param toolSuffix string
---@return table torturer
---@return table victim
local function pair(prefix, tool, toolSuffix)
    return { prefix .. '_player', tool, prefix .. toolSuffix }, { prefix .. '_victim', 'Chair', prefix .. '_chair' }
end

---@param prefix string
---@return table torturer
---@return table victim
local function clips(prefix)
    return { prefix .. '_player', 'Clip1', prefix .. '_r_clip', 'Clip2', prefix .. '_l_clip' }, { prefix .. '_victim', 'Chair', prefix .. '_chair' }
end

---@param name string
---@param dict string
---@param hold integer
---@param loop integer
---@param torturer? table
---@param victim? table
---@param cam string
---@param phase? number
---@return table
local function step(name, dict, hold, loop, torturer, victim, cam, phase)
    return { name = name, dict = dict, hold = hold, loop = loop, t = torturer, v = victim, cam = cam, phase = phase }
end

local wt, wv = pair('wrench_idle', 'Wrench', '_wrench')
local WRENCH_IDLE = step('WrenchIdle', WRENCH, 0, 1, wt, wv, 'wrench_idle_cam')

local jt, jv = pair('waterboard_idle', 'Jerrycan', '_jerrycan')
local WATER_IDLE = step('JerrycanIdle', WATER, 0, 1, jt, jv, 'waterboard_idle_cam')

local TOOTH_IDLE = step('PullToothIdle', TOOTH, 0, 1, { 'pull_tooth_idle_player', 'Pliers', 'pull_tooth_idle_pliers' }, { 'pull_tooth_idle_victim' }, 'pull_tooth_idle_cam')

local et, ev = clips('clamp_wait_loop')
local CLAMP_IDLE = step('ElectrocuteIdle', ELECTRIC, 0, 1, et, ev, 'clamp_wait_loop_cam')

---@class TortureState
---@field scenes table<string, integer>
---@field objects table<string, integer>
---@field netIds table<string, integer>
---@field particles integer[]
---@field coords vector3
---@field rotation vector3
---@field cam integer
---@field position integer
---@field otherPed integer
---@field started boolean
---@field inScene boolean

---@param S TortureState
---@param hooks { menu: fun(stage: string), controls: fun(state: boolean), damage: fun() }
---@return table<string, fun()>
return function(S, hooks)
    local scenes = {}

    ---@param dict string
    local function loadDict(dict)
        pcall(lib.requestAnimDict, dict, 5000)
    end

    ---@param asset string
    local function loadPtfx(asset)
        pcall(lib.requestNamedPtfxAsset, asset, 5000)
    end

    ---@param name string
    ---@param hold integer
    ---@param loop integer
    ---@param phase? number
    ---@return integer
    local function createScene(name, hold, loop, phase)
        local c, r = S.coords, S.rotation
        local id = NetworkCreateSynchronisedScene(c.x, c.y, c.z, r.x, r.y, r.z, 2, hold == 1, loop == 1, 1.0, phase or 0.0, 1.0)
        S.scenes[name] = id
        return id
    end

    ---@param scene integer
    ---@param dict string
    ---@param spec? table
    local function attach(scene, dict, spec)
        if not spec then return end
        if spec[1] then
            NetworkAddPedToSynchronisedScene(PlayerPedId(), scene, dict, spec[1], 1000.0, -1000.0, 1033, 0, 1000.0, 0)
        end
        local objects = S.objects
        for i = 2, #spec, 2 do
            local entity = objects[spec[i]]
            if entity and DoesEntityExist(entity) then
                NetworkAddEntityToSynchronisedScene(entity, scene, dict, spec[i + 1], 1000.0, -1000.0, 0)
            end
        end
    end

    ---@param anim string
    ---@param dict string
    local function playCam(anim, dict)
        if S.cam == 0 then
            S.cam = CreateCam('DEFAULT_ANIMATED_CAMERA', true)
            SetCamActive(S.cam, true)
            RenderScriptCams(true, false, 3000, true, false)
        end
        local c, r = S.coords, S.rotation
        PlayCamAnim(S.cam, anim, dict, c.x, c.y, c.z, r.x, r.y, r.z, false, 2)
    end

    ---@param data table
    local function run(data)
        loadDict(data.dict)
        local scene = createScene(data.name, data.hold, data.loop, data.phase)
        if S.position == 1 then
            attach(scene, data.dict, data.t)
        else
            attach(scene, data.dict, data.v)
        end
        NetworkStartSynchronisedScene(scene)
        playCam(data.cam, data.dict)
    end

    ---@param data table
    local function waitAnim(data)
        local ms = GetAnimDuration(data.dict, data.t[1]) * 1000 - 10
        if ms > 0 then Wait(ms) end
    end

    ---@param fade boolean
    local function begin(fade)
        S.inScene = true
        hooks.controls(true)
        if fade then
            DoScreenFadeOut(1000)
            Wait(1000)
        end
    end

    ---@param stage string
    local function idleThenMenu(idle, stage, delay)
        run(idle)
        Wait(delay or 1000)
        if not S.started then return end
        if S.position == 1 then
            hooks.menu(stage)
        end
    end

    local function stopFx()
        local list = S.particles
        for i = #list, 1, -1 do
            StopParticleFxLooped(list[i], false)
            list[i] = nil
        end
    end

    ---@param ped integer
    ---@param name string
    ---@param asset string
    ---@param bone integer
    ---@param y number
    local function pedFx(ped, asset, name, bone, y)
        CreateThread(function()
            Wait(200)
            if not DoesEntityExist(ped) then return end
            UseParticleFxAsset(asset)
            S.particles[#S.particles + 1] = StartParticleFxLoopedOnPedBone(name, ped, 0.0, y, 0.0, 0.0, 0.0, 0.0, bone, 1.0, false, false, false)
        end)
    end

    ---@return integer
    local function victimPed()
        return S.position == 1 and S.otherPed or PlayerPedId()
    end

    local function deleteTooth()
        local tooth = S.objects.ToothObject
        if tooth and DoesEntityExist(tooth) then
            SetEntityAsMissionEntity(tooth, true, true)
            DeleteEntity(tooth)
        end
        S.objects.ToothObject = nil
    end

    local function resetToTrolley()
        local ped = PlayerPedId()
        local trolley = S.objects.Trolley
        ClearPedTasks(ped)
        if trolley and DoesEntityExist(trolley) then
            local pos = GetOffsetFromEntityInWorldCoords(trolley, 0.0, -1.0, -0.7)
            SetEntityCoords(ped, pos.x, pos.y, pos.z, false, false, false, false)
            SetEntityHeading(ped, GetEntityHeading(trolley))
        end
    end

    local function closeCam()
        RenderScriptCams(false, false, 0, true, false)
        if S.cam ~= 0 then
            DestroyCam(S.cam, false)
            S.cam = 0
        end
    end

    ---@param damage boolean
    local function finish(damage)
        scenes.main()
        closeCam()
        if S.position == 1 then
            resetToTrolley()
        elseif damage then
            hooks.damage()
        end
        Wait(500)
        DoScreenFadeIn(1000)
        Wait(500)
        S.inScene = false
        hooks.controls(false)
    end

    function scenes.setupKit()
        loadDict(TROLLEY)
        loadDict(SELECT)
        local a = createScene('MainScene1', 0, 1)
        local b = createScene('MainScene2', 0, 1)
        local c = createScene('MainScene3', 1, 0)
        attach(a, TROLLEY, KIT_A)
        attach(b, TROLLEY, KIT_B)
        attach(c, SELECT, KIT_CHAIR)
        NetworkStartSynchronisedScene(a)
        NetworkStartSynchronisedScene(b)
        NetworkStartSynchronisedScene(c)
        local chair = S.objects.Chair
        if chair then FreezeEntityPosition(chair, true) end
    end

    ---@param victim boolean
    function scenes.seat(victim)
        loadDict(SELECT)
        local scene = createScene('MainScene3', victim and 0 or 1, victim and 1 or 0)
        attach(scene, SELECT, victim and VICTIM_SEAT or KIT_CHAIR)
        NetworkStartSynchronisedScene(scene)
        local chair = S.objects.Chair
        if chair then FreezeEntityPosition(chair, true) end
    end

    function scenes.stopAll()
        for name, id in pairs(S.scenes) do
            NetworkStopSynchronisedScene(id)
            S.scenes[name] = nil
        end
    end

    function scenes.main()
        if S.position == 1 then
            loadDict(TROLLEY)
            local a = createScene('MainScene1', 0, 1)
            local b = createScene('MainScene2', 0, 1)
            attach(a, TROLLEY, KIT_A)
            attach(b, TROLLEY, KIT_B)
            NetworkStartSynchronisedScene(a)
            NetworkStartSynchronisedScene(b)
        elseif S.position == 2 then
            scenes.seat(true)
        end
    end

    local wrenchPick = step('PickingWrench', SELECT, 1, 0, { 'weapon_select_wrench_player', 'Wrench', 'weapon_select_wrench_wrench' }, { 'weapon_select_wrench_victim', 'Chair', 'weapon_select_wrench_chair' }, 'weapon_select_wrench_cam')

    function scenes.wrench()
        begin(true)
        run(wrenchPick)
        DoScreenFadeIn(1000)
        waitAnim(wrenchPick)
        if not S.started then return end
        idleThenMenu(WRENCH_IDLE, 'wrench')
    end

    for action, prefix in pairs({ ['wrench-right'] = 'wrench_attack_right', ['wrench-left'] = 'wrench_attack_left', ['wrench-middle'] = 'wrench_attack_mid' }) do
        local t, v = pair(prefix, 'Wrench', '_wrench')
        local attack = step('WrenchAttack', WRENCH, 1, 0, t, v, prefix .. '_cam')
        scenes[action] = function()
            begin(false)
            run(attack)
            waitAnim(attack)
            if not S.started then return end
            idleThenMenu(WRENCH_IDLE, 'wrench')
        end
    end

    scenes['wrench-exit'] = function()
        begin(true)
        finish(true)
    end

    local waterPick = step('PickingJerrycan', SELECT, 1, 0, { 'weapon_select_waterboard_player', 'Jerrycan', 'weapon_select_waterboard_jerrycan' }, { 'weapon_select_waterboard_victim', 'Chair', 'weapon_select_waterboard_chair' }, 'weapon_select_waterboard_cam')
    local kt, kv = pair('waterboard_kick', 'Jerrycan', '_jerrycan')
    local waterKick = step('JerrycanKickPlayer', WATER, 1, 0, kt, kv, 'waterboard_kick_cam')
    local lt, lv = pair('waterboard_loop', 'Jerrycan', '_jerrycan')
    local waterLoop = step('JerrycanDrownLoop', WATER, 0, 1, lt, lv, 'waterboard_loop_cam')
    local ot, ov = pair('waterboard_outro', 'Jerrycan', '_jerrycan')
    local waterOutro = step('JerrycanDrownStop', WATER, 1, 0, ot, ov, 'waterboard_outro_cam')

    local function pourWater(entity)
        UseParticleFxAsset('scr_fbi3')
        S.particles[#S.particles + 1] = StartNetworkedParticleFxLoopedOnEntity('scr_fbi3_dirty_water_pour', entity, 0.15, 0.025, 0.2, 0.0, 0.0, 0.0, 1.0, false, false, false)
    end

    function scenes.jerrycan()
        begin(true)
        run(waterPick)
        DoScreenFadeIn(1000)
        waitAnim(waterPick)
        if not S.started then return end
        idleThenMenu(WATER_IDLE, 'jerrycan')
    end

    scenes['jerrycan-drown'] = function()
        begin(false)
        run(waterKick)
        waitAnim(waterKick)
        if not S.started then return end

        loadPtfx('scr_fbi3')
        run(waterLoop)

        if S.position == 1 then
            local jerrycan = S.objects.Jerrycan
            if jerrycan then pourWater(jerrycan) end
        else
            CreateThread(function()
                local netId = S.netIds.Jerrycan
                if not netId then return end
                local deadline = GetGameTimer() + 2000
                while not NetworkDoesNetworkIdExist(netId) and GetGameTimer() < deadline do
                    Wait(50)
                end
                local entity = NetworkDoesNetworkIdExist(netId) and NetworkGetEntityFromNetworkId(netId) or 0
                if entity ~= 0 and DoesEntityExist(entity) then
                    S.objects.Jerrycan = entity
                    pourWater(entity)
                end
            end)
        end

        Wait(2000)
        if not S.started then return end
        if S.position == 1 then hooks.menu('jerrycanDrown') end
    end

    scenes['jerrycan-stop'] = function()
        begin(false)
        stopFx()
        run(waterOutro)
        waitAnim(waterOutro)
        if not S.started then return end
        idleThenMenu(WATER_IDLE, 'jerrycan')
    end

    scenes['jerrycan-exit'] = function()
        begin(true)
        finish(true)
    end

    local toothPick = step('PickingPullTooth', SELECT, 1, 0, { 'weapon_select_pliers_player', 'Pliers', 'weapon_select_pliers_pliers' }, { 'weapon_select_pliers_victim' }, 'weapon_select_pliers_cam')
    local toothIntro = step('PullToothIntro', TOOTH, 1, 0, { 'pull_tooth_intro_player', 'Pliers', 'pull_tooth_intro_pliers' }, { 'pull_tooth_intro_victim' }, 'pull_tooth_intro_cam')
    local toothLoop = step('PullToothLoop', TOOTH, 0, 1, { 'pull_tooth_loop_player', 'Pliers', 'pull_tooth_loop_pliers' }, { 'pull_tooth_loop_victim' }, 'pull_tooth_loop_cam')
    local toothOutro = step('PullToothOutro', TOOTH, 1, 0, { 'pull_tooth_outro_b_player', 'Pliers', 'pull_tooth_outro_b_pliers' }, { 'pull_tooth_outro_b_victim' }, 'pull_tooth_outro_b_cam')
    local toothExit = step('PullToothExit', TOOTH, 1, 0, { 'pull_tooth_outro_player', 'Pliers', 'pull_tooth_outro_pliers' }, { 'pull_tooth_outro_victim', 'Chair', 'pull_tooth_outro_chair' }, 'pull_tooth_outro_cam', 0.5)

    function scenes.pullTooth()
        begin(true)
        run(toothPick)
        DoScreenFadeIn(1000)
        waitAnim(toothPick)
        if not S.started then return end
        idleThenMenu(TOOTH_IDLE, 'pullTooth')
    end

    scenes['pullTooth-pull'] = function()
        begin(false)
        run(toothIntro)
        waitAnim(toothIntro)
        if not S.started then return end

        loadPtfx('scr_fbi3')
        run(toothLoop)
        pedFx(victimPed(), 'scr_fbi3', 'scr_fbi3_blood_mouth', 31086, 0.1)

        Wait(2000)
        if not S.started then return end
        if S.position == 1 then hooks.menu('pullToothPull') end
    end

    scenes['pullTooth-stop'] = function()
        begin(false)
        deleteTooth()
        stopFx()

        if S.position == 1 then
            local ped = PlayerPedId()
            if pcall(lib.requestModel, TOOTH_MODEL, 5000) then
                local pos = GetEntityCoords(ped)
                local tooth = CreateObject(TOOTH_MODEL, pos.x, pos.y, pos.z, true, true, false)
                SetModelAsNoLongerNeeded(TOOTH_MODEL)
                AttachEntityToEntity(tooth, ped, GetPedBoneIndex(ped, 60309), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
                S.objects.ToothObject = tooth
            end
        end

        run(toothOutro)
        waitAnim(toothOutro)
        deleteTooth()
        if not S.started then return end
        idleThenMenu(TOOTH_IDLE, 'pullTooth')
    end

    scenes['pullTooth-exit'] = function()
        begin(false)
        run(toothExit)
        Wait(6300)
        if not S.started then return end
        DoScreenFadeOut(1000)
        Wait(1000)
        finish(true)
    end

    local electricPick = step('PickingElectrocuteClips', SELECT, 1, 0, { 'weapon_select_electrocute_player', 'Clip1', 'weapon_select_electrocute_l_clip', 'Clip2', 'weapon_select_electrocute_r_clip' }, { 'weapon_select_electrocute_victim', 'Chair', 'weapon_select_electrocute_chair' }, 'weapon_select_electrocute_cam')

    function scenes.electrocute()
        begin(true)
        run(electricPick)
        DoScreenFadeIn(1000)
        waitAnim(electricPick)
        if not S.started then return end
        idleThenMenu(CLAMP_IDLE, 'electrocute')
    end

    for action, side in pairs({ ['electrocute-right'] = 'right', ['electrocute-left'] = 'left' }) do
        local it, iv = clips('clamp_' .. side .. '_intro')
        local intro = step('Electrocute' .. side .. 'Intro', ELECTRIC, 1, 0, it, iv, 'clamp_' .. side .. '_intro_cam')
        local pt, pv = clips('clamp_' .. side .. '_loop')
        local loop = step('Electrocute' .. side .. 'Loop', ELECTRIC, 0, 1, pt, pv, 'clamp_' .. side .. '_loop_cam')
        scenes[action] = function()
            begin(false)
            run(intro)
            waitAnim(intro)
            if not S.started then return end
            idleThenMenu(loop, 'electrocuteClamp')
        end
    end

    local bt, bv = clips('electrocute_both_intro')
    local bothIntro = step('ElectrocuteBothIntro', ELECTRIC, 1, 0, bt, bv, 'electrocute_both_intro_cam')
    local blt, blv = clips('electrocute_both_loop')
    local bothLoop = step('ElectrocuteBothLoop', ELECTRIC, 0, 1, blt, blv, 'electrocute_both_loop_cam')
    local st, sv = clips('electrocute_spark')
    local spark = step('ElectrocuteSpark', ELECTRIC, 1, 0, st, sv, 'electrocute_spark_cam')
    local bot, bov = clips('electrocute_both_outro')
    local bothStop = step('ElectrocuteStop', ELECTRIC, 1, 0, bot, bov, 'electrocute_both_outro_cam')
    local electricExit = step('ElectrocuteExit', ELECTRIC, 1, 0, bot, bov, 'electrocute_both_outro_cam', 0.6)

    scenes['electrocute-both'] = function()
        begin(false)
        run(bothIntro)
        waitAnim(bothIntro)
        if not S.started then return end

        loadPtfx('core')
        run(bothLoop)
        pedFx(victimPed(), 'core', 'fire_ped_smoulder', 39317, 0.0)

        Wait(1000)
        if not S.started then return end
        if S.position == 1 then hooks.menu('electrocuteBoth') end
    end

    scenes['electrocute-spark-stop'] = function()
        begin(false)
        loadPtfx('scr_fbi3')
        run(spark)

        if S.position == 1 then
            local clip = S.objects.Clip1
            CreateThread(function()
                Wait(200)
                if not clip or not DoesEntityExist(clip) then return end
                UseParticleFxAsset('scr_fbi3')
                StartNetworkedParticleFxNonLoopedOnEntity('scr_fbi3_elec_sparks', clip, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, false, false, false)
            end)
        end

        waitAnim(spark)
        if not S.started then return end
        idleThenMenu(CLAMP_IDLE, 'electrocute')
    end

    scenes['electrocute-both-stop'] = function()
        begin(false)
        run(bothStop)
        Wait(2000)
        stopFx()
        if not S.started then return end
        idleThenMenu(CLAMP_IDLE, 'electrocute')
    end

    scenes['electrocute-exit'] = function()
        begin(false)
        run(electricExit)
        Wait(1000)
        if not S.started then return end
        DoScreenFadeOut(1000)
        Wait(1000)
        finish(true)
    end

    local syringeUse = step('SyringeUsage', SYRINGE, 1, 0, { 'Syringe_Use_Player' }, { 'Syringe_Use_Victim', 'Chair', 'Syringe_Use_Chair' }, 'Syringe_Use_Cam')
    local syringePick = step('SyringeSelect', SYRINGE, 1, 0, { 'Weapon_Select_Syringe_Player' }, { 'flatline_intro_victim', 'Chair', 'flatline_intro_chair' }, 'Weapon_Select_Syringe_Cam')

    function scenes.syringe()
        begin(true)
        run(syringePick)

        local syringe = S.objects.Syringe
        if S.position == 1 and syringe and DoesEntityExist(syringe) then
            local ped = PlayerPedId()
            AttachEntityToEntity(syringe, ped, GetPedBoneIndex(ped, 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
        end

        DoScreenFadeIn(1000)
        waitAnim(syringePick)
        if not S.started then return end

        run(syringeUse)
        local ms = GetAnimDuration(SYRINGE, 'Syringe_Use_Player') * 1000 - 1010
        if ms > 0 then Wait(ms) end
        if S.position == 1 and syringe and DoesEntityExist(syringe) then
            DetachEntity(syringe, false, true)
        end
        if not S.started then return end

        DoScreenFadeOut(1000)
        Wait(1000)
        finish(true)
    end

    scenes['default-exit'] = function()
        begin(true)
        stopFx()

        if S.position == 1 then
            local syringe = S.objects.Syringe
            if syringe and DoesEntityExist(syringe) then
                DetachEntity(syringe, false, true)
            end
            deleteTooth()
            Wait(10)
            scenes.main()
        end

        closeCam()
        if S.position == 1 then
            resetToTrolley()
        end

        Wait(500)
        DoScreenFadeIn(1000)
        Wait(500)
        S.inScene = false
        hooks.controls(false)
    end

    scenes.stopFx = stopFx
    scenes.closeCam = closeCam

    return scenes
end
