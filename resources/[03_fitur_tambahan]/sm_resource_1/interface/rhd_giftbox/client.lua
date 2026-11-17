local packObject
local packMode = false

localmodule 'modules.carry'
localmodule 'modules.objectManagement'

local config = localmodule 'config'

interface.init(false)

local frameToken = 0

local function openFrame()
    frameToken += 1
    interface.show()
end

local function closeFrame()
    frameToken += 1
    local token = frameToken

    SetTimeout(400, function()
        if token == frameToken then
            interface.hide()
        end
    end)
end

local function playAnim(anim)
    lib.requestAnimDict(anim.dict)
    TaskPlayAnim(cache.ped, anim.dict, anim.clip or anim.name, 2.0, 2.0, -1, anim.flag or 51, 0, false, false, false)
    RemoveAnimDict(anim.dict)
end

local function removePackObject()
    if packObject and DoesEntityExist(packObject) then
        DeleteEntity(packObject)
        packObject = nil
    end
end

local function setupPackObject()
    removePackObject()

    local model = joaat(config.PropsData.packing.props.model)
    lib.requestModel(model, 5000)

    local coords = config.PropsData.packing.props.coords
    local heading = config.PropsData.packing.props.heading

    packObject = CreateObject(model, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(packObject, heading)
    SetEntityCollision(packObject, false, false)
    FreezeEntityPosition(packObject, true)
    SetModelAsNoLongerNeeded(model)
end

local function setGiftBoxFocus(state)
    interface.focus(state, state)
end

local function openGiftBox()
    local itemList = ox_inventory:GetPlayerItems()
    local itemFiltered = {}

    for _, item in pairs(itemList) do
        local itemData = ox_inventory.Items and ox_inventory:Items(item.name)
        local isDegradable = config.BlockDegradable and itemData and itemData.degrade
        local hasDurability = config.BlockWithDurability and item.metadata and (item.metadata.durability or item.metadata.degrade or item.metadata.createDate)

        if not config.ForbiddenPackItems[item.name] and item.name:sub(1, 7):lower() ~= 'weapon_' and not isDegradable and not hasDurability then
            itemFiltered[#itemFiltered + 1] = {
                name = item.name,
                label = item.label,
                count = item.count,
                metadata = item.metadata,
                slot = item.slot
            }
        end
    end

    packMode = true
    setupPackObject()

    openFrame()
    interface.send({
        action = 'openGiftBox',
        data = {
            boxLabel = 'Gift Box',
            maxSlots = config.MaxSlots,
            items = itemFiltered
        }
    })

    setGiftBoxFocus(true)
    playAnim({ dict = 'mini@repair', clip = 'fixing_a_ped', flag = 41 })
end

local function closeGiftBox(skipObject, skipAnim)
    interface.send({
        action = 'closeGiftBox',
        data = {}
    })

    if packMode then
        packMode = false

        if not skipObject then
            removePackObject()
        end

        if not skipAnim then
            ClearPedTasks(cache.ped)
        end
    end

    setGiftBoxFocus(false)
    closeFrame()
end

interface.callback('exit', function(_, cb)
    cb('ok')
    closeGiftBox()
end)

interface.callback('closeGiftBox', function(_, cb)
    cb('ok')
    closeGiftBox()
end)

interface.callback('packGiftBox', function(data, cb)
    if not packMode then
        cb({ success = false, message = 'Not in pack mode' })
        lib.notify({ type = 'error', description = 'You are not packing a gift box' })
        return
    end

    closeGiftBox(true, true)
    local success, response

    success = lib.progressBar({
        duration = config.PropsData.packing.progressBar.duration,
        label = config.PropsData.packing.progressBar.label,
        useWhileDead = config.PropsData.packing.progressBar.useWhileDead,
        canCancel = config.PropsData.packing.progressBar.canCancel,
        disable = {
            move = true,
            car = true,
            combat = true,
            mouse = false
        }
    })

    removePackObject()
    ClearPedTasks(cache.ped)

    if not success then
        cb({ success = false, message = 'Packing cancelled' })
        lib.notify({ type = 'error', description = 'Packing cancelled' })
        return
    end

    success, response = lib.callback.await('rhd_giftbox:server:packGiftBox', false, data)
    cb({ success = success, message = response })

    if success then return end
    lib.notify({ type = 'error', description = response or 'Failed to pack gift box' })
end)


RegisterNetEvent('rhd_giftbox:client:showNote', function(note)
    if source == '' then return end

    openFrame()
    interface.send({
        action = 'showGiftNote',
        data = {
            note = note or ''
        }
    })

    interface.focus(true, true)
end)


ox_target:addSphereZone({
    coords = config.PropsData.packing.target.coords.xyz,
    radius = config.PropsData.packing.target.zoneRadius,
    options = {
        {
            label = config.PropsData.packing.target.label,
            icon = 'fa-solid fa-box',
            groups = config.PropsData.packing.target.groups,
            distance = config.PropsData.packing.target.distance,
            onSelect = openGiftBox
        }
    }
})
