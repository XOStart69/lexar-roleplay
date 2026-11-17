local customizers = {}

function GetCustomizeIPL(identifier, isMlo, isVisiting)
    local home = Homes[identifier]
    if not home then
        return nil
    end

    if customizers[identifier] then
        if home.properties.type == "ipl" and type(isVisiting) == "boolean" then
            customizers[identifier]:SetVisiting(isVisiting)
        end
        return customizers[identifier]
    end

    if isMlo then
        local entryCoords = ToVector3(home:GetEntryCoords())
        local entitySetData = FindEntitySetData(entryCoords)
        if entitySetData then
            customizers[identifier] = SetMenu:new(entitySetData, home.identifier)
            return customizers[identifier]
        end
    else
        for i = 1, #CustomizeIPL do
            local item = CustomizeIPL[i]
            local interior = home.properties.data.interior
            if item.name == interior then
                customizers[identifier] = IplMenu:new(item.entry, item.prices, item.ipl(), interior, isVisiting)
                return customizers[identifier]
            end
        end
    end

    return nil
end

RegisterCommand("customizeipl", function()
    if not CurrentHome or not CurrentHome.identifier then
        Notify(locale("housing"), locale("not_inside_home"), "error", 2500)
        return
    end

    local home = Homes[CurrentHome.identifier]
    local jobName = PlayerData.job.name
    local isAllowed = false

    if home and home:isOwner() then
        isAllowed = true
    elseif JobConfig.jobs[jobName] and JobConfig.jobs[jobName].permission.furnish and isAgent(CurrentHome.properties.realestate) then
        isAllowed = true
    elseif isAdmin("furnish") then
        isAllowed = true
    elseif home and home:isTenant("furnish") then
        isAllowed = true
    end

    if not isAllowed then
        Notify(locale("housing"), locale("not_allowed"), "error", 2500)
        return
    end

    local menu = GetCustomizeIPL(CurrentHome.identifier, CurrentHome.properties.type == "mlo")
    if menu then
        if menu.isVisiting and CurrentHome.properties.complex == "Apartment" then
            Notify(locale("housing"), locale("not_allowed"), "error", 2500)
            return
        end

        menu:ShowMenu()
    end
end, false)

RegisterNetEvent("Housing:client:SetDataCustomizeIPL", function(identifier, category, item, value)
    if CurrentHome and CurrentHome.identifier == identifier then
        local menu = GetCustomizeIPL(CurrentHome.identifier, CurrentHome.properties.type == "mlo")
        if menu then
            menu:Set(category, item, value)
        end
    end
end)

RegisterNetEvent("Housing:client:LoadDefaultCustomizeIPL", function(identifier)
    if CurrentHome and CurrentHome.identifier == identifier then
        local menu = GetCustomizeIPL(CurrentHome.identifier, CurrentHome.properties.type == "mlo")
        if menu then
            menu:LoadDefault()
        end
    end
end)