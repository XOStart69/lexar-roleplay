Staff = { players = {}}

local net = require 'modules.net'
local config = require 'config.shared'
local motelJob = config.motelJob
local permissions = config.permissions

function Staff.isBoss(source)
    return Staff.players[source]?.isboss
end

function Staff.isStaff(source)
    return Staff.players[source]?.onduty
end

function Staff.isOnduty(source)
    return Staff.players[source]?.onduty
end

function Staff.getRankLevel(source)
    return Staff.players[source]?.rank?.level
end

---@param source number
---@param action string
---@return boolean
function Staff.hasPermission(source, action)
    if not Staff.isOnduty(source) then
        return false
    end

    if permissions.bossBypass and Staff.isBoss(source) then
        return true
    end

    local grades = permissions.actions and permissions.actions[action]

    if not grades then
        return true
    end

    local level = tonumber(Staff.getRankLevel(source))

    if level == nil then
        return false
    end

    local tg = type(grades)

    if tg == 'string' then
        if tg:lower() == 'boss' then
            return Staff.isBoss(source)
        end
    elseif tg == "number" then
        return level >= grades
    elseif tg == "table" and lib.array.isArray(grades) then
        return lib.array.includes(grades, tonumber(level))
    end

    return false
end

function Staff.getName(source)
    if not Staff.players[source] then
        return
    end

    if not Staff.players[source].name then
        local player = Core:GetPlayer(source)
        local charinfo = player.PlayerData.charinfo

        Staff.players[source].name = charinfo.firstname .. ' ' .. charinfo.lastname
    end

    return Staff.players[source].name
end

function Staff.getData(source)
    if not Staff.players[source] then
        return
    end

    return {
        name = Staff.getName(source),
        isBoss = Staff.isBoss(source),
        onDuty = Staff.isOnduty(source),
        rank = Staff.players[source].rank
    }
end

function Staff.syncEvent(event, ...)
    for source in pairs(Staff.players) do
        net.emitLatentClient(event, source, ...)
    end
end

function Staff.count()
    local count = 0
    for _, data in pairs(Staff.players) do
        if data.onduty then
            count = count + 1
        end
    end
    return count
end

function Staff.isActive()
    return Staff.count() > 0
end

local function initializeStaff(player)
    local source = player.PlayerData.source

    if Staff.players[source] then
        return
    end

    local playerJob = player.PlayerData.job

    if playerJob.name ~= motelJob then
        return
    end

    Staff.players[source] = {
        isboss = playerJob.isboss,
        onduty = playerJob.onduty,

        rank = {
            label = playerJob.grade.name,
            level = playerJob.grade.level
        }
    }
end

AddEventHandler('playerDropped', function ()
    local source = source
    if Staff.players[source] then
        Staff.players[source] = nil
    end
end)

AddEventHandler('QBCore:Server:OnJobUpdate', function (source, job)
    if job.name == motelJob then
        Staff.players[source] = {
            isboss = job.isboss,
            onduty = job.onduty,
            rank = {
                label = job.grade.name,
                level = job.grade.level
            }
        }
    else
        if Staff.players[source] then
            Staff.players[source] = nil
        end
    end
end)

AddEventHandler('QBCore:Server:SetDuty', function (source, duty)
    if not Staff.players[source] then return end

    Staff.players[source].onduty = duty
end)

AddEventHandler('QBCore:Server:PlayerLoaded', function (player)
    initializeStaff(player)
end)

CreateThread(function ()
    Wait(1500)

    local players = Core:GetQBPlayers()

    for _, player in pairs(players) do
        initializeStaff(player)
    end
end)

return Staff