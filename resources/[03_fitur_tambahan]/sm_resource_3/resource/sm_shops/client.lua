local shops = localmodule 'data.shops'

local blips = {}

---@param coords vector3
---@param blip { id: number, scale: number }
---@param label string
local function createBlip(coords, blip, label)
    local handle = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(handle, blip.id)
    SetBlipDisplay(handle, 2)
    SetBlipScale(handle, blip.scale)
    SetBlipAsShortRange(handle, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(label)
    EndTextCommandSetBlipName(handle)

    blips[#blips + 1] = handle
end

for shopType, shop in pairs(shops) do
    local points = shop.coords

    if points then
        for i = 1, #points do
            local coords = points[i]

            ox_target:addSphereZone({
                name = ('sm_shops:%s:%d'):format(shopType, i),
                coords = coords,
                radius = shop.radius or 1.5,
                options = {
                    {
                        label = shop.label or 'Open Shop',
                        icon = 'fas fa-basket-shopping',
                        groups = shop.groups,
                        distance = shop.distance,
                        onSelect = function()
                            ox_inventory:openInventory('shop', { type = shopType, id = i })
                        end
                    }
                }
            })

            if shop.blip then
                createBlip(coords, shop.blip, shop.label)
            end
        end
    end
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    for i = 1, #blips do
        RemoveBlip(blips[i])
    end
end)
