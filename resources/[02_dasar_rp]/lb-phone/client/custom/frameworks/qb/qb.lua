if Config.Framework ~= "qb" then
    return
end

debugprint("Loading QB")

QB = exports["qb-core"]:GetCoreObject()

PlayerJob = {}
PlayerData = {}

while not LocalPlayer.state.isLoggedIn do
    Wait(500)
end

FrameworkLoaded = true

debugprint("QB loaded")

PlayerJob = QB.Functions.GetPlayerData().job
PlayerData = QB.Functions.GetPlayerData()

RegisterNetEvent("QBCore:Client:OnPlayerLoaded", function()
    PlayerData = QB.Functions.GetPlayerData()
    PlayerJob = PlayerData.job

    FetchPhone()
end)

RegisterNetEvent("QBCore:Client:OnPlayerUnload", function()
    PlayerData = {}

    LogOut()
end)

RegisterNetEvent("QBCore:Player:SetPlayerData", function(newData)
    PlayerData = newData

    local metadata = newData.metadata or {}

    if (metadata.ishandcuffed or metadata.isdead or metadata.inlaststand) and phoneOpen then
        OnDeath()
    end

    if not Config.Item.Require or Config.Item.Unique then
        return
    end

    Wait(500)

    if currentPhone and not HasPhoneItem() then
        OnDeath()
    end
end)

RegisterNetEvent("QBCore:Client:OnMoneyChange", function(moneyType)
    if moneyType ~= "bank" then
        return
    end

    SendNUIAction("wallet:setBalance", math.floor(PlayerData.money.bank))
end)

AddCheck("openPhone", function()
    local metadata = PlayerData.metadata or {}

    if metadata.ishandcuffed or metadata.isdead then
        return false
    end

    local liveMeta = (QB.Functions.GetPlayerData() or {}).metadata or {}
    if liveMeta.isdead or liveMeta.inlaststand or liveMeta.ishandcuffed or IsPedDeadOrDying(PlayerPedId(), true) then
        return false
    end

    local phoneItems = exports.ox_inventory:Search('slots', Config.Item.Name)
    if phoneItems and phoneItems[1] then
        local durability = phoneItems[1].metadata and phoneItems[1].metadata.durability
        
        if durability then
            local currentTime = GetCloudTimeAsInt()
            
            if durability <= currentTime then
                QB.Functions.Notify('Hp kamu rusak dan tidak bisa dibuka lagi', 'error')
                TriggerServerEvent('phone:server:removeBrokenPhone', phoneItems[1].slot)
                
                return false
            end
        end
    end

    return true
end)
