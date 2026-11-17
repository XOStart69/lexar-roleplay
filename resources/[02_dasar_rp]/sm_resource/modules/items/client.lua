local items = {}

function items.has_count(name, count)
    return ox_inventory:GetItemCount(name) >= (count or 1)
end

function items.checkRequired(required)
    local _tr = type(required)
    local missing = {}

    if _tr == 'string' then
        local count = 1
        local haveItems = items.has_count(required, count)

        if not haveItems then
            missing[#missing+1] = ('x%s %s'):format(count, ox_items[required]?.label or required)
        end
    elseif _tr == 'table' then
        if array.isArray(required) then
            array.forEach(required, function (val)
                local count = 1
                local haveItems = items.has_count(val, count)

                if not haveItems then
                    missing[#missing+1] = ('x%s %s'):format(count, ox_items[val]?.label or val)
                end
            end)
        else
            for name, count in pairs(required) do
                local haveItems = items.has_count(name, count)

                if not haveItems then
                    missing[#missing+1] = ('x%s %s'):format(count, ox_items[name]?.label or name)
                end
            end
        end
    end

    if #missing > 0 then
        lib.notify({
            description = ('Kamu membutuhkan (%s)'):format(table.concat(missing, ', '))
        })
        return false
    end

    return true
end

return items