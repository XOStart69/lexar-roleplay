---@class JobBlipMember
---@field source number
---@field name string
---@field coords? vector3
---@field sprite? number
---@field color? number
---@field mock? boolean
---@field velocity? vector3

---@class JobBlipInstance
---@field jobName string
---@field config table
---@field members table<string, JobBlipMember>
---@field viewers table<number, true>
---@field dirtyUpserts table<string, JobBlipMember>
---@field dirtyRemoves string[]
---@field revision number
---@field nextUpdate number
local JobBlipInstance = lib.class('JobBlipInstance')

---@param jobName string
---@param config table
function JobBlipInstance:constructor(jobName, config)
    self.jobName = jobName
    self.config = config
    self.members = {}
    self.viewers = {}
    self.dirtyUpserts = {}
    self.dirtyRemoves = {}
    self.revision = 0
    self.nextUpdate = 0
end

---@param viewerJob string?
---@return boolean
function JobBlipInstance:canBeSeenBy(viewerJob)
    if not viewerJob then return false end
    return viewerJob == self.jobName or (self.config.shared and self.config.shared[viewerJob] == true)
end

---@param source number
function JobBlipInstance:addViewer(source)
    self.viewers[source] = true
end

---@param source number
function JobBlipInstance:removeViewer(source)
    self.viewers[source] = nil
end

---@param source number
---@return boolean
function JobBlipInstance:hasViewer(source)
    return self.viewers[source] == true
end

---@param source number
---@param identifier string
---@param name string
---@param sprite? number
---@param color? number
---@return boolean
function JobBlipInstance:addMember(source, identifier, name, sprite, color)
    if not identifier then return false end

    local member = self.members[identifier]

    if member
        and member.source == source
        and member.name == name
        and member.sprite == sprite
        and member.color == color
    then
        return false
    end

    self.members[identifier] = {
        source = source,
        name = name,
        coords = member and member.coords or nil,
        sprite = sprite,
        color = color
    }

    self:markDirty(identifier)
    return true
end

---@param identifier string
---@param name string
---@param coords vector3
---@param sprite? number
---@param velocity? vector3
---@return boolean
function JobBlipInstance:addMockMember(identifier, name, coords, sprite, velocity)
    local member = self.members[identifier]

    if member
        and member.name == name
        and member.coords
        and #(member.coords - coords) <= 0.01
        and member.sprite == sprite
    then
        return false
    end

    self.members[identifier] = {
        source = -1,
        name = name,
        coords = coords,
        sprite = sprite,
        mock = true,
        velocity = velocity
    }

    self:markDirty(identifier)
    return true
end

---@param identifier string?
---@param sprite? number
---@param color? number
---@return boolean
function JobBlipInstance:setMemberBlipOverride(identifier, sprite, color)
    if not identifier then return false end

    local member = self.members[identifier]
    if not member or (member.sprite == sprite and member.color == color) then return false end

    member.sprite = sprite
    member.color = color
    self:markDirty(identifier)

    return true
end

---@param identifier string?
---@return boolean
function JobBlipInstance:removeMember(identifier)
    if not identifier or not self.members[identifier] then return false end

    self.members[identifier] = nil
    self:markDirty(nil, identifier)

    return true
end

---@return boolean
function JobBlipInstance:updateMemberCoords()
    local hasUpdates = false

    for identifier, member in pairs(self.members) do
        if member.mock then
            if member.velocity and member.coords then
                member.coords = member.coords + member.velocity
                self.dirtyUpserts[identifier] = member
                hasUpdates = true
            end
        else
            local playerPed = GetPlayerPed(member.source)

            if playerPed and playerPed ~= 0 then
                local coords = GetEntityCoords(playerPed)

                if not member.coords or #(member.coords - coords) > 1.0 then
                    member.coords = coords
                    self.dirtyUpserts[identifier] = member
                    hasUpdates = true
                end
            end
        end
    end

    if hasUpdates then
        self:markDirty()
    end

    return hasUpdates
end

---@param upsertKey? string
---@param removeKey? string
function JobBlipInstance:markDirty(upsertKey, removeKey)
    self.revision = self.revision + 1

    if upsertKey then
        self.dirtyUpserts[upsertKey] = self.members[upsertKey]
    end

    if removeKey then
        self.dirtyUpserts[removeKey] = nil
        self.dirtyRemoves[#self.dirtyRemoves + 1] = removeKey
    end
end

function JobBlipInstance:clearDirty()
    self.dirtyUpserts = {}
    self.dirtyRemoves = {}
end

---@param defaultInterval number
---@return number
function JobBlipInstance:getUpdateInterval(defaultInterval)
    return self.config.updateInterval or defaultInterval
end

---@param now number
---@param defaultInterval number
---@return boolean
function JobBlipInstance:shouldUpdate(now, defaultInterval)
    return now >= self.nextUpdate
end

---@param now number
---@param defaultInterval number
function JobBlipInstance:scheduleNextUpdate(now, defaultInterval)
    self.nextUpdate = now + self:getUpdateInterval(defaultInterval)
end

---@param defaultLimit? number
---@return number?
function JobBlipInstance:getMaxVisibleMembers(defaultLimit)
    local limit = self.config.maxVisibleMembers

    if limit == nil then
        limit = defaultLimit
    end

    if not limit or limit <= 0 then
        return nil
    end

    return math.floor(limit)
end

---@param defaultLimit? number
---@return boolean
function JobBlipInstance:isOverVisibleLimit(defaultLimit)
    local limit = self:getMaxVisibleMembers(defaultLimit)
    if not limit then return false end

    local count = 0
    for _ in pairs(self.members) do
        count = count + 1

        if count > limit then
            return true
        end
    end

    return false
end

---@param defaultLimit? number
---@return table<string, JobBlipMember>
function JobBlipInstance:getLimitedMembers(defaultLimit)
    local limit = self:getMaxVisibleMembers(defaultLimit)
    if not limit then return self.members end

    local members = {}
    local count = 0

    for identifier, member in pairs(self.members) do
        count = count + 1
        if count > limit then break end

        members[identifier] = member
    end

    return members
end

---@return table
function JobBlipInstance:toPayload(defaultLimit)
    return {
        action = 'set',
        jobName = self.jobName,
        revision = self.revision,
        color = self.config.color,
        members = self:getLimitedMembers(defaultLimit)
    }
end

---@return table
function JobBlipInstance:toDeltaPayload(defaultLimit)
    if self:isOverVisibleLimit(defaultLimit) then
        return self:toPayload(defaultLimit)
    end

    return {
        action = 'delta',
        jobName = self.jobName,
        revision = self.revision,
        color = self.config.color,
        upserts = self.dirtyUpserts,
        removes = self.dirtyRemoves
    }
end

---@return table
function JobBlipInstance:toClearPayload()
    return {
        action = 'clear',
        jobName = self.jobName,
        revision = self.revision
    }
end

return JobBlipInstance
