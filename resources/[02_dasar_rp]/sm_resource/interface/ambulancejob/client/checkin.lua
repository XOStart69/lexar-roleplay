local npcmodule = require 'modules.pedHandle.client'

local checkinloc = localmodule 'data.checkin'
local location = localmodule 'data.locations'
local config = localmodule 'config.client'

local function checkin(checkinId)
    local success = lib.progressBar({
        duration = 2000,
        label = 'Checking in...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true
        },
        anim = {
            dict = 'missheistdockssetup1clipboard@base',
            clip = 'base',
            flag = 33,
        },
        model = {
            {
                model = 'prop_notepad_01',
                bone = 18905,
                pos = vec(0.1, 0.02, 0.05),
                rot = vec(10.0, 0.0, 0.0),
            },
            {
                model = 'prop_pencil_01',
                bone = 58866,
                pos = vec(0.11, -0.02, 0.001),
                rot = vec(-120.0, 0.0, 0.0),
            }
        }
    })

    if not success then return end
    TriggerTokenEvent('ambulance:bed:send_checkin', checkinId)
end

local function treatment(checkinId)
    local success = lib.progressBar({
        duration = 2000,
        label = 'Mendaftar treatment...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true
        },
        anim = {
            dict = 'missheistdockssetup1clipboard@base',
            clip = 'base',
            flag = 33,
        },
        model = {
            {
                model = 'prop_notepad_01',
                bone = 18905,
                pos = vec(0.1, 0.02, 0.05),
                rot = vec(10.0, 0.0, 0.0),
            },
            {
                model = 'prop_pencil_01',
                bone = 58866,
                pos = vec(0.11, -0.02, 0.001),
                rot = vec(-120.0, 0.0, 0.0),
            }
        }
    })

    if not success then return end
    TriggerTokenEvent('ambulance:bed:send_treatment', checkinId)
end

CreateThread(function()
    array.forEach(checkinloc, function (val)
        if val.model and IsModelInCdimage(val.model) then
            val.target = val.target and array.map(val.target, function (data, index)
                data.onSelect = function ()
                    checkin(val.checkinId)
                end
                return data
            end)

            if val.target then
                table.insert(val.target, {
                    label = 'Treatment $' .. (val.treatmentCost or 34000),
                    icon = 'fas fa-heart',
                    distance = 1.5,
                    canInteract = function()
                        return not playerState.inMedicBed
                    end,
                    onSelect = function()
                        treatment(val.checkinId)
                    end
                })
            end

            local points = lib.points.new(val.coords.xyz, 25, {
                pedentity = nil
            })

            function points:onEnter()
                if not (self.pedentity and self.pedentity:exists()) then
                    self.pedentity = npcmodule:new(val)
                end
            end

            function points:onExit()
                if self.pedentity and self.pedentity:exists() then
                    self.pedentity:remove()
                end
                self.pedentity = nil
            end
        else
            exports.rhd_interact:addCoords({
                coords = val.coords.xyz,
                options = {
                    {
                        label = 'Check In $' .. config.billCost,
                        icon = 'fa fa-clipboard',
                        distance = 3.0,
                        onSelect = function()
                            checkin(val.checkinId)
                        end,
                        canInteract = function(_, distance)
                            return not playerState.inMedicBed
                        end
                    },
                    {
                        label = 'Treatment $' .. (val.treatmentCost or 34000),
                        icon = 'fas fa-heart',
                        distance = 3.0,
                        canInteract = function()
                            return not playerState.inMedicBed
                        end,
                        onSelect = function()
                            treatment(val.checkinId)
                        end
                    }
                }
            })
        end
    end)
end)