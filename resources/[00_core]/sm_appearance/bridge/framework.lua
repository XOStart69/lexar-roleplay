local SUPPORTED = {
    { name = "qbx", resource = "qbx_core" },
    { name = "qb", resource = "qb-core" },
    { name = "esx", resource = "es_extended" },
    { name = "ox", resource = "ox_core" }
}

---@return string
local function detect()
    for i = 1, #SUPPORTED do
        local entry = SUPPORTED[i]

        if GetResourceState(entry.resource) == "started" then
            return entry.name
        end
    end

    for i = 1, #SUPPORTED do
        local entry = SUPPORTED[i]

        if GetResourceState(entry.resource) == "starting" then
            return entry.name
        end
    end

    error("rhd_appearance: no supported framework is running (qbx_core, qb-core, es_extended, ox_core)")
end

local name = detect()
Framework = require(("bridge.framework.%s.%s"):format(name, lib.context))
Framework.name = name

---@param target string
---@return boolean
function Framework.is(target)
    return name == target
end

---@param required RequireJobs
---@param gradeOf fun(name: string): number?
---@return boolean
local function holds(required, gradeOf)
    if type(required) == "string" then
        return gradeOf(required) ~= nil
    end

    for key, value in pairs(required) do
        if type(key) == "number" then
            ---@diagnostic disable-next-line: param-type-mismatch
            if gradeOf(value) then return true end
        else
            ---@diagnostic disable-next-line: param-type-mismatch
            local grade = gradeOf(key)

            if grade then
                if type(value) == "number" then
                    if grade >= value then return true end
                else
                    for i = 1, #value do
                        if value[i] == grade then return true end
                    end
                end
            end
        end
    end

    return false
end

---@param required RequireJobs
---@return boolean
function Framework.holdsJob(required)
    return holds(required, Framework.jobGrade)
end

---@param required RequireJobs
---@return boolean
function Framework.holdsGang(required)
    return holds(required, Framework.gangGrade)
end

---@param source number
---@param required RequireJobs
---@return boolean
function Framework.playerHoldsJob(source, required)
    return holds(required, function(name) return Framework.PlayerJobGrade(source, name) end)
end

---@param source number
---@param required RequireJobs
---@return boolean
function Framework.playerHoldsGang(source, required)
    return holds(required, function(name) return Framework.PlayerGangGrade(source, name) end)
end