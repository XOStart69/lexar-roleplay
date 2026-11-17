local config = localmodule 'config.shared'
local settings = config.Settings or {}

---@class JobBlipRecord
---@field id number
---@field kind 'entity'|'coord'
---@field entity? number
---@field signature string

---@class JobBlipTarget
---@field kind 'entity'|'coord'
---@field entity? number
---@field coords? vector3
---@field isCoordBlip boolean
---@field vehicleType? string

---@class JobBlipRenderer
---@field activeBlips table<string, table<string, JobBlipRecord>>
---@field revisions table<string, number>
local JobBlipRenderer = {
    activeBlips = {},
    revisions = {}
}

local BLIP_SPRITES = {
    bike = 226,
    automobile = 225,
    boat = 427,
    heli = 43,
    plane = 307,
    default = 1
}

local BLIP_CATEGORY = 7
local BLIP_SCALE = 0.8
local UPDATE_DISTANCE = 150.0

---@param blipId number
---@param name string
---@param color number?
---@param isCoordBlip boolean
---@param vehicleType? string
local function configureBlip(blipId, name, color, isCoordBlip, vehicleType)
    if not blipId or not DoesBlipExist(blipId) then return end

    SetBlipCategory(blipId, BLIP_CATEGORY)
    SetBlipSprite(blipId, type(vehicleType) == 'number' and vehicleType or BLIP_SPRITES[vehicleType] or BLIP_SPRITES.default)
    SetBlipColour(blipId, color or 3)
    SetBlipDisplay(blipId, 6)
    SetBlipFlashes(blipId, false)

    local scale = BLIP_SCALE
    local sirenSettings = settings.siren or {}
    if sirenSettings.enabled and type(vehicleType) == 'number' and vehicleType == (sirenSettings.sprite or 42) then
        scale = sirenSettings.scale or 0.5
    end
    SetBlipScale(blipId, scale)

    if not isCoordBlip then
        SetBlipAsShortRange(blipId, true)
        SetBlipShowCone(blipId, true)
    end

    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(name)
    EndTextCommandSetBlipName(blipId)
end

---@param member JobBlipMember
---@param color number?
---@param target JobBlipTarget
---@return string
local function getBlipSignature(member, color, target)
    return ('%s|%s|%s|%s'):format(member.name, member.color or color or 3, target.kind, member.sprite or target.vehicleType or 'default')
end

---@param record JobBlipRecord?
local function removeRecord(record)
    if record and DoesBlipExist(record.id) then
        RemoveBlip(record.id)
    end
end

---@param ped number
---@return string?
local function getVehicleType(ped)
    local vehicle = GetVehiclePedIsIn(ped, false)
    return vehicle ~= 0 and GetVehicleType(vehicle) or nil
end

---@param playerPed number
---@return boolean
local function isPlayerNearby(playerPed)
    if playerPed == 0 or playerPed == cache.ped then return false end

    return #(GetEntityCoords(playerPed) - GetEntityCoords(cache.ped)) <= UPDATE_DISTANCE
end

---@param jobName string
function JobBlipRenderer:clearJob(jobName)
    local records = self.activeBlips[jobName]
    if not records then return end

    for _, record in pairs(records) do
        removeRecord(record)
    end

    self.activeBlips[jobName] = nil
end

function JobBlipRenderer:clearAll()
    for jobName in pairs(self.activeBlips) do
        self:clearJob(jobName)
    end
end

---@param member JobBlipMember
---@return JobBlipTarget?
local function resolveMemberTarget(member)
    local playerId = GetPlayerFromServerId(member.source)
    local playerPed = playerId ~= -1 and GetPlayerPed(playerId) or 0

    if member.source == cache.serverId then
        if settings.showSelfBlip == false then
            return
        end

        return {
            kind = 'entity',
            entity = cache.ped,
            isCoordBlip = false,
            vehicleType = member.sprite or getVehicleType(cache.ped)
        }
    end

    if DoesEntityExist(playerPed) and isPlayerNearby(playerPed) then
        return {
            kind = 'entity',
            entity = playerPed,
            isCoordBlip = false,
            vehicleType = member.sprite or getVehicleType(playerPed)
        }
    end

    if member.coords then
        return {
            kind = 'coord',
            coords = member.coords,
            isCoordBlip = true,
            vehicleType = member.sprite
        }
    end
end

---@param target JobBlipTarget
---@return number?
local function createBlip(target)
    if target.kind == 'entity' and target.entity then
        return AddBlipForEntity(target.entity)
    end

    if target.kind == 'coord' and target.coords then
        return AddBlipForCoord(target.coords.x, target.coords.y, target.coords.z)
    end
end

---@param jobName string
---@return table<string, JobBlipRecord>
function JobBlipRenderer:getJobRecords(jobName)
    local records = self.activeBlips[jobName]

    if not records then
        records = {}
        self.activeBlips[jobName] = records
    end

    return records
end

---@param record JobBlipRecord
---@param member JobBlipMember
---@param color number?
---@param target JobBlipTarget
local function updateRecord(record, member, color, target)
    if not DoesBlipExist(record.id) then return end

    if record.kind == 'coord' and target.coords then
        SetBlipCoords(record.id, target.coords.x, target.coords.y, target.coords.z)
    end

    local signature = getBlipSignature(member, color, target)

    if record.signature ~= signature then
        configureBlip(record.id, member.name, color, target.isCoordBlip, target.vehicleType)
        record.signature = signature
    end
end

---@param jobName string
---@param memberKey string
---@param member JobBlipMember
---@param color number?
function JobBlipRenderer:upsertMember(jobName, memberKey, member, color)
    local records = self:getJobRecords(jobName)
    local current = records[memberKey]
    local target = resolveMemberTarget(member)

    if not target then
        removeRecord(current)
        records[memberKey] = nil
        return
    end

    if current
        and DoesBlipExist(current.id)
        and current.kind == target.kind
        and (target.kind == 'coord' or current.entity == target.entity)
    then
        updateRecord(current, member, member.color or color, target)
        return
    end

    local blipId = createBlip(target)

    if not blipId then
        removeRecord(current)
        records[memberKey] = nil
        return
    end

    removeRecord(current)
    configureBlip(blipId, member.name, member.color or color, target.isCoordBlip, target.vehicleType)

    records[memberKey] = {
        id = blipId,
        kind = target.kind,
        entity = target.entity,
        signature = getBlipSignature(member, color, target)
    }
end

---@param jobName string
---@param memberKey string
function JobBlipRenderer:removeMember(jobName, memberKey)
    local records = self.activeBlips[jobName]
    if not records then return end

    removeRecord(records[memberKey])
    records[memberKey] = nil
end

---@param payload table
function JobBlipRenderer:applyPayload(payload)
    local jobName = payload and payload.jobName
    if not jobName then return end

    local revision = payload.revision or 0
    if revision < (self.revisions[jobName] or 0) then
        return
    end

    self.revisions[jobName] = revision

    if payload.action == 'clear' then
        self:clearJob(jobName)
        return
    end

    if payload.action == 'set' then
        local records = self:getJobRecords(jobName)
        local seen = {}

        for memberKey, member in pairs(payload.members or {}) do
            seen[memberKey] = true
            self:upsertMember(jobName, memberKey, member, payload.color)
        end

        for memberKey in pairs(records) do
            if not seen[memberKey] then
                self:removeMember(jobName, memberKey)
            end
        end

        return
    end

    if payload.action ~= 'delta' then
        return
    end

    local removes = payload.removes or {}
    for i = 1, #removes do
        local memberKey = removes[i]
        self:removeMember(jobName, memberKey)
    end

    for memberKey, member in pairs(payload.upserts or {}) do
        self:upsertMember(jobName, memberKey, member, payload.color)
    end
end

return JobBlipRenderer
