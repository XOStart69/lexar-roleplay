local INTERVAL = 60000

---@type Cache[]
local registry = {}
local ticking = false

---@class Cache: OxClass
---@field rows table[]
---@field writer { update: fun(id: number, row: table), remove: fun(id: number) }
---@field updates table<number, table>
---@field deletes table<number, true>
local Cache = lib.class('AppearanceCache')

---@param writer { update: fun(id: number, row: table), remove: fun(id: number) }
function Cache:constructor(writer)
    self.rows = {}
    self.writer = writer
    self.updates = {}
    self.deletes = {}

    registry[#registry + 1] = self
end

---@param rows table[]
function Cache:load(rows)
    self.rows = rows or {}
    self.updates = {}
    self.deletes = {}
end

---@return table[]
function Cache:all()
    return self.rows
end

---@param id number
---@return table? row
---@return number? index
function Cache:find(id)
    for i = 1, #self.rows do
        if self.rows[i].id == id then return self.rows[i], i end
    end
end

function Cache:beforeInsert()
    if next(self.deletes) == nil then return end

    self:flush()
end

---@param row table
function Cache:insert(row)
    local existing, index = self:find(row.id)

    if existing then
        self.rows[index] = row
    else
        self.rows[#self.rows + 1] = row
    end

    self.updates[row.id] = nil
end

---@param id number
---@param row table
function Cache:update(id, row)
    local _, index = self:find(id)

    row.id = id

    if index then
        self.rows[index] = row
    else
        self.rows[#self.rows + 1] = row
    end

    self.updates[id] = row
end

---@param id number
---@param match fun(row: table): boolean
function Cache:removeWhere(id, match)
    for i = #self.rows, 1, -1 do
        if match(self.rows[i]) then table.remove(self.rows, i) end
    end

    self.updates[id] = nil
    self.deletes[id] = true
end

---@param match fun(row: table): boolean
function Cache:forget(match)
    for i = #self.rows, 1, -1 do
        local row = self.rows[i]

        if match(row) then
            table.remove(self.rows, i)
            self.updates[row.id] = nil
        end
    end
end

---@param id number
function Cache:remove(id)
    self:removeWhere(id, function(row) return row.id == id end)
end

---@return boolean
function Cache:pending()
    return next(self.updates) ~= nil or next(self.deletes) ~= nil
end

function Cache:flush()
    for id, row in pairs(self.updates) do
        self.writer.update(id, row)
    end

    for id in pairs(self.deletes) do
        self.writer.remove(id)
    end

    self.updates = {}
    self.deletes = {}
end

local cache = {}

---@param writer { update: fun(id: number, row: table), remove: fun(id: number) }
---@return Cache
function cache.new(writer)
    if not ticking then
        ticking = true

        CreateThread(function()
            while true do
                Wait(INTERVAL)
                cache.flush()
            end
        end)
    end

    return Cache:new(writer)
end

function cache.flush()
    for i = 1, #registry do
        if registry[i]:pending() then registry[i]:flush() end
    end
end

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then cache.flush() end
end)

return cache
