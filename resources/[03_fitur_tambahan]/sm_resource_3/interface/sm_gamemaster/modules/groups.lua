local pairs = pairs
local next = next
local DoesEntityExist = DoesEntityExist

local groups = {}

---@class GmGroup
---@field id string
---@field name string
---@field members table<integer, true>
---@field order integer

---@type table<string, GmGroup>
local list = {}
---@type table<integer, table<string, true>>
local byEntity = {}
local seq = 0

---@param name string
---@return string
function groups.create(name)
    seq += 1

    local id = 'g' .. seq

    list[id] = { id = id, name = name, members = {}, order = seq }

    return id
end

---@param id string
function groups.delete(id)
    local group = list[id]

    if not group then return end

    for entity in pairs(group.members) do
        local owned = byEntity[entity]

        if owned then
            owned[id] = nil

            if not next(owned) then
                byEntity[entity] = nil
            end
        end
    end

    list[id] = nil
end

---@param id string
---@param entities integer[]
---@return integer
function groups.add(id, entities)
    local group = list[id]

    if not group then return 0 end

    local added = 0

    for i = 1, #entities do
        local entity = entities[i]

        if not group.members[entity] then
            group.members[entity] = true

            local owned = byEntity[entity]

            if not owned then
                owned = {}
                byEntity[entity] = owned
            end

            owned[id] = true
            added += 1
        end
    end

    return added
end

---@param id string
---@param entities integer[]
---@return integer
function groups.remove(id, entities)
    local group = list[id]

    if not group then return 0 end

    local removed = 0

    for i = 1, #entities do
        local entity = entities[i]

        if group.members[entity] then
            group.members[entity] = nil
            removed += 1

            local owned = byEntity[entity]

            if owned then
                owned[id] = nil

                if not next(owned) then
                    byEntity[entity] = nil
                end
            end
        end
    end

    return removed
end

---@param id string
---@return integer[]
function groups.members(id)
    local group = list[id]
    local result = {}

    if not group then return result end

    local count = 0

    for entity in pairs(group.members) do
        if DoesEntityExist(entity) then
            count += 1
            result[count] = entity
        end
    end

    return result
end

---@param a integer
---@param b integer
---@return boolean
function groups.share(a, b)
    local owned = byEntity[a]

    if not owned then return false end

    local other = byEntity[b]

    if not other then return false end

    for id in pairs(owned) do
        if other[id] then return true end
    end

    return false
end

---@param entity integer
---@return string[]
function groups.of(entity)
    local owned = byEntity[entity]
    local result = {}

    if not owned then return result end

    local count = 0

    for id in pairs(owned) do
        count += 1
        result[count] = id
    end

    return result
end

---@return boolean
function groups.prune()
    local changed = false

    for entity, owned in pairs(byEntity) do
        if not DoesEntityExist(entity) then
            for id in pairs(owned) do
                local group = list[id]

                if group then
                    group.members[entity] = nil
                end
            end

            byEntity[entity] = nil
            changed = true
        end
    end

    return changed
end

---@return { id: string, name: string, count: integer }[]
function groups.summary()
    local result = {}
    local count = 0

    for id, group in pairs(list) do
        local members = 0

        for _ in pairs(group.members) do
            members += 1
        end

        count += 1
        result[count] = { id = id, name = group.name, count = members, order = group.order }
    end

    table.sort(result, function(a, b)
        return a.order < b.order
    end)

    return result
end

return groups
