local State = require 'gardener.modules.client.state'
local Util = require 'gardener.modules.client.util'
local Sync = require 'gardener.modules.client.sync'
local utils = require 'modules.utils'

local Branch = {}

local registeredBranchNetIds = {}
local ladderInteractionIds = {}

local branchAttachOffset = {
    pos = vec3(-0.5654692597958, 0.29908800610878, 0.12108623566059),
    rot = vec3(12.709732104161, 68.238857147238, 33.267279312787),
}
local palmAttachOffset = {
    pos = vec3(0.94722195674638, 0.14971768963774, 0.087273866932391),
    rot = vec3(82.321591660431, -43.726443161802, -110.93202746398),
}
local ladderCarryOffset = {
    pos = vec3(-0.0019488132165861, 0.36719249267956, 0.13732293274839),
    rot = vec3(172.43208872756, 70.747994138044, -135.06240470822),
}

---@param branchId number
---@return boolean
function Branch.isBranchTaskFinished(branchId)
    for _, branch in ipairs(State.branchObject) do
        if branch.branchId == branchId and branch.inTree then
            return false
        end
    end
    return true
end

local function findBranchIndexByNetId(netId)
    for i, branch in ipairs(State.branchObject) do
        if branch.objectNetId == netId then
            return i
        end
    end
end

local function isBranchProp(prop)
    for _, name in ipairs(State.objectTable.branch) do
        if name == prop then
            return true
        end
    end
    return false
end

local function nearErectedLadder(coords)
    for index, ladderCoords in ipairs(State.ladderObject.ladderCoords) do
        local settings = State.ladderObject.ladderSettings[index]
        if settings and settings.CreateLadder and #(coords - ladderCoords) <= 3.0 then
            return true
        end
    end
    return false
end

local function unregisterBranchNetId(netId)
    if netId and registeredBranchNetIds[netId] then
        exports.rhd_interact:removeEntity(netId)
        registeredBranchNetIds[netId] = nil
    end
end

---@param index number
function Branch.takeBranch(index)
    local branch = State.branchObject[index]
    if not branch then return end
    if not Util.playAnim('takeBranch') then return end

    if not Sync.deleteObject(branch.objectNetId) then return end
    unregisterBranchNetId(branch.objectNetId)

    local object = utils.createProp(branch.prop, branch.coords, true)
    if not object then return end

    branch.object = object
    branch.objectNetId = NetworkGetNetworkIdFromEntity(object)
    branch.process = true

    local offset = isBranchProp(branch.prop) and branchAttachOffset or palmAttachOffset
    State.isPlacingObject = true
    AttachEntityToEntity(object, cache.ped, -1, offset.pos.x, offset.pos.y, offset.pos.z,
        offset.rot.x, offset.rot.y, offset.rot.z, true, true, false, true, 1, true)

    State.playerHandObject.branch = object
    Sync.updateMissionTable('branchObject', State.branchObject)
end

---@param index number
function Branch.dropBranch(index)
    local branch = State.branchObject[index]
    if not branch then return end

    if not Sync.deleteObject(branch.objectNetId) then return end
    unregisterBranchNetId(branch.objectNetId)

    local object = utils.createProp(branch.prop, branch.coords, true)
    if not object then return end

    SetEntityRotation(object, branch.rotation.x, branch.rotation.y, branch.rotation.z, 2, true)
    branch.object = object
    branch.objectNetId = NetworkGetNetworkIdFromEntity(object)
    Sync.updateMissionTable('branchObject', State.branchObject)

    FreezeEntityPosition(object, false)
    SetEntityCollision(object, true, true)
    ApplyForceToEntity(object, 0, 0.0, 0.0, -9.81, 0.0, 0.0, 0.0, 0, true, true, true, false, true)

    local startTime = GetGameTimer()
    while State.getStartJob() do
        Wait(0)

        local ladderCoords = State.ladderObject.ladderCoords[branch.branchId]
        if not ladderCoords then break end

        local currentCoords = GetEntityCoords(object)
        if GetGameTimer() - startTime >= 50000 or math.abs(currentCoords.z - ladderCoords.z) <= 1.2 then
            Wait(200)
            branch.inTree = false
            branch.process = false
            branch.coords = currentCoords
            Sync.updateMissionTable('branchObject', State.branchObject)
            Sync.blipsDelete(index, 'branch')
            SetEntityRotation(object, 0.0, 60.0, 0.0, 2, true)
            FreezeEntityPosition(object, true)
            break
        end
    end

    Branch.refreshInteractions()
end

local function buildBranchOptions(netId)
    return {
        {
            name = 'sm_gardener:branch:cut',
            label = 'Potong Dahan',
            icon = 'fas fa-tree',
            key = 'G',
            distance = 8.0,
            offset = vec(0.0, 0.0, 1.0),
            canInteract = function()
                if not State.isTaskActive('branch') then return false end
                local index = findBranchIndexByNetId(netId)
                local branch = index and State.branchObject[index]
                return branch and branch.inTree and not branch.process
                    and State.playerHandObject.trimmer ~= false
                    and not State.showBar and not State.isInteracting
            end,
            onSelect = function(data)
                local index = findBranchIndexByNetId(netId)
                if not index or not data.entity then return end

                interface.focus(true, true)
                State.nuiMessage('START_MINIGAME', {
                    syncObject = data.entity,
                    branchCoords = GetEntityCoords(data.entity),
                    closestIndex = index,
                })
            end,
        },
        {
            name = 'sm_gardener:branch:take',
            label = 'Ambil Dahan',
            icon = 'fas fa-tree',
            distance = 4.0,
            pointDistance = 7.0,
            offset = vec(0.0, 0.0, 1.0),
            canInteract = function(entity)
                if not State.hasTaskReached('branch') then return false end
                local index = findBranchIndexByNetId(netId)
                local branch = index and State.branchObject[index]
                if not branch or branch.inTree or branch.process or branch.inVehicle then return false end
                if State.isCarryingAnything() or State.showBar or State.isInteracting then return false end
                return not nearErectedLadder(GetEntityCoords(entity))
            end,
            onSelect = function(data)
                local index = findBranchIndexByNetId(netId)
                if not index or not data.entity then return end
                Branch.takeBranch(index)
            end,
        },
    }
end

function Branch.refreshInteractions()
    local validNetIds = {}
    for _, branch in ipairs(State.branchObject) do
        if branch.objectNetId and not branch.inVehicle and NetworkDoesNetworkIdExist(branch.objectNetId) then
            validNetIds[branch.objectNetId] = true
        end
    end

    for netId in pairs(registeredBranchNetIds) do
        if not validNetIds[netId] then
            exports.rhd_interact:removeEntity(netId)
            registeredBranchNetIds[netId] = nil
        end
    end

    for netId in pairs(validNetIds) do
        if not registeredBranchNetIds[netId] then
            exports.rhd_interact:addEntity(netId, buildBranchOptions(netId))
            registeredBranchNetIds[netId] = true
        end
    end
end

function Branch.clearInteractions()
    for netId in pairs(registeredBranchNetIds) do
        exports.rhd_interact:removeEntity(netId)
    end
    registeredBranchNetIds = {}
end

---@param coords vector3
---@param index number
function Branch.createLadder(coords, index)
    local settings = State.ladderObject.ladderSettings[index]
    if not settings then return end

    State.isPlacingLadder = false

    if DoesEntityExist(State.playerHandObject.ladder) then
        DeleteEntity(State.playerHandObject.ladder)
        State.playerHandObject.ladder = false
    end

    if not Util.playAnim('ladderUp') then return end

    local baseCoords = coords + vec3(settings.offset.x, settings.offset.y, settings.offset.z)
    local ladderProp
    for _, model in ipairs(State.cfg.models.placementLadder) do
        ladderProp = utils.createProp(model, baseCoords, true)
        if ladderProp then break end
    end
    if not ladderProp then
        lib.print.error('[gardener] gagal membuat prop tangga untuk semua model')
        return
    end

    SetEntityRotation(ladderProp, settings.pitchIncline, 0.0, settings.ladderHeading, 2, true)
    FreezeEntityPosition(ladderProp, true)

    local rad = math.rad(settings.ladderHeading)
    local limitCoords = baseCoords + vec3(
        settings.limitOffset.x * math.cos(rad) - settings.limitOffset.y * math.sin(rad),
        settings.limitOffset.x * math.sin(rad) + settings.limitOffset.y * math.cos(rad),
        settings.limitOffset.z
    )

    local limitProp = utils.createProp('prop_wallbrick_01', limitCoords, true)
    if limitProp then
        SetEntityHeading(limitProp, settings.ladderHeading)
        FreezeEntityPosition(limitProp, true)
        SetEntityAlpha(limitProp, 0, false)
        settings.limitPropNetId = NetworkGetNetworkIdFromEntity(limitProp)
    end

    settings.objectNetId = NetworkGetNetworkIdFromEntity(ladderProp)
    settings.CreateLadder = true
    Sync.updateMissionTable('ladderObject', State.ladderObject)

    SetTimeout(1000, State.endInteraction)
end

---@param index number
function Branch.removeLadder(index)
    local settings = State.ladderObject.ladderSettings[index]
    if not settings or not settings.CreateLadder then return end

    if not Util.playLadderDownAnim() then return end

    if settings.objectNetId then
        if not Sync.deleteObject(settings.objectNetId) then return end
        if settings.limitPropNetId and not Sync.deleteObject(settings.limitPropNetId) then return end
        settings.objectNetId = nil
        settings.limitPropNetId = nil
    end

    settings.CreateLadder = false
    Sync.updateMissionTable('ladderObject', State.ladderObject)

    local object
    for _ = 1, 3 do
        object = utils.createProp(State.cfg.models.vehicleLadder, GetEntityCoords(cache.ped), true)
        if object then break end
        Wait(100)
    end
    if not object then
        lib.print.error('[gardener] gagal membuat prop tangga bawaan')
        return
    end

    State.playerHandObject.ladder = object
    SetEntityCollision(object, false, false)
    State.isPlacingLadder = true
    AttachEntityToEntity(object, cache.ped, -1, ladderCarryOffset.pos.x, ladderCarryOffset.pos.y,
        ladderCarryOffset.pos.z, ladderCarryOffset.rot.x, ladderCarryOffset.rot.y, ladderCarryOffset.rot.z,
        true, true, false, true, 1, true)

    SetTimeout(1000, State.endInteraction)
end

local function missionVehicleNearby(coords)
    if not State.mission then return false end

    for _, list in ipairs({ State.mission.trucks, State.mission.mowers }) do
        for _, data in ipairs(list) do
            local vehicle = NetworkDoesNetworkIdExist(data.netId) and NetToVeh(data.netId) or 0
            if vehicle ~= 0 and DoesEntityExist(vehicle) and #(coords - GetEntityCoords(vehicle)) <= 5.0 then
                return true
            end
        end
    end
    return false
end

---@param enable boolean
function Branch.toggleLadderInteractions(enable)
    if not enable then
        for i = 1, #ladderInteractionIds do
            exports.rhd_interact:removeCoords(ladderInteractionIds[i])
        end
        ladderInteractionIds = {}
        return
    end

    if #ladderInteractionIds > 0 then return end

    for index, ladderCoords in ipairs(State.ladderObject.ladderCoords) do
        local coordsId = ('sm_gardener:ladder_%s'):format(index)
        exports.rhd_interact:addCoords({
            id = coordsId,
            coords = ladderCoords,
            options = {
                {
                    name = coordsId .. ':place',
                    label = 'Pasang Tangga',
                    icon = 'fas fa-arrows-up-to-line',
                    distance = 3.0,
                    pointDistance = 6.0,
                    canInteract = function()
                        if not State.isTaskActive('branch') then return false end
                        local settings = State.ladderObject.ladderSettings[index]
                        if not settings or settings.CreateLadder or settings.jobFinished then return false end
                        if Branch.isBranchTaskFinished(index) then return false end
                        if State.playerHandObject.ladder == false or State.isInteracting then return false end
                        if missionVehicleNearby(ladderCoords) then
                            State.notify('Jauhkan kendaraan dari sini untuk memasang tangga', 'error')
                            return false
                        end
                        return true
                    end,
                    onSelect = function()
                        State.startInteraction()
                        Branch.createLadder(ladderCoords, index)
                    end,
                },
                {
                    name = coordsId .. ':remove',
                    label = 'Ambil Tangga',
                    icon = 'fas fa-arrows-down-to-line',
                    distance = 3.0,
                    pointDistance = 6.0,
                    canInteract = function()
                        local settings = State.ladderObject.ladderSettings[index]
                        if not settings or not settings.CreateLadder then return false end
                        if State.isCarryingAnything() or State.isInteracting then return false end

                        if not settings.jobFinished and Branch.isBranchTaskFinished(index) then
                            settings.jobFinished = true
                            Sync.updateMissionTable('ladderObject', State.ladderObject)
                        end
                        return not missionVehicleNearby(ladderCoords)
                    end,
                    onSelect = function()
                        State.startInteraction()
                        Branch.removeLadder(index)
                    end,
                },
            },
        })
        ladderInteractionIds[#ladderInteractionIds + 1] = coordsId
    end
end

---@param maxBranchCount number
function Branch.spawnBranchObjects(maxBranchCount)
    local region = State.getRegion()
    if not region or not region.potongDahan or maxBranchCount <= 0 then return end

    CreateThread(function()
        local branches = region.potongDahan

        if #State.ladderObject.ladderCoords == 0 then
            for _, branch in ipairs(branches) do
                if branch.ladderCoords then
                    State.ladderObject.ladderCoords[#State.ladderObject.ladderCoords + 1] = branch.ladderCoords
                    State.ladderObject.ladderSettings[#State.ladderObject.ladderSettings + 1] = {
                        offset = branch.ladderSettings.offset,
                        limitOffset = branch.ladderSettings.limitOffset,
                        pitchIncline = branch.ladderSettings.pitchIncline,
                        ladderHeading = branch.ladderSettings.ladderHeading,
                        CreateLadder = false,
                    }
                end
            end
            Sync.updateMissionTable('ladderObject', State.ladderObject)
        end

        while State.getStartJob() do
            local playerCoords = GetEntityCoords(cache.ped)
            local isNear = false
            for _, ladderCoords in ipairs(State.ladderObject.ladderCoords) do
                if #(playerCoords - ladderCoords) <= 100.0 then
                    isNear = true
                    break
                end
            end
            if isNear then break end
            Wait(1000)
        end
        if not State.getStartJob() then return end

        local spawnedCount = 0
        local blipsData = {}

        local orderedPoints = {}
        local maxPerTree = 0
        for _, branch in ipairs(branches) do
            local count = branch.branchCoords and #branch.branchCoords or 0
            if count > maxPerTree then maxPerTree = count end
        end
        for pointIndex = 1, maxPerTree do
            for branchId, branch in ipairs(branches) do
                local branchPoint = branch.branchCoords and branch.branchCoords[pointIndex]
                if branchPoint then
                    orderedPoints[#orderedPoints + 1] = { branchId = branchId, point = branchPoint }
                end
            end
        end

        for _, entry in ipairs(orderedPoints) do
            if spawnedCount >= maxBranchCount then break end

            local branchPoint = entry.point
            local object = utils.createProp(branchPoint.prop, branchPoint.position, true)
            if object then
                FreezeEntityPosition(object, true)
                SetEntityRotation(object, branchPoint.rotation.x, branchPoint.rotation.y,
                    branchPoint.rotation.z, 2, true)

                State.branchObject[#State.branchObject + 1] = {
                    object = object,
                    prop = branchPoint.prop,
                    objectNetId = NetworkGetNetworkIdFromEntity(object),
                    coords = branchPoint.position,
                    rotation = branchPoint.rotation,
                    inTree = true,
                    process = false,
                    inVehicle = false,
                    branchId = entry.branchId,
                }

                spawnedCount += 1
                blipsData[#blipsData + 1] = {
                    task = branchPoint.position,
                    blipsName = 'branch',
                    id = #State.branchObject,
                }
                Sync.updateMissionTable('branchObject', State.branchObject)
                Wait(500)
            end
        end

        if State.getStartJob() then
            Sync.blipsBatch(blipsData)
        end
        Branch.refreshInteractions()
    end)
end

---@param data { success: boolean, branchCoords?: table, closestIndex?: number }
function Branch.onMinigameResult(data)
    if not data.success or not data.closestIndex then return end

    local branch = State.branchObject[data.closestIndex]
    if not branch or not branch.inTree then
        State.notify('Dahan sudah tidak berada di pohon', 'error')
        return
    end

    local ptfxDone = false
    CreateThread(function()
        lib.requestNamedPtfxAsset('core', 10000)
        while not ptfxDone do
            UseParticleFxAssetNextCall('core')
            StartParticleFxNonLoopedAtCoord('ent_dst_wood_splinter', data.branchCoords.x, data.branchCoords.y,
                data.branchCoords.z + 1.0, 0.0, 0.0, 0.0, 1.0, false, false, false)
            Wait(500)
        end
    end)

    State.nuiMessage('playSound', { sound = 'trimAnimation.ogg' })
    Util.progressBar('Memangkas dahan...', 4300)
    ptfxDone = true

    branch.process = true
    Sync.updateMissionTable('branchObject', State.branchObject)
    Branch.dropBranch(data.closestIndex)
end

function Branch.teardown()
    Branch.clearInteractions()
    Branch.toggleLadderInteractions(false)
end

return Branch
