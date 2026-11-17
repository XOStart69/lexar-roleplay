local config = localmodule 'config.client'

CreateThread(function ()
    for k, v in pairs(config) do
        for label, data in pairs(v) do
            exports.ox_target:addSphereZone({
                coords = data.coords,
                radius = 1.5,
                options = {
                    {
                        label = label,
                        icon = 'fa-solid fa-person-walking-arrow-right',
                        distance = 0.5,
                        groups = data.groups,
                        onSelect = function ()
                            DoScreenFadeOut(500)
                            Wait(1000)
                            SetEntityCoords(cache.ped, data.toCoords.x, data.toCoords.y, data.toCoords.z, false, false, false, false)
                            SetEntityHeading(cache.ped, data.toCoords.w)
                            Wait(1000)
                            DoScreenFadeIn(600)
                        end
                    }
                }
            })
        end
    end
end)