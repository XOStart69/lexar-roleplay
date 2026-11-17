local function isStarterApartment(identifier)
    for i = 1, #StarterApartment do
        if StarterApartment[i].identifier == identifier then
            return true
        end
    end
    return false
end

RegisterNetEvent("Housing:client:RefreshStarterApartment", function(starterApartments)
    StarterApartment = starterApartments
end)

AddEventHandler("Housing:client:AddStarter", function()
    local boxes = {}
    for _, home in pairs(Homes) do
        if not isStarterApartment(home.identifier) and not home.properties.owner then
            boxes[#boxes + 1] = {
                text = {
                    title = home.properties.name,
                    subtitle = home.identifier
                },
                icon = "home",
                event = "Housing:server:AddStarterApartment",
                server = true,
                args = { home.identifier }
            }
        end
    end
    TriggerEvent("Housing:client:CreateMenu", {
        title = locale("starter_apartment_add"),
        subtitle = locale("choose_actions"),
        boxes = boxes
    })
end)

AddEventHandler("Housing:client:RemoveStarter", function()
    local boxes = {}
    for _, home in pairs(Homes) do
        if isStarterApartment(home.identifier) then
            boxes[#boxes + 1] = {
                text = {
                    title = home.properties.name,
                    subtitle = home.identifier
                },
                icon = "home",
                event = "Housing:server:RemoveStarterApartment",
                server = true,
                args = { home.identifier }
            }
        end
    end
    TriggerEvent("Housing:client:CreateMenu", {
        title = locale("starter_apartment_remove"),
        subtitle = locale("choose_actions"),
        boxes = boxes
    })
end)

AddEventHandler("Housing:client:ListStarterApartment", function()
    local boxes = {}
    for _, home in pairs(Homes) do
        if isStarterApartment(home.identifier) then
            boxes[#boxes + 1] = {
                text = {
                    title = home.properties.name,
                    subtitle = home.identifier
                },
                icon = "home",
                event = "Housing:client:nothing"
            }
        end
    end
    TriggerEvent("Housing:client:CreateMenu", {
        title = locale("starter_apartment_list"),
        boxes = boxes
    })
end)

RegisterCommand(commands.starterapartment.name, function(source, args)
    if not isAdmin() then
        return
    end
    TriggerEvent("Housing:client:CreateMenu", {
        title = locale("starter_apartment_menu"),
        subtitle = locale("choose_actions"),
        boxes = {
            {
                text = { title = locale("starter_apartment_add") },
                icon = "plus",
                event = "Housing:client:AddStarter"
            },
            {
                text = { title = locale("starter_apartment_remove") },
                icon = "trash",
                event = "Housing:client:RemoveStarter"
            },
            {
                text = { title = locale("starter_apartment_list") },
                icon = "home",
                event = "Housing:client:ListStarterApartment"
            }
        }
    })
end)