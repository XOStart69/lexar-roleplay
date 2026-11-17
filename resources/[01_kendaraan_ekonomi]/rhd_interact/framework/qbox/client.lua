local Player = {}
local qbx_core = exports.qbx_core

Player.Loaded = LocalPlayer.state.isLoggedIn
Player.PlayerData = qbx_core:GetPlayerData() or {}

local function loadGroups()
    Player.groups = {
        job = Player.PlayerData.job,
        gang = Player.PlayerData.gang
    }
end

CreateThread(loadGroups)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    if not Player.groups?.job then return end

    local old = Player.groups.job

    Player.groups.job = job
    TriggerEvent('rhd_interact:groupsChanged', old, Player.groups)
end)

RegisterNetEvent('QBCore:Client:OnGangUpdate', function(gang)
    if not Player.groups?.gang then return end
    
    local old = Player.groups.gang

    Player.groups.gang = gang
    TriggerEvent('rhd_interact:groupsChanged', old, Player.groups)
end)


RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function ()
    Player.Loaded = true
    loadGroups()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    Player.Loaded = false
    Player.PlayerData = {}
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
    Player.PlayerData = val
end)


_ENV.Framework = {}

---@diagnostic disable-next-line: duplicate-set-field
function Framework.isDead()
    local pState = LocalPlayer.state
    return pState.isDead
end

---@diagnostic disable-next-line: duplicate-set-field
function Framework.isCuffed()
    local playerData = Player.PlayerData
    local metadata = playerData?.metadata
    return metadata and metadata.ishandcuffed
end

---@diagnostic disable-next-line: duplicate-set-field
function Framework.playerLoaded()
    return Player.Loaded
end

---@diagnostic disable-next-line: duplicate-set-field
function Framework.vehicles()
    return qbx_core:GetVehiclesByName()
end

---@diagnostic disable-next-line: duplicate-set-field
function Framework.getCitizenid()
    return Player.PlayerData.citizenid
end

---@diagnostic disable-next-line: duplicate-set-field
function Framework.getGroups(groupType)
    local groupList = {
        job = Player.groups.job,
        gang = Player.groups.gang
    }
    return groupList[groupType]
end

---@diagnostic disable-next-line: duplicate-set-field
function Framework.getMoney(moneyType)
    local moneyList = {
        cash = Player.PlayerData.money.cash,
        bank = Player.PlayerData.money.bank
    }

    return moneyList[moneyType] or 0
end

---@diagnostic disable-next-line: duplicate-set-field
function Framework.getName(nameType)
    local charinfo = Player.PlayerData.charinfo
    
    local nameList = {
        first = charinfo.firstname,
        last = charinfo.lastname,
        full = charinfo.firstname .. ' ' .. charinfo.lastname
    }

    return nameList[nameType] or nameList.full
end

---@diagnostic disable-next-line: duplicate-set-field
function Framework.group_contains(groups)

    local has_groups = Utils.group_contains(groups, Player.groups.job)

    if not has_groups and Player.groups.gang then
        has_groups = Utils.group_contains(groups, Player.groups.gang)
    end

    return has_groups
end