return {
    rentalLocations = {
        {
            name = "Rental kendaraan",
            coords = vec3(1270.6146, 3774.3372, 37.5523),
            spawnLocations = {
                vector4(1269.0679, 3772.6548, 36.9964, 21.8899),
            },
            type = "road",
            showBlip = true
        },
        {
            name = "Rental kendaraan",
            coords = vec3(-331.780121, 7693.974609, 6.571624),
            spawnLocations = {
                vector4(-338.2434, 7690.1489, 6.4069, 219.6869),
            },
            type = "road",
            showBlip = true
        },
        {
            name = "Rental kendaraan",
            coords = vector3(-1030.0098, -2735.0623, 20.2442),
            spawnLocations = {
                vector4(-1028.07, -2732.05, 19.61, 238.65),
            },
            type = "road",
            showBlip = true
        },
        {
            name = "Rental kendaraan",
            coords = vector3(-749.4218, -1294.1118, 5.1518),
            spawnLocations = {
                vector4(-751.49, -1290.35, 4.51, 297.67)
            },
            type = "road",
            showBlip = false
        },
        {
            name = "Rental kendaraan",
            coords = vector3(140.8339, 6611.0898, 31.8230),
            spawnLocations = {
                vector4(140.7864, 6606.6392, 31.8449, 182.5176)
            },
            type = "road",
            showBlip = true
        },
        {
            name = "Rental Sepeda",
            coords = vector3(1164.1127, -1517.1561, 34.8438),
            spawnLocations = {
                vector4(1164.1127, -1517.1561, 34.8438, 0.9956)
            },
            type = "sepedaaja",
            showBlip = true
        },
        {
            name = "Rental Sepeda",
            coords = vector3(-2708.5518, 4178.0732, 25.6233),
            spawnLocations = {
                vector4(-2707.5793, 4174.5200, 25.6233, 234.2022)
            },
            type = "rentalroel",
            showBlip = false
        },
        {
            name = "Rental Kapal",
            coords = vector3(3867.11, 4463.67, 2.73),
            spawnLocations = {
                vector4(3862.57, 4476.55, 0.1, 276.6)
            },
            type = "boat",
            showBlip = true
        },
        {
            name = "Rental Kapal",
            coords = vector3(-3427.79, 954.08, 8.35),
            spawnLocations = {
                vector4(-3427.98, 941.23, 0.06, 78.06)
            },
            type = "boat",
            showBlip = true
        },
        {
            name = "Rental Kapal",
            coords = vector3(-801.48, -1513.32, 1.6),
            spawnLocations = {
                vector4(-810.39, -1520.61, 0.12, 126.45)
            },
            type = "boat",
            showBlip = true
        },
        {
            name = "Rental Kapal",
            coords = vector3(-318.3552, 6633.5884, 1.7443),
            spawnLocations = {
                vector4(-329.9410, 6629.3540, 1.8292, 46.8481)
            },
            type = "boat",
            showBlip = true
        },
    },

    vehicles = {
        { model = 'bmx',      label = 'BMX',      price = 2000,  duration = 30, type = 'sepedaaja' },
        { model = 'bmxbocil', label = 'BMX Bocil', price = 2000,  duration = 30, type = 'rentalroel' },
        { model = 'bmx',      label = 'BMX', price = 2000,  duration = 30, type = 'rentalroel' },
        { model = 'smski',    label = 'Ski',       price = 15000, duration = 15, type = 'snow'      },
        { model = 'sanchez',  label = 'Sanchez',   price = 15000, duration = 30, type = 'road'      },
        { model = 'bmx',      label = 'BMX',       price = 2000,  duration = 30, type = 'road'      },
        { model = 'dinghy',   label = 'Dinghy',    price = 15000, duration = 30, type = 'boat'      },
        { model = 'seashark', label = 'Seashark',  price = 2000,  duration = 30, type = 'boat'      },
    }
}