---@param src number
---@return table?
local function getAppearance(src)
    if GetResourceState('fivem-appearance') == 'started' then
        return exports['fivem-appearance']:getPedAppearance(GetPlayerPed(src))
    end

    if GetResourceState('illenium-appearance') == 'started' then
        return exports['illenium-appearance']:getAppearance(GetPlayerPed(src))
    end

    if GetResourceState('qb-clothing') == 'started' then
        return exports['qb-clothing']:getOutfitData(GetPlayerPed(src))
    end
end

---@param src number
---@param appearance table
local function setAppearance(src, appearance)
    if GetResourceState('fivem-appearance') == 'started' then
        exports['fivem-appearance']:setPedAppearance(GetPlayerPed(src), appearance)
        return
    end

    if GetResourceState('illenium-appearance') == 'started' then
        exports['illenium-appearance']:setAppearance(GetPlayerPed(src), appearance)
        return
    end

    if GetResourceState('qb-clothing') == 'started' then
        TriggerClientEvent('qb-clothing:client:loadOutfit', src, appearance)
    end
end

RegisterNetEvent('Housing:server:SaveCurrentOutfit', function(homeId, label)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home or not label then return end

    local identifier = Housing:GetIdentifier(src)
    if not home:HasAccess(identifier, 'wardrobe') then return end

    local appearance = getAppearance(src)
    if not appearance then
        Housing:Notify(src, 'Sistem appearance tidak terdeteksi', 'error')
        return
    end

    home.data.outfits = home.data.outfits or {}
    home.data.outfits[#home.data.outfits + 1] = { label = label, appearance = appearance, owner = identifier }
    home:Save()

    TriggerClientEvent('Housing:client:RefreshOutfits', -1, homeId, home.data.outfits)
    Housing:Notify(src, 'Outfit disimpan', 'success')
end)

RegisterNetEvent('Housing:server:LoadOutfit', function(homeId, label)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home or not label or not home.data.outfits then return end

    for i = 1, #home.data.outfits do
        if home.data.outfits[i].label == label then
            setAppearance(src, home.data.outfits[i].appearance)
            return
        end
    end
end)