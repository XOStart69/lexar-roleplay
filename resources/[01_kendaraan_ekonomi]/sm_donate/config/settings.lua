Settings = {}

Settings.openCommand = 'donasi'

Settings.Phone = 'gksphone'
Settings.CashOrBank = 'bank'

Settings.SqlVehicleType = 'vehicle'
Settings.SqlAirType = 'air'
Settings.SqlBoatType = 'boat'

Settings.GiveAddKeys = true
Settings.GiveAddKeysFunction = function(newPlate)
    TriggerEvent('sm_vehiclekeys:client:setVehicleOwner', newPlate)
end

Settings.testDriveTime = 60
Settings.testDriveSpawn = vector4(-1607.1, -2995.84, 13.94, 240.29)

Settings.TestDriveZone = {
    name = 'zona:donasi',
    points = {
        vec3(271.0, 1094.0, 217.0),
        vec3(199.38999938965, 1042.8499755859, 217.0),
        vec3(129.17999267578, 1241.2299804688, 217.0),
        vec3(224.67999267578, 1278.4399414062, 217.0),
        vec3(226.0299987793, 1271.9499511719, 217.0),
    },
    thickness = 79.25,
}
