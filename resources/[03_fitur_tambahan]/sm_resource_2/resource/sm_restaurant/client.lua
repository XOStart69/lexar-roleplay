local config = localmodule 'config'
local interact = exports.rhd_interact

local DISTANCE = config.interactDistance
local PED_ANIM = { dict = 'amb@code_human_in_bus_passenger_idles@female@tablet@idle_a', anim = 'idle_a', flag = 63 }
local PED_PROP = { propModel = 'prop_cs_tablet', bone = 28422, rot = vec3(0.0, 0.0, 0.03), pos = vec3(0.0, 0.0, 0.03) }

---@param description string
---@param kind? string
local function notify(description, kind)
    lib.notify({ description = description, type = kind or 'error' })
end

---@param jobName string
local function openGoods(jobName)
    ox_inventory:openInventory('shop', { type = jobName .. '-goods' })
end

---@param jobName string
---@param job table
local function changeStatus(jobName, job)
    local input = lib.inputDialog(job.label, {
        {
            type = 'select',
            label = job.label .. ' status',
            required = true,
            options = {
                { value = 'open', label = 'Buka' },
                { value = 'closed', label = 'Tutup' },
            },
        },
    })
    if not input then return end

    if lib.callback.await('sm_restaurant:setAutoShop', false, jobName, input[1] == 'closed') then
        notify(input[1] == 'closed' and 'Toko ditutup, pembeli memesan lewat menu.' or 'Toko dibuka, pesanan diambil di meja.', 'success')
    else
        notify('Gagal mengubah status toko.')
    end
end

---@param jobName string
---@param job table
---@return table[]
local function managementOptions(jobName, job)
    local groups = { [jobName] = 0 }
    local options = {}

    if not job.disableDuty then
        options[#options + 1] = {
            label = 'On/Off Duty',
            icon = 'cutlery',
            groups = groups,
            distance = DISTANCE,
            onSelect = function() TriggerServerEvent('QBCore:ToggleDuty') end,
        }
    end

    options[#options + 1] = {
        label = 'Status Toko',
        icon = 'cutlery',
        groups = groups,
        distance = DISTANCE,
        onSelect = function() changeStatus(jobName, job) end,
    }

    options[#options + 1] = {
        label = 'Toko Bahan',
        icon = 'cutlery',
        groups = { [jobName] = job.minGrade or 0 },
        distance = DISTANCE,
        onSelect = function() openGoods(jobName) end,
    }

    return options
end

---@param jobName string
---@param job table
local function addTray(jobName, job)
    interact:addCoords({
        id = 'sm_restaurant_tray_' .. jobName,
        coords = job.tray.coords,
        options = {
            {
                label = 'Open Table ' .. job.label,
                icon = 'cutlery',
                distance = DISTANCE,
                onSelect = function()
                    if lib.callback.await('sm_restaurant:isAutoShop', false, jobName) then
                        ox_inventory:openInventory('shop', { type = jobName .. '-shop' })
                    else
                        ox_inventory:openInventory('stash', job.tray.id)
                    end
                end,
            },
        },
    })
end

---@param jobName string
---@param job table
local function addManagement(jobName, job)
    if job.peds then
        for i = 1, #job.peds do
            local ped = job.peds[i]
            local options = ped.type == 'shop' and {
                {
                    label = 'Toko Bahan',
                    icon = 'cutlery',
                    groups = { [jobName] = job.minGrade or 0 },
                    distance = DISTANCE,
                    onSelect = function() openGoods(jobName) end,
                },
            } or managementOptions(jobName, job)

            exports[cache.resource]:addPed({
                model = ped.model,
                coords = { ped.coords },
                renderDistance = 30.0,
                animation = PED_ANIM,
                prop = PED_PROP,
                interactOptions = options,
            })
        end
        return
    end

    local coords = job.interact_coords
    if not coords then return end
    if type(coords) == 'vector3' then coords = { coords } end

    for i = 1, #coords do
        interact:addCoords({
            id = ('sm_restaurant_manage_%s_%d'):format(jobName, i),
            coords = coords[i],
            options = managementOptions(jobName, job),
        })
    end
end

CreateThread(function()
    for jobName, job in pairs(config.jobs) do
        addTray(jobName, job)
        addManagement(jobName, job)
    end
end)
