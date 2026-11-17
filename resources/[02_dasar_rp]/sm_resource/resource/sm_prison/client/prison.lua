local cachePrison = {}
local prisonZone = {}
local inOOCJail = false

local prisonJob = localmodule 'modules.prison_job'
local clientConfig = localmodule 'config.location'
local permission = localmodule 'config.permission'

local function secondToClock(seconds)
    local total_seconds = tonumber(seconds)
    if total_seconds <= 0 then return 0, 0, 0 end
    local hours = string.format('%02.f', math.floor(total_seconds / 3600))
    local mins = string.format('%02.f', math.floor(total_seconds / 60 - (hours * 60)))
    local secs = string.format('%02.f', math.floor(total_seconds - hours * 3600 - mins * 60))
    return hours, mins, secs
end

local function createZone(location)
    local zoneData = clientConfig.zone[location]
    prisonZone[location] = lib.zones.poly({
        points = zoneData.points,
        thickness = zoneData.thickness,
        onExit = function()
            local metadata = QBPlayerData and QBPlayerData.metadata
            if cachePrison[cache.serverId] and metadata and metadata.injail and metadata.injail > 0 then
                DoScreenFadeOut(500)
                while not IsScreenFadedOut() do
                    Wait(10)
                end

                DetachEntity(PlayerPedId(), true, false)
                local coordsMasuk = cachePrison[cache.serverId].coords.enter
                SetEntityCoords(PlayerPedId(), coordsMasuk.x, coordsMasuk.y, coordsMasuk.z - 0.9, 0, 0, 0, false)
                TriggerServerEvent("InteractSound_SV:PlayOnSource", "jail", 0.5)
                TriggerServerEvent("sm_prison:server:jailEscapeAlert")
                Wait(2000)
                DoScreenFadeIn(500)
            end
        end
    })
end

local function removeZone(location)
    if prisonZone[location] then
        prisonZone[location]:remove()
    end
end

local oocZone

local function teleportToOOCJail(ped, fadeTime)
    DoScreenFadeOut(fadeTime)
    while not IsScreenFadedOut() do Wait(10) end

    local coords = clientConfig.oocjail.enter
    ClearPedTasks(ped)
    DetachEntity(ped, true, false)
    SetEntityCoords(ped, coords.x, coords.y, coords.z - 0.9, 0, 0, 0, false)
    SetEntityHeading(ped, coords.w)
end

local function removeOOCZone()
    if oocZone then
        oocZone:remove()
        oocZone = nil
    end
end

local function createOOCZone()
    removeOOCZone()
    local zoneData = clientConfig.oocjail.zone
    oocZone = lib.zones.poly({
        points = zoneData.points,
        thickness = zoneData.thickness,
        onExit = function()
            if not inOOCJail then return end
            local ped = PlayerPedId()
            teleportToOOCJail(ped, 500)
            Wait(1000)
            DoScreenFadeIn(500)
        end
    })
end

local function prisonerActionMenu(prisoner)
    local context = {
        id = 'prisoner:contextActionMenu',
        title = 'Prisoner Action Menu',
        options = {
            {
                title = 'Unjail',
                icon = 'fas fa-circle-info',
                description = 'Keluarkan pemain dari penjara',
                onSelect = function()
                    ExecuteCommand('unjail ' .. prisoner.source)
                end
            },
            {
                title = 'Remote time',
                icon = 'fas fa-clock',
                description = 'Kurangi masa tahanan',
                onSelect = function()
                    local input = lib.inputDialog('Waktu', {
                        { type = 'number', label = 'Berapa menit?', placeholder = '' },
                    })
                    if not input then return end
                    TriggerTokenEvent('sm_prison:kurangiWaktuTahanan', { prisoner.source, input[1] })
                end
            }
        }
    }
    lib.registerContext(context)
    lib.showContext('prisoner:contextActionMenu')
end

local function prisonerMenu(location)
    local prisoners = lib.callback.await('sm_prison:getPrisoner', 1500, location)

    if prisoners and #prisoners < 1 then
        return lib.notify({
            description = 'Tidak ada prisoner',
            type = 'error'
        })
    end

    local context = {
        id = 'prisoner:contextMenu',
        title = 'Prisoner Menu',
        options = {}
    }

    for i = 1, #prisoners do
        local prisoner = prisoners[i]
        local h, m, s = secondToClock(prisoner.timer)
        local text = ('%s Jam %s Menit %s Detik'):format(h, m, s)

        context.options[#context.options + 1] = {
            title = prisoner.name,
            description = 'Waktu tersisa: ' .. text,
            icon = 'fas fa-user',
            onSelect = function()
                prisonerActionMenu(prisoner)
            end
        }
    end

    lib.registerContext(context)
    lib.showContext('prisoner:contextMenu')
end

lib.callback.register('sm_prison:getInputData', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    local players = lib.callback.await('sm_prison:getNearbyPlayers', false, coords)

    if #players < 1 then
        return lib.notify({
            description = 'Tidak ada pemain!',
            type = 'error'
        })
    end

    local input = lib.inputDialog('PENJARA', {
        { type = 'multi-select', label = 'Pilih pemain',        required = true, options = players },
        { type = 'number',       label = 'Waktu penjara (menit)', required = true, min = 1, max = 999999 },
        { type = 'select',       label = 'Lokasi Penjara',      required = true, options = {
            { value = 'police', label = 'Boilingbroke' }
        } }
    })

    if not input then return end

    return {
        players = input[1],
        time = input[2],
        location = input[3]
    }
end)

lib.callback.register('sm_prison:sendToJail', function(location)
    local ped = cache.ped
    if not ped or not DoesEntityExist(ped) then
        return false
    end

    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do
        Wait(10)
    end

    cachePrison[cache.serverId] = {
        coords = clientConfig.coords[location],
        location = location
    }

    local prisonerData = cachePrison[cache.serverId]
    if not prisonerData or not prisonerData.coords or not prisonerData.coords.enter then
        DoScreenFadeIn(500)
        return false
    end

    local coordsMasuk = prisonerData.coords.enter

    ped = PlayerPedId()
    SetEntityCoords(ped, coordsMasuk.x, coordsMasuk.y, coordsMasuk.z - 0.9, 0, 0, 0, false)
    TriggerServerEvent("InteractSound_SV:PlayOnSource", "jail", 0.5)
    Wait(1000)
    DoScreenFadeIn(500)

    createZone(prisonerData.location)
    prisonJob.createPrisonJobs(prisonerData.location)

    lib.notify({
        description = 'Selamat menjalani masa tahanan!',
    })

    return true
end)

RegisterNetEvent('sm_prison:releaseFromJail', function()
    if source == '' then return end

    local ped = cache.ped
    if not ped or not DoesEntityExist(ped) then return end

    local serverId = cache.serverId
    if not serverId then return end

    local prisonerData = cachePrison[serverId]
    if not prisonerData or not prisonerData.coords or not prisonerData.coords.release then return end

    removeZone(prisonerData.location)
    prisonJob.removePrisonJobs(prisonerData.location)
    cachePrison[serverId] = nil

    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(10) end

    local coordsKeluar = prisonerData.coords.release
    ped = PlayerPedId()
    SetEntityCoords(ped, coordsKeluar.x, coordsKeluar.y, coordsKeluar.z - 0.9, 0, 0, 0, false)
    SetEntityHeading(ped, coordsKeluar.w)
    Wait(2000)
    DoScreenFadeIn(500)

    lib.notify({
        description = 'Anda telah bebas dari penjara.',
        type = 'success'
    })
end)

RegisterNetEvent('sm_prison:oocjail:sendToJail', function()
    if source == '' then return end

    local ped = cache.ped
    if not ped or not DoesEntityExist(ped) then return end

    teleportToOOCJail(ped, 1000)
    inOOCJail = true
    createOOCZone()

    Wait(2000)
    DoScreenFadeIn(1000)

    lib.notify({
        description = 'Anda telah dijail OOC!',
        type = 'error'
    })
end)

RegisterNetEvent('sm_prison:oocjail:leaveJail', function()
    if source == '' then return end
    if not inOOCJail then return end

    local ped = cache.ped
    if not ped or not DoesEntityExist(ped) then return end

    inOOCJail = false
    removeOOCZone()

    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(10) end

    local coords = clientConfig.oocjail.release
    SetEntityCoords(ped, coords.x, coords.y, coords.z - 0.9, 0, 0, 0, false)

    Wait(500)
    DoScreenFadeIn(1000)

    lib.notify({
        description = 'Anda telah bebas dari jail OOC.',
        type = 'success'
    })
end)

RegisterNetEvent('sm_prison:openManageMenu', function()
    if source == '' then return end

    local locations = {}
    for location in pairs(clientConfig.prison_handler) do
        locations[#locations + 1] = location
    end

    if #locations == 1 then
        return prisonerMenu(locations[1])
    end

    local options = {}
    for i = 1, #locations do
        local location = locations[i]
        options[i] = {
            title = location,
            icon = 'fas fa-building',
            onSelect = function()
                prisonerMenu(location)
            end
        }
    end

    lib.registerContext({
        id = 'prisoner:contextLocationMenu',
        title = 'Pilih Penjara',
        options = options
    })
    lib.showContext('prisoner:contextLocationMenu')
end)

exports('inOOCJail', function()
    return inOOCJail
end)

CreateThread(function()
    lib.table.forEach(clientConfig.blip, function(val)
        local prisonMainBlip = AddBlipForCoord(val.coords.x, val.coords.y, val.coords.z)
        SetBlipSprite(prisonMainBlip, 189)
        SetBlipDisplay(prisonMainBlip, 2)
        SetBlipScale(prisonMainBlip, 1.0)
        SetBlipAsShortRange(prisonMainBlip, true)
        SetBlipColour(prisonMainBlip, 3)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(val.label)
        EndTextCommandSetBlipName(prisonMainBlip)
    end)

    for k, v in pairs(clientConfig.prison_handler) do
        for i = 1, #v do
            local c = v[i]
            ox_target:addSphereZone({
                coords = c.xyz,
                radius = 0.5,
                options = {
                    {
                        label = 'Manage Prisoner',
                        icon = 'fas fa-user',
                        distance = 1.5,
                        onSelect = function()
                            local job = QBPlayerData.job.name
                            if not permission[job] then return end
                            prisonerMenu(k)
                        end
                    }
                }
            })
        end
    end
end)