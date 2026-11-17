---@class QbPlayerInstance
local playerInstance = lib.class('PlayerInstance')

function playerInstance:constructor(player)
    local playerData = player.PlayerData
    local playerJob = playerData.job
    local charinfo = playerData.charinfo

    self.source = playerData.source
    self.job = {
        name = playerJob.name,
        label = playerJob.label,
        grade = {
            label = playerJob.grade.name,
            level = playerJob.grade.level
        },
        onduty = playerJob.onduty or false
    }
    self.name = ('%s %s'):format(charinfo.firstname, charinfo.lastname)
    self.identifier = playerData.citizenid
end

function playerInstance:setjob(job)
    self.job = {
        name = job.name,
        label = job.label,
        grade = {
            label = job.grade.name,
            level = job.grade.level
        },
        onduty = job.onduty or false
    }
    blipUpdate(self.source)
end

function playerInstance:setduty(onduty)
    self.job.onduty = onduty
    blipUpdate(self.source)
end

local playerManager = {}

local function removePlayer(source)
    if playerManager[source] then
        table.wipe(playerManager[source])
        playerManager[source] = nil
    end
end

RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local source = source --[[@as number]]
    local player = sm_core:GetPlayer(source)
    if not player then return end

    ---@diagnostic disable-next-line: undefined-field
    playerManager[source] = playerInstance:new(player)
    blipUpdate(source, true)
end)

AddEventHandler('QBCore:Server:SetDuty', function (source, onduty)
    if type(source) ~= 'number' then return end

    if playerManager[source] then
        playerManager[source]:setduty(onduty)
    end
end)

AddEventHandler('QBCore:Server:OnJobUpdate', function(source, job)
    if type(source) ~= 'number' then return end

    if playerManager[source] then
        playerManager[source]:setjob(job)
        return
    end

    local player = sm_core:GetPlayer(source)
    if not player then return end

    ---@diagnostic disable-next-line: undefined-field
    playerManager[source] = playerInstance:new(player)
    blipUpdate(source, true)
end)

AddEventHandler('QBCore:Server:OnPlayerUnload', function(source)
    if type(source) ~= 'number' then return end

    blipUpdate.logout(source)
    removePlayer(source)
end)

AddEventHandler('playerDropped', function()
    local source = source --[[@as number]]

    blipUpdate.logout(source)
    removePlayer(source)
end)

local function initializePlayers()
    local players = sm_core:GetQBPlayers()

    for _, instance in pairs(players) do
        local source = instance.PlayerData.source
        playerManager[source] = playerInstance:new(instance)
        blipUpdate(source, true)
    end
end

CreateThread(function()
    Wait(1000)
    initializePlayers()
end)

return playerManager