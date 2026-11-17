local config = localmodule 'config.shared'

local function showTextUI(text, icon)
    lib.showTextUI(text, { position = "top-center", icon = icon or '' })
end

local function hideTextUI()
    lib.hideTextUI()
end

local function notify(message, notifyType)
    lib.notify({ description = message, type = notifyType })
end

local function progressBar(label, duration, disable, anim, prop)
    return lib.progressBar({
        label = label,
        duration = duration,
        position = config.progressbarPos,
        useWhileDead = false,
        canCancel = true,
        disable = disable,
        anim = anim,
        prop = prop
    })
end

local function openStation(id)
    local station = config.stations[id]
    if not IsPedInAnyVehicle(cache.ped, false) then
        notify('tidak ada didalam kendaraan', 'error')
        return
    end

    local vehicle = GetVehiclePedIsIn(cache.ped, false)
    if not DoesEntityExist(vehicle) then
        notify('tidak ada kendaraan', 'error')
        return
    end

    local activeJobs = lib.callback.await('sm_workshops:server:getActiveStations', false)
    local isAllowed = false
    for _, job in ipairs(activeJobs) do
        if job == station.jobs then
            isAllowed = true
            break
        end
    end

    if not isAllowed then
        notify(("Station %s tidak aktif karena ada mekanik yang tersedia!"):format(station.label or id), "error")
        return
    end

    local finalPrice = math.ceil(station.price)
    local alert = lib.alertDialog({
        header = 'stations',
        content = 'Total harga perbaikan ' .. finalPrice,
        centered = true,
        cancel = true
    })

    if alert == 'confirm' then
        if progressBar('memperbaiki...', station.progress, { car = true, walk = true }, {}, {}) then
            local success = lib.callback.await('sm_workshops:server:repairVehicleAxon', false, finalPrice, station.jobs)
            if success then
                SetVehicleFixed(vehicle)
                SetVehicleDeformationFixed(vehicle)
                SetVehicleEngineHealth(vehicle, 1000.0)
                SetVehicleBodyHealth(vehicle, 1000.0)
                SetVehiclePetrolTankHealth(vehicle, 1000.0)
                notify('berhasil bayar ' .. finalPrice, 'success')
            else
                notify('tidak ada uang', 'error')
            end
        end
    end
end

local function startScript()
    for k, v in pairs(config.stations) do
        lib.zones.poly({
            points = v.zone.points,
            thickness = v.zone.thickness,
            debug = false,
            onEnter = function()
                if (not v.job) or (getPlayerJob() == v.job) then
                    showTextUI('[E] ' .. v.label, "tools")
                end
            end,
            onExit = function()
                if (not v.job) or (getPlayerJob() == v.job) then
                    hideTextUI()
                end
            end,
            inside = function()
                if IsControlJustPressed(0, 38) then
                    if (not v.job) or (getPlayerJob() == v.job) then
                        openStation(k)
                    end
                end
            end
        })
    end
end

CreateThread(startScript)