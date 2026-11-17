---@class MockPlayersOptions
---@field spread? number
---@field moving? boolean
---@field moveStep? number
---@field sprite? number
---@field command? string
---@field clearCommand? string
---@field defaultCount? number
---@field color? number

---@class MockPlayersContext
---@field getInstance fun(instanceName: string): JobBlipInstance?
---@field ensureViewer fun(source: number, instance: JobBlipInstance)
---@field syncInstance fun(instance: JobBlipInstance)
---@field beforeSpawn? fun(source: number)

---@class MockPlayers
---@field instanceName string
---@field count number
---@field options MockPlayersOptions
local MockPlayers = lib.class('MockPlayers')

---@param instanceName string
---@param count number
---@param options? MockPlayersOptions
function MockPlayers:constructor(instanceName, count, options)
    self.instanceName = instanceName
    self.count = count
    self.options = options or {}
end

---@param source number
---@return vector3
function MockPlayers:getCenter(source)
    local ped = source > 0 and GetPlayerPed(source) or 0

    if ped and ped ~= 0 then
        return GetEntityCoords(ped)
    end

    return vector3(0.0, 0.0, 72.0)
end

---@param index number
---@return vector3
function MockPlayers:getOffset(index)
    local spread = self.options.spread or 1500.0
    local angle = (index / self.count) * math.pi * 2.0
    local ring = math.floor((index - 1) / 60) + 1
    local radius = math.min(spread, 35.0 * ring)

    return vector3(math.cos(angle) * radius, math.sin(angle) * radius, 0.0)
end

---@param index number
---@return vector3?
function MockPlayers:getVelocity(index)
    if not self.options.moving then return nil end

    local step = self.options.moveStep or 8.0
    local angle = (index % 360) * math.pi / 180.0

    return vector3(math.cos(angle) * step, math.sin(angle) * step, 0.0)
end

---@param index number
---@return string
function MockPlayers:getIdentifier(index)
    return ('mock:%s:%03d'):format(self.instanceName, index)
end

---@param blipInstance JobBlipInstance
---@return number
function MockPlayers:clear(blipInstance)
    local removed = 0

    for identifier, member in pairs(blipInstance.members) do
        if member.mock and blipInstance:removeMember(identifier) then
            removed = removed + 1
        end
    end

    return removed
end

---@param source number
---@param blipInstance JobBlipInstance
---@return number
function MockPlayers:spawn(source, blipInstance)
    local center = self:getCenter(source)

    self:clear(blipInstance)

    for i = 1, self.count do
        local identifier = self:getIdentifier(i)
        local coords = center + self:getOffset(i)

        blipInstance:addMockMember(
            identifier,
            ('Mock %03d'):format(i),
            coords,
            self.options.sprite,
            self:getVelocity(i)
        )
    end

    return self.count
end

---@param value string?
---@param fallback number
---@param min number
---@param max number
---@return number
function MockPlayers.parseBoundedNumber(value, fallback, min, max)
    local parsed = tonumber(value) or fallback
    parsed = math.floor(parsed)

    if parsed < min then return min end
    if parsed > max then return max end

    return parsed
end

---@param options MockPlayersOptions
---@return string
function MockPlayers.getInstanceName(options)
    return options.instance or '__mock'
end

---@param options MockPlayersOptions
---@return table
function MockPlayers.getInstanceConfig(options)
    return {
        color = options.color or 5,
        shared = {}
    }
end

---@param options MockPlayersOptions
---@param count? number
---@return MockPlayers
function MockPlayers.newFromOptions(options, count)
    return MockPlayers:new(
        MockPlayers.getInstanceName(options),
        count or options.defaultCount or 500,
        options
    )
end

---@param source number
---@param context MockPlayersContext
function MockPlayers:spawnForSource(source, context)
    local instance = context.getInstance(self.instanceName)

    if not instance then
        lib.print.warn(('[rhd_job_blip] Mock instance "%s" does not exist.'):format(self.instanceName))
        return
    end

    if source > 0 and context.beforeSpawn then
        context.beforeSpawn(source)
    end

    context.ensureViewer(source, instance)
    self:spawn(source, instance)
    context.syncInstance(instance)

    lib.print.info(('[rhd_job_blip] Created %s mock blips in instance "%s".'):format(self.count, self.instanceName))
end

---@param context MockPlayersContext
---@return number
function MockPlayers:clearForContext(context)
    local instance = context.getInstance(self.instanceName)
    if not instance then return 0 end

    local removed = self:clear(instance)

    if removed > 0 then
        context.syncInstance(instance)
    end

    return removed
end

---@param options MockPlayersOptions
---@param context MockPlayersContext
function MockPlayers.registerCommands(options, context)
    local manager

    RegisterCommand(options.command or 'jobblip_mock', function(source, args)
        local count = MockPlayers.parseBoundedNumber(args[1], options.defaultCount or 500, 1, 2000)

        manager = MockPlayers.newFromOptions(options, count)
        manager:spawnForSource(source, context)
    end, false)

    RegisterCommand(options.clearCommand or 'jobblip_mock_clear', function()
        manager = manager or MockPlayers.newFromOptions(options, 0)

        local removed = manager:clearForContext(context)
        lib.print.info(('[rhd_job_blip] Removed %s mock blips from instance "%s".'):format(removed, manager.instanceName))
    end, false)
end

return MockPlayers
