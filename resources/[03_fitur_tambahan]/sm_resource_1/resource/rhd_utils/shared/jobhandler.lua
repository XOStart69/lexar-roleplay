local handler = {}
handler.cache = {}

---@class PlayerJobGrades
---@field name string
---@field level number

---@class PlayerJob
---@field name string
---@field type? string
---@field onduty boolean
---@field grade PlayerJobGrades
---@field isboss boolean

---@param job PlayerJob
---@param t string|string[]|table<string, number|number[]>
---@param duty? boolean
---@return boolean
local function checkjob(job, t, duty)
    if not job then return false end

    local jn = job.name
    local jt = job.type
    local jd = job.onduty
    local jg = job.grade.level

    if duty and not jd then
        return false
    end

    local tt = type(t)

    if tt == 'string' then
        return jn == t or jt == t
    end

    if tt == 'table' then
        if array.isArray(t) then
            return tbl.contains(t, jn) or tbl.contains(t, jt)
        end

        local requirement = t[jn] or t[jt]
        if not requirement then return false end

        local rt = type(requirement)

        if rt == 'number' then
            return jg >= requirement
        end

        if rt == 'table' and array.isArray(requirement) then
            return tbl.contains(requirement, jg)
        end

        return false
    end

    return false
end

---@param t string|string[]|table<string, number>
local function checkavailable(t)
    local _t = type(t)
    local missing = {}

    if _t == 'string' then
        local count = handler.getCount(t)
        if count < 1 then
            missing[#missing + 1] = ('%s (0/1)'):format(qb_jobs[t]?.label or t)
        end
    end

    if _t == 'table' then
        if lib.array.isArray(t) then
            lib.array.forEach(t, function(val)
                local count = handler.getCount(val)
                if count < 1 then
                    missing[#missing + 1] = ('%s (0/1)'):format(qb_jobs[val]?.label or val)
                end
            end)
        else
            lib.table.forEach(t, function(required, job)
                local count = handler.getCount(job)
                if count < required then
                    missing[#missing + 1] = ('%s (%s/%s)'):format(qb_jobs[job]?.label or job, count, required)
                end
            end)
        end
    end

    local available = #missing < 1

    local err = not available and ([[
Pekerjaan yang dibutuhkan tidak tersedia: %s
    ]]):format(table.concat(missing, ', ')) or nil

    return available, err
end

---@param job_table string|string[]|table<string, number>
---@return boolean, string?
function handler.checkavailable(job_table)
    return checkavailable(job_table)
end

if lib.context == 'server' then
    handler.source = {}
    handler.state = {}

    local function update(source, job)
        if not handler.source[job.name] then
            handler.state[job.name] = 0
            handler.source[job.name] = {}
        end

        local state = GlobalState
        local total = #handler.source[job.name]
        local already = array.find(handler.source[job.name], function (val)
            return val == source
        end)

        if not already then
            local oldJob = handler.cache[source]?.name
            local oldIndex = handler.source[oldJob] and array.findIndex(handler.source[oldJob], function (val)
                return val == source
            end)

            if oldIndex then
                table.remove(handler.source[oldJob], oldIndex)
                handler.state[oldJob] = #handler.source[oldJob]
            end

            handler.source[job.name][total+1] = source
            handler.state[job.name] = #handler.source[job.name]
            state:set('sm_jobcount', handler.state, true)
        end
        
        handler.cache[source] = job
    end

    local function removeCache(source)
        local oldJob = handler.cache[source]?.name
        local oldIndex = handler.source[oldJob] and array.findIndex(handler.source[oldJob], function (val)
            return val == source
        end)

        if oldIndex then
            table.remove(handler.source[oldJob], oldIndex)
        end

        handler.cache[source] = nil
    end

    local function reload()
        local players = qb_ecore:GetQBPlayers()

        for _, player in pairs(players) do
            local PlayerData = player.PlayerData
            local playerJob = PlayerData.job
            local playerSource = PlayerData.source

            update(playerSource, playerJob)
        end
    end

    ---@param jobname string|string[]
    ---@return number|table<string, number>
    function handler.getCount(jobname)
        local _t = type(jobname)

        if _t == "table" and array.isArray(jobname) then
            local jt = {}
            array.forEach(jobname, function (job)
                jt[job] = #(handler.source[job] or {})
            end)
            return jt
        end

        if _t ~= 'string' then return 0 end
        return #(handler.source[jobname] or {})
    end

    ---@param jobname string
    ---@return number
    function handler.getOnDutyCount(jobname)
        if type(jobname) ~= 'string' then return 0 end
        local sources = handler.source[jobname] or {}
        local count = 0
        for _, src in ipairs(sources) do
            local job = handler.cache[src]
            if job and job.onduty then
                count = count + 1
            end
        end
        return count
    end

    ---@param source number
    ---@param job_table string|string[]|table<string, number|number[]>
    ---@param onduty? boolean
    ---@return boolean
    function handler.check(source, job_table, onduty)
        local myjob = handler.cache[source]
        return checkjob(myjob, job_table, onduty)
    end

    ---@param event string
    ---@param jobname string|string[]
    ---@param ... any Parameter
    function handler.triggerJobEvent(event, jobname, ...)
        local _t = type(jobname)

        if _t == "table" and array.isArray(jobname) then
            local args = {...}
            array.forEach(jobname, function (job)
                local players = handler.source[job]
                if players then lib.triggerClientEvent(event, players, tbl.unpack(args)) end
            end)
        end

        if _t ~= 'string' then return end

        local players = handler.source[jobname]
        if not players or #players == 0 then return end

        return lib.triggerClientEvent(event, players, ...)
    end

    ---@class OxNotify
    ---@field title? string
    ---@field description string
    ---@field type 'success' | 'error' | 'info' | 'warn'
    ---@field duration? number
    
    ---@param jobname string|string[]
    ---@param notify OxNotify
    function handler.triggerNotify(jobname, notify)
        handler.triggerJobEvent('ox_lib:notify', jobname, notify)
    end

    AddEventHandler('QBCore:Server:OnJobUpdate', function (source, job)
        update(source, job)
    end)

    AddEventHandler('QBCore:Server:PlayerLoaded', function (self)
        update(self.PlayerData.source, self.PlayerData.job)
    end)

    AddEventHandler('playerDropped', function ()
        local source = source
        removeCache(source)
    end)

    local exportWrapper = require 'export_wrapper'
    exportWrapper('sm_utilized', 'GetByName', handler.getCount)
    exportWrapper('sm_utilized', 'GetOnDutyByName', handler.getOnDutyCount)

    CreateThread(function()
        Wait(1500)
        reload()
    end)
else
    ---@param jobname string|string[]
    ---@return number|table<string, number>
    function handler.getCount(jobname)
        local _t = type(jobname)
        local state = GlobalState.sm_jobcount or {}

        if _t == "table" and array.isArray(jobname) then
            local jt = {}
            array.forEach(jobname, function (job)
                jt[job] = state[job] or 0
            end)
            return jt
        end

        if _t ~= 'string' then return 0 end
        return state[jobname] or 0
    end

    ---@param job_table string|string[]|table<string, number|number[]>
    ---@param onduty? boolean
    ---@return boolean
    function handler.check(job_table, onduty)
        local myjob = QBPlayerData.job
        return checkjob(myjob, job_table, onduty)
    end
end

_ENV.jobhandler = handler