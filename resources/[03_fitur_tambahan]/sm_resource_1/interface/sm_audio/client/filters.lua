local Util = localmodule 'modules/util'

local filterFields = {}
local filterTypes = {}

AddEventHandler('sm_audio:client:receiveFilters', function(types, limits)
    if not types or not limits then return end

    table.wipe(filterFields)
    table.wipe(filterTypes)

    local count = 0

    for filterType, fields in pairs(types) do
        local built = {}

        for i = 1, #fields do
            local field = fields[i]
            local limit = limits[field]

            built[i] = {
                type = 'number',
                label = Util.ucfirst(field),
                description = locale('Between %s to %s %s', limit.min, limit.max, limit.units),
                icon = 'wave-square',
                default = limit.default,
                step = limit.step,
                precision = limit.precision,
                min = limit.min,
                max = limit.max,
                required = true,
                key = field,
            }
        end

        filterFields[filterType] = built

        count = count + 1
        filterTypes[count] = {
            filterType = filterType,
            title = Util.ucfirst(filterType),
            icon = 'ear-listen',
        }
    end
end)

---@param filterType string
---@return table[]
function GetFilterTypeInputFields(filterType)
    return filterFields[filterType] or {}
end

AddEventHandler('sm_audio:client:speakerFilters', function(data)
    local options = {}
    local activeCount = 0
    local appliedCount = 0
    local filters = data.filters or {}

    for i = 1, #filters do
        if filters[i].applyMethod then
            appliedCount = appliedCount + 1
        else
            activeCount = activeCount + 1
        end
    end

    options[1] = {
        title = locale('Total %s active filters.', activeCount),
        icon = 'filter',
    }

    options[2] = {
        title = locale('New filter'),
        description = locale('Modify sound output.'),
        icon = 'sliders',
        event = 'sm_audio:client:newFilterMenu',
        args = data,
    }

    local count = 2

    for i = 1, #filters do
        local filter = filters[i]

        if not filter.applyMethod then
            count = count + 1
            options[count] = {
                title = ('%s - %s'):format(i - appliedCount, filter.type),
                description = locale('Select to remove filter.'),
                icon = 'circle-xmark',
                serverEvent = 'sm_audio:server:removeFilter',
                args = { data.speakerId, filter.id },
            }
        end
    end

    lib.registerContext({
        id = 'speaker-filter-list',
        title = locale('Speaker filters'),
        menu = 'speaker-settings',
        options = options,
    })

    lib.showContext('speaker-filter-list')
end)

AddEventHandler('sm_audio:client:newFilterMenu', function(data)
    local allowed = {}
    local allowedList = data.allowedFilters or {}

    for i = 1, #allowedList do
        allowed[allowedList[i]] = true
    end

    local options = {}
    local count = 0

    for i = 1, #filterTypes do
        local entry = filterTypes[i]

        if allowed[entry.filterType] then
            count = count + 1
            options[count] = {
                title = entry.title,
                icon = entry.icon,
                onSelect = function()
                    local input = lib.inputDialog(locale('Filter values'), filterFields[entry.filterType])
                    if not input then return end
                    TriggerServerEvent('sm_audio:server:addFilter', data.speakerId, entry.filterType, input)
                end,
            }
        end
    end

    lib.registerContext({
        id = 'speaker-filter-type',
        title = locale('Filter type'),
        menu = 'speaker-filter-list',
        options = options,
    })

    lib.showContext('speaker-filter-type')
end)
