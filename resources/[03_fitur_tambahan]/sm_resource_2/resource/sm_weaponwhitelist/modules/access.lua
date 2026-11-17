---@param list string[]?
---@param job { name: string, type: string? }?
---@return boolean
local function inJobs(list, job)
    if not list or not job then return false end

    local name, jobType = job.name, job.type
    for i = 1, #list do
        local entry = list[i]
        if entry == name or entry == jobType then
            return true
        end
    end

    return false
end

---@param rule { jobs: string[]?, items: string[]? }
---@param job { name: string, type: string? }?
---@param countItems fun(items: string[]): boolean
---@return boolean
return function(rule, job, countItems)
    if inJobs(rule.jobs, job) then return true end

    local items = rule.items
    return items ~= nil and #items > 0 and countItems(items)
end
