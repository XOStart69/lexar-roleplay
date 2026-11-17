local config = localmodule 'config'

local Wait = Wait
local DoesEntityExist = DoesEntityExist
local IsEntityPlayingAnim = IsEntityPlayingAnim
local TaskPlayAnim = TaskPlayAnim
local floor = math.floor
local ceil = math.ceil

local PRICE = config.price
local COOLDOWN = config.cooldown
local DEATH_COOLDOWN = config.deathCooldown
local CPR_DICT = 'mini@cpr@char_a@cpr_str'
local CPR_CLIP = 'cpr_pumpchest'
local FADE_TIMEOUT = 3000

local cooldownEnd = 0
local deathCooldownEnd = 0
local deathToken = 0
local busy = false

local cayoZone = lib.zones.poly({
    name = 'sm_npcmedic:cayo',
    points = config.cayoZone.points,
    thickness = config.cayoZone.thickness,
})

---@param title string
---@param description string
---@param kind string
local function notify(title, description, kind)
    lib.notify({ title = title, description = description, type = kind })
end

---@return number
local function deathCooldownRemaining()
    local remaining = deathCooldownEnd - GetGameTimer()
    return remaining > 0 and remaining or 0
end

local function clearDeathCooldown()
    if deathCooldownEnd == 0 then return end

    deathCooldownEnd = 0
    deathToken = deathToken + 1
    TriggerTokenEvent('sm_npcmedic:server:deathCooldown', false)
end

local function startDeathCooldown()
    deathCooldownEnd = GetGameTimer() + DEATH_COOLDOWN
    deathToken = deathToken + 1

    local token = deathToken

    SetTimeout(DEATH_COOLDOWN, function()
        if deathToken ~= token then return end

        clearDeathCooldown()
        notify('Cooldown Selesai', 'Anda sekarang bisa menggunakan /helpme.', 'success')
    end)
end

AddEventHandler('baseevents:onPlayerDied', function()
    TriggerTokenEvent('sm_npcmedic:server:deathCooldown', true)
    startDeathCooldown()
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    local metadata = QBPlayerData.metadata

    if metadata and metadata.deathCooldown then
        startDeathCooldown()
    end
end)

---@return boolean
local function onCooldown()
    if GetGameTimer() >= cooldownEnd then return false end

    notify('Cooldown', 'Tunggu sebentar! Anda harus menunggu cooldown (20 detik).', 'error')
    return true
end

---@return boolean
local function onDeathCooldown()
    local remaining = deathCooldownRemaining()
    if remaining <= 0 then return false end

    local total = ceil(remaining / 1000)
    notify('Doktor lokal', ('Tunggu %d menit %d detik lagi setelah mati.'):format(floor(total / 60), total % 60), 'error')
    return true
end

---@return boolean
local function isDead()
    local metadata = QBPlayerData.metadata

    if metadata and (metadata.isdead or metadata.inlaststand) then return true end

    notify('Error', 'Perintah ini hanya bisa digunakan saat Anda dalam keadaan mati.', 'error')
    return false
end

local function startCooldown()
    cooldownEnd = GetGameTimer() + COOLDOWN
end

---@param ped number
local function deleteDoctor(ped)
    if not DoesEntityExist(ped) then return end

    local attempt = 0

    while not NetworkHasControlOfEntity(ped) and attempt < 100 do
        NetworkRequestControlOfEntity(ped)
        Wait(100)
        attempt = attempt + 1
    end

    if NetworkHasControlOfEntity(ped) then
        DeletePed(ped)
    end
end

---@param ped number
---@return fun()
local function animateDoctor(ped)
    local animating = true

    CreateThread(function()
        if not lib.requestAnimDict(CPR_DICT, 5000) then return end

        while animating and DoesEntityExist(ped) do
            if not IsEntityPlayingAnim(ped, CPR_DICT, CPR_CLIP, 3) then
                TaskPlayAnim(ped, CPR_DICT, CPR_CLIP, 8.0, 8.0, -1, 1, 0, false, false, false)
            end

            Wait(100)
        end

        RemoveAnimDict(CPR_DICT)
    end)

    return function()
        animating = false
    end
end

---@param paid boolean
local function callDoctor(paid)
    local model = config.doctorModel
    if not lib.requestModel(model, 10000) then return end

    local coords = GetEntityCoords(cache.ped)
    local doctor = CreatePed(4, model, coords.x, coords.y, coords.z, 0.0, true, false)
    SetModelAsNoLongerNeeded(model)

    if not DoesEntityExist(doctor) then return end

    local stopAnimation = animateDoctor(doctor)

    local done = lib.progressBar({
        label = 'Healing...',
        duration = config.reviveTime,
        useWhileDead = true,
        allowRagdoll = true,
        allowFalling = true,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
        },
    })

    stopAnimation()
    ClearPedTasks(doctor)

    if not done then
        notify('Cancelled', 'Penyembuhan dibatalkan!', 'error')
        return deleteDoctor(doctor)
    end

    if not lib.callback.await('sm_npcmedic:server:complete', false) then
        return deleteDoctor(doctor)
    end

    TriggerTokenEvent('ambulance:reviveplayer', cache.serverId, nil)
    StopScreenEffect('DeathFailOut')

    if paid then
        notify('Success', ('Anda telah sembuh! Biaya layanan dokter: $%s'):format(PRICE), 'success')
    else
        notify('Success', 'Anda telah sembuh oleh petugas EMS.', 'success')
        clearDeathCooldown()
    end

    Wait(1000)
    deleteDoctor(doctor)
end

---@param isRoxwood boolean
local function teleportToHospital(isRoxwood)
    local isCayo = not isRoxwood and cayoZone:contains(GetEntityCoords(cache.ped))
    local place = isCayo and 'Tabib Cayo Perico' or 'rumah sakit'

    local done = lib.progressBar({
        label = isCayo and 'Membawa Anda ke Tabib Cayo Perico...' or 'Membawa Anda ke rumah sakit...',
        duration = 5000,
        useWhileDead = true,
        allowRagdoll = true,
        allowFalling = true,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
        },
    })

    if not done then
        return notify('Cancelled', ('Teleportasi ke %s dibatalkan.'):format(place), 'error')
    end

    local target = isRoxwood and config.roxwood.hospital or isCayo and config.cayoHospital or config.hospital

    DoScreenFadeOut(500)

    local fadeDeadline = GetGameTimer() + FADE_TIMEOUT

    while not IsScreenFadedOut() and GetGameTimer() < fadeDeadline do
        Wait(100)
    end

    NetworkResurrectLocalPlayer(target.x, target.y, target.z, target.w, false, false)
    SetEntityCoords(cache.ped, target.x, target.y, target.z, false, false, false, true)
    SetEntityHeading(cache.ped, target.w)
    DoScreenFadeIn(1000)

    notify('Info', ('Anda telah dibawa ke %s, mohon tunggu dokter...'):format(place), 'info')
end

---@param fn fun()
local function runExclusive(fn)
    if busy then return end

    busy = true

    local ok, err = pcall(fn)

    busy = false

    if not ok then
        lib.print.error(err)
    end
end

if config.helpMeEnabled then
    RegisterCommand('helpme', function()
        runExclusive(function()
            if onCooldown() or onDeathCooldown() or not isDead() then return end

            local count, payable, isRoxwood = lib.callback.await('sm_npcmedic:server:status', false)

            if count == 0 then
                if not payable then
                    return notify('Error', 'Uang Anda tidak cukup untuk menggunakan layanan dokter ini.', 'error')
                end

                startCooldown()
                return callDoctor(true)
            end

            if count <= 3 then
                notify('Info', 'Kamu akan dibawa ke rumah sakit', 'info')
                Wait(2000)
                startCooldown()
                return teleportToHospital(isRoxwood)
            end

            notify('Error', 'Dokter terlalu banyak, silahkan tunggu respond dokter.', 'error')
        end)
    end, false)
end

---@param mode 'helpems'|'doklokems'
local function emsDoctor(mode)
    runExclusive(function()
        if mode == 'doklokems' and onCooldown() then return end

        local ok, reason = lib.callback.await('sm_npcmedic:server:emsDoctor', false, mode)

        if not ok then
            return notify('Error', reason or 'Anda tidak memiliki akses perintah ini.', 'error')
        end

        local paid = mode == 'doklokems'

        if paid then
            notify('Info', 'Memanggil bantuan medis...', 'info')
            startCooldown()
        end

        Wait(2000)
        callDoctor(paid)
    end)
end

RegisterCommand('helpems', function()
    emsDoctor('helpems')
end, false)

RegisterCommand('doklokems', function()
    emsDoctor('doklokems')
end, false)
