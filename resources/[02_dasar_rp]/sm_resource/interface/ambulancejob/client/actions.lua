local config = localmodule 'config.client'
local itemModule = require 'modules.items.client'

local function isMedicalJob(name)
    return config.medicalJobs[name] or false
end

local lib1CharA = 'mini@cpr@char_a@cpr_def'
local lib2CharA = 'mini@cpr@char_a@cpr_str'
local lib1CharB = 'mini@cpr@char_b@cpr_def'
local lib2CharB = 'mini@cpr@char_b@cpr_str'

local animStart = 'cpr_intro'
local animPump = 'cpr_pumpchest'
local animSuccess = 'cpr_success'

local function plyCpr()
    SetCurrentPedWeapon(cache.ped, GetHashKey('WEAPON_UNARMED'), true)

    pcall(lib.requestAnimDict, lib1CharA, 1500)
    TaskPlayAnim(cache.ped, lib1CharA, animStart, 8.0, 8.0, -1, 0, 0, false, false, false)
    Wait(15800 - 900)

    pcall(lib.requestAnimDict, lib2CharA, 1500)

    for _ = 1, 15 do
        Wait(900)
        TaskPlayAnim(cache.ped, lib2CharA, animPump, 8.0, 8.0, -1, 0, 0, false, false, false)
    end

    TaskPlayAnim(cache.ped, lib2CharA, animSuccess, 8.0, 8.0, -1, 0, 0, false, false, false)
    Wait(3000)

    ClearPedTasks(cache.ped)
end

local function playInjectionAnim()
    local ped = cache.ped

    pcall(lib.requestAnimDict, 'injecting@writzstudio', 1500)
    
    local propModel = `prop_syringe`
    lib.requestModel(propModel, 1500)
    
    local prop = CreateObject(propModel, 0.0, 0.0, 0.0, true, true, true)
    
    AttachEntityToEntity(
        prop, 
        ped, 
        GetPedBoneIndex(ped, 57005), -- PropBone: right hand
        0.25,    -- x
        0.014,   -- y
        0.005,   -- z
        -70.0,   -- rotX
        0.0,     -- rotY
        -90.0,   -- rotZ
        true, 
        true, 
        false, 
        true, 
        1, 
        true
    )
    
    TaskPlayAnim(ped, 'injecting@writzstudio', 'injecting', 8.0, 8.0, -1, 51, 0, false, false, false)
    
    return prop
end

local function stopInjectionAnim(prop)
    local ped = cache.ped
    
    if DoesEntityExist(prop) then
        DeleteEntity(prop)
    end
    
    ClearPedTasks(ped)
end

RegisterNetEvent('ambulance:action:playCprTarget', function(coords)
    if source == '' then return end

    local heading = math.rad(coords.w)
    local offsetDistance = 0.8

    local targetX = coords.x + math.sin(-heading) * offsetDistance
    local targetY = coords.y + math.cos(-heading) * offsetDistance
    local targetZ = coords.z

    pcall(lib.requestAnimDict, lib1CharB, 1500)
    SetEntityCoords(cache.ped, targetX, targetY, targetZ, false, false, false, true)
    SetEntityHeading(cache.ped, coords.w - 270.0)

    TaskPlayAnim(cache.ped, lib1CharB, animStart, 8.0, 8.0, -1, 0, 0, false, false, false)
    Wait(15800 - 900)

    pcall(lib.requestAnimDict, lib2CharB, 1500)

    for _ = 1, 15 do
        Wait(900)
        TaskPlayAnim(cache.ped, lib2CharB, animPump, 8.0, 8.0, -1, 0, 0, false, false, false)
    end

    TaskPlayAnim(cache.ped, lib2CharB, animSuccess, 8.0, 8.0, -1, 0, 0, false, false, false)
    Wait(3000)

    ClearPedTasks(cache.ped)
end)

RegisterNetEvent('hospital:client:RevivePlayer', function()
    local pdata = QBPlayerData
    local jobName = pdata.job.name

    if not isMedicalJob(jobName) then
        return lib.notify({ description = 'Anda tidak memiliki akses untuk merevive!', type = 'error' })
    end

    local requiredItem = config.jobItems[jobName]

    if not requiredItem then
        return lib.notify({ description = 'Anda tidak memiliki akses untuk merevive!', type = 'error' })
    end

    if not itemModule.checkRequired(requiredItem) then
        return
    end

    local player = lib.getClosestPlayer(RHDCache.coords.xyz)

    if not player then
        return lib.notify({ description = 'Tidak ada pemain di dekat Anda', type = 'error' })
    end

    local playerId = GetPlayerServerId(player)
    local success = lib.callback.await('ambulance:action:startCpr', false, playerId)

    if not success then
        return lib.notify({ description = 'Target tidak dalam kondisi yang tepat untuk CPR', type = 'error' })
    end

    CreateThread(plyCpr)

    local completed = lib.progressBar({
        duration = 20000,
        label = 'Melakukan CPR...',
        useWhileDead = false,
        canCancel = false,
        disable = {
            move = true,
            car = true,
            combat = true,
        }
    })

    if completed then
        TriggerTokenEvent('ambulance:reviveplayer', playerId, requiredItem)
        lib.notify({ description = 'Berhasil merevive pemain!', type = 'success' })
    else
        ClearPedTasks(cache.ped)
        lib.notify({ description = 'CPR dibatalkan', type = 'error' })
    end
end)

RegisterNetEvent('hospital:client:TreatWounds', function()
    local pdata = QBPlayerData
    local jobName = pdata.job.name

    if not isMedicalJob(jobName) then
        return lib.notify({ description = 'Anda tidak memiliki akses untuk heal!', type = 'error' })
    end

    local requiredItem = config.jobItems[jobName]

    if not requiredItem then
        return lib.notify({ description = 'Anda tidak memiliki akses untuk merevive!', type = 'error' })
    end

    if not itemModule.checkRequired(requiredItem) then
        return
    end

    local player = lib.getClosestPlayer(RHDCache.coords.xyz)

    if not player then
        return lib.notify({ description = 'Tidak ada pemain di dekat Anda', type = 'error' })
    end

    local playerId = GetPlayerServerId(player)
    
    local prop = playInjectionAnim()

    local completed = lib.progressBar({
        duration = 15000,
        label = 'Menyembuhkan luka...',
        useWhileDead = false,
        canCancel = false,
        disable = {
            move = false,
            car = true,
            combat = true,
        }
    })

    stopInjectionAnim(prop)

    if completed then
        TriggerTokenEvent('ambulance:treatWounds', playerId, requiredItem)
    else
        lib.notify({ description = 'Penyembuhan dibatalkan', type = 'error' })
    end
end)

RegisterNetEvent('ambulance:action:heal', function()
    if source == '' then return end

    SetEntityMaxHealth(cache.ped, 200)
    SetEntityHealth(cache.ped, 200)
    ClearPedBloodDamage(cache.ped)
end)

RegisterNetEvent('ambulance:action:killPlayer', function()
    if source == '' then return end
    SetEntityHealth(cache.ped, 0)
end)