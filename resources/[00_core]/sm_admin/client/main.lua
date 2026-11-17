local qb_jobs = qb_core:GetSharedJobs()
local default_data = require 'config.default'

local job_input = {}
local grade_input = {}

for k, v in pairs(qb_jobs) do
    job_input[#job_input+1] = {
        label = v.label, value = k
    }

    local input = {}
    for grade, data in pairs(v.grades) do
        input[#input+1] = {
            label = ('%s (%s)'):format(data.name, grade), value = grade
        }
    end

    grade_input[k] = input
end

local function openAdmin()
    local garages = {}
    for label in pairs(garage:GetGarages()) do
        garages[#garages+1] = {
            label = label,
            value = label
        }
    end

    SendNUIMessage({
        action = 'setVisible',
        data = {
            visible = true,
            vehicles = default_data.vehicles,
            items = default_data.items,
            garages = garages,
            peds = default_data.peds,
            jobs = job_input,
            job_grades = grade_input
        }
    })
    SetNuiFocus(true, true)
end

RegisterNetEvent('sm_admin:openMenu', function(data)
    -- server will send net id `65535` for events from the server
    if source ~= 65535 then return end

    openAdmin()
end)

lib.addKeybind({
    name = 'open_admin',
    description = 'Open Admin Menu',
    defaultKey = 'PageDown',
    onPressed = function(self)
        local havePermissions = lib.callback.await('sm_admin:havePermissions', 500, {
            perms = 'admin'
        })

        if not havePermissions then
            lib.notify({
                description = 'Kamu tidak memiliki permissions untuk melakukan ini.',
                type = 'error'
            })
            return
        end

        openAdmin()
    end,
})