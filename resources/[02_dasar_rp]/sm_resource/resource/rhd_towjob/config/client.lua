return {
    ped_start = {
        model = 'csb_tonya',
        coords = vec(392.1541, -1637.4374, 28.2919, 232.9300)
    },
    vehicle = {
        model = 'towtruck',
        spawn_coords = vec(408.8326, -1639.0717, 29.2587, 230.1275)
    },
    store_zone = {
        debug = {
            zone = false,
            marker = false
        },
        coords = vec3(401.5, -1632.2, 29.0),
        size = vec3(8.5, 14.5, 6.5),
        rotation = 321.5,
        marker_heading = 140.0,
    },
    kendaraan_rusak = {
        model = {
            'felon',
            'prairie',
            'baller',
            'sentinel',
            'zion',
            'ruiner',
            'asea',
            'ingot',
            'intruder',
            'primo',
            'stratum',
            'tailgater'
        },
        lokasi = {
            vec(1015.3276, -2462.3572, 27.7853, 82.8159),
            vec(-247.7807, -1687.8434, 33.4754, 178.8647),
            vec(372.9686, -767.0320, 29.2700, 0.0682),
            vec(-1276.2042, -556.5905, 30.2092, 219.8612),
            vec(1205.2948, -708.5202, 59.4169, 9.6660),
            vec(213.8225, 389.6160, 106.5621, 171.4204),
            vec(-498.8797, 121.7785, 63.1309, 269.0685),
            vec(-928.4528, -124.9771, 37.2992, 117.7664),
            vec(-1772.7124, -519.8768, 38.5269, 299.9457),
            vec(-1308.8690, -851.5054, 15.6849, 37.1244),
            vec(-1322.9799, -454.8239, 33.0699, 35.9689),
            vec(-928.3329, -317.4822, 38.9133, 246.2742),
            vec(-570.4581, -384.4131, 34.6319, 271.2078),
            vec(83.4780, -312.9476, 46.0560, 250.1325),
            vec(235.4800, -369.5933, 43.9610, 249.5175),
            vec(226.6196, -854.3265, 29.6857, 249.8725)
        }
    },
    waiting_time = function ()
        return math.random(1, 5) -- waktu untuk menunggu panggilan dari pelanggan
    end,
    chance_dapat_orderan = 0.2, --- maximal 1, 0.1 = 10%
    give_vehicle_keys = function (plate)
        TriggerEvent('sm_vehiclekeys:client:setVehicleOwner', plate)
    end
}