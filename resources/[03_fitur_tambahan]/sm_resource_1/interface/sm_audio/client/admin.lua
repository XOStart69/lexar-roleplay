local vehicleAttachOptions = {
    { value = 'none', label = 'No attaching to vehicles' },
    { value = 'direct', label = 'Allow without gizmo' },
    { value = 'gizmo', label = 'Allow with gizmo' },
    { value = 'both', label = 'Allow both, let player decide' },
}

local vehicleClassLabels = {
    'Compacts', 'Sedans', 'SUVs', 'Coupes', 'Muscle', 'Sports Classics', 'Sports',
    'Super', 'Motorcycles', 'Off-road', 'Industrial', 'Utility', 'Vans', 'Cycles',
    'Boats', 'Helicopters', 'Planes', 'Service', 'Emergency', 'Military',
    'Commercial', 'Trains', 'Open Wheel',
}

---@return table[]
local function buildVehicleClassOptions()
    local options = {}

    for i = 1, #vehicleClassLabels do
        options[i] = { value = i - 1, label = locale(vehicleClassLabels[i]) }
    end

    return options
end

---@param options table[]
---@return table[]
local function localizeOptions(options)
    local result = {}

    for i = 1, #options do
        result[i] = { value = options[i].value, label = locale(options[i].label) }
    end

    return result
end

---@param data? table
---@return table[]
local function speakerTypeFields(data)
    data = data or {}

    return {
        {
            type = 'input',
            label = locale('Label'),
            placeholder = locale('Speaker'),
            description = locale('Used in inventory, speakers shop and speakers menu.'),
            required = true,
            default = data.title,
        },
        {
            type = 'input',
            label = locale('Description'),
            placeholder = locale('Large club speaker!'),
            description = locale('Used in inventory, speakers shop and speakers menu.'),
            required = true,
            default = data.description,
        },
        {
            type = 'input',
            label = locale('Image'),
            placeholder = 'speaker1.png',
            description = locale('Image file name.'),
            required = true,
            default = data.image,
        },
        {
            type = 'input',
            label = locale('Model'),
            placeholder = locale('prop_boombox_01'),
            description = locale('Speaker entity model.'),
            required = true,
            default = data.textModel,
        },
        {
            type = 'number',
            label = locale('Max volume'),
            icon = 'volume-high',
            default = data.maxVolume or 1.0,
            min = 0.1,
            max = 3.0,
            precision = 1,
            step = 0.1,
            required = true,
        },
        {
            type = 'number',
            label = locale('Max range'),
            icon = 'radio',
            default = data.maxRange or 25.0,
            min = 5.0,
            max = 999.0,
            precision = 1,
            required = true,
        },
    }
end

---@param permissions table[]
---@param filters table[]
---@param data? table
---@return table[]
local function fullSpeakerTypeFields(permissions, filters, data)
    local fields = speakerTypeFields(data)

    local defaults
    if data and data.permissions then
        defaults = {}
        local count = 0
        for permission in pairs(data.permissions) do
            count = count + 1
            defaults[count] = permission
        end
    end

    fields[7] = {
        type = 'multi-select',
        label = locale('Permissions'),
        required = true,
        options = permissions,
        default = defaults,
    }

    fields[8] = {
        type = 'multi-select',
        label = locale('Allowed filters'),
        options = filters,
        default = data and data.allowedFilters or nil,
    }

    fields[9] = {
        type = 'input',
        label = locale('Inventory item ID'),
        description = locale('Leave this blank if you are are running inventory that supports metadata or are using command creation method.'),
        default = data and data.itemId or nil,
    }

    fields[10] = {
        type = 'number',
        label = locale('Shop price'),
        description = locale('Leave this blank if you are not using built-in speaker shop.'),
        icon = 'dollar-sign',
        min = 1,
        max = 100000000,
        default = data and data.price or nil,
    }

    return fields
end

lib.callback.register('sm_audio:client:getSpeakerOptions', function(permissions, filters)
    return lib.inputDialog(locale('New speaker type'), fullSpeakerTypeFields(permissions, filters))
end)

lib.callback.register('sm_audio:client:getExistingSpeakerTypeOptions', function(permissions, filters, data)
    return lib.inputDialog(locale('Edit speaker type'), fullSpeakerTypeFields(permissions, filters, data))
end)

lib.callback.register('sm_audio:client:getSpeakerTypeAttachData', function(data)
    return lib.inputDialog(locale('Attach data'), {
        {
            type = 'input',
            label = locale('Attach key'),
            placeholder = locale('speaker'),
            description = locale('This must be unique for every speaker type. Set this to empty to remove attached data.'),
            default = data.key,
        },
        {
            type = 'number',
            label = locale('Attach bone'),
            default = data.bone or 28422,
        },
        {
            type = 'number',
            label = locale('Attach x coord'),
            min = -10,
            max = 10.0,
            precision = 3,
            default = data.xCoord or 0.0,
            required = true,
        },
        {
            type = 'number',
            label = locale('Attach y coord'),
            min = -10,
            max = 10.0,
            precision = 3,
            default = data.yCoord or 0.0,
            required = true,
        },
        {
            type = 'number',
            label = locale('Attach z coord'),
            min = -10,
            max = 10.0,
            precision = 3,
            default = data.zCoord or 0.0,
            required = true,
        },
        {
            type = 'number',
            label = locale('Attach x rot'),
            min = -400,
            max = 400.0,
            precision = 1,
            default = data.xRotation or 0.0,
            required = true,
        },
        {
            type = 'number',
            label = locale('Attach y rot'),
            min = -400,
            max = 400.0,
            precision = 1,
            default = data.yRotation or 0.0,
            required = true,
        },
        {
            type = 'number',
            label = locale('Attach z rot'),
            min = -400,
            max = 400.0,
            precision = 1,
            default = data.zRotation or 0.0,
            required = true,
        },
        {
            type = 'select',
            label = locale('Vehicle attach type'),
            description = locale('Can this speaker type be attached to vehicles and how should the attachment work.'),
            options = localizeOptions(vehicleAttachOptions),
            default = data.vehicleAttach or 'none',
            required = true,
        },
        {
            type = 'multi-select',
            label = locale('Vehicle classes'),
            description = locale('Which vehicle classes can this speaker type be attached to.'),
            options = buildVehicleClassOptions(),
            clearable = true,
            default = data.vehicleClasses or { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 12 },
        },
    })
end)

lib.callback.register('sm_audio:client:getSpeakerTypeAnimationData', function(data)
    return lib.inputDialog(locale('Animation data'), {
        {
            type = 'input',
            label = locale('Animation dictionary'),
            description = locale('Set this to empty to remove animation.'),
            default = data.animationDict or 'anim@heists@box_carry@',
        },
        {
            type = 'input',
            label = locale('Animation clip'),
            default = data.animationName or 'idle',
        },
    })
end)

RegisterNetEvent('sm_audio:client:speakerTypeAdminMenu', function(types, maxRange, maxVolume)
    local options = {
        {
            title = locale('New speaker type'),
            icon = 'plus',
            iconColor = 'green',
            serverEvent = 'sm_audio:server:createNewSpeakerType',
        },
    }

    for i = 1, #types do
        local speakerType = types[i]
        local rangeProgress = math.floor((speakerType.maxRange / maxRange) * 100)
        local volumeProgress = math.floor((speakerType.maxVolume / maxVolume) * 100)

        options[i + 1] = {
            title = speakerType.title,
            description = speakerType.description,
            icon = speakerType.image,
            image = speakerType.image,
            arrow = true,
            event = 'sm_audio:client:speakerTypeMenu',
            args = { id = speakerType.id, inShop = speakerType.inShop },
            metadata = {
                { label = locale('Range'), value = ('%s/%s'):format(speakerType.maxRange, maxRange), progress = rangeProgress },
                { label = locale('Max volume'), value = ('%s/%s'):format(speakerType.maxVolume, maxVolume), progress = volumeProgress },
            },
        }
    end

    lib.registerContext({
        id = 'speaker-types-admin',
        title = locale('Speaker types'),
        options = options,
    })

    lib.showContext('speaker-types-admin')
end)

AddEventHandler('sm_audio:client:speakerTypeMenu', function(data)
    local id = data.id

    lib.registerContext({
        id = 'speaker-type-admin',
        title = locale('Speaker type'),
        menu = 'speaker-types-admin',
        options = {
            {
                title = locale('Edit speaker type'),
                description = locale('Everything related to type settings.'),
                icon = 'pencil',
                serverEvent = 'sm_audio:server:editSpeakerType',
                args = id,
            },
            {
                title = locale('Edit forced filters'),
                description = locale('When a certain filter is applied.'),
                icon = 'filter',
                serverEvent = 'sm_audio:server:editSpeakerForcedFilters',
                args = id,
            },
            {
                title = locale('Edit attachable'),
                description = locale('Necessary for carriable speakers.'),
                icon = 'hand',
                serverEvent = 'sm_audio:server:editSpeakerAttachData',
                args = id,
            },
            {
                title = locale('Edit animations'),
                description = locale('Apply animation to attachable.'),
                icon = 'person-running',
                serverEvent = 'sm_audio:server:editSpeakerAnimationData',
                args = id,
            },
            {
                title = locale('Give speaker item'),
                description = locale('Spawn inventory item with metadata.'),
                icon = 'plus',
                serverEvent = 'sm_audio:server:getSpeakerItem',
                args = id,
            },
            {
                title = data.inShop and locale('Remove from shop') or locale('Send to shop'),
                description = data.inShop
                    and locale('Remove speaker type from speaker shop.')
                    or locale('Make speaker type available in speaker shop.'),
                icon = 'shopping-cart',
                serverEvent = 'sm_audio:server:sendSpeakerTypeToShop',
                args = id,
            },
        },
    })

    lib.showContext('speaker-type-admin')
end)

RegisterNetEvent('sm_audio:client:speakerForcedFiltersMenu', function(speakerTypeId, filterTypeOptions, applyMethodOptions, forcedFilters)
    local options = {
        {
            title = locale('New forced filter'),
            icon = 'plus',
            iconColor = 'green',
            onSelect = function()
                local input = lib.inputDialog(locale('Forced filters'), {
                    {
                        type = 'select',
                        label = locale('Filter type'),
                        description = locale('What filter type is forced'),
                        options = filterTypeOptions,
                        required = true,
                    },
                    {
                        type = 'select',
                        label = locale('Apply method'),
                        description = locale('When the filter is forced upon the speaker'),
                        options = localizeOptions(applyMethodOptions),
                        required = true,
                    },
                })

                if not input then return end
                TriggerServerEvent('sm_audio:server:addForcedFilter', speakerTypeId, input)
            end,
        },
    }

    for i = 1, #forcedFilters do
        local filter = forcedFilters[i]

        options[i + 1] = {
            title = locale('Forced filter %s', i),
            description = locale('Type: %s, apply method: %s', filter.type, filter.applyMethod),
            icon = 'pencil',
            event = 'sm_audio:client:speakerForcedFilterMenu',
            args = { filter = filter, speakerTypeId = speakerTypeId, index = i },
        }
    end

    lib.registerContext({
        id = 'speaker-types-forced-filters',
        title = locale('Forced filters'),
        menu = 'speaker-types-admin',
        options = options,
    })

    lib.showContext('speaker-types-forced-filters')
end)

AddEventHandler('sm_audio:client:speakerForcedFilterMenu', function(data)
    lib.registerContext({
        id = 'speaker-types-forced-filter',
        title = locale('Forced filter %s', data.index),
        menu = 'speaker-types-forced-filters',
        options = {
            {
                title = locale('Edit forced filter'),
                description = locale('Edit filter data'),
                icon = 'pencil',
                onSelect = function()
                    local fields = lib.table.deepclone(GetFilterTypeInputFields(data.filter.type))
                    local minDistIndex, maxDistIndex

                    for i = 1, #fields do
                        local key = fields[i].key
                        if key and data.filter[key] then
                            fields[i].default = data.filter[key]
                        end
                    end

                    if data.filter.applyMethod == 'distance' then
                        minDistIndex = #fields + 1
                        fields[minDistIndex] = {
                            type = 'number',
                            label = locale('Minimum distance'),
                            description = locale('Minimum distance when filter is applied'),
                            icon = 'people-arrows',
                            min = 0,
                            max = 300.0,
                            precision = 1,
                            step = 1,
                            required = true,
                            key = 'minDist',
                            default = data.filter.minDist or 0.0,
                        }

                        maxDistIndex = #fields + 1
                        fields[maxDistIndex] = {
                            type = 'number',
                            label = locale('Maximum distance'),
                            description = locale('Maximum distance when filter is applied'),
                            icon = 'people-arrows',
                            min = 0,
                            max = 300.0,
                            precision = 1,
                            step = 1,
                            required = true,
                            key = 'maxDist',
                            default = data.filter.maxDist or 100.0,
                        }
                    end

                    local input = lib.inputDialog(locale('Forced filters'), fields)
                    if not input then return end

                    TriggerServerEvent('sm_audio:server:updateForcedFilter', data.speakerTypeId, data.index, input,
                        minDistIndex and input[minDistIndex] or nil,
                        maxDistIndex and input[maxDistIndex] or nil)
                end,
            },
            {
                title = locale('Delete forced filter'),
                description = locale('Type: %s, apply method: %s', data.filter.type, data.filter.applyMethod),
                icon = 'trash',
                iconColor = '#8A0707',
                serverEvent = 'sm_audio:server:removeForcedFilter',
                args = { data.speakerTypeId, data.index },
            },
        },
    })

    lib.showContext('speaker-types-forced-filter')
end)

RegisterNetEvent('sm_audio:client:speakerCreationMenu', function(types, maxRange, maxVolume)
    local options = {}

    for i = 1, #types do
        local speakerType = types[i]
        local rangeProgress = math.floor((speakerType.maxRange / maxRange) * 100)
        local volumeProgress = math.floor((speakerType.maxVolume / maxVolume) * 100)

        options[i] = {
            title = speakerType.title,
            description = speakerType.description,
            icon = speakerType.image,
            image = speakerType.image,
            progress = rangeProgress,
            colorScheme = 'teal',
            metadata = {
                { label = locale('Range'), value = ('%s/%s'):format(speakerType.maxRange, maxRange), progress = rangeProgress },
                { label = locale('Max volume'), value = ('%s/%s'):format(speakerType.maxVolume, maxVolume), progress = volumeProgress },
            },
            serverEvent = 'sm_audio:server:createSpeaker',
            args = speakerType.id,
        }
    end

    lib.registerContext({
        id = 'speaker-creation',
        title = locale('Create new speaker'),
        options = options,
    })

    lib.showContext('speaker-creation')
end)
