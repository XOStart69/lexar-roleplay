local QBCore = exports['qb-core']:GetCoreObject()
local Jobs = QBCore.Shared.Jobs
local Gangs = QBCore.Shared.Gangs

local function initalizeBanking()
    CreatePeds()

    local locales = lib.getLocales()
    SendNUIMessage({
        action = 'updateLocale',
        translations = locales,
        currency = Config.currency
    })
end

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    Wait(100)
    initalizeBanking()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    DeletePeds()
end)

function GetSocietyLabel(society)
    return Jobs[society] and Jobs[society].label or Gangs[society] and Gangs[society].label or society
end

function GetPlayerObject(source)
    return QBCore.Functions.GetPlayer(source)
end

function GetPlayerObjectFromID(identifier)
    return QBCore.Functions.GetPlayerByCitizenId(identifier:upper())
end

function GetCharacterName(Player)
    return ("%s %s"):format(Player.PlayerData.charinfo.firstname, Player.PlayerData.charinfo.lastname)
end

function GetIdentifier(Player)
    return Player.PlayerData.citizenid
end

function GetFunds(Player)
    return {
        cash = Player.PlayerData.money.cash,
        bank = Player.PlayerData.money.bank
    }
end

function AddMoney(Player, Amount, Type, comment)
    Player.Functions.AddMoney(Type, Amount, comment)
end

function RemoveMoney(Player, Amount, Type, comment)
    local currentAmount = Player.Functions.GetMoney(Type)
    if currentAmount >= Amount then
        Player.Functions.RemoveMoney(Type, Amount, comment)
        return true
    end
    return false
end

function GetJobs(Player)
    return {
        name = Player.PlayerData.job.name,
        grade = tostring(Player.PlayerData.job.grade.level)
    }
end

function GetGang(Player)
    return Player.PlayerData.gang.name
end

function IsJobAuth(job, grade)
    if not Jobs[job] then return false end
    local numGrade = tonumber(grade)
    return Jobs[job].grades[grade] and Jobs[job].grades[grade].bankAuth or Jobs[job].grades[numGrade] and Jobs[job].grades[numGrade].bankAuth
end

function IsGangAuth(Player, gang)
    if not Gangs[gang] then return false end
    local grade = tostring(Player.PlayerData.gang.grade.level)
    local gradeNum = tonumber(grade)
    return Gangs[gang].grades[grade] and Gangs[gang].grades[grade].bankAuth or Gangs[gang].grades[gradeNum] and Gangs[gang].grades[gradeNum].bankAuth
end

function Notify(src, settings)
    TriggerClientEvent("ox_lib:notify", src, settings)
end

function IsDead(Player)
    return Player.PlayerData.metadata.isdead
end

function GetFrameworkGroups()
    return Jobs, Gangs
end

AddEventHandler('onResourceStart', function(resourceName)
    Wait(250)
    if resourceName == GetCurrentResourceName() then
        CreatePeds()

        local locales = lib.getLocales()
        SendNUIMessage({
            action = 'updateLocale',
            translations = locales,
            currency = Config.currency
        })
    end
end)
