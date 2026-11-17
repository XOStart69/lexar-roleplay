local config = localmodule 'config'
local state = localmodule 'modules.state'
local util = localmodule 'modules.util'
local control = localmodule 'modules.control'
local groups = localmodule 'modules.groups'
local selection = localmodule 'modules.selection'

local pairs = pairs
local next = next
local joaat = joaat
local Wait = Wait
local CreateThread = CreateThread
local GetGameTimer = GetGameTimer
local PlayerPedId = PlayerPedId
local DoesEntityExist = DoesEntityExist
local GetEntityCoords = GetEntityCoords
local GetGamePool = GetGamePool
local GetActivePlayers = GetActivePlayers
local GetPlayerPed = GetPlayerPed
local IsEntityAPed = IsEntityAPed
local IsPedAPlayer = IsPedAPlayer
local IsPedHuman = IsPedHuman
local IsPedDeadOrDying = IsPedDeadOrDying
local IsPedInCombat = IsPedInCombat
local IsPedInAnyVehicle = IsPedInAnyVehicle
local IsPedArmed = IsPedArmed
local GetPedInVehicleSeat = GetPedInVehicleSeat
local GetVehicleModelNumberOfSeats = GetVehicleModelNumberOfSeats
local GetEntityModel = GetEntityModel
local GetVehicleType = GetVehicleType
local GetEntityHeightAboveGround = GetEntityHeightAboveGround
local NetworkHasControlOfEntity = NetworkHasControlOfEntity
local NetworkGetEntityIsNetworked = NetworkGetEntityIsNetworked
local ClearPedTasks = ClearPedTasks
local ClearPedTasksImmediately = ClearPedTasksImmediately
local TaskStandStill = TaskStandStill
local TaskGoStraightToCoord = TaskGoStraightToCoord
local TaskFollowNavMeshToCoord = TaskFollowNavMeshToCoord
local TaskVehicleDriveToCoordLongrange = TaskVehicleDriveToCoordLongrange
local TaskHeliMission = TaskHeliMission
local TaskCombatPed = TaskCombatPed
local TaskVehicleChase = TaskVehicleChase
local TaskVehicleShootAtPed = TaskVehicleShootAtPed
local TaskLeaveVehicle = TaskLeaveVehicle
local TaskEnterVehicle = TaskEnterVehicle
local TaskSmartFleeCoord = TaskSmartFleeCoord
local TaskWanderStandard = TaskWanderStandard
local TaskUseNearestScenarioToCoord = TaskUseNearestScenarioToCoord
local TaskUseNearestScenarioToCoordWarp = TaskUseNearestScenarioToCoordWarp
local TaskPlayAnim = TaskPlayAnim
local DoesScenarioExistInArea = DoesScenarioExistInArea
local SetPedKeepTask = SetPedKeepTask
local SetBlockingOfNonTemporaryEvents = SetBlockingOfNonTemporaryEvents
local SetPedFleeAttributes = SetPedFleeAttributes
local SetPedCombatAttributes = SetPedCombatAttributes
local SetPedCombatAbility = SetPedCombatAbility
local SetPedCombatRange = SetPedCombatRange
local SetPedCombatMovement = SetPedCombatMovement
local SetPedAlertness = SetPedAlertness
local SetPedAccuracy = SetPedAccuracy
local SetPedCanEvasiveDive = SetPedCanEvasiveDive
local SetPedHearingRange = SetPedHearingRange
local SetPedCanRagdollFromPlayerImpact = SetPedCanRagdollFromPlayerImpact
local SetCanAttackFriendly = SetCanAttackFriendly
local SetCurrentPedWeapon = SetCurrentPedWeapon
local SetPedCurrentWeaponVisible = SetPedCurrentWeaponVisible
local SetPedDropsWeaponsWhenDead = SetPedDropsWeaponsWhenDead
local GiveWeaponToPed = GiveWeaponToPed
local SetPedInfiniteAmmo = SetPedInfiniteAmmo
local RemoveAllPedWeapons = RemoveAllPedWeapons
local SetEntityHealth = SetEntityHealth
local ResurrectPed = ResurrectPed
local ClearPedBloodDamage = ClearPedBloodDamage
local SetEntityInvincible = SetEntityInvincible
local SetEntityProofs = SetEntityProofs
local SetPedCanRagdoll = SetPedCanRagdoll
local SetPedDiesWhenInjured = SetPedDiesWhenInjured
local SetPedSuffersCriticalHits = SetPedSuffersCriticalHits
local FreezeEntityPosition = FreezeEntityPosition
local SetEntityCoords = SetEntityCoords
local SetEntityHeading = SetEntityHeading
local SetPedCanPlayAmbientAnims = SetPedCanPlayAmbientAnims
local SetPedCanPlayAmbientBaseAnims = SetPedCanPlayAmbientBaseAnims
local SetPedRelationshipGroupHash = SetPedRelationshipGroupHash
local GetPedRelationshipGroupHash = GetPedRelationshipGroupHash
local SetRelationshipBetweenGroups = SetRelationshipBetweenGroups
local AddRelationshipGroup = AddRelationshipGroup
local SetVehicleEngineOn = SetVehicleEngineOn
local SetVehicleHandbrake = SetVehicleHandbrake
local SetDriveTaskCruiseSpeed = SetDriveTaskCruiseSpeed
local SetDriveTaskDrivingStyle = SetDriveTaskDrivingStyle
local SetVehicleDoorsLocked = SetVehicleDoorsLocked
local BreakOffVehicleWheel = BreakOffVehicleWheel
local SetVehicleEngineHealth = SetVehicleEngineHealth
local SetVehicleUndriveable = SetVehicleUndriveable
local IsVehicleSeatFree = IsVehicleSeatFree

local SPEEDS = config.speeds
local ATTACK_AREA_MS = config.attackAreaMs
local RANGE = config.attackRange
local PED = config.ped
local TICK_MS = 250
local STYLE_RUSH = 2883621
local STYLE_NORMAL = 786603
local UNARMED = `WEAPON_UNARMED`

local orders = {}

---@class GmPedSettings
---@field mode 'none'|'players'|'everyone'
---@field range integer
---@field accuracy integer

---@type table<integer, table>
local active = {}
---@type table<integer, GmPedSettings>
local settings = {}
---@type table<integer, integer>
local oldRelation = {}
---@type table<integer, integer>
local pairTarget = {}
---@type table<integer, true>
local god = {}
---@type table<integer, true>
local frozen = {}
---@type table<integer, integer>
local stabilize = {}
---@type { ped: integer, radius: number, untilAt: integer }?
local rangePreview = nil
local ticking = false
local lastNeutralize = 0

---@type GmPedSettings
local DEFAULT_SETTINGS = { mode = 'none', range = RANGE.default, accuracy = 50 }

local ATTACKER = 0
local TARGET = 0
local ALLY = 0

local function ensureGroups()
    if ATTACKER ~= 0 then return end

    local _, attacker = AddRelationshipGroup('SMGM_ATTACKER')
    local _, target = AddRelationshipGroup('SMGM_TARGET')
    local _, ally = AddRelationshipGroup(PED.allyGroup)

    ATTACKER = attacker
    TARGET = target
    ALLY = ally

    SetRelationshipBetweenGroups(5, ATTACKER, TARGET)
    SetRelationshipBetweenGroups(5, TARGET, ATTACKER)
    SetRelationshipBetweenGroups(0, ATTACKER, ATTACKER)
    SetRelationshipBetweenGroups(2, TARGET, TARGET)
    SetRelationshipBetweenGroups(0, ALLY, ALLY)
end

---@type table<string, integer>
local teams = {}
---@type table<integer, true>
local teamHashes = {}

---@param hash integer
local function bindTeam(hash)
    SetRelationshipBetweenGroups(0, hash, hash)
    SetRelationshipBetweenGroups(5, hash, TARGET)
    SetRelationshipBetweenGroups(5, TARGET, hash)
    SetRelationshipBetweenGroups(5, hash, ATTACKER)
    SetRelationshipBetweenGroups(5, ATTACKER, hash)

    for other in pairs(teamHashes) do
        if other ~= hash then
            SetRelationshipBetweenGroups(5, hash, other)
            SetRelationshipBetweenGroups(5, other, hash)
        end
    end
end

---@param ped integer
---@return integer?
local function teamOf(ped)
    local ids = groups.of(ped)
    local id = ids[1]

    if not id then return nil end

    local hash = teams[id]

    if not hash then
        local _, created = AddRelationshipGroup('SMGM_TEAM_' .. id)

        hash = created
        teams[id] = hash
        teamHashes[hash] = true
    end

    bindTeam(hash)

    return hash
end

local function neutralizeOthers()
    local now = GetGameTimer()

    if now - lastNeutralize < 1500 then return end

    lastNeutralize = now

    local seen = {}
    local pool = GetGamePool('CPed')

    for i = 1, #pool do
        local hash = GetPedRelationshipGroupHash(pool[i])

        if hash ~= 0 and hash ~= ATTACKER and hash ~= TARGET and not teamHashes[hash] and not seen[hash] then
            seen[hash] = true
            SetRelationshipBetweenGroups(3, ATTACKER, hash)
            SetRelationshipBetweenGroups(3, hash, ATTACKER)
            SetRelationshipBetweenGroups(3, TARGET, hash)
            SetRelationshipBetweenGroups(3, hash, TARGET)
        end
    end

    SetRelationshipBetweenGroups(5, ATTACKER, TARGET)
    SetRelationshipBetweenGroups(5, TARGET, ATTACKER)

    for hash in pairs(teamHashes) do
        bindTeam(hash)
    end
end

---@param ped integer
local function remember(ped)
    if not oldRelation[ped] then
        oldRelation[ped] = GetPedRelationshipGroupHash(ped)
    end
end

---@param ped integer
local function revert(ped)
    local old = oldRelation[ped]

    if not old then return end

    oldRelation[ped] = nil

    if DoesEntityExist(ped) and NetworkHasControlOfEntity(ped) then
        SetPedRelationshipGroupHash(ped, old)
    end
end

---@param attacker integer
---@param target integer
local function hostile(attacker, target)
    ensureGroups()
    neutralizeOthers()
    remember(attacker)
    SetPedRelationshipGroupHash(attacker, teamOf(attacker) or ATTACKER)
    SetCanAttackFriendly(attacker, false, false)

    if not IsPedAPlayer(target) and NetworkHasControlOfEntity(target) then
        remember(target)
        SetPedRelationshipGroupHash(target, teamOf(target) or TARGET)
    end

    pairTarget[attacker] = target
end

---@param ped integer
local function releasePair(ped)
    local target = pairTarget[ped]

    pairTarget[ped] = nil
    revert(ped)

    if target then
        revert(target)
    end
end

---@param ped integer
---@return GmPedSettings
function orders.settings(ped)
    local entry = settings[ped]

    if not entry then
        entry = { mode = 'none', range = RANGE.default, accuracy = 50 }
        settings[ped] = entry
    end

    return entry
end

---@param ped integer
---@return GmPedSettings
function orders.peek(ped)
    return settings[ped] or DEFAULT_SETTINGS
end

---@param ped integer
---@return boolean
local function armed(ped)
    return IsPedArmed(ped, 4) or IsPedArmed(ped, 2)
end

---@param kind 'ped'|'vehicle'
---@return number
local function speedOf(kind)
    local entry = SPEEDS[kind]

    return state.options.run and entry.run or entry.walk
end

---@param ped integer
---@param vehicle integer
---@return boolean
local function attacksFromSeat(ped, vehicle)
    if GetPedInVehicleSeat(vehicle, -1) ~= ped then return false end

    return GetVehicleModelNumberOfSeats(GetEntityModel(vehicle)) <= 1
end

---@param ped integer
---@param vehicle integer
---@param x number
---@param y number
---@param z number
---@param speed number
---@param style integer
local function drive(ped, vehicle, x, y, z, speed, style)
    SetVehicleEngineOn(vehicle, true, true, false)
    SetVehicleHandbrake(vehicle, false)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedKeepTask(ped, true)

    if GetVehicleType(vehicle) == 'heli' then
        TaskHeliMission(ped, vehicle, 0, 0, x, y, z, 4, speed * 2.0, -1.0, -1.0, -1, -1, -1.0, 288)
        return
    end

    TaskVehicleDriveToCoordLongrange(ped, vehicle, x, y, z, speed, style, 4.0)
    SetDriveTaskCruiseSpeed(ped, speed)
    SetDriveTaskDrivingStyle(ped, style)
end

---@param center vector3
---@param color { r: integer, g: integer, b: integer }
---@param heading number
local function marker(center, color, heading)
    local now = GetGameTimer()
    local ground = util.groundZ(center.x, center.y, center.z + 2.0)
    local list = state.markers

    list[#list + 1] = {
        x = center.x,
        y = center.y,
        z = (ground or center.z) + 0.05,
        r = color.r,
        g = color.g,
        b = color.b,
        heading = heading,
        startAt = now,
        expiresAt = now + 3000,
    }
end

local GREEN = { r = 38, g = 187, b = 183 }
local BLUE = { r = 0, g = 150, b = 200 }
local RED = { r = 220, g = 60, b = 60 }
local ORANGE = { r = 245, g = 140, b = 40 }

---@param ped integer
local function forget(ped)
    active[ped] = nil
    releasePair(ped)
end

local tick

local function startTicking()
    if ticking then return end

    ticking = true
    CreateThread(tick)
end

---@param ped integer
---@param order table
local function assign(ped, order)
    active[ped] = order
    startTicking()
end

---@param entities integer[]
---@return integer[]
local function withVehicles(entities)
    local list = {}
    local count = 0

    for i = 1, #entities do
        local ped = entities[i]

        count += 1
        list[count] = ped

        local vehicle = selection.vehicleOf(ped)

        if vehicle ~= 0 then
            count += 1
            list[count] = vehicle
        end
    end

    return list
end

---@param target vector3
---@param kind 'direct'|'path'|'stand'
function orders.goTo(target, kind)
    local actors = selection.actors()

    if #actors == 0 then return end

    control.ensure(withVehicles(actors))

    local positions = util.formation(target, #actors, 1.5)
    local pedSpeed = speedOf('ped')
    local vehicleSpeed = speedOf('vehicle')
    local style = kind == 'direct' and STYLE_RUSH or STYLE_NORMAL

    for i = 1, #actors do
        local ped = actors[i]
        local pos = positions[i] or target

        forget(ped)

        local vehicle = selection.vehicleOf(ped)

        if vehicle ~= 0 then
            if GetPedInVehicleSeat(vehicle, -1) == ped then
                drive(ped, vehicle, pos.x, pos.y, pos.z, vehicleSpeed, style)
            end
        else
            local heading = util.headingTo(ped, pos)

            ClearPedTasks(ped)

            if kind == 'direct' then
                TaskGoStraightToCoord(ped, pos.x, pos.y, pos.z, pedSpeed, -1, heading, 0.5)
            else
                TaskFollowNavMeshToCoord(ped, pos.x, pos.y, pos.z, pedSpeed, -1, 0.25, 0, heading)
            end

            if kind == 'stand' then
                assign(ped, { kind = 'stand', dest = pos })
            end
        end
    end

    local color = kind == 'direct' and GREEN or BLUE

    marker(target, color, util.headingTo(actors[1], target))
end

---@param ped integer
local function fightReady(ped)
    SetPedDropsWeaponsWhenDead(ped, false)
    SetCanAttackFriendly(ped, false, false)
    SetPedCombatAttributes(ped, 68, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedFleeAttributes(ped, 0, false)
    SetPedCombatAttributes(ped, 46, true)
    SetPedCombatAttributes(ped, 0, true)
    SetPedCombatAttributes(ped, 5, true)
    SetPedCombatAbility(ped, 2)
    SetPedCombatRange(ped, 2)
    SetPedAlertness(ped, 3)
    SetPedCombatMovement(ped, 2)

    if IsPedHuman(ped) and not IsPedArmed(ped, 7) then
        SetCurrentPedWeapon(ped, UNARMED, true)
    end
end

---@param ped integer
---@param target integer
local function engage(ped, target)
    local vehicle = selection.vehicleOf(ped)

    hostile(ped, target)

    if vehicle == 0 then
        fightReady(ped)
        TaskCombatPed(ped, target, 0, 16)
        SetPedKeepTask(ped, true)
        return 'foot'
    end

    local isDriver = GetPedInVehicleSeat(vehicle, -1) == ped

    if isDriver and not attacksFromSeat(ped, vehicle) then
        SetVehicleEngineOn(vehicle, true, true, false)
        SetVehicleHandbrake(vehicle, false)

        if armed(ped) then
            TaskVehicleChase(ped, target)
            SetPedKeepTask(ped, true)
            return 'chase'
        end

        local coords = GetEntityCoords(target)

        drive(ped, vehicle, coords.x, coords.y, coords.z, 24.0, STYLE_RUSH)
        return 'approach'
    end

    if armed(ped) then
        TaskVehicleShootAtPed(ped, target, 20.0)
    else
        TaskCombatPed(ped, target, 0, 16)
    end

    SetPedKeepTask(ped, true)

    return 'seat'
end

---@param target integer
function orders.attack(target)
    local actors = selection.actors()

    if #actors == 0 or not DoesEntityExist(target) then return end

    local list = withVehicles(actors)

    list[#list + 1] = target
    control.ensure(list)

    for i = 1, #actors do
        local ped = actors[i]

        if ped ~= target and not groups.share(ped, target) then
            forget(ped)

            if selection.vehicleOf(ped) == 0 then
                ClearPedTasksImmediately(ped)
            end

            local how = engage(ped, target)

            if how == 'approach' then
                assign(ped, { kind = 'driveExit', target = target })
            else
                assign(ped, { kind = 'attack', target = target, retaskAt = 0 })
            end
        end
    end

    marker(GetEntityCoords(target), RED, 0.0)
end

---@param ped integer
---@param center vector3
---@param radius number
---@param skip table<integer, true>
---@return boolean
local function attackNearest(ped, center, radius, skip)
    local pool = GetGamePool('CPed')
    local best = nil
    local bestDist = radius * radius
    local own = PlayerPedId()

    for i = 1, #pool do
        local candidate = pool[i]

        if candidate ~= ped and candidate ~= own and not skip[candidate] and NetworkGetEntityIsNetworked(candidate) and not IsPedDeadOrDying(candidate, true) then
            local coords = GetEntityCoords(candidate)
            local dx = coords.x - center.x
            local dy = coords.y - center.y
            local dz = coords.z - center.z
            local dist = dx * dx + dy * dy + dz * dz

            if dist <= bestDist and not groups.share(ped, candidate) then
                bestDist = dist
                best = candidate
            end
        end
    end

    if not best then return false end

    control.request(best)
    engage(ped, best)

    return true
end

---@param center vector3
function orders.attackArea(center)
    local actors = selection.actors()

    if #actors == 0 then return end

    control.ensure(withVehicles(actors))

    local skip = {}

    for i = 1, #actors do
        skip[actors[i]] = true
    end

    local untilAt = GetGameTimer() + ATTACK_AREA_MS

    for i = 1, #actors do
        local ped = actors[i]
        local range = orders.settings(ped).range
        local vehicle = selection.vehicleOf(ped)

        forget(ped)

        if vehicle ~= 0 then
            if GetPedInVehicleSeat(vehicle, -1) == ped then
                drive(ped, vehicle, center.x, center.y, center.z, 22.0, STYLE_RUSH)
                assign(ped, { kind = 'moveArea', center = center, skip = skip, exitOnArrive = not armed(ped), untilAt = untilAt })
            elseif armed(ped) then
                attackNearest(ped, center, range, skip)
                assign(ped, { kind = 'area', center = center, skip = skip, untilAt = untilAt })
            end
        else
            ClearPedTasksImmediately(ped)
            fightReady(ped)

            local coords = GetEntityCoords(ped)
            local dx = coords.x - center.x
            local dy = coords.y - center.y
            local reach = math.max(8.0, range * 0.8)

            if dx * dx + dy * dy > reach * reach then
                TaskFollowNavMeshToCoord(ped, center.x, center.y, center.z, 2.0, -1, range * 0.5, 0, util.headingTo(ped, center))
                assign(ped, { kind = 'moveArea', center = center, skip = skip, untilAt = untilAt })
            else
                attackNearest(ped, center, range, skip)
                assign(ped, { kind = 'area', center = center, skip = skip, untilAt = untilAt })
            end
        end
    end

    marker(center, ORANGE, 0.0)
end

---@param ped integer
local function standStill(ped)
    ClearPedTasks(ped)
    TaskStandStill(ped, -1)
end

---@param ped integer
---@param order table
---@param now integer
---@return boolean done
local function step(ped, order, now)
    local kind = order.kind

    if kind == 'stand' then
        local coords = GetEntityCoords(ped)
        local dest = order.dest
        local dx = coords.x - dest.x
        local dy = coords.y - dest.y

        if dx * dx + dy * dy > 1.5625 then return false end

        SetEntityHeading(ped, util.headingTo(ped, dest))
        standStill(ped)

        return true
    end

    if kind == 'attack' then
        local target = order.target

        if not DoesEntityExist(target) or IsPedDeadOrDying(target, true) then
            standStill(ped)
            releasePair(ped)
            return true
        end

        if not IsPedInCombat(ped, target) and now >= order.retaskAt then
            order.retaskAt = now + 2000
            engage(ped, target)
        end

        return false
    end

    if kind == 'driveExit' then
        local target = order.target

        if not DoesEntityExist(target) then return true end

        local vehicle = selection.vehicleOf(ped)

        if vehicle == 0 then
            fightReady(ped)
            engage(ped, target)
            active[ped] = { kind = 'attack', target = target, retaskAt = now + 2000 }
            return false
        end

        local a = GetEntityCoords(ped)
        local b = GetEntityCoords(target)
        local dx = a.x - b.x
        local dy = a.y - b.y

        if dx * dx + dy * dy <= 144.0 and not order.leaving then
            order.leaving = true
            TaskLeaveVehicle(ped, vehicle, 0)
        end

        return false
    end

    if kind == 'moveArea' then
        if now > order.untilAt then
            standStill(ped)
            return true
        end

        local coords = GetEntityCoords(ped)
        local center = order.center
        local range = orders.settings(ped).range
        local dx = coords.x - center.x
        local dy = coords.y - center.y

        if dx * dx + dy * dy > range * range then return false end

        local vehicle = selection.vehicleOf(ped)

        if vehicle ~= 0 and order.exitOnArrive then
            TaskLeaveVehicle(ped, vehicle, 0)
            active[ped] = { kind = 'exitArea', center = center, skip = order.skip, untilAt = order.untilAt }
            return false
        end

        attackNearest(ped, center, range, order.skip)
        active[ped] = { kind = 'area', center = center, skip = order.skip, untilAt = order.untilAt }

        return false
    end

    if kind == 'exitArea' then
        if now > order.untilAt then
            standStill(ped)
            return true
        end

        if selection.vehicleOf(ped) ~= 0 then return false end

        fightReady(ped)
        attackNearest(ped, order.center, orders.settings(ped).range, order.skip)
        active[ped] = { kind = 'area', center = order.center, skip = order.skip, untilAt = order.untilAt }

        return false
    end

    if kind == 'area' then
        if now > order.untilAt then
            standStill(ped)
            releasePair(ped)
            return true
        end

        if not IsPedInCombat(ped, 0) then
            attackNearest(ped, order.center, orders.settings(ped).range, order.skip)
        end

        return false
    end

    return true
end

---@param ped integer
---@param mode 'players'|'everyone'
---@param own integer
local function aggro(ped, mode, own)
    if IsPedInCombat(ped, 0) then return end

    local coords = GetEntityCoords(ped)
    local range = orders.settings(ped).range
    local best = nil
    local bestDist = range * range

    if mode == 'players' then
        local players = GetActivePlayers()

        for i = 1, #players do
            local target = GetPlayerPed(players[i])

            if target ~= own and target ~= 0 and not IsPedDeadOrDying(target, true) then
                local pos = GetEntityCoords(target)
                local dx = pos.x - coords.x
                local dy = pos.y - coords.y
                local dz = pos.z - coords.z
                local dist = dx * dx + dy * dy + dz * dz

                if dist <= bestDist then
                    bestDist = dist
                    best = target
                end
            end
        end
    else
        local pool = GetGamePool('CPed')

        for i = 1, #pool do
            local target = pool[i]

            if target ~= ped and target ~= own and not IsPedDeadOrDying(target, true) and not groups.share(ped, target) then
                local pos = GetEntityCoords(target)
                local dx = pos.x - coords.x
                local dy = pos.y - coords.y
                local dz = pos.z - coords.z
                local dist = dx * dx + dy * dy + dz * dz

                if dist <= bestDist then
                    bestDist = dist
                    best = target
                end
            end
        end
    end

    if not best then return end

    hostile(ped, best)
    TaskCombatPed(ped, best, 0, 16)
end

local behave

function tick()
    local lastAggro = 0
    local finished = {}

    while next(active) or next(stabilize) or next(settings) do
        local now = GetGameTimer()
        local own = PlayerPedId()
        local doneCount = 0

        for ped, order in pairs(active) do
            if not DoesEntityExist(ped) then
                doneCount += 1
                finished[doneCount] = ped
            else
                control.request(ped)

                if NetworkHasControlOfEntity(ped) and step(ped, order, now) then
                    doneCount += 1
                    finished[doneCount] = ped
                end
            end
        end

        for i = 1, doneCount do
            local ped = finished[i]

            if active[ped] then
                active[ped] = nil
            end

            finished[i] = nil
        end

        for ped, count in pairs(stabilize) do
            if not DoesEntityExist(ped) or count <= 0 then
                stabilize[ped] = nil
            elseif not active[ped] and NetworkHasControlOfEntity(ped) then
                behave(ped)
                stabilize[ped] = count - 1
            end
        end

        if now - lastAggro >= 500 then
            lastAggro = now

            for ped, entry in pairs(settings) do
                if not DoesEntityExist(ped) then
                    settings[ped] = nil
                    god[ped] = nil
                    frozen[ped] = nil
                    oldRelation[ped] = nil
                elseif entry.mode ~= 'none' and not active[ped] and not IsPedDeadOrDying(ped, true) then
                    control.request(ped)

                    if NetworkHasControlOfEntity(ped) then
                        aggro(ped, entry.mode, own)
                    end
                end
            end
        end

        Wait(TICK_MS)
    end

    ticking = false
end

---@param ped integer
function behave(ped)
    ensureGroups()
    SetPedRelationshipGroupHash(ped, ALLY)
    SetCanAttackFriendly(ped, false, false)
    SetPedCombatAttributes(ped, 17, false)
    SetPedCombatAttributes(ped, 58, true)
    SetPedCombatAttributes(ped, 5, false)
    SetPedCombatAbility(ped, 0)
    SetPedAlertness(ped, 0)
    SetPedCanEvasiveDive(ped, false)
    SetPedKeepTask(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedFleeAttributes(ped, 0, false)

    if PED.hearingRange > 0.0 then
        SetPedHearingRange(ped, PED.hearingRange)
    end

    SetPedCanRagdollFromPlayerImpact(ped, false)
    SetPedDropsWeaponsWhenDead(ped, false)
end

---@param ped integer
function orders.stabilize(ped)
    behave(ped)
    stabilize[ped] = PED.reapplyCount
    startTicking()
end

---@param ped integer
---@param mode 'none'|'players'|'everyone'
function orders.setMode(ped, mode)
    local entry = orders.settings(ped)

    entry.mode = mode

    if mode == 'none' then
        releasePair(ped)
    else
        SetPedCombatAttributes(ped, 5, true)
        SetPedCombatAttributes(ped, 46, true)
        SetPedCombatAbility(ped, 2)
        SetPedAlertness(ped, 3)
    end

    startTicking()
end

---@param ped integer
---@param range number
function orders.setRange(ped, range)
    orders.settings(ped).range = util.clamp(math.floor(range), RANGE.min, RANGE.max)
end

---@param ped integer
---@param accuracy number
function orders.setAccuracy(ped, accuracy)
    local value = util.clamp(math.floor(accuracy), 0, 100)

    orders.settings(ped).accuracy = value
    SetPedAccuracy(ped, value)
end

---@param ped integer
---@param radius number
function orders.previewRange(ped, radius)
    rangePreview = { ped = ped, radius = radius, untilAt = GetGameTimer() + 2000 }
end

---@return { ped: integer, radius: number, untilAt: integer }?
function orders.rangePreview()
    if rangePreview and GetGameTimer() > rangePreview.untilAt then
        rangePreview = nil
    end

    return rangePreview
end

---@param ped integer
---@return boolean
function orders.isGod(ped)
    return god[ped] == true
end

---@param ped integer
---@return boolean
function orders.isFrozen(ped)
    return frozen[ped] == true
end

---@param ped integer
function orders.stand(ped)
    forget(ped)
    standStill(ped)
end

---@param ped integer
---@param immediate boolean
function orders.clear(ped, immediate)
    forget(ped)

    if immediate then
        ClearPedTasksImmediately(ped)
    else
        ClearPedTasks(ped)
    end

    SetPedKeepTask(ped, false)
    TaskStandStill(ped, -1)
    SetBlockingOfNonTemporaryEvents(ped, false)
end

---@param ped integer
function orders.ambient(ped)
    forget(ped)
    stabilize[ped] = nil
    SetBlockingOfNonTemporaryEvents(ped, false)
    ClearPedTasks(ped)
    FreezeEntityPosition(ped, false)
    frozen[ped] = nil
    SetPedCanPlayAmbientAnims(ped, true)
    SetPedCanPlayAmbientBaseAnims(ped, true)

    local coords = GetEntityCoords(ped)

    if DoesScenarioExistInArea(coords.x, coords.y, coords.z, 15.0, true) then
        TaskUseNearestScenarioToCoord(ped, coords.x, coords.y, coords.z, 15.0, -1)
    else
        TaskWanderStandard(ped, 10.0, 10)
    end

    SetPedKeepTask(ped, true)
end

---@param ped integer
function orders.flee(ped)
    forget(ped)

    local coords = GetEntityCoords(ped)

    TaskSmartFleeCoord(ped, coords.x + 1.0, coords.y + 1.0, coords.z, 80.0, -1, false, false)
end

---@param ped integer
---@param weapon string
function orders.giveWeapon(ped, weapon)
    if not IsPedHuman(ped) then return end

    local hash = joaat(weapon)

    GiveWeaponToPed(ped, hash, 500, false, true)
    SetPedDropsWeaponsWhenDead(ped, false)
    SetCurrentPedWeapon(ped, hash, true)
    SetPedCurrentWeaponVisible(ped, true, false, false, false)
    SetPedInfiniteAmmo(ped, true, hash)
end

---@param ped integer
function orders.removeWeapons(ped)
    RemoveAllPedWeapons(ped, true)
end

---@param ped integer
function orders.revive(ped)
    local coords = GetEntityCoords(ped)
    local ground = util.groundZ(coords.x, coords.y, coords.z + 2.0)
    local z = ground and ground + 0.15 or coords.z
    local _, maxHealth = util.health(ped)

    ResurrectPed(ped)
    ClearPedTasksImmediately(ped)
    SetEntityCoords(ped, coords.x, coords.y, z, false, false, false, false)
    SetEntityHealth(ped, maxHealth)
    ClearPedBloodDamage(ped)
end

---@param ped integer
function orders.heal(ped)
    if IsPedDeadOrDying(ped, true) then
        orders.revive(ped)
        return
    end

    local _, maxHealth = util.health(ped)

    SetEntityHealth(ped, maxHealth)
    ClearPedBloodDamage(ped)
end

---@param ped integer
function orders.kill(ped)
    forget(ped)
    SetEntityHealth(ped, 0)
end

---@param ped integer
function orders.toggleGod(ped)
    local enabled = not god[ped]

    god[ped] = enabled or nil
    orders.settings(ped)

    SetEntityInvincible(ped, enabled)
    SetEntityProofs(ped, enabled, enabled, enabled, enabled, enabled, enabled, enabled, enabled)
    SetPedCanRagdoll(ped, not enabled)
    SetPedDiesWhenInjured(ped, not enabled)
    SetPedSuffersCriticalHits(ped, not enabled)
end

---@param ped integer
function orders.toggleFreeze(ped)
    local enabled = not frozen[ped]

    frozen[ped] = enabled or nil
    orders.settings(ped)
    FreezeEntityPosition(ped, enabled)

    if enabled then
        ClearPedTasksImmediately(ped)
    end
end

---@param ped integer
---@param anim { dict: string, name: string, flag?: integer }
function orders.playAnim(ped, anim)
    if not IsPedHuman(ped) then return end

    lib.requestAnimDict(anim.dict, 5000)
    forget(ped)
    ClearPedTasks(ped)
    SetBlockingOfNonTemporaryEvents(ped, true)
    TaskPlayAnim(ped, anim.dict, anim.name, 4.0, -4.0, -1, anim.flag or 1, 0.0, false, false, false)
    SetPedKeepTask(ped, true)
end

---@param ped integer
---@param coords vector3
---@param warp boolean
function orders.scenario(ped, coords, warp)
    forget(ped)
    ClearPedTasks(ped)
    SetBlockingOfNonTemporaryEvents(ped, false)

    if warp then
        TaskUseNearestScenarioToCoordWarp(ped, coords.x, coords.y, coords.z, 6.0, 0)
    else
        TaskUseNearestScenarioToCoord(ped, coords.x, coords.y, coords.z, 6.0, -1)
    end

    SetPedKeepTask(ped, true)
end

---@param ped integer
function orders.dismount(ped)
    local vehicle = selection.vehicleOf(ped)

    if vehicle == 0 then return end

    forget(ped)
    TaskLeaveVehicle(ped, vehicle, 0)

    CreateThread(function()
        local tries = 0

        while DoesEntityExist(ped) and IsPedInAnyVehicle(ped, false) do
            tries += 1

            if tries > 40 then break end

            Wait(50)
        end

        if DoesEntityExist(ped) and NetworkHasControlOfEntity(ped) then
            TaskStandStill(ped, -1)
            SetBlockingOfNonTemporaryEvents(ped, true)
            SetPedKeepTask(ped, true)
        end
    end)
end

---@param vehicle integer
---@return integer
local function maxSeat(vehicle)
    return GetVehicleModelNumberOfSeats(GetEntityModel(vehicle)) - 2
end

---@param vehicle integer
function orders.unmountAll(vehicle)
    local last = maxSeat(vehicle)
    local peds = {}
    local count = 0

    for seat = -1, last do
        local ped = GetPedInVehicleSeat(vehicle, seat)

        if ped ~= 0 and not IsPedAPlayer(ped) then
            count += 1
            peds[count] = ped
        end
    end

    if count == 0 then return end

    control.ensure(peds)

    for i = 1, count do
        orders.dismount(peds[i])
    end
end

---@param vehicle integer
function orders.disable(vehicle)
    orders.unmountAll(vehicle)

    if not control.one(vehicle) then return end

    for wheel = 0, 3 do
        BreakOffVehicleWheel(vehicle, wheel, false, false, true, false)
    end

    SetVehicleEngineHealth(vehicle, -4000.0)
    SetVehicleUndriveable(vehicle, true)
end

---@param vehicle integer
---@return boolean
function orders.isFlyingHeli(vehicle)
    return GetVehicleType(vehicle) == 'heli' and GetEntityHeightAboveGround(vehicle) > 3.0
end

---@param vehicle integer
---@param coords? vector3
function orders.land(vehicle, coords)
    local pilot = GetPedInVehicleSeat(vehicle, -1)

    if pilot == 0 or IsPedAPlayer(pilot) then return end

    control.ensure({ vehicle, pilot })

    local pos = coords or GetEntityCoords(vehicle)
    local ground = util.groundZ(pos.x, pos.y, pos.z + 30.0)
    local z = ground and ground + 1.0 or pos.z

    forget(pilot)
    SetVehicleEngineOn(vehicle, true, true, false)
    SetBlockingOfNonTemporaryEvents(pilot, true)
    SetPedKeepTask(pilot, true)
    TaskHeliMission(pilot, vehicle, 0, 0, pos.x, pos.y, z, 20, 24.0, -1.0, -1.0, -1, -1, -1.0, 288)
end

---@param vehicle integer
---@param seat integer
---@return boolean
function orders.seatFree(vehicle, seat)
    return IsVehicleSeatFree(vehicle, seat)
end

---@param vehicle integer
---@return integer
function orders.lastSeat(vehicle)
    return maxSeat(vehicle)
end

---@param ped integer
---@param vehicle integer
---@param seat integer
function orders.enter(ped, vehicle, seat)
    if not IsPedHuman(ped) or IsPedInAnyVehicle(ped, false) then return end

    local occupant = GetPedInVehicleSeat(vehicle, seat)
    local list = { ped, vehicle }

    if occupant ~= 0 and not IsPedAPlayer(occupant) then
        list[3] = occupant
    end

    control.ensure(list)
    forget(ped)
    SetVehicleDoorsLocked(vehicle, 1)

    if occupant ~= 0 and not IsPedAPlayer(occupant) then
        TaskLeaveVehicle(occupant, vehicle, 16)
    end

    TaskEnterVehicle(ped, vehicle, -1, seat, 1.0, 1, 0)
end

---@param vehicle integer
function orders.enterAll(vehicle)
    local peds = selection.peds()
    local seats = {}
    local seatCount = 0

    for seat = -1, maxSeat(vehicle) do
        if IsVehicleSeatFree(vehicle, seat) then
            seatCount += 1
            seats[seatCount] = seat
        end
    end

    local index = 0

    for i = 1, #peds do
        local ped = peds[i]

        if IsPedHuman(ped) and not IsPedInAnyVehicle(ped, false) then
            index += 1

            local seat = seats[index]

            if not seat then break end

            orders.enter(ped, vehicle, seat)
        end
    end
end

---@param ped integer
---@return boolean
function orders.hasOrder(ped)
    return active[ped] ~= nil
end

---@param entity integer
---@return boolean
function orders.isArmed(entity)
    return IsEntityAPed(entity) and armed(entity)
end

function orders.reset()
    for ped in pairs(active) do
        releasePair(ped)
    end

    active = {}
    stabilize = {}
    rangePreview = nil
end

return orders
