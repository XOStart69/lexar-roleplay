cfg = {}

cfg.rhd_interact = false --- false if you are not using rhd_interact (default ox_target)

cfg.shops = {
    police = {
        label = 'Cardealer',
        blip = {
            sprite = 227,
            color = 3
        },
        vehicles = 'cardealer',
        coords = {
            shop = vec(37.9169, -352.2711, 39.1266, 162.3560),
            preview = vec(-42.7148, -1098.7284, 26.4224, 77.6479),
            testDrive = vec(-951.8230, -3171.0383, 13.6740, 59.8417),
            spawnOnBuy = vec(-32.9260, -1079.9927, 26.3904, 70.6111)
        },
        ped = {
            model = 's_m_m_strpreach_01',
            coords = vec(-55.6022, -1098.0679, 26.4224, 349.4848)
        },
        testdriveTime = 1.0,
        prefix_plate = 'PDM ', --- max 4 characters
        default_garage = 'Garasi Kota'
    }
}

cfg.sell_localveh = {
    {
        coords = vec(-45.7729, -1081.5928, 26.6902, 253.3235),
        vehicles = 'cardealer',
        pricePercentage = 50
    }
}

---@param netId number
---@param plate string
cfg.giveKeys = function (netId, plate)
    TriggerEvent('sm_vehiclekeys:client:setVehicleOwner', plate)
end

cfg.installment = {
    type = 'days', -- (month / weeks / days) billing logic on the server side; the UI label follows this value.
    options = {
        {
            duration = 1,
            interest = 15
        },
        {
            duration = 3,
            interest = 10
        },
        {
            duration = 6,
            interest = 8
        },
        {
            duration = 12,
            interest = 5
        }
    },
    minDownPayment = 50 -- Minimum down payment percentage (e.g., 10 means 10%)
}
