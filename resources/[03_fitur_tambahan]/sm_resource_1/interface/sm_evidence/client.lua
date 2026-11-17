local Config = localmodule 'config'
local Data = localmodule 'data/evidence'

local GetEntityCoords = GetEntityCoords
local GetSelectedPedWeapon = GetSelectedPedWeapon
local IsPedShooting = IsPedShooting
local IsPedArmed = IsPedArmed
local GetWeaponDamageType = GetWeaponDamageType
local IsPlayerFreeAiming = IsPlayerFreeAiming
local GetGroundZFor_3dCoord = GetGroundZFor_3dCoord
local GetWeapontypeGroup = GetWeapontypeGroup
local GetPedDrawableVariation = GetPedDrawableVariation
local ClearEntityLastDamageEntity = ClearEntityLastDamageEntity
local HasEntityBeenDamagedByWeapon = HasEntityBeenDamagedByWeapon
local HasPedBeenDamagedByWeapon = HasPedBeenDamagedByWeapon
local GetPedLastDamageBone = GetPedLastDamageBone
local PlayerPedId = PlayerPedId
local GetGameTimer = GetGameTimer
local SetDrawOrigin = SetDrawOrigin
local ClearDrawOrigin = ClearDrawOrigin
local BeginTextCommandDisplayText = BeginTextCommandDisplayText
local EndTextCommandDisplayText = EndTextCommandDisplayText
local AddTextComponentSubstringPlayerName = AddTextComponentSubstringPlayerName
local SetTextScale = SetTextScale
local SetTextFont = SetTextFont
local SetTextColour = SetTextColour
local SetTextCentre = SetTextCentre
local SetTextOutline = SetTextOutline
local Wait = Wait
local mathRandom = math.random
local mathAbs = math.abs

local Types = Data.types
local Groups = Data.groups
local Flashlight = Config.Flashlight
local DrawDistance = Config.Marker.drawDistance
local DrawDistanceSq = DrawDistance * DrawDistance
local InteractDistance = Config.Marker.interactDistance
local InteractDistanceSq = InteractDistance * InteractDistance
local CollectDuration = Config.CollectDuration
local CasingCooldown = Config.Cooldown.bullet_casing
local SyncCooldown = 3000
local DAMAGE_ANY = 2
local DAMAGE_BULLET = 3
local ShellSpread = 2.0

---@type table<number, { id: number, type: string, coords: vector3, ttl: number, deadline: number }>
local evidence = {}
local evidenceCount = 0

local isAuthorized = false
local isInspecting = false
local collecting = false

local marker = lib.marker.new({
    type = 'HorizontalCircleSkinny',
    coords = vec3(0, 0, 0),
    width = 0.35,
    height = 0.35,
    color = { r = 255, g = 255, b = 255, a = 160 },
})

local function draw3DText(coords, text)
    SetDrawOrigin(coords.x, coords.y, coords.z + 0.28)
    SetTextFont(4)
    SetTextScale(0.32, 0.32)
    SetTextColour(255, 255, 255, 215)
    SetTextCentre(true)
    SetTextOutline()
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

---@return boolean
local function hasGloves()
    return GetPedDrawableVariation(cache.ped, 3) > 15
end

---@return vector3 titik di permukaan tanah
local function groundCoords(coords)
    local found, z = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 0.5, true)

    if not found or mathAbs(z - coords.z) > 3.0 then
        z = coords.z - 0.9
    end

    return vec3(coords.x, coords.y, z + 0.02)
end

---@return boolean
local function checkJob()
    local job = QBPlayerData and QBPlayerData.job
    if not job then return false end

    local minGrade = Config.Jobs[job.name]
    if not minGrade then return false end

    return (job.grade and job.grade.level or 0) >= minGrade
end

local function clearEvidence()
    if evidenceCount == 0 then return end

    evidence = {}
    evidenceCount = 0
end

local function syncEvidence()
    if not isAuthorized then return end

    local list = lib.callback.await('sm_evidence:sync', false, GetEntityCoords(cache.ped))
    if not list then return end

    clearEvidence()

    local now = GetGameTimer()

    for i = 1, #list do
        local ev = list[i]
        ev.coords = vec3(ev.coords.x, ev.coords.y, ev.coords.z)
        ev.deadline = now + (ev.ttl or 0) * 1000
        evidence[ev.id] = ev
        evidenceCount = evidenceCount + 1
    end
end

RegisterNetEvent('sm_evidence:add', function(ev)
    if not isAuthorized or evidence[ev.id] then return end

    ev.coords = vec3(ev.coords.x, ev.coords.y, ev.coords.z)
    ev.deadline = GetGameTimer() + (ev.ttl or 0) * 1000
    evidence[ev.id] = ev
    evidenceCount = evidenceCount + 1
end)

local function pruneExpired()
    if evidenceCount == 0 then return end

    local now = GetGameTimer()

    for id, ev in pairs(evidence) do
        if ev.deadline and now >= ev.deadline then
            evidence[id] = nil
            evidenceCount = evidenceCount - 1
        end
    end
end

RegisterNetEvent('sm_evidence:remove', function(ids)
    if type(ids) ~= 'table' then return end

    for i = 1, #ids do
        local id = ids[i]

        if evidence[id] then
            evidence[id] = nil
            evidenceCount = evidenceCount - 1
        end
    end
end)

local function collectEvidence(ev)
    if collecting then return end
    collecting = true

    local success = lib.progressCircle({
        duration = CollectDuration,
        label = ('Mengambil %s...'):format(Types[ev.type] and Types[ev.type].label or 'barang bukti'),
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = {
            dict = 'amb@medic@standing@kneel@base',
            clip = 'base',
            flag = 1,
        },
    })

    if not success then
        collecting = false
        return
    end

    local ok = lib.callback.await('sm_evidence:collect', false, ev.id)

    if ok then
        if evidence[ev.id] then
            evidence[ev.id] = nil
            evidenceCount = evidenceCount - 1
        end

        lib.notify({
            title = 'Barang Bukti',
            description = 'Sampel berhasil diamankan. Analisa di lab forensik.',
            type = 'success',
        })
    else
        lib.notify({
            title = 'Barang Bukti',
            description = 'Gagal mengambil sampel.',
            type = 'error',
        })
    end

    collecting = false
end

CreateThread(function()
    local nextSync = 0
    local nextPrune = 0

    while true do
        local sleep = 1000

        if isAuthorized then
            local ped = cache.ped
            local holding = GetSelectedPedWeapon(ped) == Flashlight

            if holding then
                sleep = 200
                local aiming = IsPlayerFreeAiming(cache.playerId)

                if aiming ~= isInspecting then
                    isInspecting = aiming

                    if aiming then
                        local now = GetGameTimer()

                        if now >= nextSync then
                            nextSync = now + SyncCooldown
                            syncEvidence()
                        end
                    end
                end
            elseif isInspecting then
                isInspecting = false
            end

            if evidenceCount > 0 then
                local now = GetGameTimer()

                if now >= nextPrune then
                    nextPrune = now + 1000
                    pruneExpired()
                end
            end
        else
            sleep = 3000
        end

        Wait(sleep)
    end
end)

CreateThread(function()
    while true do
        local sleep = 500

        if isInspecting and evidenceCount > 0 then
            sleep = 0

            local coords = GetEntityCoords(cache.ped)
            local nearest, nearestDistSq

            for _, ev in pairs(evidence) do
                local ec = ev.coords
                local dx = ec.x - coords.x
                if dx > DrawDistance or dx < -DrawDistance then goto continue end

                local dy = ec.y - coords.y
                if dy > DrawDistance or dy < -DrawDistance then goto continue end

                local dz = ec.z - coords.z
                local distSq = dx * dx + dy * dy + dz * dz

                if distSq <= DrawDistanceSq then
                    local typeData = Types[ev.type]

                    if typeData then
                        local color = typeData.color
                        local mc = marker.color

                        marker.coords = ec
                        mc.r, mc.g, mc.b = color.r, color.g, color.b
                        marker:draw()

                        if not nearestDistSq or distSq < nearestDistSq then
                            nearest, nearestDistSq = ev, distSq
                        end
                    end
                end

                ::continue::
            end

            if nearest then
                local typeData = Types[nearest.type]

                if nearestDistSq <= InteractDistanceSq then
                    draw3DText(nearest.coords, ('%s  [E] Ambil Sampel'):format(typeData.label))

                    if IsControlJustReleased(0, 38) and not collecting then
                        collectEvidence(nearest)
                    end
                else
                    draw3DText(nearest.coords, typeData.label)
                end
            end
        end

        Wait(sleep)
    end
end)


CreateThread(function()
    while true do
        local sleep = 500
        local ped = PlayerPedId()

        if IsPedArmed(ped, 4) then
            sleep = 0

            if IsPedShooting(ped) then
                local weapon = GetSelectedPedWeapon(ped)
                local group = GetWeaponDamageType(weapon) == DAMAGE_BULLET
                    and (Groups[GetWeapontypeGroup(weapon)] or 'unknown')

                if group then
                    local pc = GetEntityCoords(ped)
                    local spread = ShellSpread

                    LocalPlayer.state:set('evidenceShot', {
                        coords = groundCoords(vec3(
                            pc.x + (mathRandom() - 0.5) * spread,
                            pc.y + (mathRandom() - 0.5) * spread,
                            pc.z
                        )),
                        group = group,
                        gloves = hasGloves(),
                        t = GetGameTimer(),
                    }, true)

                    sleep = CasingCooldown
                end
            end
        end

        Wait(sleep)
    end
end)

AddEventHandler('gameEventTriggered', function(name)
    if name ~= 'CEventNetworkEntityDamage' then return end

    local ped = PlayerPedId()

    if not HasEntityBeenDamagedByWeapon(ped, 0, DAMAGE_ANY) then return end
    if not GetPedLastDamageBone(ped) then return end
    if not HasPedBeenDamagedByWeapon(ped, 0, DAMAGE_ANY) then return end

    local unarmed = HasPedBeenDamagedByWeapon(ped, `WEAPON_UNARMED`, 0)

    ClearEntityLastDamageEntity(ped)

    if unarmed then return end

    LocalPlayer.state:set('evidenceBleed', {
        coords = groundCoords(GetEntityCoords(ped)),
        t = GetGameTimer(),
    }, true)
end)


interface.init(false)

local labOpen = false
local frameMounted = false
local activeStation = nil

local function closeLab()
    if not labOpen then return end

    labOpen = false
    activeStation = nil
    interface.focus(false, false)
    interface.send({ action = 'setVisible', data = false })
    interface.hide()

    frameMounted = false
end

local function pushSamples()
    local station = activeStation
    if not station then return end

    local samples = lib.callback.await('sm_evidence:getSamples', false, station.id) or {}

    interface.send({ action = 'setStation', data = { label = station.label, types = station.types } })
    interface.send({ action = 'setSamples', data = samples })
    interface.send({ action = 'setVisible', data = true })
    interface.focus(true, true)
end

local function openLab(station)
    if labOpen or not isAuthorized then return end

    labOpen = true
    activeStation = station

    if not frameMounted then
        frameMounted = true
        interface.show()
        return
    end

    pushSamples()
end

interface.callback('ready', function(_, cb)
    cb('ok')

    if labOpen then pushSamples() end
end)

interface.callback('close', function(_, cb)
    cb({})
    closeLab()
end)

interface.callback('exit', function(_, cb)
    cb({})
    closeLab()
end)

interface.callback('analyze', function(data, cb)
    if not data or not data.slot or not activeStation then return cb({ ok = false }) end

    local ok, report = pcall(lib.callback.await, 'sm_evidence:analyze', false, data.slot, activeStation.id)

    if not ok or not report then return cb({ ok = false }) end

    cb({ ok = true, report = report })
end)

interface.callback('refresh', function(_, cb)
    if not activeStation then return cb({ samples = {} }) end

    local ok, samples = pcall(lib.callback.await, 'sm_evidence:getSamples', false, activeStation.id)
    cb({ samples = ok and samples or {} })
end)

for i = 1, #Config.AnalyzePoints do
    local point = Config.AnalyzePoints[i]

    local station = {
        id = i,
        label = point.label or 'Analisa Barang Bukti',
        types = point.types,
    }

    ox_target:addSphereZone({
        coords = point.coords,
        radius = 1.0,
        options = {
            {
                label = station.label,
                icon = 'fa-solid fa-microscope',
                distance = 1.8,
                canInteract = function()
                    return isAuthorized and not labOpen
                end,
                onSelect = function()
                    openLab(station)
                end,
            }
        }
    })
end

local function refreshAuth()
    local was = isAuthorized
    isAuthorized = checkJob()

    if isAuthorized and not was then
        syncEvidence()
    elseif not isAuthorized and was then
        clearEvidence()
        isInspecting = false
        closeLab()
    end
end

RegisterNetEvent('QBCore:Client:OnJobUpdate', refreshAuth)
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    refreshAuth()
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= cache.resource then return end
    refreshAuth()
end)

