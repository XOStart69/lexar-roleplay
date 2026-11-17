local pedExist = {}

local interact = cfg.rhd_interact and
                    exports.rhd_interact or exports.ox_target

---@param key string
---@param model string
---@param coords vector4
---@param groups string|string[]|table<string, number|number[]>
---@return integer? PedHandle
local function setupPed(key, model, coords, groups)
    model = qbLib.safecall(lib.requestModel, model, 1500)

    if not model then return end

    local ped = CreatePed(0, model --[[@as integer]], coords.x, coords.y, coords.z -1, coords.w, false, false)
    
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetEntityInvincible(ped, true)
    SetEntityProofs(ped, true, true, true, true, true, true, true, true)
    FreezeEntityPosition(ped, true)
    SetModelAsNoLongerNeeded(model)

    local options_1 = {
        label = 'Access vehicle shop',
        icon = 'fas fa-car',
        onSelect = function ()
            Client.openShop(key)
        end,
        groups = groups,
        distance = 2.5,
    }

    if cfg.rhd_interact then
        options_1.progress = {
            duration = 500
        }
        options_1.distance = 5.0
    end

    local options_2 = {
        label = 'Vehicle installment',
        icon = 'fas fa-file-invoice',
        onSelect = function ()
            Client.openInstallmentUI()
        end,
        groups = groups,
        distance = options_1.distance
    }

    pedExist[#pedExist+1] = ped
    interact:addLocalEntity(ped, { options_1, options_2 })

    return ped
end

CreateThread(function()
    for _, v in pairs(cfg.shops) do
        if v.ped and v.ped.model and v.ped.coords then
            local coords = v.ped.coords

            local points = lib.points.new(coords, 5, {
                pedEntity = nil
            })
            
            
            function points:onEnter()
                if not (self.pedEntity and DoesEntityExist(self.pedEntity)) then
                    self.pedEntity = setupPed(_, v.ped.model, v.ped.coords, v.groups)
                end
            end
            
            function points:onExit()
                if self.pedEntity and DoesEntityExist(self.pedEntity) then
                    pcall(DeleteEntity, self.pedEntity)
                end

                self.pedEntity = nil
            end
            
            qbLib.blip.Add({
                coords = coords,
                sprite = v.blip.sprite,
                color = v.blip.color,
                label = v.label
            })
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        for i=1, #pedExist do
            local entity = pedExist[i]
            qbLib.safecall(DeleteEntity, entity)
        end
    end
end)