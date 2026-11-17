local function isStarterApartment(identifier)
    if not StarterApartment then
        return false
    end
    for i = 1, #StarterApartment do
        if StarterApartment[i].identifier == identifier then
            return true
        end
    end
    return false
end

RegisterNUICallback("getStarterApartments", function(data, cb)
    local search = (data and data.search or ""):lower()
    local results = {}
    if StarterApartment then
        for i = 1, #StarterApartment do
            local apartment = StarterApartment[i]
            local name = (apartment.name or ""):lower()
            local identifier = (apartment.identifier or ""):lower()
            if search == "" or name:find(search, 1, true) or identifier:find(search, 1, true) then
                results[#results + 1] = apartment
            end
        end
    end
    cb(results)
end)

RegisterNUICallback("getAvailableStarterHomes", function(data, cb)
    local search = (data and data.search or ""):lower()
    local results = {}
    if Homes then
        for _, home in pairs(Homes) do
            if not isStarterApartment(home.identifier) and not (home.properties and home.properties.owner) then
                local name = ((home.properties and home.properties.name) or home.identifier or ""):lower()
                local identifier = (home.identifier or ""):lower()
                if search == "" or name:find(search, 1, true) or identifier:find(search, 1, true) then
                    results[#results + 1] = {
                        identifier = home.identifier,
                        name = (home.properties and home.properties.name) or home.identifier,
                        complex = home.complex or "Individual",
                        type = home.type or "shell",
                        price = home.price or 0,
                    }
                end
            end
        end
    end
    cb(results)
end)

RegisterNUICallback("addStarterApartment", function(data, cb)
    if data and data.homeId then
        TriggerServerEvent("Housing:server:AddStarterApartment", data.homeId)
        cb(true)
    else
        cb(false)
    end
end)

RegisterNUICallback("removeStarterApartment", function(data, cb)
    if data and data.homeId then
        TriggerServerEvent("Housing:server:RemoveStarterApartment", data.homeId)
        cb(true)
    else
        cb(false)
    end
end)