---@diagnostic disable: duplicate-set-field
if GetResourceState('qb-core') ~= 'started' then return end
if GetResourceState('qbx_core') == 'started' then return end

QBCore = exports['qb-core']:GetCoreObject()

Framework = Framework or {}
Framework.Shared = QBCore.Shared

Framework.GetFrameworkName = function()
    return 'qb-core'
end

Framework.GetPlayerData = function()
    return QBPlayerData
end

Framework.GetPlayerIdentifier = function()
    return QBPlayerData.citizenid
end

Framework.GetPlayerName = function()
    local info = QBPlayerData.charinfo
    if not info then return end
    return info.firstname, info.lastname
end

Framework.GetPlayerDob = function()
    local info = QBPlayerData.charinfo
    if not info then return end
    return info.birthdate
end

Framework.GetPlayerMetaData = function(metadata)
    local meta = QBPlayerData.metadata
    if not meta then return end
    return meta[metadata]
end

Framework.GetPlayerJob = function()
    local job = QBPlayerData.job
    if not job then return end
    return job.name, job.label, job.grade.name, job.grade.level
end

Framework.GetIsPlayerDead = function()
    local meta = QBPlayerData.metadata
    if not meta then return false end
    return meta["isdead"] or meta["inlaststand"]
end

Framework.GetFrameworkJobs = function()
    local jobs = {}
    for k, v in pairs(QBCore.Shared.Jobs) do
        table.insert(jobs, {
            name = k,
            label = v.label,
            grade = v.grades
        })
    end
    return jobs
end

Framework.Notify = function(message, type, time)
    TriggerEvent('QBCore:Notify', message, 'primary', time)
end

Framework.ShowHelpText = function(message, _position)
    return exports['qb-core']:DrawText(message, _position)
end

Framework.HideHelpText = function()
    return exports['qb-core']:HideText()
end

Framework.GetItemInfo = function(item)
    local itemData = QBCore.Shared.Items[item]
    if not itemData then return {} end
    return {
        name = itemData.name,
        label = itemData.label,
        stack = itemData.unique,
        weight = itemData.weight,
        description = itemData.description,
        image = itemData.image
    }
end

Framework.HasItem = function(item)
    return QBCore.Functions.HasItem(item)
end

Framework.GetItemCount = function(item)
    local frameworkInv = QBPlayerData.items
    if not frameworkInv then return 0 end
    local count = 0
    for _, v in pairs(frameworkInv) do
        if v.name == item then
            count = count + v.amount
        end
    end
    return count
end

Framework.GetPlayerInventory = function()
    local frameworkInv = QBPlayerData.items
    if not frameworkInv then return {} end
    local items = {}
    for _, v in pairs(frameworkInv) do
        table.insert(items, {
            name = v.name,
            label = v.label,
            count = v.amount,
            slot = v.slot,
            metadata = v.info,
            stack = v.unique,
            close = v.useable,
            weight = v.weight
        })
    end
    return items
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(1500)
    TriggerEvent('sm_chatheme:client:onPlayerLoaded')
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    TriggerEvent('sm_chatheme:client:onPlayerUnload')
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(data)
    TriggerEvent('sm_chatheme:client:onPlayerJobUpdate', data.name, data.label, data.grade_label, data.grade)
end)

RegisterNetEvent('QBCore:Client:OnGangUpdate', function(data)
    TriggerEvent('sm_chatheme:client:onPlayerGangUpdate', data.name, data.label, data.grade.name, data.grade.level)
end)

return Framework