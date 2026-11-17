local RESOURCE = GetCurrentResourceName()
local FILE = "data/peds.lua"
local MAX_ENTRIES = 4096
local NAME_MAX = 64

---@type string[]
local catalogue = require "data.peds"

local pedsCatalogue = {}

---@return string[]
function pedsCatalogue.all()
    return catalogue
end

---@param value any
---@return boolean
local function validModel(value)
    return type(value) == "string" and #value > 0 and #value <= NAME_MAX and value:match("^[%w_]+$") ~= nil
end

---@param value any
---@return boolean
local function validList(value)
    if type(value) ~= "table" or #value == 0 or #value > MAX_ENTRIES then return false end

    local seen = {}

    for i = 1, #value do
        local model = value[i]

        if not validModel(model) or seen[model] then return false end

        seen[model] = true
    end

    return true
end

---@param list string[]
---@return boolean
function pedsCatalogue.save(list)
    if not validList(list) then return false end

    local lines = table.create(#list + 2, 0)

    lines[1] = "return {"

    for i = 1, #list do
        lines[i + 1] = ("    %q,"):format(list[i])
    end

    lines[#lines + 1] = "}\n"

    local written = SaveResourceFile(RESOURCE, FILE, table.concat(lines, "\n"), -1)

    if not written then return false end

    catalogue = list

    return true
end

return pedsCatalogue
