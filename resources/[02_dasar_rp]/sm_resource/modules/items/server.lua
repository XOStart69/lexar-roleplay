local items = {}

function items.has_count(source, name, count)
    return ox_inventory:GetItemCount(source, name) >= (count or 1)
end

function items.add(source, ...)
    local canAdd = ox_inventory:CanCarryItem(source, ...)
    return canAdd and ox_inventory:AddItem(source, ...)
end

function items.remove(source, ...)
    return ox_inventory:RemoveItem(source, ...)
end

function items.checkRequired(source, required)
    local _tr = type(required)

    local missing = {}

    if _tr == 'string' then
        local count = 1
        local haveItems = items.has_count(source, required, count)

        if haveItems then
            missing[#missing+1] = ('x%s %s'):format(count, ox_items[required]?.label or required)
        end
    elseif _tr == 'table' then
        if array.isArray(required) then
            array.forEach(required, function (val)
                local count = 1
                local haveItems = items.has_count(source, val, count)

                if haveItems then
                    missing[#missing+1] = ('x%s %s'):format(count, ox_items[val]?.label or val)
                end
            end)
        else
            for name, count in pairs(required) do
                local inventory_count = ox_inventory:GetItemCount(source, name)

                if inventory_count < count then
                    missing[#missing+1] = ('x%s %s'):format(count, ox_items[name]?.label or name)
                end
            end
        end
    end

    if #missing > 0 then
        return lib.notify(source, {
            description = ('Kamu membutuhkan (%s)'):format(table.concat(missing, ', '))
        })
    end

    return true
end

---@class TransactionItemsData
---@field name string
---@field count? number
---@field metadata? any
---@field required? boolean

---@class TransactionItems
---@field add? string|string[]|table<string, number>|TransactionItemsData|TransactionItemsData[]
---@field remove? string|string[]|table<string, number>|TransactionItemsData|TransactionItemsData[]

---@param source number
---@param data TransactionItems
---@param giveBack? boolean
---@param notify? boolean
---@return boolean
function items.transaction(source, data, giveBack, notify)
    local removed = {}
    local added = {}
    local missing = {}
    local canProceed = true

    if data.remove then
        local _tr = type(data.remove)

        if _tr == 'string' then
            local success = items.remove(source, data.remove, 1)

            if success then
                removed[#removed+1] = { name = data.remove, count = 1 }
            else
                canProceed = false
                missing[#missing+1] = ('x%s %s'):format(1, ox_items[data.remove]?.label or data.remove)
            end
        elseif _tr == 'table' then
            if array.isArray(data.remove) then
                array.forEach(data.remove, function(val)
                    local _tv = type(val)

                    if _tv == 'string' then
                        local success = items.remove(source, val, 1)

                        if success then
                            removed[#removed+1] = { name = val, count = 1 }
                        else
                            canProceed = false
                            missing[#missing+1] = ('x%s %s'):format(1, ox_items[val]?.label or val)
                        end
                    elseif _tv == 'table' then
                        local success = items.remove(source, val.name, val.count or 1, val.metadata)

                        if success then
                            removed[#removed+1] = { name = val.name, count = val.count or 1, metadata = val.metadata }
                        else
                            missing[#missing+1] = ('x%s %s'):format(val.count or 1, ox_items[val.name]?.label or val.name)

                            if val.required then
                                if giveBack then
                                    for j = 1, #removed do
                                        items.add(source, removed[j].name, removed[j].count, removed[j].metadata)
                                    end
                                end

                                if notify then
                                    lib.notify(source, {
                                        description = ('Kamu membutuhkan (%s)'):format(table.concat(missing, ', '))
                                    })
                                end

                                return false
                            end
                            canProceed = false
                        end
                    end
                end)
            else
                local isKeyValueFormat = false
                local hasNameField = data.remove.name ~= nil
                
                if not hasNameField then
                    ---@diagnostic disable-next-line: param-type-mismatch
                    for k, v in pairs(data.remove) do
                        if type(k) == 'string' and type(v) == 'number' then
                            isKeyValueFormat = true
                            local success = items.remove(source, k, v)

                            if success then
                                removed[#removed+1] = { name = k, count = v }
                            else
                                canProceed = false
                                missing[#missing+1] = ('x%s %s'):format(v, ox_items[k]?.label or k)
                            end
                        end
                    end
                end

                if not isKeyValueFormat then
                    local success = items.remove(source, data.remove.name, data.remove.count or 1, data.remove.metadata)

                    if success then
                        removed[#removed+1] = { name = data.remove.name, count = data.remove.count or 1, metadata = data.remove.metadata }
                    else
                        missing[#missing+1] = ('x%s %s'):format(data.remove.count or 1, ox_items[data.remove.name]?.label or data.remove.name)

                        if data.remove.required then
                            if notify then
                                lib.notify(source, {
                                    description = ('Kamu membutuhkan (%s)'):format(table.concat(missing, ', '))
                                })
                            end

                            return false
                        end
                        canProceed = false
                    end
                end
            end
        end
    end

    if not canProceed then
        if giveBack then
            for j = 1, #removed do
                items.add(source, removed[j].name, removed[j].count, removed[j].metadata)
            end
        end

        if notify and #missing > 0 then
            lib.notify(source, {
                description = ('Kamu membutuhkan (%s)'):format(table.concat(missing, ', '))
            })
        end

        return false
    end

    if data.add then
        local _ta = type(data.add)

        if _ta == 'string' then
            local success = items.add(source, data.add, 1)

            if not success then
                missing[#missing+1] = ('x%s %s'):format(1, ox_items[data.add]?.label or data.add)

                if giveBack then
                    for j = 1, #removed do
                        items.add(source, removed[j].name, removed[j].count, removed[j].metadata)
                    end
                end

                if notify then
                    lib.notify(source, {
                        description = ('Gagal menambahkan (%s)'):format(table.concat(missing, ', '))
                    })
                end

                return false
            end
        elseif _ta == 'table' then
            if array.isArray(data.add) then
                local hasError = false

                array.forEach(data.add, function(val)
                    local _tv = type(val)

                    if _tv == 'string' then
                        local success = items.add(source, val, 1)

                        if not success then
                            missing[#missing+1] = ('x%s %s'):format(1, ox_items[val]?.label or val)
                            hasError = true
                        else
                            added[#added+1] = { name = val, count = 1 }
                        end
                    elseif _tv == 'table' then
                        local success = items.add(source, val.name, val.count or 1, val.metadata)

                        if not success then
                            missing[#missing+1] = ('x%s %s'):format(val.count or 1, ox_items[val.name]?.label or val.name)

                            if val.required then
                                hasError = true
                            end
                        else
                            added[#added+1] = { name = val.name, count = val.count or 1, metadata = val.metadata }
                        end
                    end
                end)

                if hasError then
                    if giveBack then
                        for j = 1, #added do
                            items.remove(source, added[j].name, added[j].count, added[j].metadata)
                        end
                        for j = 1, #removed do
                            items.add(source, removed[j].name, removed[j].count, removed[j].metadata)
                        end
                    end

                    if notify then
                        lib.notify(source, {
                            description = ('Gagal menambahkan (%s)'):format(table.concat(missing, ', '))
                        })
                    end

                    return false
                end
            else
                local isKeyValueFormat = false
                local hasNameField = data.add.name ~= nil
                local hasError = false
                
                if not hasNameField then
                    ---@diagnostic disable-next-line: param-type-mismatch
                    for k, v in pairs(data.add) do
                        if type(k) == 'string' and type(v) == 'number' then
                            isKeyValueFormat = true
                            local success = items.add(source, k, v)

                            if not success then
                                missing[#missing+1] = ('x%s %s'):format(v, ox_items[k]?.label or k)
                                hasError = true
                            else
                                added[#added+1] = { name = k, count = v }
                            end
                        end
                    end
                end

                if hasError then
                    if giveBack then
                        for j = 1, #added do
                            items.remove(source, added[j].name, added[j].count, added[j].metadata)
                        end
                        for j = 1, #removed do
                            items.add(source, removed[j].name, removed[j].count, removed[j].metadata)
                        end
                    end

                    if notify then
                        lib.notify(source, {
                            description = ('Gagal menambahkan (%s)'):format(table.concat(missing, ', '))
                        })
                    end

                    return false
                end

                if not isKeyValueFormat then
                    local success = items.add(source, data.add.name, data.add.count or 1, data.add.metadata)

                    if not success then
                        missing[#missing+1] = ('x%s %s'):format(data.add.count or 1, ox_items[data.add.name]?.label or data.add.name)

                        if data.add.required then
                            if giveBack then
                                for j = 1, #removed do
                                    items.add(source, removed[j].name, removed[j].count, removed[j].metadata)
                                end
                            end

                            if notify then
                                lib.notify(source, {
                                    description = ('Gagal menambahkan (%s)'):format(table.concat(missing, ', '))
                                })
                            end

                            return false
                        end
                    end
                end
            end
        end
    end

    return true
end

return items