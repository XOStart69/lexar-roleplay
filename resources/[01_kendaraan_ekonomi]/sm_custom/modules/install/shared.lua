local data = lib.load('data.install')

---@class InstallAnim
---@field dict string
---@field clip string
---@field flag? integer
---@field time? integer

---@class InstallProp
---@field model string
---@field bone integer
---@field pos vector3
---@field rot vector3
---@field anim? InstallAnim
---@field slow? boolean
---@field ped? boolean
---@field order? integer

---@class InstallWork
---@field anim InstallAnim
---@field intro? InstallAnim
---@field time integer
---@field tool? InstallProp
---@field grip? InstallProp
---@field doors? integer[]
---@field under? boolean

---@class InstallSpot
---@field side? string
---@field wheel? string
---@field offset? vector3

---@class InstallDefinition
---@field kind? 'part' | 'wheels' | 'paint' | 'engine'
---@field group? string
---@field jack? boolean
---@field carry? InstallProp
---@field reuse? boolean
---@field item? string
---@field spots? InstallSpot[]
---@field work? InstallWork
---@field prompt? string
---@field progress? string

local AREAS <const> = {
    wheel_lf = 'front-left',
    wheel_rf = 'front-right',
    wheel_lr = 'rear-left',
    wheel_rr = 'rear-right',
    door = 'left',
}

---@class InstallShared
local parts = {
    jack = data.jack,
    hoist = data.hoist,
    spray = data.spray,
    creeper = data.creeper,
}

---@param name string
---@return string
function parts.area(name)
    return AREAS[name] or name
end

---@param patch table
---@return string[]
function parts.keys(patch)
    local keys = {}

    for key in pairs(patch) do
        keys[#keys + 1] = key
    end

    table.sort(keys)

    return keys
end

---@param keys string[]
---@return InstallDefinition
function parts.of(keys)
    for i = 1, #keys do
        local definition = data.parts[keys[i]]
        if definition then return definition end
    end

    return data.default
end

---@param kind string
---@param definition InstallDefinition
---@return InstallProp | InstallProp[] | nil
function parts.carry(kind, definition)
    if kind == 'engine' then return data.hoist.carry end
    if kind == 'jackUp' then return data.jack.carry end
    if kind == 'jackDown' then return end

    return definition.carry
end

---@return table<integer, true>
function parts.models()
    local models = {}

    local function collect(value)
        if type(value) ~= 'table' then return end

        if type(value.model) == 'string' then
            models[joaat(value.model)] = true
        end

        for _, child in pairs(value) do
            collect(child)
        end
    end

    collect(data)
    models[joaat(data.creeper)] = true

    return models
end

return parts
