return {
    --- Jangan di ubah-ubah ya panteeeeeek 
    default_setting = {
        status = "open",
        roles = {
            {
                roleid = "owner",
                access = {
                    withdraw = true,
                    deposit = true,
                    hire_emp = true,
                    fire_emp = true,
                    setting_label = true,
                    setting_price = true,
                },
            },
            {
                roleid = "employee",
                access = {
                    withdraw = false,
                    deposit = false,
                    hire_emp = false,
                    fire_emp = false,
                    setting_label = false,
                    setting_price = false
                }
            },
        },
        label = 'Pom Bensin'
    },

    default_fuel = 10,
    max_employee = 10,

    price_config = {
        refuel = {
            min = 300, --- minimal harga (tidak bisa menyetting harga dibawah min)
            max = 600 -- maximal harga (tidak bisa menyetting harga diatas max)
        },
        charger = {
            min = 200,
            max = 600
        },
        jerrycan = {
            min = 7500,
            max = 15000
        }
    },

    mission = {
        fuel_price = 250,
        delivery_timeout = 30, -- menit (waktu delivery, kalau lewat maka gagal) 
        delivery_cooldown = 2 -- menit
    }
}


