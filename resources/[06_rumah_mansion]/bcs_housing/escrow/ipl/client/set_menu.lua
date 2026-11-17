SetMenu = lib.class("SetMenu")

function SetMenu:constructor(entitySet, id)
    self.id = id
    self.entitySet = entitySet
    self.data = lib.callback.await("Housing:server:GetDataCustomizeIPL", false, self.id)
end

function SetMenu:Load()
    self.entitySet:LoadDefault()

    for name, itemData in pairs(self.data) do
        for i = 1, #self.entitySet.list do
            local item = self.entitySet.list[i]
            if item.name == name then
                exports.bob74_ipl:SetIplPropState(GetInteriorFromEntity(cache.ped), item.values, false, false)

                local isEnabled = itemData[2]
                if not isEnabled then
                    isEnabled = true
                end

                exports.bob74_ipl:SetIplPropState(GetInteriorFromEntity(cache.ped), itemData[1], isEnabled, false)
                break
            end
        end
    end

    RefreshInterior(GetInteriorFromEntity(cache.ped))
end

function SetMenu:Set(name, value, isEnabled)
    for i = 1, #self.entitySet.list do
        local item = self.entitySet.list[i]
        if item.name == name then
            exports.bob74_ipl:SetIplPropState(GetInteriorFromEntity(cache.ped), item.values, false, false)

            local state = isEnabled
            if not isEnabled then
                state = true
            end

            exports.bob74_ipl:SetIplPropState(GetInteriorFromEntity(cache.ped), value, state, true)
            break
        end
    end

    for key, itemData in pairs(self.data) do
        if key == name then
            itemData[1] = value
            itemData[2] = isEnabled
            return
        end
    end

    self.data[name] = { value, isEnabled }
end

function SetMenu:ShowMenu()
    if not Homes[CurrentHome.identifier] then
        return
    end

    local isConfirmed = false
    local pendingChanges = {}

    if self.entitySet.list and next(self.entitySet.list) then
        local options = {}

        for i = 1, #self.entitySet.list do
            local item = self.entitySet.list[i]

            if item.type == "check" then
                for j = 1, #item.values do
                    local propValue = item.values[j]
                    options[#options + 1] = {
                        label = item.name,
                        checked = IsInteriorEntitySetActive(GetInteriorFromEntity(cache.ped), propValue),
                        close = false,
                        value = propValue,
                        setPreview = function(prop, state)
                            exports.bob74_ipl:SetIplPropState(GetInteriorFromEntity(cache.ped), prop, state, true)
                        end
                    }
                end
            else
                local defaultIndex = nil
                for j = 1, #item.values do
                    if IsInteriorEntitySetActive(GetInteriorFromEntity(cache.ped), item.values[j]) then
                        defaultIndex = j
                        break
                    end
                end

                options[#options + 1] = {
                    label = item.name,
                    values = item.values,
                    price = item.price,
                    defaultIndex = defaultIndex,
                    close = false,
                    setPreview = function(propValue)
                        exports.bob74_ipl:SetIplPropState(GetInteriorFromEntity(cache.ped), item.values, false, true)
                        exports.bob74_ipl:SetIplPropState(GetInteriorFromEntity(cache.ped), propValue, true, true)
                    end
                }
            end
        end

        options[#options + 1] = {
            label = locale("confirm"),
            description = locale("confirm_change")
        }

        lib.registerMenu({
            id = "custom_entity_set",
            title = locale("customize_set"),
            options = options,
            onSideScroll = function(selected, scrollIndex)
                local option = options[selected]
                if option.setPreview then
                    option.setPreview(option.values[scrollIndex])
                    pendingChanges[option.label] = { option.values[scrollIndex], nil, option.price }
                end
            end,
            onCheck = function(selected, checked)
                local option = options[selected]
                if option.setPreview then
                    option.setPreview(option.value, checked)
                    pendingChanges[option.label] = { option.value, checked, option.price }
                end
            end,
            onClose = function()
                if not isConfirmed then
                    self:Load()
                end
                isConfirmed = false
            end
        }, function(selected)
            local option = options[selected]
            if option.label == locale("confirm") then
                local totalPrice = 0
                for _, changeData in pairs(pendingChanges) do
                    local price = changeData[3] or 0
                    totalPrice = totalPrice + price
                end

                local confirmation = lib.alertDialog({
                    header = locale("confirm"),
                    content = locale("confirm_changes_total", totalPrice),
                    cancel = true,
                    labels = {
                        cancel = "No",
                        confirm = "Yes"
                    }
                })

                if confirmation == "confirm" then
                    isConfirmed = true
                    if pendingChanges then
                        for name, data in pairs(pendingChanges) do
                            TriggerServerEvent("Housing:server:SetDataCustomizeIPL", self.id, nil, name, data)
                        end
                        return
                    end
                end
            end
        end)

        lib.showMenu("custom_entity_set")
    end
end