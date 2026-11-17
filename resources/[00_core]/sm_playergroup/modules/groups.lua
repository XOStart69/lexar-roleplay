local net = require 'modules.net'

---@class GroupMember
---@field source number
---@field name string

---@class GroupRequest
---@field source number
---@field name string

---@class GroupChatMessage
---@field id number
---@field source number
---@field name string
---@field text string
---@field time number
---@field system boolean

---@alias GroupTaskType 'count' | 'percentage' | 'progress' | 'timer' | 'location' | 'checklist'
---@alias GroupMissionStatus 'active' | 'completed' | 'failed'

---@class GroupTaskItem
---@field id string
---@field label string
---@field done boolean

---@class GroupTaskCoords
---@field x number
---@field y number
---@field z number

---@class GroupTaskData
---@field id string
---@field name string
---@field description string
---@field type GroupTaskType
---@field target number
---@field value number
---@field isDone boolean
---@field isFailed boolean
---@field isActive boolean
---@field optional boolean
---@field hidden boolean
---@field unit? string
---@field duration? number
---@field onExpire? 'fail' | 'done'
---@field endsAt? number
---@field timerToken? number
---@field coords? GroupTaskCoords
---@field radius? number
---@field autoComplete? boolean
---@field items? GroupTaskItem[]

---@class GroupTaskInput
---@field id string
---@field name string
---@field description? string
---@field tasksType? GroupTaskType
---@field type? GroupTaskType
---@field target? number
---@field optional? boolean
---@field hidden? boolean
---@field unit? string
---@field duration? number
---@field onExpire? 'fail' | 'done'
---@field coords? vector3 | GroupTaskCoords
---@field radius? number
---@field autoComplete? boolean
---@field items? (string | { id: string, label?: string })[]

---@class GroupMissionInput
---@field title? string
---@field tasks GroupTaskInput[]

---@class Group: OxClass
---@field id string
---@field name string
---@field owner number
---@field members Array
---@field requests Array
---@field tasks Array
---@field chat Array
---@field chatCounter number
---@field missionTitle? string
---@field missionStatus? GroupMissionStatus
---@field activeTaskId? string
local group = lib.class("Group")

local ids = {}

local function generateId()
    local id

    repeat
        id = 'group_' .. lib.string.random('........')
    until not ids[id]

    ids[id] = true
    return id
end

---@param coords vector3 | GroupTaskCoords
---@return GroupTaskCoords
local function toCoords(coords)
    return { x = coords.x or coords[1], y = coords.y or coords[2], z = coords.z or coords[3] }
end

---@param input GroupTaskInput
---@return GroupTaskData
local function buildTask(input)
    local taskType = input.tasksType or input.type or 'progress'

    ---@type GroupTaskData
    local task = {
        id = input.id,
        name = input.name,
        description = input.description or '',
        type = taskType,
        target = input.target or 1,
        value = 0,
        isDone = false,
        isFailed = false,
        isActive = false,
        optional = input.optional == true,
        hidden = input.hidden == true,
        unit = input.unit,
    }

    if taskType == 'percentage' then
        task.target = input.target or 100
    elseif taskType == 'timer' then
        task.duration = input.duration or input.target or 60
        task.target = task.duration
        task.onExpire = input.onExpire == 'done' and 'done' or 'fail'
    elseif taskType == 'location' then
        task.coords = input.coords and toCoords(input.coords) or nil
        task.radius = input.radius or 5.0
        task.autoComplete = input.autoComplete ~= false
    elseif taskType == 'checklist' then
        local items = {}
        local inputs = input.items or {}

        for i = 1, #inputs do
            local item = inputs[i]

            if type(item) == 'table' then
                items[i] = { id = item.id, label = item.label or item.id, done = false }
            else
                items[i] = { id = tostring(item), label = tostring(item), done = false }
            end
        end

        task.items = items
        task.target = #items
    end

    return task
end

---@param task GroupTaskData
local function taskToData(task)
    return {
        id = task.id,
        name = task.name,
        description = task.description,
        type = task.type,
        target = task.target,
        value = task.value,
        isDone = task.isDone,
        isFailed = task.isFailed,
        isActive = task.isActive,
        optional = task.optional,
        hidden = task.hidden,
        unit = task.unit,
        duration = task.duration,
        onExpire = task.onExpire,
        remaining = task.endsAt and math.max(0, task.endsAt - os.time()) or nil,
        coords = task.coords,
        radius = task.radius,
        autoComplete = task.autoComplete,
        items = task.items,
    }
end

---@param source number
---@param name string
---@param ownerName string
function group:constructor(source, name, ownerName)
    self.id = generateId()
    self.name = name
    self.owner = source
    self.members = lib.array:new({ source = source, name = ownerName })
    self.requests = lib.array:new()
    self.tasks = lib.array:new()
    self.chat = lib.array:new()
    self.chatCounter = 0
end

function group:getMemberCount()
    return #self.members
end

---@param event string
---@param ... any
function group:broadcast(event, ...)
    for i = 1, #self.members do
        net.emitLatentClient(event, self.members[i].source, ...)
    end
end

---@param source number
---@return GroupMember?
function group:getMember(source)
    return self.members:find(function(member)
        return member.source == source
    end)
end

---@param source number
---@return boolean
function group:hasMember(source)
    return self:getMember(source) ~= nil
end

---@param source number
---@return boolean
function group:hasRequest(source)
    return self.requests:find(function(request)
        return request.source == source
    end) ~= nil
end

---@param data GroupMember
function group:addMember(data)
    if not data or not data.source then return end
    if self:hasMember(data.source) then return end
    self.members:push(data)
end

---@param source number
---@return boolean
function group:removeMember(source)
    local before = #self.members
    self.members = self.members:filter(function(member)
        return member.source ~= source
    end) --[[@as Array]]
    return #self.members < before
end

---@param data GroupRequest
function group:addRequest(data)
    if not data or not data.source then return end
    if self:hasMember(data.source) or self:hasRequest(data.source) then return end
    self.requests:push(data)
end

---@param source number
---@return boolean
function group:removeRequest(source)
    local before = #self.requests
    self.requests = self.requests:filter(function(request)
        return request.source ~= source
    end) --[[@as Array]]
    return #self.requests < before
end

---Transfers ownership to the next member in line.
---@return number? newOwner
function group:transferOwnership()
    local next = self.members:find(function(member)
        return member.source ~= self.owner
    end)

    if next then
        self.owner = next.source
        return next.source
    end
end

---@param inputs GroupTaskInput[]
---@param title? string
function group:registerTasks(inputs, title)
    self.missionTitle = title
    self.missionStatus = nil
    self.activeTaskId = nil
    self.tasks = lib.array:from(inputs):map(buildTask) --[[@as Array]]
end

---@param id string
---@return GroupTaskData?
function group:getTask(id)
    return self.tasks:find(function(task)
        return task.id == id
    end)
end

---@param id string
---@return GroupTaskData? startedTimer
function group:setCurrentTask(id)
    local started

    self.tasks:forEach(function(task)
        task.isActive = task.id == id

        if task.isActive and task.type == 'timer' and not task.endsAt and not task.isDone and not task.isFailed then
            task.endsAt = os.time() + task.duration
            task.timerToken = (task.timerToken or 0) + 1
            started = task
        end
    end)

    return started
end

---@param id string
---@param value number
---@return GroupTaskData?
function group:setTaskValue(id, value)
    local task = self:getTask(id)
    if not task or task.isDone or task.isFailed then return end

    task.value = math.max(0, math.min(value, task.target))
    if task.value >= task.target then
        task.isDone = true
    end

    return task
end

---@param id string
---@return GroupTaskData?
function group:setTaskDone(id)
    local task = self:getTask(id)
    if not task then return end

    task.value = task.target
    task.isDone = true
    task.isFailed = false

    if task.items then
        for i = 1, #task.items do
            task.items[i].done = true
        end
    end

    return task
end

---@param id string
---@return GroupTaskData?
function group:setTaskFailed(id)
    local task = self:getTask(id)
    if not task or task.isDone then return end

    task.isFailed = true
    return task
end

---@param id string
---@param itemId string
---@param done boolean
---@return GroupTaskData?
function group:setChecklistItem(id, itemId, done)
    local task = self:getTask(id)
    if not task or not task.items or task.isDone or task.isFailed then return end

    local count = 0

    for i = 1, #task.items do
        local item = task.items[i]

        if item.id == itemId then
            item.done = done ~= false
        end

        if item.done then
            count = count + 1
        end
    end

    task.value = count
    task.isDone = task.target > 0 and count >= task.target
    return task
end

---@param id string
---@param hidden boolean
---@return GroupTaskData?
function group:setTaskHidden(id, hidden)
    local task = self:getTask(id)
    if not task then return end

    task.hidden = hidden == true
    return task
end

---@param id string
---@param token number
---@return GroupTaskData?
function group:expireTimer(id, token)
    local task = self:getTask(id)
    if not task or task.type ~= 'timer' or task.timerToken ~= token then return end
    if task.isDone or task.isFailed or not task.isActive then return end

    if task.onExpire == 'done' then
        task.value = task.target
        task.isDone = true
    else
        task.isFailed = true
    end

    return task
end

function group:clearTasks()
    self.tasks = lib.array:new()
    self.missionTitle = nil
    self.missionStatus = nil
    self.activeTaskId = nil
end

---@return GroupMissionStatus?
function group:getMissionStatus()
    if #self.tasks == 0 then return end

    local failed, pending = false, false

    self.tasks:forEach(function(task)
        if task.optional then return end

        if task.isFailed then
            failed = true
        elseif not task.isDone then
            pending = true
        end
    end)

    if failed then return 'failed' end
    if pending then return 'active' end
    return 'completed'
end

---@param message { source: number, name: string, text: string, system?: boolean }
---@param history number
---@return GroupChatMessage
function group:addChatMessage(message, history)
    self.chatCounter = self.chatCounter + 1
    message.id = self.chatCounter
    message.time = os.time()
    message.system = message.system == true
    self.chat:push(message)

    while #self.chat > history do
        self.chat:shift()
    end

    return message --[[@as GroupChatMessage]]
end

---Serializes the group into a plain table for the NUI.
function group:toData()
    local members = self.members:map(function(member)
        return {
            source = member.source,
            name = member.name,
            isOwner = member.source == self.owner,
        }
    end)

    local status = self:getMissionStatus()

    return {
        id = self.id,
        name = self.name,
        owner = self.owner,
        members = members,
        requests = self.requests,
        tasks = self.tasks:map(taskToData),
        chat = self.chat,
        mission = status and { title = self.missionTitle, status = status } or nil,
    }
end

function group:release()
    ids[self.id] = nil
end

return group
