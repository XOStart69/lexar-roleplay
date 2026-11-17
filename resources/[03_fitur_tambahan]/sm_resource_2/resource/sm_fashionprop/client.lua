local config = localmodule 'config'

local GetGameTimer = GetGameTimer
local DoesEntityExist = DoesEntityExist
local DeleteEntity = DeleteEntity

local DEBOUNCE = config.debounce

---@type table<string, number>
local attached = {}
local lastUse = 0

---@param description string
---@param kind? string
local function notify(description, kind)
    lib.notify({ description = description, type = kind or 'inform' })
end

---@param item string
local function detach(item)
    local entity = attached[item]
    attached[item] = nil
    if entity and DoesEntityExist(entity) then
        DetachEntity(entity, true, true)
        DeleteEntity(entity)
    end
end

---@param item string
---@param prop table
local function attach(item, prop)
    local model = joaat(prop.model)
    if not IsModelInCdimage(model) or not pcall(lib.requestModel, model, 5000) then
        return notify(('Model %s belum di-stream.'):format(prop.model), 'error')
    end

    local ped = cache.ped
    local coords = GetEntityCoords(ped)
    local entity = CreateObject(model, coords.x, coords.y, coords.z, true, true, false)
    SetModelAsNoLongerNeeded(model)
    if not DoesEntityExist(entity) then
        return notify('Gagal memasang prop.', 'error')
    end

    local offset, rotation = prop.offset, prop.rotation
    AttachEntityToEntity(entity, ped, GetPedBoneIndex(ped, prop.bone), offset.x, offset.y, offset.z, rotation.x, rotation.y, rotation.z, true, true, false, true, 1, true)

    attached[item] = entity
    notify('Prop terpasang.', 'success')
end

for item, prop in pairs(config.props) do
    AddEventHandler(item .. ':SPAWN', function()
        local now = GetGameTimer()
        if now - lastUse < DEBOUNCE then return end
        lastUse = now

        if attached[item] then
            detach(item)
            return notify('Prop dilepas.')
        end

        attach(item, prop)
    end)
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end
    for item in pairs(attached) do
        detach(item)
    end
end)
