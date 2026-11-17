RegisterNetEvent("Housing:client:UpdateOwner", function(homeId, owner, apartmentId)
    local home = Homes[homeId]
    if not home then
        return
    end

    if home.properties.complex == "Apartment" then
        local apartmentManager = Apartments[homeId]
        if apartmentManager then
            local apartment = apartmentManager:GetApartmentById(apartmentId)
            if apartment then
                apartment.owner = owner
            end
        end
    else
        home.properties.owner = owner
        if not owner then
            home.keys = Keys:new(home.identifier, {}, {})
            if home.properties.type == "mlo" and not Config.SaveDoorsWhenSold then
                home.doors = {}
            end
        end

        if home.properties.complex == "Flat" then
            RefreshFlatBlip()
        end
    end

    if home.properties.complex ~= "Flat" then
        RefreshHomeBlip(homeId)
    end
end)

RegisterNetEvent("Housing:client:GiveApartment", function(homeId, apartmentId, apartmentData)
    if Homes[homeId] and Apartments[homeId] then
        Apartments[homeId]:AddApartment(apartmentId, apartmentData)
    end
end)

RegisterNetEvent("Housing:client:RemoveApartment", function(homeId, apartmentId)
    local apartmentManager = Apartments[homeId]
    if apartmentManager then
        apartmentManager:RemoveApartment(apartmentId)
    end
end)

RegisterNetEvent("Housing:client:SaveHomeProperty", function(homeId, property, value)
    local home = Homes[homeId]
    if not home then
        return
    end

    if property == "shell" then
        home.properties.data.placement = value.shell
        home.properties.data.placement.w = value.heading
        home.properties.data.interior = value.interior
    elseif property == "edit" then
        home.properties.price = value.price
        home.properties.payment = value.payment
        home.properties.data.expiry = value.expiry
    elseif property == "garage" then
        home.properties.data.garage = value
        home:SetGarageZone()
    elseif property == "signboard" then
        if value then
            home.properties.data.signboard = value
            LoadSignboard(home.properties.data.signboard, home.realestate)
        else
            DeleteSpawnedSign(homeId)
        end
    elseif property == "area" then
        home.properties.area = value
        if value then
            home:SetAreaZone()
        end
    elseif property == "isRented" then
        home.properties.rent = value
    elseif property == "renameflat" then
        home.properties.data.flat.name = value
        Flats[home.properties.data.flat.identifier].name = value
        RefreshFlatBlip()
    elseif property == "downpayment" then
        home.properties.data.downpayment = value
    elseif property == "entry" then
        if Config.target then
            RemoveTargetZone("HouseEntrance-" .. homeId)
        end

        local entranceManager = nil
        if home.properties.complex == "Individual" then
            entranceManager = Individuals[home.identifier]
        elseif home.properties.complex == "Apartment" then
            entranceManager = Apartments[home.identifier]
        end

        home.properties.entry = value
        if entranceManager then
            entranceManager:DestroyZone(home.properties.name)
            entranceManager:SetEntranceZone(value, home.properties.name)
        end

        local isAdminUser, adminName = isAdmin()
        RefreshHomeBlip(homeId, isAdminUser, adminName)
    elseif property == "flatentrance" then
        local flat = Flats[value.identifier]
        if flat then
            flat.entry = value.coords
            Homes[homeId].properties.data.flat.coords = value.coords
            flat:DestroyZone()
            flat:SetEntranceZone(value.coords)
            RefreshFlatBlip()
        end
    elseif property == "configuration" then
        home:UpdateConfig(value)
    else
        home.properties[property] = value
    end
end)

RegisterNetEvent("Housing:client:LockHome", function(homeId, apartmentId, isLocked)
    local home = Homes[homeId]
    if not home then
        return
    end

    if home.properties.complex == "Apartment" then
        local apartmentManager = Apartments[homeId]
        if apartmentManager then
            local apartment = apartmentManager:GetApartmentById(apartmentId)
            if apartment then
                apartment.locked = isLocked
            end
        end
    else
        home.properties.locked = isLocked
    end
end)

RegisterNetEvent("Housing:client:DeleteHome", function(homeId)
    local home = Homes[homeId]
    if not home then
        return
    end

    deleteBlip(homeId .. "_owned")
    deleteBlip(homeId .. "_sell")
    TriggerEvent("qb-garages:client:removeHouseGarage", homeId)

    if home.properties.complex == "Flat" then
        local flatId = home.properties.data.flat.identifier
        for index, room in pairs(Flats[flatId].rooms) do
            if room.identifier == homeId then
                table.remove(Flats[flatId].rooms, index)
                break
            end
        end

        if #Flats[flatId].rooms == 0 then
            local entranceZone = Flats[flatId].zones.entranceZone
            if entranceZone then
                entranceZone:remove()
            elseif Config.target then
                RemoveTargetZone("entrance-flat-" .. Flats[flatId].name)
            end
            Flats[flatId] = nil
        end

        deleteBlip(flatId .. "_sell")
        deleteBlip(flatId .. "_owned")
        RefreshFlatBlip()
    end

    home:DestroyZones()
    home:DeleteFurnitures()
    home:DeleteStoragesZone()
    home:DeleteWardrobesZone()
    home:DeleteGarages()
    home:DeleteTeleports()

    if home.properties.data and home.properties.data.signboard then
        DeleteSpawnedSign(homeId)
    end

    Homes[homeId] = nil
end)