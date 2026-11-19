local QBCore = exports['qb-core']:GetCoreObject()

local framework = {}

function framework.getCharacterId(source)
    local Player = QBCore.Functions.GetPlayer(source)

    return Player and Player.PlayerData.citizenid or nil
end

function framework.hasGroup(source, groups)
    local Player = QBCore.Functions.GetPlayer(source)

    if not Player then return false end

    local job = Player.PlayerData.job

    if not job then return false end

    local grade = groups[job.name] or groups[job.type]

    if not grade then return false end

    if type(grade) == 'number' then
        return (job.grade.level or 0) >= grade
    end

    return grade == true
end

function framework.hasItem(source, items)
    for i = 1, #items do
        local item = items[i]

        if item ~= '' then
            local count = exports.ox_inventory:Search(source, 'count', item)

            if count and count > 0 then return true, item end
        end
    end

    return false
end

function framework.removeItem(source, item)
    if not item or item == '' then return end

    exports.ox_inventory:RemoveItem(source, item, 1)
end

function framework.notify(source, message)
    TriggerClientEvent('ox_lib:notify', source, { description = message, type = 'inform' })
end

return framework
