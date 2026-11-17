---@diagnostic disable: undefined-field

local ce = {}
local ci = {}

local pd = {
    nextTip = 0,
    deliver = 0,
    rewards = 0,
    finish = false
}

local cl
local dt
local interval

local mi = [[
Tip     : $%s
Total Tips: $%s
Pizzas Delivered: %s/%s

Time Left : %s
]]


local pedlist = require 'resource.rhd_pizzadelivery.data.peds'
local sharedConfig = require 'resource.rhd_pizzadelivery.config.shared'

local timer = require 'modules.timers.shared'
local pedModule = require 'modules.pedHandle.client'
local blipModule = require 'modules.blipHandle.client'


local function cVehicle(model, coords, warp)
    if not pcall(lib.requestModel, model) then
        return
    end

    ce.veh = CreateVehicle(
        model, coords.x, coords.y, coords.z, coords.w, true, true
    )

    SetVehicleHasBeenOwnedByPlayer(ce.veh, true)
    SetVehicleFixed(ce.veh)
    SetVehicleOnGroundProperly(ce.veh)
    SetVehicleFuelLevel(ce.veh, 100.0)
    SetEntityAsMissionEntity(ce.veh, true, true)
    
    if warp then
        TaskWarpPedIntoVehicle(cache.ped, ce.veh, -1)
    end
end

local function carryAnim (ped)
    local Ped = ped or cache.ped
    lib.requestAnimDict("anim@heists@box_carry@")
    TaskPlayAnim(Ped, 'anim@heists@box_carry@', 'idle', 5.0, -1, -1, 50, 0, false, false, false)

    if ce.pih and DoesEntityExist(ce.pih) then
        AttachEntityToEntity(ce.pih, Ped, GetPedBoneIndex(Ped, 57005), 0.22, 0.04, -0.20, -58.11, -111.12, 12.22, true, true, false, true, 1, true)
    end

    CreateThread(function()
        while ce.pih do
            Wait(0)
            if not IsEntityPlayingAnim(Ped, 'anim@heists@box_carry@', 'idle', 3) then
                TaskPlayAnim(Ped, 'anim@heists@box_carry@', 'idle', 8.0, 8.0, -1, 50, 0, false, false, false)
            end
        end
    end)
end

local function onJobEnd()
    for key, instance in pairs(ci) do
        if instance then
            if type(instance) == "table" then
                if #instance > 0 then
                    for i = 1, #instance do
                        if instance[i] and type(instance[i]) == "table" and instance[i].remove then
                            pcall(function()
                                instance[i]:remove()
                            end)
                        end
                    end
                else
                    if instance.remove then
                        pcall(function()
                            instance:remove()
                        end)
                    end
                end
            end
        end
    end

    local notify = false

    if ce.pih then
        pcall(function()
            DeleteEntity(ce.pih)
        end)
        notify = true
    end

    if ce.piv and #ce.piv > 0 then
        for i = 1, #ce.piv do
            pcall(function()
                if DoesEntityExist(ce.piv[i]) then
                    DetachEntity(ce.piv[i], true, true)
                    DeleteEntity(ce.piv[i])
                end
            end)
        end
        notify = true
    end

    if notify then
        lib.notify({
            description = 'Kamu gagal mengantarkan semua pizza!',
            type = 'error',
            duration = 8000
        })
    end

    infoUI.remove('pizza_delivery')

    if interval then
        ---@diagnostic disable-next-line: undefined-global
        ClearInterval(interval)
    end

    ci = {}
    ce.piv = {}

    dt = nil
    ce.pih = nil
    interval = nil
end

local function prepareTimer(time, total)
    local info = {
        id = 'pizza_delivery',
        title = 'Pizza delivery',
        icon = 'fas fa-pizza-slice',
        description = mi:format(
            pd.nextTip, pd.rewards, pd.deliver, total, '-'
        )
    }

    infoUI.show(info)

    dt = timer:new('menit', 15, onJobEnd)

    ---@diagnostic disable-next-line: undefined-global
    interval = SetInterval(function ()
        if dt then
            info.description = mi:format(
                pd.nextTip, pd.rewards, pd.deliver, total, dt:getTimeLeftFormat()
            )
            infoUI.show(info)
        end
    end, 500)
end

local function updateTip(t)
    local tt = type(t)

    if tt == "table" then
        t.min = t.min or 1
        t.max = t.max or t.min * 2
        pd.nextTip = math.random(t.min, t.max)
    else
        pd.nextTip = t
    end
end

local function createLocation(location)
    local cfg = sharedConfig[location]
    if not cfg then return end

    local dd = cfg.delivery
    local dl = dd.locations

    if not ci.p then
        ci.p = {}
    end

    if not ci.b then
        ci.b = {}
    end

    for i=1, #dl do
        local coords = dl[i]

        ci.b[i] = blipModule:new({
            coords = coords.xyz,
            label = 'Pizza delivery location',
            sprite = 1,
            color = 60,
            short = false
        })

        ci.p[i] = lib.points.new({
            coords = coords.xyz,
            distance = 10.0,
            onExit = function ()
                if ci.c then 
                    pcall(function()
                        ci.c:remove()
                    end)
                    ci.c = nil 
                end
            end,
            onEnter = function ()
                if ci.c then 
                    pcall(function()
                        ci.c:remove()
                    end)
                    ci.c = nil 
                end
                
                ci.c = pedModule:new({
                    model = pedlist[math.random(#pedlist)],
                    coords = vec(coords.x, coords.y, coords.z, coords.w),
                    fadeIn = true,
                    target = {
                        {
                            label = 'Berikan pizza',
                            icon = 'fas fa-pizza-slice',
                            distance = 1.0,
                            canInteract = function()
                                return ce.pih
                            end,
                            onSelect = function ()
                                local success = lib.progressBar({
                                    duration = 5000,
                                    label = 'Memberikan pizza',
                                    useWhileDead = true,
                                    canCancel = false,
                                    disable = {
                                        move = true,
                                        car = true,
                                        combat = true
                                    },
                                })

                                if not success then return end
                                DetachEntity(ce.pih, true, true)

                                local ped = ci.c:getEntity()
                                lib.playAnim(ped, 'anim@heists@box_carry@', 'idle', 5.0, -1, -1, 50, 0, false, false, false)
                                AttachEntityToEntity(ce.pih, ped, GetPedBoneIndex(ped, 57005), 0.22, 0.04, -0.20, -58.11, -111.12, 12.22, true, true, false, true, 1, true)
                                
                                pd.deliver += 1
                                pd.rewards += pd.nextTip

                                lib.notify({
                                    description = ('Kamu mendapatkan tip $%s dari customer'):format(pd.nextTip),
                                    type = 'success'
                                })

                                updateTip(dd.customerTip)
                                
                                Wait(500)
                                
                                pcall(function()
                                    DeleteEntity(ce.pih)
                                    ce.pih = nil
                                end)

                                StopAnimTask(cache.ped, 'anim@heists@box_carry@', 'idle', 1.0)
                             
                                if ci.c then
                                    pcall(function()
                                        ci.c:remove()
                                    end)
                                end
                                
                                if ci.p[i] then
                                    pcall(function()
                                        ci.p[i]:remove()
                                    end)
                                end
                                
                                if ci.b[i] then
                                    pcall(function()
                                        ci.b[i]:remove()
                                    end)
                                end

                                ci.c = nil
                                ci.p[i] = nil
                                ci.b[i] = nil
                                
                                if pd.deliver >= #dl then
                                    lib.notify({
                                        description = 'Kamu telah mengantarkan semua pizza dengan baik, kembali ke toko dan minta upah kamu.',
                                        type = 'success',
                                        duration = 12000
                                    })

                                    Wait(100)
                                    pd.finish = true
                
                                    if dt then
                                        dt:stop(true)
                                    end
                                end

                            end
                        }
                    }
                })
            end
        })
    end
end

local function startDelivery(location)
    local config = sharedConfig[location]

    local dv = config.vehicle
    local dd = config.delivery
    local dl = dd.locations

    pd = {
        nextTip = 0,
        deliver = 0,
        rewards = 0,
        finish = false
    }

    cVehicle(dv.model, dv.coords, true)
    local plate = GetVehicleNumberPlateText(ce.veh):trim()
    TriggerEvent("sm_vehiclekeys:client:setVehicleOwner", plate)

    local rearSeat = GetEntityBoneIndexByName(ce.veh, "seat_r")
    local coords = GetWorldPositionOfEntityBone(ce.veh, rearSeat)
    local propModel = joaat("prop_pizza_box_02")

    ce.piv = {}
    for i=1, #dl do
        local prefixZ = #ce.piv / 12
        ce.piv[#ce.piv+1] = CreateObject(propModel, coords.x, coords.y, coords.z, true, true, true)
        AttachEntityToEntity(ce.piv[#ce.piv], ce.veh, rearSeat, 0.0, -0.1, -0.1+prefixZ, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
    end

    cl = location
    updateTip(dd.customerTip)
    prepareTimer(dd.time, #dl)
    createLocation(location)
end

CreateThread(function ()
    for k, v in pairs(sharedConfig) do
        if v.ped then
            pedModule:new({
                model = v.ped.model,
                coords = v.ped.coords,
                target = {
                    {
                        label = 'Start pizza delivery',
                        icon = 'fas fa-pizza-slice',
                        distance = 1.0,
                        canInteract = function ()
                            return not cl
                        end,
                        onSelect = function ()
                            startDelivery(k)
                        end
                    },
                    
                    {
                        label = 'Finish pizza delivery',
                        icon = 'fas fa-pizza-slice',
                        distance = 1.0,
                        canInteract = function ()
                            return cl
                        end,
                        onSelect = function ()
                            pd.finish = true
                            TriggerTokenEvent('rhd_pizzadelivery:giveMoney')

                            onJobEnd()
                            pcall(function()
                                if ce.veh and DoesEntityExist(ce.veh) then
                                    DeleteEntity(ce.veh)
                                end
                                ce.veh = nil
                            end)
                        end
                    }
                }
            })

            if v.blip then
                blipModule:new({
                    coords = v.ped.coords,
                    color = v.blip.color,
                    label = v.blip.label,
                    sprite = v.blip.sprite,
                    short = true
                })
            end
        end
    end
end)

CreateThread(function()
    ox_target:addGlobalVehicle({
        {
            name = "rhd_pizza:take",
            label = "Take Pizza",
            icon = "fas fa-hand",
            distance = 1.5,
            onSelect = function ()
                local boxId = #ce.piv
                local pizzaBox = ce.piv[boxId]

                table.remove(ce.piv, boxId)
                DetachEntity(pizzaBox, true, true)

                ce.pih = pizzaBox
                carryAnim()
            end,
            canInteract = function (entity, distance)
                local pz = (ce.piv and #ce.piv) or 0
                return pz > 0 and not ce.pih and ce.veh == entity or false
            end
        },
        {
            name = "rhd_pizza:return",
            label = "Return Pizza",
            icon = "fas fa-hand",
            distance = 1.5,
            onSelect = function (data)
                local prefixZ = #ce.piv / 12

                pcall(function()
                    DetachEntity(ce.pih, true, true)
                end)

                local rearSeat = GetEntityBoneIndexByName(data.entity, "seat_r")
                ce.piv[#ce.piv+1] = ce.pih
                AttachEntityToEntity(ce.pih, data.entity, rearSeat, 0.0, -0.1, -0.1+prefixZ, 0.0, 0.0, 0.0, true, true, false, true, 1, true)

                ce.pih = nil
                StopAnimTask(cache.ped, 'anim@heists@box_carry@', 'idle', 1.0)
            end,
            canInteract = function (entity, distance)
                return ce.pih and ce.veh == entity or false
            end
        }
    })
end)

lib.callback.register('rhd_pizzadelivery:get', function()
    if not pd.finish then return end

    local l, d = cl, pd

    cl = nil
    pd = nil

    return {l, d}
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then

        pcall(function()
            if ce.veh and DoesEntityExist(ce.veh) then
                DeleteEntity(ce.veh)
            end
        end)

        if ce.piv and #ce.piv > 0 then
            for i=1, #ce.piv do
                pcall(function()
                    if DoesEntityExist(ce.piv[i]) then
                        DeleteEntity(ce.piv[i])
                    end
                end)
            end
        end

        pcall(function()
            if ce.pih and DoesEntityExist(ce.pih) then
                DeleteEntity(ce.pih)
            end
        end)
    end
end)