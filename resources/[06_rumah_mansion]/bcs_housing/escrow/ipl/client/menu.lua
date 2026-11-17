function GenerateValues(data, price)
    if type(data) ~= 'table' then
        return {}
    end

    local values = {}

    for name, value in pairs(data) do
        if name ~= 'Set' and name ~= 'Clear' and name ~= 'Enable' then
            local priceText = ''
            if price > 0 then
                priceText = '($' .. price .. ')'
            end

            table.insert(values, { label = string.format('%s %s', name, priceText), close = false, value = value })
        end
    end

    return values, TableContainsKey(data, 'Enable')
end

function GetDefaultValueByData(items, targetValue)
    for i = 1, #items do
        if items[i].value == targetValue then
            return i
        end
    end

    return 1
end