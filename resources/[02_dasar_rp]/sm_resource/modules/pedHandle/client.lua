if lib.context == 'server' then return end

local pedExist = {}

---@class PedHandle: OxClass
---@field id string
---@field entity number
---@field data Modules_PedData
---@field blip? BlipHandle
---@field props table<number, number> Table of attached prop entities (key: index, value: entity handle)
---@field point? table lib.points instance used when renderDistance is set
local ped = lib.class('PedHandle')

local function generateId()
    local id
    repeat
        ---@diagnostic disable-next-line: undefined-field
        id = string.random('...-...-..')
    until not pedExist[id]

    return id
end

---@param self PedHandle
local function spawnPedEntity(self)
    local data = self.data

    local model = safecall.fun(function()
        return lib.requestModel(data.model, 15000)
    end)

    if not model then return end

    local pedType = data.networked and 4 or 0
    self.entity = CreatePed(
        pedType,
        model,
        data.coords.x,
        data.coords.y,
        data.coords.z - 1,
        data.coords.w or 0.0,
        data.networked or false,
        false
    )

    if not DoesEntityExist(self.entity) then
        lib.print.error(('Failed to create ped entity for id "%s"'):format(self.id))
        self.entity = nil
        return
    end

    if data.freeze ~= false then
        FreezeEntityPosition(self.entity, true)
    end

    if data.invincible ~= false then
        SetEntityInvincible(self.entity, true)
        SetEntityProofs(self.entity, true, true, true, true, true, true, true, true)
    end

    if data.blockEvents ~= false then
        SetBlockingOfNonTemporaryEvents(self.entity, true)
    end

    if data.fadeIn then
        CreateThread(function()
            SetEntityAlpha(self.entity, 0, false)
            for i = 1, 255 do
                if not DoesEntityExist(self.entity) then break end
                SetEntityAlpha(self.entity, i, false)
                Wait(15)
            end
            if DoesEntityExist(self.entity) then
                ResetEntityAlpha(self.entity)
            end
        end)
    end

    if data.scenario then
        TaskStartScenarioInPlace(self.entity, data.scenario, 0, true)
    end

    if data.anim then
        self:playAnimation(data.anim.dict, data.anim.name, data.anim.flag)
    end

    if data.target and ox_target then
        ox_target:addLocalEntity(self.entity, data.target)
    end

    if data.prop then
        local props = type(data.prop) == 'table' and data.prop[1] and data.prop or { data.prop }
        for i, propData in ipairs(props) do
            self:attachProp(propData, i)
        end
    end
end

---@param self PedHandle
local function despawnPedEntity(self)
    self:removeAllProps()

    if DoesEntityExist(self.entity) then
        if self.data.target and ox_target then
            ox_target:removeLocalEntity(self.entity)
        end

        SetEntityAsMissionEntity(self.entity, true, true)
        DeleteEntity(self.entity)
    end

    self.entity = nil
end

---@param data Modules_PedData
function ped:constructor(data)
    if not data.model or not data.coords then
        lib.print.error('Ped requires model and coords')
        return
    end

    self.id = data.id or generateId()

    if pedExist[self.id] then
        warn(('Ped with id "%s" already exists, removing old one'):format(self.id))
        pedExist[self.id]:remove()
    end

    self.data = data
    self.props = {}

    if data.renderDistance then
        local coords = vec3(data.coords.x, data.coords.y, data.coords.z)

        self.point = lib.points.new({
            coords = coords,
            distance = data.renderDistance,
        })

        local selfRef = self

        function self.point:onEnter()
            if not selfRef.entity then
                spawnPedEntity(selfRef)
            end
        end

        function self.point:onExit()
            if selfRef.entity then
                despawnPedEntity(selfRef)
            end
        end

        -- spawn sekarang jika player sudah dalam jangkauan
        if (self.point.currentDistance or 0) <= data.renderDistance then
            spawnPedEntity(self)
        end
    else
        spawnPedEntity(self)
    end

    pedExist[self.id] = self
end

---@param propData Modules_PedPropData
---@param index? number
---@return number|nil propEntity
function ped:attachProp(propData, index)
    if not DoesEntityExist(self.entity) then return end
    if not propData.model then
        lib.print.error('Prop requires model')
        return
    end

    local model = safecall.fun(function()
        return lib.requestModel(propData.model, 15000)
    end)

    if not model then return end

    local propEntity = CreateObject(model, 0.0, 0.0, 0.0, false, false, false)

    if not DoesEntityExist(propEntity) then
        lib.print.error('Failed to create prop entity')
        return
    end

    local bone = propData.bone or 60309
    local pos = propData.pos or { x = 0.0, y = 0.0, z = 0.0 }
    local rot = propData.rot or { x = 0.0, y = 0.0, z = 0.0 }
    local rotOrder = propData.rotOrder or 0

    AttachEntityToEntity(
        propEntity,
        self.entity,
        GetPedBoneIndex(self.entity, bone),
        pos.x, pos.y, pos.z,
        rot.x, rot.y, rot.z,
        true, true, false, true, rotOrder, true
    )

    local idx = index or (#self.props + 1)
    self.props[idx] = propEntity

    return propEntity
end

---@param index number
function ped:removeProp(index)
    local propEntity = self.props[index]
    if propEntity and DoesEntityExist(propEntity) then
        DetachEntity(propEntity, true, true)
        DeleteEntity(propEntity)
    end
    self.props[index] = nil
end

function ped:removeAllProps()
    for index, propEntity in pairs(self.props) do
        if DoesEntityExist(propEntity) then
            DetachEntity(propEntity, true, true)
            DeleteEntity(propEntity)
        end
    end
    self.props = {}
end

---@return table<number, number>
function ped:getProps()
    return self.props
end

---@param dict string
---@param name string
---@param flag? number
---@param duration? number
function ped:playAnimation(dict, name, flag, duration)
    if not DoesEntityExist(self.entity) then return end

    local animDict = safecall.fun(function ()
        return lib.requestAnimDict(dict, 1500)
    end)

    if not animDict then return end
    TaskPlayAnim(self.entity, animDict, name, 8.0, -8.0, duration or -1, flag or 1, 0, false, false, false)
end

---@param scenario string
function ped:playScenario(scenario)
    if not DoesEntityExist(self.entity) then return end

    ClearPedTasks(self.entity)
    TaskStartScenarioInPlace(self.entity, scenario, 0, true)
    self.data.scenario = scenario
end

function ped:clearTasks()
    if DoesEntityExist(self.entity) then
        ClearPedTasks(self.entity)
    end
end

---@param coords vector3|vector4
function ped:setCoords(coords)
    self.data.coords = coords

    if self.point then
        self.point.coords = vec3(coords.x, coords.y, coords.z)
    end

    if DoesEntityExist(self.entity) then
        SetEntityCoords(self.entity, coords.x, coords.y, coords.z, false, false, false, false)
        if coords.w then
            SetEntityHeading(self.entity, coords.w)
        end
    end
end

---@param heading number
function ped:setHeading(heading)
    if DoesEntityExist(self.entity) then
        SetEntityHeading(self.entity, heading)
        if self.data.coords then
            self.data.coords = vec4(self.data.coords.x, self.data.coords.y, self.data.coords.z, heading)
        end
    end
end

---@param state boolean
function ped:setFrozen(state)
    if DoesEntityExist(self.entity) then
        FreezeEntityPosition(self.entity, state)
        self.data.freeze = state
    end
end

---@param state boolean
function ped:setInvincible(state)
    if DoesEntityExist(self.entity) then
        SetEntityInvincible(self.entity, state)
        SetEntityProofs(self.entity, state, state, state, state, state, state, state, state)
        self.data.invincible = state
    end
end

---@param alpha number
function ped:setAlpha(alpha)
    if DoesEntityExist(self.entity) then
        SetEntityAlpha(self.entity, alpha, false)
    end
end

---@param duration? number
function ped:fadeIn(duration)
    if not DoesEntityExist(self.entity) then return end

    duration = duration or 3825
    local steps = 255
    local delay = math.floor(duration / steps)

    CreateThread(function()
        SetEntityAlpha(self.entity, 0, false)
        for i = 1, steps do
            if not DoesEntityExist(self.entity) then break end
            SetEntityAlpha(self.entity, i, false)
            Wait(delay)
        end
        if DoesEntityExist(self.entity) then
            ResetEntityAlpha(self.entity)
        end
    end)
end

---@param duration? number
---@param removeAfter? boolean
function ped:fadeOut(duration, removeAfter)
    if not DoesEntityExist(self.entity) then return end

    duration = duration or 3825
    local steps = 255
    local delay = math.floor(duration / steps)

    CreateThread(function()
        for i = 255, 0, -1 do
            if not DoesEntityExist(self.entity) then break end
            SetEntityAlpha(self.entity, i, false)
            Wait(delay)
        end
        if removeAfter and DoesEntityExist(self.entity) then
            self:remove()
        end
    end)
end

---@return number
function ped:getEntity()
    return self.entity
end

---@return vector3
function ped:getCoords()
    if DoesEntityExist(self.entity) then
        return GetEntityCoords(self.entity)
    end
    return vec3(self.data.coords.x, self.data.coords.y, self.data.coords.z)
end

---@return number
function ped:getHeading()
    if DoesEntityExist(self.entity) then
        return GetEntityHeading(self.entity)
    end
    return self.data.coords.w or 0.0
end

---@return boolean
function ped:exists()
    return DoesEntityExist(self.entity)
end

function ped:remove()
    if self.point then
        self.point:remove()
        self.point = nil
    end

    self:removeAllProps()

    if DoesEntityExist(self.entity) then
        if self.data.target and ox_target then
            ox_target:removeLocalEntity(self.entity)
        end

        SetEntityAsMissionEntity(self.entity, true, true)
        DeleteEntity(self.entity)
    end

    if self.blip then
        self.blip:remove()
        self.blip = nil
    end

    pedExist[self.id] = nil
    self.entity = nil
end

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        for id, pedHandle in pairs(pedExist) do
            pedHandle:remove()
        end
    end
end)

return ped