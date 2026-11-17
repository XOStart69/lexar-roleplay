
qbLib.entityStateHandler('rhd_garage_lockvehicle', function (entity, _, value)
    if value == nil then return end
    local state = value and 2 or 0
    SetVehicleDoorsLocked(entity, state)
    Entity(entity).state:set('rhd_garage_lockvehicle', nil, true)
end)