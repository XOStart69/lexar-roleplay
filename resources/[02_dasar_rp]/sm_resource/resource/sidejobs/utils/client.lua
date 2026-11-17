local f = {}

-- Each side job gets its own collapsible category/header on the pause-menu map.
-- IDs must be globally unique across all resources (1-10 = GTA builtin,
-- 12-22 = bcs_housing, 23-25 = gudang/lahan/animalfarm).
local BLIP_CATEGORIES = {
    Lumberjack = { id = 26, name = 'Lumberjack' },
    Tailor     = { id = 27, name = 'Tailor' },
    OilWorker  = { id = 28, name = 'Oil Worker' },
    Recycle    = { id = 29, name = 'Recycle' },
    Mining     = { id = 30, name = 'Mining' },
}

---@param data table blip data (coords, sprite, color, scale, label)
---@param group? string side-job group name used to resolve the blip category
function f.createBlip(data, group)
    if not data.coords then return end
    local coords = data.coords
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, data.sprite)
    SetBlipColour(blip, data.color)
    SetBlipScale(blip, data.scale)
    SetBlipAsShortRange(blip, true)

    local category = group and BLIP_CATEGORIES[group]
    local label = data.label

    if category then
        AddTextEntry('BLIP_CAT_' .. category.id, category.name)
        SetBlipCategory(blip, category.id)
        -- header already shows the job name, drop the "Job - " prefix on the map
        label = (label:gsub('^.- %- ', ''))
    end

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(label)
    EndTextCommandSetBlipName(blip)
    return blip
end

function f.checkRequired(weapons, items)
    if weapons and cache.weapon ~= joaat(weapons) then
        return lib.notify({
            description = ('Kamu harus membutuhkan %s untuk melakukan ini.'):format(
                ox_items[weapons:upper()]?.label or weapons
            ),
            type = 'error'
        })
    end

    if items then
       local mi = {}
        for i, c in pairs(items) do
            local count = ox_inventory:GetItemCount(i)

            if count < c then
                mi[#mi+1] = ('x%s %s'):format(c, ox_items[i]?.label or i)
            end
        end

        if #mi > 0 then
            return lib.notify({
                description = ('Kamu membutuhkan (%s)'):format(table.concat(mi, ', ')),
                type = 'error'
            })
        end

        return true
    end

    return true
end

function f.loadModel(model)
    local ok, response = pcall(function (...)
        return lib.requestModel(model, 15000)
    end)

    if not ok and response then
        lib.print.warn(response)
    end

    return ok and response
end

return f