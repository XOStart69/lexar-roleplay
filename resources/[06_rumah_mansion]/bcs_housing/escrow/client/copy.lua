function CopyHome(homeId)
    local home = Homes[homeId]
    if not home then
        return false
    end

    local data = lib.callback.await("Housing:server:GetData", false, homeId)
    local storages = data.storages or {}
    local wardrobes = data.wardrobes or {}
    local furniture = data.furniture or {}

    if home.properties.type ~= "mlo" then
        local locations = {}
        displayHelp("Press ~E~ to Add Location<br>Press ~DELETE~ to Remove Location<br>Press ~ENTER~ to Save Locations <br> Press ~X~ to Cancel")

        while true do
            if IsControlJustReleased(0, 38) then
                local coords = GetEntityCoords(cache.ped)
                table.insert(locations, {
                    x = round(coords.x, 2),
                    y = round(coords.y, 2),
                    z = round(coords.z - 1.0, 2),
                    w = round(GetEntityHeading(cache.ped), 2)
                })
            elseif IsControlJustReleased(0, 178) then
                local pedCoords = GetEntityCoords(cache.ped)
                for i = 1, #locations do
                    local loc = locations[i]
                    if #(vec3(loc.x, loc.y, loc.z) - pedCoords) < 2.0 then
                        table.remove(locations, i)
                        break
                    end
                end
            elseif IsControlJustReleased(0, 191) then
                if #locations > 0 then
                    for i = 1, #locations do
                        local homeData = {
                            name = home.properties.name .. string.format(" Copy %d", i),
                            type = home.properties.type,
                            payment = home.properties.payment,
                            price = home.properties.price,
                            mortgage = home.mortgages,
                            data = home.properties.data,
                            configuration = home.configuration,
                            storages = {},
                            wardrobes = wardrobes,
                            furniture = furniture,
                            permission = home.permission,
                            garages = home.garages,
                            complex = home.properties.complex,
                            entry = locations[i]
                        }

                        if homeData.configuration.garage then
                            local garageCoords, garageData = GetVehiclePoint()
                            if garageData then
                                homeData.garages = {
                                    {
                                        coords = garageCoords,
                                        name = garageData[1],
                                        type = garageData[2]
                                    }
                                }
                            end
                        end

                        for _, storage in pairs(storages) do
                            if storage.type == "zone" then
                                table.insert(homeData.storages, storage)
                            end
                        end

                        TriggerServerEvent("Housing:server:CreateHome", homeData)
                    end
                end
                break
            elseif IsControlJustReleased(0, 73) then
                break
            end

            for i = 1, #locations do
                local loc = locations[i]
                DrawMarker(2, loc.x, loc.y, loc.z + 1, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5, 255, 0, 0, 100, false, true, 2, nil, nil, false, false)
            end

            Wait(0)
        end

        closeHelp()
    end
end

RegisterCommand(commands.copyhome.name, function(source, args)
    local homeId = args[1]
    if not homeId or not Homes[homeId] then
        local options = {}
        for id, home in pairs(Homes) do
            table.insert(options, {
                value = id,
                label = home.properties.name
            })
        end

        local input = lib.inputDialog("Copy House", {
            {
                type = "select",
                label = "House",
                options = options,
                searchable = true,
                clearable = true,
                description = locale("invalid_homeid_select")
            }
        })
        if not input then
            return
        end

        homeId = input[1]
    end

    CopyHome(homeId)
end, false)