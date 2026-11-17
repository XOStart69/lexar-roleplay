local config = require 'config.init'
local reasons = require 'data.reason'
local weapons = require 'data.weapons'
local body = require 'data.bones'
local bridge = require 'bridge.init'

local watched = false

local deathText = {
    shot = 'Luka tembak',
    cut = 'Luka sayat',
    burn = 'Luka bakar',
    bruise = 'Luka benturan',
    gastric = 'Terkena asam lambung',
    unknown = 'Tidak diketahui',
}

---@alias DamageKind 'bruise'|'cut'|'burn'|'shot'|'gastric'

---@class RegionDamage
---@field bruise integer
---@field cut integer
---@field burn integer
---@field shot integer
---@field gastric integer

---@class BodyDamageReport
---@field regions table<BodyRegion, RegionDamage>
---@field totals RegionDamage
---@field cause string

---@type BodyDamageReport
local report = {
    regions = {},
    totals = { bruise = 0, cut = 0, burn = 0, shot = 0, gastric = 0 },
    cause = '',
}

local opened = false
---@type integer?
local viewing

---@type DamageKind?
local lastKind
---@type integer?
local lastHash
local lastStarve = false

local function publish()
    if not watched then return end
    TriggerServerEvent('rhd_bodydamage:push', report)
end

local function reset()
    report.regions = {}
    report.totals = { bruise = 0, cut = 0, burn = 0, shot = 0, gastric = 0 }
    report.cause = ''

    lastKind = nil
    lastHash = nil
    lastStarve = false
end

---@param region BodyRegion
---@param kind DamageKind
---@param amount integer
local function markRegion(region, kind, amount)
    local entry = report.regions[region]

    if not entry then
        entry = { bruise = 0, cut = 0, burn = 0, shot = 0, gastric = 0 }
        report.regions[region] = entry
    end

    entry[kind] += amount
    report.totals[kind] += amount
end

---@param kind? DamageKind
---@param hash? integer
---@param starved boolean
---@return string
local function resolveDeath(kind, hash, starved)
    if starved or (bridge.isStarving() and (not hash or hash == `WEAPON_FALL`)) then
        return deathText.gastric
    end

    local cause = reasons[hash] or reasons[GetPedCauseOfDeath(cache.ped)]

    if cause then
        if cause.all_regions then
            local regions = body.regions

            for i = 1, #regions do
                markRegion(regions[i], cause.all_regions, 1)
            end
        end

        return cause.reason
    end

    return kind and deathText[kind] or deathText.unknown
end

---@param action string
---@param data any
local function sendNui(action, data)
    SendNUIMessage({ action = action, data = data })
end

---@param data BodyDamageReport
local function show(data)
    sendNui('setDiagnosis', {
        id = viewing,
        regions = data.regions,
        totals = data.totals,
        cause = data.cause,
        showTotals = config.show_totals,
        showCause = config.show_cause,
    })
end

local function closeNui()
    if not opened then return end

    opened = false
    viewing = nil

    TriggerServerEvent('rhd_bodydamage:close')

    SetNuiFocus(false, false)
    sendNui('setVisible', false)
end

local function openSelf()
    opened = true
    viewing = cache.serverId --[[@as integer]]

    show(report)
    SetNuiFocus(true, true)
    sendNui('setVisible', true)
end

---@param playerId integer
---@param data BodyDamageReport?
local function open(playerId, data)
    if playerId == cache.serverId --[[@as integer]] then return openSelf() end
    if not data then return end

    opened = true
    viewing = playerId

    show(data)
    SetNuiFocus(true, true)
    sendNui('setVisible', true)
end

RegisterNUICallback('exit', function(_, cb)
    closeNui()
    cb(1)
end)

RegisterNetEvent('rhd_bodydamage:open', function(playerId, data)
    if source == '' then return end

    if opened then return closeNui() end

    open(playerId, data)
end)

RegisterNetEvent('rhd_bodydamage:update', function(playerId, data)
    if source == '' then return end
    if not opened or viewing ~= playerId or not data then return end

    show(data)
end)

RegisterNetEvent('rhd_bodydamage:targetLost', function()
    if source == '' then return end

    closeNui()
end)

RegisterNetEvent('rhd_bodydamage:setWatched', function(state)
    watched = state == true
end)

lib.callback.register('rhd_bodydamage:collect', function()
    return report
end)

local damagedByEvent = false
local eventHealth = 0

---@param args table
---@return integer?
local function eventWeapon(args)
    if weapons[args[5]] then return args[5] end
    if weapons[args[7]] then return args[7] end
end

AddEventHandler('gameEventTriggered', function(name, args)
    if name ~= 'CEventNetworkEntityDamage' then return end

    local ped = cache.ped
    if args[1] ~= ped then return end

    damagedByEvent = true

    local hash = eventWeapon(args)
    local kind = hash and weapons[hash]
    if not kind then return end

    local health = GetEntityHealth(ped)
    local lost = eventHealth - health
    eventHealth = health

    lastKind = kind
    lastHash = hash
    lastStarve = false

    if hash == `WEAPON_FALL` and bridge.isDead() then return end

    local points = lost > 0 and math.ceil(lost / config.damage_per_wound) or 1
    local cause = reasons[hash]
    local hit, bone = GetPedLastDamageBone(ped)

    if hit then ClearPedLastDamageBone(ped) end

    local region = (hit and body.map[bone]) or (cause and cause.fallback)

    if not region then return end

    markRegion(region, kind, points)

    publish()

    if opened and viewing == cache.serverId --[[@as integer]] then
        show(report)
    end
end)

CreateThread(function ()
    exports.ox_target:addGlobalPlayer({
        {
            name = 'sm_diagnosis',
            label = 'Diagnosis',
            icon = 'fas fa-notes-medical',
            onSelect = function (data)
                local player = NetworkGetPlayerIndexFromPed(data.entity)
                local playerId = GetPlayerServerId(player)
                TriggerServerEvent('rhd_bodydamage:requestOpen', playerId)
            end,
            groups = config.allowed_jobs,
            distance = 3.0
        }
    })
end)

CreateThread(function()
    local prevHealth = GetEntityHealth(cache.ped)
    local wasDead = false

    while true do
        Wait(500)

        local ped = cache.ped

        SetPlayerHealthRechargeMultiplier(cache.playerId --[[@as number]], 0.0)

        if opened and IsPauseMenuActive() then
            closeNui()
        end

        local health = GetEntityHealth(ped)
        local dead = bridge.isDead()
        local changed = false

        eventHealth = health

        if health < prevHealth then
            if not damagedByEvent and bridge.isStarving() then
                markRegion('abdomen', 'gastric', 1)
                lastStarve = true
                changed = true
            end

            damagedByEvent = false
        end

        if dead then
            if report.cause == '' then
                report.cause = resolveDeath(lastKind, lastHash, lastStarve)
                changed = true
            end
        elseif wasDead or (health >= config.max_health and health > prevHealth) then
            reset()
            changed = true

            if opened and viewing == cache.serverId --[[@as integer]] then
                closeNui()
            end
        end

        wasDead = dead
        prevHealth = health

        if changed then
            publish()

            if opened and viewing == cache.serverId --[[@as integer]] then
                show(report)
            end
        end
    end
end)
