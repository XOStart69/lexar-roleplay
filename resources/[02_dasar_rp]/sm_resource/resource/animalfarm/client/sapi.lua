local isworking = false
local currentMode = 'manual' --[[@as 'manual' | 'automatic']]
local proccessStatus = 'none'

local config = localmodule 'config.sapi'
local pedModule = require 'modules.pedHandle.client'
local blipModule = require 'modules.blipHandle.client'
local itemModule = require 'modules.items.client'

local cowcfg = config.cow
local proccesscfg = config.proccess

local function setState(status, stage)
    isworking = status
    proccessStatus = stage or 'none'
    playerState.canEmote = not status
end

local function perahSusuTobrut(index)
    local items = cowcfg.item

    if not itemModule.checkRequired(items.remove) then
        return setState(false)
    end

    setState(true)

    local success = lib.progressBar({
        duration = 10000,
        label = 'Memerah susu...',
        canCancel = true,
        useWhileDead = false,
        disable = {
            move = true,
            car = true,
            combat = true
        },
        anim = cowcfg.anim
    })

    if success then
        setState(true, 'perah_success')
        TriggerTokenEvent('af:cowmilk', index)
    else
        currentMode = 'manual'
    end

    ClearPedTasks(cache.ped)

    if currentMode == 'automatic' then
        SetTimeout(1000, function ()
            perahSusuTobrut(index)
        end)
    else
        setState(false)
    end
end

local function proccessMilk(index)
    local items = proccesscfg[index].item

    if not itemModule.checkRequired(items.remove) then
        return setState(false)
    end

    setState(true)

    local success = lib.progressBar({
        duration = 15000,
        label = 'Memproses susu...',
        canCancel = true,
        useWhileDead = false,
        disable = {
            move = true,
            car = true,
            combat = true
        },
        anim = proccesscfg[index].anim
    })

    if success then
        setState(true, 'proccess_success')
        TriggerTokenEvent('af:cowmilkproccess', index)
    else
        currentMode = 'manual'
    end

    ClearPedTasks(cache.ped)

    if currentMode == 'automatic' then
        SetTimeout(1000, function ()
            proccessMilk(index)
        end)
    else
        setState(false)
    end
end

lib.callback.register('af:cowdata', function(source)
    local status = proccessStatus proccessStatus = 'none'
    return status
end)

CreateThread(function ()
    for i=1, #cowcfg.coords do
        local coords = cowcfg.coords[i]

        local cowpoints = lib.points.new(coords.xyz, 25, {
            entity = nil,
            config = {
                model = cowcfg.model,
                coords = coords,
                target = {
                    {
                        icon = 'fas fa-circle-info',
                        label = 'Perah susu',
                        distance = 1.5,
                        onSelect = function ()
                            currentMode = 'manual'
                            perahSusuTobrut(i)
                        end,
                        canInteract = function ()
                            return not isworking
                        end
                    },
                    {
                        icon = 'fas fa-circle-info',
                        label = 'Perah susu (automatic)',
                        distance = 1.5,
                        onSelect = function ()
                            currentMode = 'automatic'
                            perahSusuTobrut(i)
                        end,
                        canInteract = function ()
                            return not isworking
                        end
                    },
                }
            }
        })

        function cowpoints:onEnter()
            if not (self.entity and self.entity:exists()) then
                self.entity = pedModule:new(self.config)
            end
        end
        
        function cowpoints:onExit()
            if self.entity and self.entity:exists() then
                self.entity:remove()
            end
            self.entity = nil
        end
    end

    for i=1, #proccesscfg do
        local proccessData = proccesscfg[i]
        
        proccessData.boxzone.options = {
            {
                icon = 'fas fa-circle-info',
                label = 'Proses susu',
                distance = 1.5,
                onSelect = function ()
                    currentMode = 'manual'
                    proccessMilk(i)
                end,
                canInteract = function ()
                    return not isworking
                end
            },
            {
                icon = 'fas fa-circle-info',
                label = 'Proses susu (automatic)',
                distance = 1.5,
                onSelect = function ()
                    currentMode = 'automatic'
                    proccessMilk(i)
                end,
                canInteract = function ()
                    return not isworking
                end
            },
        }

        ox_target:addBoxZone(proccessData.boxzone)
    end

    if not config.blip then return end
    AddTextEntry("BLIP_CAT_" .. 25, "Animal Farmer")
    for _, blipdata in pairs(config.blip) do
        blipModule:new(blipdata)
    end
end)