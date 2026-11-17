local Config = SmPets.Config
local k9 = Config.K9
local uiActions = SmPets.uiActions
local accessoryHandlers = SmPets.accessoryHandlers

local DoesEntityExist = DoesEntityExist
local DeleteEntity = DeleteEntity
local GetEntityCoords = GetEntityCoords
local GetEntityHeading = GetEntityHeading
local SetEntityHeading = SetEntityHeading
local SetEntityCoords = SetEntityCoords
local SetEntityRotation = SetEntityRotation
local GetOffsetFromEntityInWorldCoords = GetOffsetFromEntityInWorldCoords
local FreezeEntityPosition = FreezeEntityPosition
local ClearPedTasks = ClearPedTasks
local ClearPedTasksImmediately = ClearPedTasksImmediately
local TaskFollowToOffsetOfEntity = TaskFollowToOffsetOfEntity
local TaskTurnPedToFaceEntity = TaskTurnPedToFaceEntity
local TaskAchieveHeading = TaskAchieveHeading
local SetPedToRagdoll = SetPedToRagdoll
local SetEntityHealth = SetEntityHealth
local IsPedAPlayer = IsPedAPlayer
local IsPedDeadOrDying = IsPedDeadOrDying
local IsPlayerFreeAiming = IsPlayerFreeAiming
local GetEntityPlayerIsFreeAimingAt = GetEntityPlayerIsFreeAimingAt
local NetworkGetPlayerIndexFromPed = NetworkGetPlayerIndexFromPed
local GetPlayerServerId = GetPlayerServerId
local NetworkGetNetworkIdFromEntity = NetworkGetNetworkIdFromEntity
local CreateObject = CreateObject
local DisableControlAction = DisableControlAction
local IsControlJustReleased = IsControlJustReleased
local GetScreenCoordFromWorldCoord = GetScreenCoordFromWorldCoord
local PlayerId = PlayerId
local GetGameTimer = GetGameTimer
local Wait = Wait
local CreateThread = CreateThread
local mrandom = math.random
local msqrt = math.sqrt
local GetEntityType = GetEntityType
local GetEntityModel = GetEntityModel
local GetModelDimensions = GetModelDimensions

local MELEE_DICT = 'creatures@rottweiler@melee@streamed_core@'
local VICTIM_ANIM = { MELEE_DICT, 'victim_takedown_from_front' }
local BITE_ANIM = { MELEE_DICT, 'ground_attack_0' }
local LUNGE_ANIM = { 'creatures@rottweiler@melee@', 'dog_attack' }
local FOUND_ANIMS = {
    [1] = { 'creatures@rottweiler@melee@streamed_taunts@', 'taunt_01' },
    [2] = { 'creatures@rottweiler@tricks@', 'sit_loop' },
    [3] = { 'creatures@rottweiler@melee@streamed_taunts@', 'taunt_02' },
    [4] = { 'creatures@rottweiler@tricks@', 'sit_loop' },
}
local FOUND_TEXT = {
    [1] = 'Pet menemukan bau narkoba!',
    [2] = 'Pet menemukan bau uang kotor!',
    [3] = 'Pet menemukan bau senjata!',
    [4] = 'Pet menemukan barang ilegal!',
}
local HOOP_ANIMS = {
    { 'pulandochopdog@animations', 'pulandochopdog_clip' },
    { 'pulandoarchopdog@animations', 'pulandoarchopdog_clip' },
    { 'pulandocaindochopdog@animations', 'pulandocaindochopdog_clip' },
}

---@return boolean
local function isHandler()
    local job = QBPlayerData.job
    return job ~= nil and k9.jobs[job.name] == true
end

---@param pet table
---@return boolean
local function canOrderAttack(pet)
    if pet.k9 then return isHandler() end
    return pet.canAttack == true
end

---@param model string
---@param coords vector3
---@param heading number
---@return integer
local function spawnProp(model, coords, heading)
    local hash = SmPets.loadModel(model)
    if not hash then return 0 end
    local object = CreateObject(hash, coords.x, coords.y, coords.z, true, true, false)
    SetEntityHeading(object, heading or 0.0)
    FreezeEntityPosition(object, true)
    SetModelAsNoLongerNeeded(hash)
    return object
end

---@param list integer[]
local function deleteAll(list)
    for i = 1, #list do
        if DoesEntityExist(list[i]) then DeleteEntity(list[i]) end
        list[i] = nil
    end
end

---@param name string
---@param onCancel fun(silent: boolean)
---@return table
local function begin(name, onCancel)
    local pet = SmPets.pet
    if pet.cancel then
        local cancel = pet.cancel
        pet.cancel = nil
        cancel(true)
    end
    SmPets.setAction(name, onCancel)
    return pet
end

local function finish()
    local pet = SmPets.pet
    if not pet then return end
    pet.cancel = nil
    if pet.state ~= 'dead' then
        pet.state = 'idle'
        if DoesEntityExist(pet.ped) then ClearPedTasks(pet.ped) end
    end
end

---@param targetPed integer
function SmPets.attack(targetPed)
    local pet = SmPets.pet
    if not pet or not (pet.k9 or pet.canAttack) or pet.state == 'dead' or pet.state == 'attack' then return end
    if k9.onlyPlayers and not IsPedAPlayer(targetPed) then return end
    local serverId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(targetPed))
    if not serverId or serverId <= 0 then return end

    local result = lib.callback.await('sm_pets:k9:attack', false, serverId)
    if not result or not result.ok then
        if result and result.msg then SmPets.notify(result.msg, 'error') end
        return
    end

    if not result.understood then
        SmPets.notify(('%s bingung dengan perintahmu. Latih lagi kemampuan menyerangnya.'):format(pet.name), 'warning')
        local p = begin('busy', function() end)
        SmPets.playAnim(p.ped, p.anims.sit, 1)
        SetTimeout(3000, function()
            if SmPets.pet == p and p.state == 'busy' then finish() end
        end)
        return
    end

    local active = true
    pet = begin('attack', function()
        active = false
        local p = SmPets.pet
        if p and DoesEntityExist(p.ped) then ClearPedTasksImmediately(p.ped) end
    end)
    local ped = pet.ped
    local agility = result.agility or 0
    local speed = agility > 75 and 4.0 or agility > 50 and 3.0 or agility > 25 and 2.0 or 1.5
    TaskFollowToOffsetOfEntity(ped, targetPed, 0.0, 0.0, 0.0, speed, -1, 0.5, true)
    SmPets.vocal('attack')

    CreateThread(function()
        local deadline = GetGameTimer() + 15000
        while active and GetGameTimer() < deadline do
            if not DoesEntityExist(targetPed) or IsPedDeadOrDying(targetPed, true) then break end
            if #(GetEntityCoords(ped) - GetEntityCoords(targetPed)) <= 2.0 then
                if lib.callback.await('sm_pets:k9:takedown', false, serverId) then
                    ClearPedTasksImmediately(ped)
                    SmPets.playAnim(ped, BITE_ANIM, 1)
                    local releaseAt = GetGameTimer() + k9.takedownMs
                    while active and GetGameTimer() < releaseAt do Wait(250) end
                end
                break
            end
            Wait(100)
        end
        if active and SmPets.pet == pet then finish() end
    end)
end

RegisterNetEvent('sm_pets:client:takedown', function(_, duration, lethal)
    local ped = cache.ped
    if IsPedDeadOrDying(ped, true) then return end
    duration = math.min(tonumber(duration) or 0, k9.takedownMs)
    if not SmPets.loadDict(MELEE_DICT) then return end
    ClearPedTasksImmediately(ped)
    TaskPlayAnim(ped, VICTIM_ANIM[1], VICTIM_ANIM[2], 8.0, -8.0, -1, 1, 0.0, false, false, false)
    local releaseAt = GetGameTimer() + duration
    while GetGameTimer() < releaseAt and not IsPedDeadOrDying(cache.ped, true) do
        DisableControlAction(0, 30, true)
        DisableControlAction(0, 31, true)
        DisableControlAction(0, 21, true)
        DisableControlAction(0, 22, true)
        DisableControlAction(0, 24, true)
        DisableControlAction(0, 25, true)
        DisableControlAction(0, 44, true)
        Wait(0)
    end
    ClearPedTasks(cache.ped)
    if lethal == true and not IsPedDeadOrDying(cache.ped, true) then
        SetEntityHealth(cache.ped, 0)
    end
end)

local aimLoop = false

local function startAimLoop()
    if aimLoop or not k9.attackOnAim then return end
    aimLoop = true
    CreateThread(function()
        local playerId = PlayerId()
        while aimLoop do
            local pet = SmPets.pet
            if not pet or not (pet.k9 or pet.canAttack) then break end
            local sleep = 1000
            if cache.weapon and canOrderAttack(pet) and (pet.state == 'idle' or pet.state == 'follow') then
                sleep = 200
                if IsPlayerFreeAiming(playerId) then
                    local hit, target = GetEntityPlayerIsFreeAimingAt(playerId)
                    if hit and target ~= 0 and target ~= pet.ped and IsPedAPlayer(target) then
                        SmPets.attack(target)
                        sleep = 1500
                    end
                end
            end
            Wait(sleep)
        end
        aimLoop = false
    end)
end

AddEventHandler('sm_pets:client:spawned', function(pet)
    if pet.k9 or pet.canAttack then startAimLoop() end
end)

AddEventHandler('sm_pets:client:removed', function()
    aimLoop = false
end)

---@param target integer
---@param ped integer
---@return vector3
local function sniffSpot(target, ped)
    if GetEntityType(target) == 2 then
        local min = GetModelDimensions(GetEntityModel(target))
        return GetOffsetFromEntityInWorldCoords(target, 0.0, min.y - 0.6, 0.0)
    end
    local t, p = GetEntityCoords(target), GetEntityCoords(ped)
    local dx, dy = p.x - t.x, p.y - t.y
    local len = msqrt(dx * dx + dy * dy)
    if len < 0.01 then return GetOffsetFromEntityInWorldCoords(target, 0.0, 0.8, 0.0) end
    return vec3(t.x + dx / len * 0.8, t.y + dy / len * 0.8, t.z)
end

---@param target integer
---@param serverCall fun(): integer|false
local function sniffTarget(target, serverCall)
    local cancelled = false
    local pet = begin('busy', function()
        cancelled = true
        local p = SmPets.pet
        if p and DoesEntityExist(p.ped) then FreezeEntityPosition(p.ped, false) end
    end)
    local ped = pet.ped
    local goal = sniffSpot(target, ped)
    SmPets.goTo(ped, goal, 2.0)
    local arrived = SmPets.waitArrive(ped, goal, 0.6, 8000, function() return cancelled end)
    if cancelled then return end
    if not arrived and #(GetEntityCoords(ped) - GetEntityCoords(target)) > k9.sniffRange then
        ClearPedTasks(ped)
        SmPets.notify('Pet tidak bisa mendekati target.', 'error')
        return finish()
    end
    ClearPedTasks(ped)

    TaskTurnPedToFaceEntity(ped, target, 1000)
    Wait(800)
    if cancelled then return end
    SmPets.playAnim(ped, pet.anims.eat, 1)
    SmPets.vocal('sniff')
    Wait(2500)
    if cancelled then return end

    local code = serverCall()
    if cancelled then return end
    ClearPedTasks(ped)
    if code and code > 0 then
        SmPets.playAnim(ped, FOUND_ANIMS[code], 0)
        SmPets.vocal('bark')
        SmPets.notify(FOUND_TEXT[code], 'success')
    else
        SmPets.vocal('whine')
        SmPets.notify('Pet tidak menemukan apa-apa.', 'inform')
    end
    Wait(2000)
    if not cancelled then finish() end
end

function SmPets.sniffPlayer()
    local pet = SmPets.pet
    if not pet or not pet.k9 then return end
    if not isHandler() then return SmPets.notify('Hanya petugas yang bisa memberi perintah K9.', 'error') end
    if not SmPets.canCommand() then return end
    local targetPed = SmPets.selectTarget({ kind = 'player', range = 8.0, title = ('Endus orang dengan %s'):format(pet.name), action = 'Endus', icon = 'fas fa-user-magnifying-glass' })
    if not targetPed then return end
    local serverId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(targetPed))
    if not serverId or serverId <= 0 then return end
    sniffTarget(targetPed, function()
        return lib.callback.await('sm_pets:k9:sniffPlayer', false, serverId)
    end)
end

function SmPets.sniffVehicle()
    local pet = SmPets.pet
    if not pet or not pet.k9 then return end
    if not isHandler() then return SmPets.notify('Hanya petugas yang bisa memberi perintah K9.', 'error') end
    if not SmPets.canCommand() then return end
    local vehicle = SmPets.selectTarget({ kind = 'vehicle', range = 8.0, title = ('Endus kendaraan dengan %s'):format(pet.name), action = 'Endus', icon = 'fas fa-car' })
    if not vehicle then return end
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    sniffTarget(vehicle, function()
        return lib.callback.await('sm_pets:k9:sniffVehicle', false, netId)
    end)
end

---@param pet table
---@param points vector3[]
---@param success boolean
---@param isCancelled fun(): boolean
---@return boolean completed
local function runCourse(pet, points, success, isCancelled)
    local tripAt = success and 0 or mrandom(1, #points)
    for i = 1, #points do
        if isCancelled() then return false end
        local p = points[i]
        SmPets.goTo(pet.ped, p, 2.0)
        SmPets.waitArrive(pet.ped, p, 0.9, 8000, isCancelled)
        if i == tripAt then
            SetPedToRagdoll(pet.ped, 1500, 1500, 0, false, false, false)
            SmPets.notify('Pet tersandung. Coba lagi nanti.', 'error')
            Wait(1600)
            return false
        end
    end
    return true
end

local function trainingDone(result)
    if result and result.ok then
        SmPets.vocal('bark')
        SmPets.notify('Latihan berhasil, kemampuan pet naik.', 'success')
    end
end

accessoryHandlers.training = function(_, key)
    local pet = SmPets.pet
    if not pet or not pet.k9 then return SmPets.notify('Alat ini khusus pet K9.', 'error') end
    if not isHandler() then return SmPets.notify('Hanya petugas yang bisa melatih K9.', 'error') end
    local start = lib.callback.await('sm_pets:k9:trainStart', false, key)
    if not start or not start.ok then
        return SmPets.notify(start and start.msg or 'Latihan gagal dimulai.', 'error')
    end

    local props = {}
    local cancelled = false
    local kind = start.kind

    if kind == 'dummy' then
        local biting = false
        pet = begin('training', function(silent)
            cancelled = true
            infoUI.remove('sm_pets:dummy')
            local p = SmPets.pet
            if p and DoesEntityExist(p.ped) then FreezeEntityPosition(p.ped, false) end
            deleteAll(props)
            if biting and not silent then
                local result = lib.callback.await('sm_pets:k9:trainFinish', false)
                if result and result.result == 'perfect' then
                    trainingDone(result)
                elseif result and result.result == 'late' then
                    SmPets.notify('Terlambat menghentikan pet.', 'error')
                else
                    SmPets.notify('Terlalu cepat menghentikan pet.', 'error')
                end
            end
        end)
        local ped, player = pet.ped, cache.ped
        local spot = GetOffsetFromEntityInWorldCoords(player, 0.0, 2.5, 0.0)
        local ground = vec3(spot.x, spot.y, SmPets.groundZ(spot))
        props[1] = spawnProp('cdev_pets_dummy_t', ground, GetEntityHeading(player))
        props[2] = spawnProp('cdev_pets_dummy_l', ground, GetEntityHeading(player))
        local front = GetOffsetFromEntityInWorldCoords(props[1], 0.0, -1.0, 0.0)
        SmPets.goTo(ped, front, 2.0)
        SmPets.waitArrive(ped, front, 0.8, 8000, function() return cancelled end)
        if cancelled then return end
        TaskAchieveHeading(ped, GetEntityHeading(props[1]), 1200)
        Wait(900)
        if cancelled then return end
        SmPets.playAnim(ped, LUNGE_ANIM, 1)
        Wait(900)
        if cancelled then return end
        SmPets.playAnim(ped, BITE_ANIM, 1)
        FreezeEntityPosition(ped, true)
        biting = lib.callback.await('sm_pets:k9:dummyBite', false) == true
        infoUI.show({ id = 'sm_pets:dummy', title = 'Latihan Dummy', icon = 'fas fa-stopwatch', description = ('Tekan %s antara detik ke-8 dan ke-10.'):format(Config.CancelKey) })
        local giveUpAt = GetGameTimer() + k9.training.dummy.windowMs[2] + 2500
        while not cancelled and GetGameTimer() < giveUpAt do Wait(250) end
        if not cancelled and SmPets.pet == pet then SmPets.cancelAction() end
        return
    end

    pet = begin('training', function()
        cancelled = true
        local p = SmPets.pet
        if p and DoesEntityExist(p.ped) then FreezeEntityPosition(p.ped, false) end
        deleteAll(props)
    end)
    local isCancelled = function() return cancelled end
    local ped, player = pet.ped, cache.ped
    SmPets.playAnim(player, pet.anims.pickup, 0, 1500)
    Wait(1200)
    if cancelled then return end
    local heading = GetEntityHeading(player)
    local completed = false

    if kind == 'cones' then
        local a = GetOffsetFromEntityInWorldCoords(player, 1.5, 2.0, 0.0)
        local b = GetOffsetFromEntityInWorldCoords(player, 1.5, 5.0, 0.0)
        props[1] = spawnProp('prop_mp_cone_03', vec3(a.x, a.y, SmPets.groundZ(a)), heading)
        props[2] = spawnProp('prop_mp_cone_03', vec3(b.x, b.y, SmPets.groundZ(b)), heading)
        local points = {
            GetOffsetFromEntityInWorldCoords(player, 0.5, 2.0, 0.0),
            GetOffsetFromEntityInWorldCoords(player, 2.5, 3.5, 0.0),
            GetOffsetFromEntityInWorldCoords(player, 0.5, 5.0, 0.0),
            GetOffsetFromEntityInWorldCoords(player, 1.5, 6.5, 0.0),
            GetOffsetFromEntityInWorldCoords(player, 2.5, 5.0, 0.0),
            GetOffsetFromEntityInWorldCoords(player, 0.5, 3.5, 0.0),
            GetOffsetFromEntityInWorldCoords(player, 2.5, 2.0, 0.0),
            GetOffsetFromEntityInWorldCoords(player, 1.5, 0.5, 0.0),
        }
        completed = runCourse(pet, points, start.success, isCancelled)
    elseif kind == 'ramp' then
        local center = GetOffsetFromEntityInWorldCoords(player, 0.0, 4.0, 0.0)
        props[1] = spawnProp('cdev_pets_ramp1', vec3(center.x, center.y, SmPets.groundZ(center)), heading)
        local points = {
            GetOffsetFromEntityInWorldCoords(props[1], 0.0, -3.5, 0.0),
            GetOffsetFromEntityInWorldCoords(props[1], 0.0, 0.0, 1.0),
            GetOffsetFromEntityInWorldCoords(props[1], 0.0, 3.5, 0.0),
            GetOffsetFromEntityInWorldCoords(props[1], 0.0, 0.0, 1.0),
            GetOffsetFromEntityInWorldCoords(props[1], 0.0, -3.5, 0.0),
        }
        completed = runCourse(pet, points, start.success, isCancelled)
    elseif kind == 'hoop' then
        local center = GetOffsetFromEntityInWorldCoords(player, 0.0, 3.0, 0.0)
        local ground = vec3(center.x, center.y, SmPets.groundZ(center))
        props[1] = spawnProp('cdev_pets_hoop2', ground, heading + 90.0)
        local approach = GetOffsetFromEntityInWorldCoords(player, 0.0, 1.0, 0.0)
        SmPets.goTo(ped, approach, 2.0)
        SmPets.waitArrive(ped, approach, 0.8, 8000, isCancelled)
        if cancelled then return end
        SetEntityHeading(ped, heading)
        if pet.species == 'bigdog' then
            for i = 1, #HOOP_ANIMS do
                if cancelled then return end
                local duration = SmPets.playAnim(ped, HOOP_ANIMS[i], 0)
                if i == 2 and not start.success then
                    Wait((duration > 0 and duration or 1000) // 2)
                    ClearPedTasksImmediately(ped)
                    SetPedToRagdoll(ped, 1500, 1500, 0, false, false, false)
                    SetEntityRotation(props[1], -80.0, 0.0, heading + 90.0, 2, true)
                    SmPets.notify('Pet menabrak ring.', 'error')
                    Wait(1600)
                    break
                end
                Wait(duration > 0 and duration or 1000)
            end
            completed = start.success and not cancelled
            if completed then
                local landing = GetOffsetFromEntityInWorldCoords(props[1], 1.5, 0.0, 0.0)
                SetEntityCoords(ped, landing.x, landing.y, SmPets.groundZ(landing), false, false, false, false)
            end
        else
            local beyond = GetOffsetFromEntityInWorldCoords(player, 0.0, 5.0, 0.0)
            completed = runCourse(pet, { ground, beyond }, start.success, isCancelled)
        end
    end

    if cancelled then return end
    if completed then trainingDone(lib.callback.await('sm_pets:k9:trainFinish', false)) end
    deleteAll(props)
    finish()
end

function SmPets.attackSelect()
    local pet = SmPets.pet
    if not pet or not (pet.k9 or pet.canAttack) then return end
    if not canOrderAttack(pet) then return SmPets.notify('Hanya petugas yang bisa memberi perintah K9.', 'error') end
    if not SmPets.canCommand() then return end
    local target = SmPets.selectTarget({
        kind = 'player',
        range = k9.attackRange,
        title = ('Serang dengan %s'):format(pet.name),
        action = 'Serang',
        color = { r = 220, g = 60, b = 60 },
    })
    if target then SmPets.attack(target) end
end

uiActions.attackSelect = function()
    SmPets.closeUI()
    CreateThread(SmPets.attackSelect)
    return { ok = true, closed = true }
end

uiActions.sniffPlayer = function()
    SmPets.closeUI()
    CreateThread(SmPets.sniffPlayer)
    return { ok = true, closed = true }
end

uiActions.sniffVehicle = function()
    SmPets.closeUI()
    CreateThread(SmPets.sniffVehicle)
    return { ok = true, closed = true }
end
