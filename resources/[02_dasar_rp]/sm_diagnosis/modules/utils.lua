local utils = {}

if lib.context == 'server' then
    ---@param source integer
    ---@return integer|boolean
    function utils.getClosestPlayer(source)
        local playerped = GetPlayerPed(source)
        local playerpos = GetEntityCoords(playerped)

        local players = GetPlayers()

        for i=1, #players do
            local target = players[i]

            if tonumber(target) ~= source then
                local targetped = GetPlayerPed(target)
                local targetpos = GetEntityCoords(targetped)

                local distance = #(playerpos - targetpos)

                if distance < 3.0 then
                    return target --[[@as integer]]
                end
            end
        end

        return false
    end
end

---@param myjob table
---@param targetjob string|table
---@return boolean
function utils.job_contains(myjob, targetjob)
    if not myjob or not targetjob then return false end
    
    local typet = type(targetjob)

    if typet == 'string' then
        return myjob.name == targetjob
    end

    if typet == 'table' then
        local ttype = table.type(targetjob)
        if ttype == 'array' and type(targetjob[1]) == 'string' then
            return lib.array.includes(targetjob, myjob.name)
        elseif ttype == 'hash' then
            local jobgrade = targetjob[myjob.name]
            return jobgrade and myjob.grade.level >= jobgrade or false
        end
    end

    return false
end

return utils
