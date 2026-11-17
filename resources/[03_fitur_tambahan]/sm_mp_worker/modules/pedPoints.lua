local peds = {}

---@class AnimationPed
---@field dict string
---@field clip string
---@field flags integer

---@class InteractionSelectData
---@field coords vector3
---@field coordsId? string
---@field playerId? number
---@field entity? integer
---@field distance? number

---@class PedInteractOptions
---@field name? string
---@field label string
---@field icon? string
---@field key? string
---@field distance? number
---@field pointDistance? number
---@field groups? string|string[]|table<string, number|number[]>
---@field canInteract? fun(entity: integer, distance: number, coords: vector3, name: string, bone: string): boolean
---@field onSelect? fun(data: InteractionSelectData)

---@class PedPoints
---@field id? string
---@field model string|integer
---@field coords vector4
---@field renderDistance? number default 20
---@field scenario? string
---@field animation? AnimationPed
---@field args? any
---@field interactOptions? PedInteractOptions[]

---@param data PedPoints
local function setupPeds(data)
    local _type = type(data.model)

    if _type ~= 'string' and _type ~= 'number' then
        error(("invalid ped model type: %s"):format(_type), 2)
    end

    local pedModel = _type == 'string'
        and joaat(data.model) or data.model

    if not pcall(function (...)
        return lib.requestModel(pedModel, 15000)
    end) then return end

    local x, y, z, w = table.unpack(data.coords)
    local entity = CreatePed(0, pedModel, x, y, z + -1, w, false, false)

    FreezeEntityPosition(entity, true)
    SetEntityProofs(entity, true, true, true, true, true, true, true, true)
    SetBlockingOfNonTemporaryEvents(entity, true)
    SetEntityInvincible(entity, true)

    if data.scenario then
        TaskStartScenarioInPlace(entity, data.scenario, 0, true)
    elseif data.animation then
        local dict, clip, flags in data.animation
        lib.playAnim(entity, dict, clip, nil, nil, -1, flags or 0)
    end

    if data.interactOptions then
        exports.rhd_interact:addLocalEntity(entity, data.interactOptions)
    end

    peds[data.id] = {
        entity = entity,
        useInteract = data.interactOptions ~= nil,
    }

    return entity
end

---@param id string
local function removePeds(id)
    if not peds[id] then
        return warn(("ped points with id '%s' does not exist"):format(id))
    end

    local pedData = peds[id]
    if pedData.useInteract then
        exports.rhd_interact:removeLocalEntity(pedData.entity)
    end

    DeleteEntity(pedData.entity)
    peds[id] = nil
end

---@param data PedPoints
---@return CPoint
return function (data)
    assert(data.coords and type(data.coords) == 'vector4', "invalid ped coords")

    data.id = ('peds_%s'):format(data.coords)
    data.renderDistance = data.renderDistance or 20
    local pts = lib.points.new(data.coords.xyz, data.renderDistance, data.args)

    function pts:onEnter()
        if not (self.pedEntities and DoesEntityExist(self.pedEntities)) then
            self.pedEntities = setupPeds(data)
        end
    end

    function pts:onExit()
        if self.pedEntities and DoesEntityExist(self.pedEntities) then
            removePeds(data.id)
        end
    end

    function pts:cleanup()
        if self.pedEntities and DoesEntityExist(self.pedEntities) then
            removePeds(data.id)
        end
        self:remove()
    end

    return pts
end