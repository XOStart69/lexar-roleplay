local utils = require 'client.utils'
local playerItems = utils.getItems()

require '@sm_core.modules.playerdata'

local function setPlayerItems()
    if not QBPlayerData or not QBPlayerData.items then return end

    table.wipe(playerItems)

    for _, item in pairs(QBPlayerData.items) do
        playerItems[item.name] = (playerItems[item.name] or 0) + (item.amount or 0)
    end
end

local usingOxInventory = utils.hasExport('ox_inventory.Items')

if not usingOxInventory then
    setPlayerItems()
end

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    if not usingOxInventory then setPlayerItems() end
end)

---@diagnostic disable-next-line: duplicate-set-field
function utils.hasPlayerGotGroup(filter)
    local _type = type(filter)

    local playerJobType = QBPlayerData.job.type
    local playerJob = QBPlayerData.job.name
    local playerGang = QBPlayerData.gang.name
    local playerCitizenid = QBPlayerData.citizenid
    local playerJobGrade = QBPlayerData.job.grade
    local playerGangGrade = QBPlayerData.gang.grade

    if _type == 'string' then
        local job = playerJob == filter or playerJobType == filter
        local gang = playerGang == filter
        local citizenId = playerCitizenid == filter

        return job or gang or citizenId
    elseif _type == 'table' then
        local tabletype = table.type(filter)

        if tabletype == 'hash' then
            local jobGrade = filter[playerJob] or filter[playerJobType]
            local gangGrade = filter[playerGang]
            local citizenid = filter[playerCitizenid]

            local grade = (jobGrade or gangGrade) or false

            if not grade then
                return citizenid
            end

            local gradeType = type(grade)
            local playerGrade = jobGrade and playerJobGrade or gangGrade and playerGangGrade

            if gradeType == "number" then
                return grade <= playerGrade.level
            elseif gradeType == "table" and table.type(grade) == 'array' then
                return lib.table.contains(grade, playerGrade.level)
            end

        elseif tabletype == 'array' then
            for i = 1, #filter do
                local name = filter[i]
                local job = QBPlayerData.job.name == name
                local gang = QBPlayerData.gang.name == name
                local citizenId = QBPlayerData.citizenid == name

                if job or gang or citizenId then
                    return true
                end
            end
        end
    end
end
