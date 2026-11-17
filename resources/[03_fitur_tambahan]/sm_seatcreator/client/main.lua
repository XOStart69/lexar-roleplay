local SitBusy = false
local SitEmote = false

local RHD = {
    functions = require "modules.utils",
    TargetZoneData = require "data.target",
    TargetZoneCreated = {}
}

local function checkCancelKlicked ()
    local sleep = 100
    
    if SitBusy then
        sleep = 0

        DisableControlAction(0, 73, true)

        if IsDisabledControlJustPressed(0, 73) then
            lib.hideTextUI()
            SetEntityCollision(cache.ped, true, true)
            FreezeEntityPosition(cache.ped, false)

            if SitEmote and LocalPlayer.state.isInAnimation then
                TriggerEvent('animations:client:EmoteCommandStart', { 'c' })
            end
            SitEmote = false

            ClearPedTasks(cache.ped)
            SitBusy = false
        end
    end

    return sleep
end

local function Setting ( Id )
    lib.registerContext({
        id = 'rhd_animplacer:Setting',
        title = 'seat Creator - Setting',
        options = {
            {
                title = 'Edit Location',
                description = '',
                icon = "map-location-dot",
                onSelect = function(args)
                    RHD.functions.StartPlacer({
                        type = "edit_location",
                        generated = function ( data )
                           local data = data
                          
                           RHD.TargetZoneData[Id].TargetCoords = data.tCoords
                           RHD.TargetZoneData[Id].TargetRadius = data.radius
                           TriggerServerEvent("rhd_animplacer:server:saveData", RHD.TargetZoneData, true)
                        end
                    })
                end,
            },
            {
                title = 'Remove Location',
                description = '',
                icon = "trash",
                onSelect = function(args)
                    RHD.TargetZoneData[Id] = nil
                    TriggerServerEvent("rhd_animplacer:server:saveData", RHD.TargetZoneData, true)
                end,
            },
            {
                title = 'Add Options',
                description = '',
                icon = "plus",
                onSelect = function(args)
                    RHD.functions.StartPlacer({
                        type = "create_location",
                        generated = function ( data )
                           local data = data

                           local input = lib.inputDialog('RHD FiveM', {
                            { type = 'input', label = 'Target Label', placeholder = 'Duduk Yuk', required = true, min = 1 },
                            { type = 'input', label = 'Target Icon', placeholder = 'fas fa-chair', required = true, min = 1 },
                           })
                
                           if input then
                                if input[1]:len() < 1 then
                                    return
                                end
                
                                if input[2]:len() < 1 then
                                    return
                                end
                
                                RHD.TargetZoneData[Id].Options[#RHD.TargetZoneData[Id].Options+1] = {
                                    PlayerCoords = data.pCoords,
                                    TargetLabel = input[1],
                                    TargetIcon = input[2],
                                    Animation = data.anim
                                }
                                TriggerServerEvent("rhd_animplacer:server:saveData", RHD.TargetZoneData, true)
                           end
                        end
                    })
                end,
            },
            {
                title = 'Remove Options',
                description = '',
                icon = "minus",
                onSelect = function(args)
                    local ContextOptions = {}
                    local OptionsData = RHD.TargetZoneData[Id].Options

                    for _, data in pairs(OptionsData) do
                        ContextOptions[#ContextOptions+1] = {
                            title = data.TargetLabel,
                            icon = data.TargetIcon,
                            onSelect = function ()
                                RHD.TargetZoneData[Id].Options[_] = nil
                                TriggerServerEvent("rhd_animplacer:server:saveData", RHD.TargetZoneData, true)
                                -- exports.rhd_notify:send("The target option has been removed", "success", 8000)
                            end
                        }
                    end

                    lib.registerContext({
                        id = 'rhd_animplacer:setting:removeOption',
                        title = 'Remove Options',
                        menu = "rhd_animplacer:Setting",
                        onBack = function ()
                            
                        end,
                        options = ContextOptions,
                    })
                    lib.showContext("rhd_animplacer:setting:removeOption")
                end,
            },
        },
    })
    lib.showContext("rhd_animplacer:Setting")
end

local function LoadTarget ( data, Edit )

    data = data or RHD.TargetZoneData

    if Edit then
        for k, v in pairs(RHD.TargetZoneCreated) do
            exports.ox_target:removeZone(RHD.TargetZoneCreated[k])
            RHD.TargetZoneCreated[k] = nil
        end
    end

    for k,v in pairs(data) do
        if not RHD.TargetZoneCreated[k] then
            local options = {
                -- {
                --     label = "Setting",
                --     icon = "fas fa-gear",
                --     onSelect = function ()
                --         Setting(k)
                --     end
                -- }
            }

            for _, data in pairs(v.Options) do
                options[#options+1] = {
                    label = data.TargetLabel,
                    icon = data.TargetIcon,
                    onSelect = function( ... )
                        if SitBusy then return end
                        SetEntityCollision(cache.ped, false, false)
                        FreezeEntityPosition(cache.ped, true)
                        SetEntityCoords(cache.ped, data.PlayerCoords.xy, data.PlayerCoords.z - 1)
                        SetEntityHeading(cache.ped, data.PlayerCoords.w)
                        lib.requestAnimDict(data.Animation.dict)
                        TaskPlayAnim(cache.ped, data.Animation.dict, data.Animation.clip, 2.0, 2.0, -1, 1, 0, false, false, false)

                        SitEmote = false
                        if data.Emote then
                            Wait(200)
                            TriggerEvent('animations:client:EmoteCommandStart', { data.Emote })
                            SitEmote = true
                        end

                        lib.showTextUI('[X] - Berdiri', {
                            position = 'bottom-center'
                        })
                        SitBusy = true
                    end
                }
            end
            
            RHD.TargetZoneCreated[k] = exports.ox_target:addSphereZone({
                coords = v.TargetCoords.xyz,
                radius = v.TargetRadius,
                debug = false,
                options = options
            })
        end
    end
end

local function StartPlacer ()
    RHD.functions.StartPlacer({
        type = "create_location",
        generated = function ( data )
           local data = data
           data.id = ("rhd_%s"):format(RHD.functions.GenerateId(math.random(5, 10)))

           local input = lib.inputDialog('RHD AP', {
            { type = 'input', label = 'Target Label', placeholder = 'Duduk Yuk', required = true, min = 1 },
            { type = 'input', label = 'Target Icon', placeholder = 'fas fa-chair', required = true, min = 1 },
           })

           if input then
                if input[1]:len() < 1 then
                    return
                end

                if input[2]:len() < 1 then
                    return
                end

                if not RHD.TargetZoneData[data.id] then
                    RHD.TargetZoneData[data.id] = {
                        TargetCoords = data.tCoords,
                        TargetRadius = data.radius,
                        Options = {
                            {
                                PlayerCoords = data.pCoords,
                                TargetLabel = input[1],
                                TargetIcon = input[2],
                                Animation = data.anim
                            }
                        }
                    }
                    TriggerServerEvent("rhd_animplacer:server:saveData", RHD.TargetZoneData)
                end
           end
        end
    })
end

CreateThread(function ()
    while true do
        Wait(checkCancelKlicked())
    end
end)

RegisterNetEvent('rhd_animplacer:client:start', StartPlacer)
RegisterNetEvent('rhd_animplacer:client:sync', LoadTarget)

AddEventHandler('QBCore:Client:OnPlayerLoaded', LoadTarget)
AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        LoadTarget()
    end
end)