local locations = localmodule 'data.locations'
local interact = exports.rhd_interact

local gmatch = string.gmatch

local ids = {}

CreateThread(function()
    for key, coordsList in pairs(locations) do
        local jobs = {}

        for job in gmatch(key, '([^|]+)') do
            jobs[#jobs + 1] = job
        end

        for i = 1, #coordsList do
            local id = ('sm_duty:%s:%d'):format(key, i)
            ids[#ids + 1] = id

            interact:addCoords({
                id = id,
                coords = coordsList[i],
                options = {
                    {
                        label = 'On/Off Duty',
                        icon = 'fas fa-clipboard',
                        distance = 1.0,
                        groups = jobs,
                        onSelect = function()
                            TriggerServerEvent('QBCore:ToggleDuty')
                        end,
                    }
                }
            })
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    for i = 1, #ids do
        interact:removeCoords(ids[i])
    end
end)
