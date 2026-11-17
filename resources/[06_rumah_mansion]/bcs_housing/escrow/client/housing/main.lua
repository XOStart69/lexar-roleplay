local dashboardCards = {}

dashboardCards.general = function()
    local ownedHomes = exports[cache.resource]:GetOwnedHomeKeys() or {}
    local totalPrice = 0
    local individualCount = 0
    local apartmentCount = 0
    local flatCount = 0
    local publicCount = 0
    local mortgageCount = 0
    local rentedCount = 0
    local rentalIncome = 0

    for i = 1, #ownedHomes do
        local home = ownedHomes[i]
        local price = home.properties and home.properties.price or 0
        totalPrice = totalPrice + price

        local complex = home.properties and home.properties.complex
        if complex == "Individual" then
            individualCount = individualCount + 1
        elseif complex == "Apartment" then
            apartmentCount = apartmentCount + 1
        elseif complex == "Flat" then
            flatCount = flatCount + 1
        else
            publicCount = publicCount + 1
        end

        if home.mortgage then
            mortgageCount = mortgageCount + 1
        end

        if home.configuration and home.configuration.rentable then
            local rent = home.properties and home.properties.rent
            if rent and rent.isRented and rent.rentedAt then
                rentedCount = rentedCount + 1
                local elapsedDays = math.floor((GetCloudTimeAsInt() - rent.rentedAt) / 86400)
                local income = 0

                if rent.durationType == "day" then
                    income = rent.price * math.floor(elapsedDays / rent.duration)
                elseif rent.durationType == "week" then
                    income = rent.price * math.floor(elapsedDays / rent.duration * 7)
                end

                rentalIncome = rentalIncome + income
            end
        elseif home.properties and home.properties.rented then
            rentedCount = rentedCount + 1
        end
    end

    return {
        { title = "Owned Properties", value = #ownedHomes, description = "Total properties you have keys to", icon = "key" },
        { title = "Individual Houses", value = individualCount, description = "Private individual houses", icon = "home" },
        { title = "Apartment Complexes", value = apartmentCount, description = "Residences in building complexes", icon = "building" },
        { title = "Flat Units & Rooms", value = flatCount, description = "Dedicated flat units and rooms", icon = "door-closed" },
        { title = "Public Housing", value = publicCount, description = "Publicly accessible residences", icon = "users" },
        { title = "Mortgaged Homes", value = mortgageCount, description = "Properties with active mortgage", icon = "credit-card" },
        { title = "Rented Properties", value = rentedCount, description = "Homes currently on lease", icon = "file-text" },
        { title = "Rent Income", value = "$" .. string.format("%d", rentalIncome), description = "Total active rental income", icon = "dollar-sign" },
        { title = "Total Property Value", value = "$" .. string.format("%d", totalPrice), description = "Combined real estate valuation", icon = "dollar-sign" },
    }
end

dashboardCards.realestate = function()
    local jobName = (PlayerData and PlayerData.job and PlayerData.job.name) or ""
    local managedHomes = exports[cache.resource]:GetRealestateHomes(jobName) or {}
    local totalPrice = 0
    local occupiedCount = 0
    local vacantCount = 0
    local individualCount = 0
    local apartmentCount = 0
    local flatCount = 0
    local publicCount = 0

    for i = 1, #managedHomes do
        local home = managedHomes[i]
        local price = home.properties and home.properties.price or 0
        totalPrice = totalPrice + price

        if home.properties then
            if home.properties.owner or home.properties.status then
                occupiedCount = occupiedCount + 1
            end
        else
            vacantCount = vacantCount + 1
        end

        local complex = home.properties and home.properties.complex
        if complex == "Individual" then
            individualCount = individualCount + 1
        elseif complex == "Apartment" then
            apartmentCount = apartmentCount + 1
        elseif complex == "Flat" then
            flatCount = flatCount + 1
        else
            publicCount = publicCount + 1
        end
    end

    return {
        { title = "Total Managed Homes", value = #managedHomes, description = "Properties in agency catalog", icon = "building" },
        { title = "Individual Houses", value = individualCount, description = "Private individual catalog", icon = "home" },
        { title = "Apartment Complexes", value = apartmentCount, description = "Building catalog units", icon = "building-2" },
        { title = "Flat Units & Rooms", value = flatCount, description = "Dedicated flat catalog rooms", icon = "door-closed" },
        { title = "Public Housing", value = publicCount, description = "Public / shared property units", icon = "users" },
        { title = "Occupied / Sold", value = occupiedCount, description = "Properties with active owners", icon = "check-circle-2" },
        { title = "Available / Vacant", value = vacantCount, description = "Ready to be assigned or sold", icon = "tag" },
        { title = "Total Catalog Value", value = "$" .. string.format("%d", totalPrice), description = "Total market capitalization", icon = "dollar-sign" },
    }
end

dashboardCards.admin = function()
    local homes = exports[cache.resource]:GetHomes() or {}
    local totalPrice = 0
    local ownedCount = 0
    local disabledCount = 0
    local individualCount = 0
    local apartmentCount = 0
    local flatCount = 0
    local publicCount = 0

    for i = 1, #homes do
        local home = homes[i]
        local price = home.properties and home.properties.price or 0
        totalPrice = totalPrice + price

        if home.properties and home.properties.owner then
            ownedCount = ownedCount + 1
        end

        if home.properties and (home.properties.disabled == 1 or home.properties.disabled == true) then
            disabledCount = disabledCount + 1
        end

        local complex = home.properties and home.properties.complex
        if complex == "Individual" then
            individualCount = individualCount + 1
        elseif complex == "Apartment" then
            apartmentCount = apartmentCount + 1
        elseif complex == "Flat" then
            flatCount = flatCount + 1
        else
            publicCount = publicCount + 1
        end
    end

    return {
        { title = "Total Registered Homes", value = #homes, description = "Global properties in database", icon = "shield-check" },
        { title = "Active Owners Count", value = ownedCount, description = "Properties with registered owners", icon = "users" },
        { title = "Individual Houses", value = individualCount, description = "Server-wide individual houses", icon = "home" },
        { title = "Apartment Complexes", value = apartmentCount, description = "Multi-unit apartment complexes", icon = "building" },
        { title = "Flat Units & Rooms", value = flatCount, description = "Dedicated flat units and rooms", icon = "door-closed" },
        { title = "Public Housing Units", value = publicCount, description = "Publicly accessible residences", icon = "user-check" },
        { title = "Disabled Properties", value = disabledCount, description = "Inactive / disabled properties", icon = "alert-triangle" },
        { title = "Server Real Estate Value", value = "$" .. string.format("%d", totalPrice), description = "Global economy housing value", icon = "dollar-sign" },
    }
end

local dashboardCharts = {}

dashboardCharts.realestate = function()
    local jobName = (PlayerData and PlayerData.job and PlayerData.job.name) or ""
    local managedHomes = exports[cache.resource]:GetRealestateHomes(jobName) or {}
    local individualCount = 0
    local apartmentCount = 0
    local flatCount = 0
    local publicCount = 0

    for i = 1, #managedHomes do
        local home = managedHomes[i]
        if home.properties then
            local complex = home.properties.complex
            if complex == "Individual" then
                individualCount = individualCount + 1
            elseif complex == "Apartment" then
                apartmentCount = apartmentCount + 1
            elseif complex == "Flat" then
                flatCount = flatCount + 1
            else
                publicCount = publicCount + 1
            end
        end
    end

    return {
        pieChart = {
            title = "Agency Catalog Complex Distribution",
            data = {
                { label = "Individual Houses", value = individualCount, color = "hsl(var(--accent))" },
                { label = "Apartments", value = apartmentCount, color = "#3b82f6" },
                { label = "Flat Units", value = flatCount, color = "#8b5cf6" },
                { label = "Public Housing", value = publicCount, color = "#10b981" },
            },
        },
        barChart = {
            title = "Managed Complex Types Quantities",
            data = {
                { label = "Individual", value = individualCount },
                { label = "Apartment", value = apartmentCount },
                { label = "Flat", value = flatCount },
                { label = "Public", value = publicCount },
            },
        },
    }
end

dashboardCharts.admin = function()
    local homes = exports[cache.resource]:GetHomes() or {}
    local individualCount = 0
    local apartmentCount = 0
    local flatCount = 0
    local publicCount = 0

    for i = 1, #homes do
        local home = homes[i]
        if home.properties then
            local complex = home.properties.complex
            if complex == "Individual" then
                individualCount = individualCount + 1
            elseif complex == "Apartment" then
                apartmentCount = apartmentCount + 1
            elseif complex == "Flat" then
                flatCount = flatCount + 1
            else
                publicCount = publicCount + 1
            end
        end
    end

    return {
        pieChart = {
            title = "Server Complex Distribution Ratio",
            data = {
                { label = "Individual Houses", value = individualCount, color = "hsl(var(--accent))" },
                { label = "Apartment Complexes", value = apartmentCount, color = "#3b82f6" },
                { label = "Flat Units", value = flatCount, color = "#8b5cf6" },
                { label = "Public Units", value = publicCount, color = "#10b981" },
            },
        },
        barChart = {
            title = "Server Housing Complex Breakdown",
            data = {
                { label = "Individual", value = individualCount },
                { label = "Apartment", value = apartmentCount },
                { label = "Flat", value = flatCount },
                { label = "Public", value = publicCount },
            },
        },
    }
end

RegisterNUICallback("loadHomes", function(data, cb)
    local loadCategory = {
        general = function()
            HomeList = exports[cache.resource]:GetOwnedHomeKeys()
            HomeListAdmin = false
        end,
        realestate = function()
            HomeList = exports[cache.resource]:GetRealestateHomes(PlayerData.job.name)
            HomeListAdmin = false
        end,
        admin = function()
            HomeList = exports[cache.resource]:GetHomes()
            HomeListAdmin = true
        end,
    }

    if loadCategory[data] then
        loadCategory[data]()
    end

    cb(true)
end)

RegisterNUICallback("doAction", function(data, cb)
    ToggleNuiFrame(false)
    Wait(50)

    local command = data.action
    if data.args and #data.args > 0 then
        command = command .. " " .. table.concat(data.args, " ")
    end

    ExecuteCommand(command)
    cb(true)
end)

RegisterNUICallback("getHomeOptions", function(data, cb)
    local options = {}
    local homes = exports[cache.resource]:GetHomes() or {}

    for i = 1, #homes do
        local home = homes[i]
        options[#options + 1] = {
            label = string.format("%s - %s", home.properties.name, home.identifier),
            value = home.identifier,
        }
    end

    cb(options)
end)

RegisterNUICallback("getApartmentOptions", function(data, cb)
    local options = {}
    local homes = exports[cache.resource]:GetHomes() or {}

    for i = 1, #homes do
        local home = homes[i]
        if home.properties.complex == "Apartment" then
            local apartmentData = Apartments[home.identifier]
            local apartmentList = apartmentData and apartmentData.apartments
            if apartmentList then
                for j = 1, #apartmentList do
                    options[#options + 1] = {
                        label = string.format("%s - %s - %s", home.properties.name, home.identifier, apartmentList[j].apartment),
                        value = string.format("%s %s", home.identifier, apartmentList[j].apartment),
                    }
                    break
                end
            end
        end
    end

    cb(options)
end)

RegisterNUICallback("getFlatsOptions", function(data, cb)
    local options = {}

    for _, flat in pairs(Flats) do
        for _, room in pairs(flat.rooms) do
            local label = room.properties.data and room.properties.data.flat and room.properties.data.flat.name or room.properties.name
            options[#options + 1] = {
                label = label,
                value = room.identifier,
            }
        end
    end

    cb(options)
end)

RegisterNUICallback("getFurnitureOptions", function(data, cb)
    local options = {}

    for _, category in pairs(FurnitureList) do
        if category.list then
            for i = 1, #category.list do
                local item = category.list[i]
                options[#options + 1] = {
                    label = item.label,
                    value = item.model,
                }
            end
        end
    end

    cb(options)
end)

RegisterNUICallback("getOwnedHomeOptions", function(data, cb)
    local options = {}
    local homes = exports[cache.resource]:GetHomes() or {}

    for i = 1, #homes do
        local home = homes[i]
        if home.properties.owner then
            options[#options + 1] = {
                label = string.format("%s - %s", home.properties.name, home.identifier),
                value = home.identifier,
            }
        end
    end

    cb(options)
end)

RegisterNUICallback("getNoOwnedHomeOptions", function(data, cb)
    local options = {}
    local homes = exports[cache.resource]:GetHomes() or {}

    for i = 1, #homes do
        local home = homes[i]
        if not home.properties.owner then
            options[#options + 1] = {
                label = string.format("%s - %s", home.properties.name, home.identifier),
                value = home.identifier,
            }
        end
    end

    cb(options)
end)

RegisterNUICallback("getDashboarCard", function(data, cb)
    local handler = dashboardCards[data]
    if handler then
        cb(handler())
    else
        cb({})
    end
end)

RegisterNUICallback("getCardData", function(data, cb)
    local handler = dashboardCards[data]
    if handler then
        cb(handler())
    else
        cb({})
    end
end)

RegisterNUICallback("getChartData", function(data, cb)
    local handler = dashboardCharts[data]
    if handler then
        cb(handler())
    else
        cb({})
    end
end)

RegisterNUICallback("getPlayerJobLabel", function(data, cb)
    local job = JobConfig.jobs[PlayerData.job.name]
    local label = job and job.label or ""
    cb(label)
end)

RegisterNUICallback("getBlipStatus", function(data, cb)
    cb(blipStatus[data])
end)

RegisterNUICallback("toggleBlip", function(data, cb)
    ToggleBlip(data)
    cb(true)
end)

RegisterNuiCallback("getHousingPermissions", function(data, cb)
    local isAgentJob = JobConfig.jobs[PlayerData.job.name]
    if isAgentJob then
        isAgentJob = isAgent(PlayerData.job.name)
    end

    cb({
        general = true,
        admin = isAdmin(),
        realestate = isAgentJob,
    })
end)