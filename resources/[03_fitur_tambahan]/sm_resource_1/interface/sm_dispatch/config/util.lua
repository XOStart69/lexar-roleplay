local Config = localmodule 'config'
local Locales = localmodule 'config.locales'

local sformat = string.format

local strings = Locales[Config.Locale] or Locales.en

local Util = {}

---@param key string
---@return string
function Util.L(key, ...)
    local text = strings[key]

    if not text then
        return sformat('locale hilang: %s', key)
    end

    if select('#', ...) == 0 then
        return text
    end

    return sformat(text, ...)
end

Util.strings = strings

---@param jobName string?
---@return string?
function Util.getDispatchIndexByJob(jobName)
    if not jobName then return nil end

    for index, dispatchConfig in pairs(Config.Dispatch) do
        if dispatchConfig.jobs[jobName] then
            return index
        end
    end

    return nil
end

---@param dispatchIndex string
---@param permission string
---@param jobName string
---@param grade number
---@return boolean
function Util.hasPermission(dispatchIndex, permission, jobName, grade)
    local dispatchConfig = Config.Dispatch[dispatchIndex]
    if not dispatchConfig then return false end

    local permissions = dispatchConfig.permissions
    local required = permissions and permissions[permission]

    if not required then return true end

    local minGrade = required[jobName]
    if not minGrade then return false end

    return grade >= minGrade
end

return Util
