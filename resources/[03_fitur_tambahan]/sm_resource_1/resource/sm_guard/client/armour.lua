local config = localmodule 'config.shared'

local refillCfg = config.refill
local refillArmour = refillCfg.armour

---@param job string
---@param index integer
local function refill(job, index)
    if GetPedArmour(cache.ped) >= refillArmour then
        return lib.notify({ description = 'Armour sudah penuh', type = 'error' })
    end

    local done = lib.progressBar({
        duration = refillCfg.duration,
        label = 'Memakai armour',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            combat = true
        },
        anim = {
            dict = 'rick3d@weapons',
            clip = 'armorplate'
        },
        prop = {
            model = 'prop_armorplate',
            bone = 28422,
            pos = vec3(0.030, 0.010, -0.145),
            rot = vec3(-168.0, 96.0, 0.0)
        }
    })

    ClearPedTasksImmediately(cache.ped)

    if not done then return end

    if not lib.callback.await('sm_guard:refillArmour', false, job, index) then
        return lib.notify({ description = 'Refill armour gagal, coba lagi nanti', type = 'error' })
    end

    SetPedArmour(cache.ped, refillArmour)
    lib.notify({ description = 'Armour telah dipakai!', type = 'success' })
end

CreateThread(function()
    for job, points in pairs(refillCfg.points) do
        for i = 1, #points do
            exports.rhd_interact:addCoords({
                id = ('sm_guard_refill_%s_%d'):format(job, i),
                coords = points[i],
                options = {
                    {
                        name = 'sm_guard_refill',
                        label = 'Refill Armour',
                        icon = 'fas fa-vest',
                        distance = 1.5,
                        groups = { job },
                        onSelect = function()
                            refill(job, i)
                        end
                    }
                }
            })
        end
    end
end)
