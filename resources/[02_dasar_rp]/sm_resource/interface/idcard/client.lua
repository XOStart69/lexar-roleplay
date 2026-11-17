if not interface.init(false) then
    return
end

local card
local mugshotPromise
local currentLocation

local uiBusy = false
local sconfig = localmodule 'config.shared'
local showanim = localmodule 'modules.showanim'

local function displayMeta()
   ox_inventory:displayMetadata({
        card_owner = 'Name',
        card_expired = 'Expired',
    })
end

local function openCreator(cardList)
    if uiBusy then
        return
    end

    interface.show()
    interface.send({
        action = 'openCardCreator',
        data = cardList
    })

    card = nil
    uiBusy = true
    interface.focus(uiBusy, uiBusy)
end

local function openManagement(managementId)
    if uiBusy then
        return
    end

    if not managementId then return end

    interface.show()
    interface.send({
        action = 'openManager',
        data = {
            management = managementId
        }
    })

    card = nil
    uiBusy = true
    interface.focus(uiBusy, uiBusy)
end

local function gantiNama()
    local playerInput = {}

    local mycoords = GetEntityCoords(cache.ped)
    local playerNearby = lib.getNearbyPlayers(mycoords, 5.0, true)

    array.forEach(playerNearby, function (val)
        local serverId = GetPlayerServerId(val.id)
        local playerLabel = ('Player (%s)'):format(serverId)
        local playerValue = serverId

        playerInput[#playerInput+1] = {
            label = playerLabel, value = playerValue
        }
    end)

    local input = lib.inputDialog('Identity Form', {
        { type = 'select', label = 'Player', placeholder = 'Player id', required = true, options = playerInput },
        { type = 'input', label = 'First name', placeholder = 'Gatot', required = true },
        { type = 'input', label = 'Last name', placeholder = 'Subroto', required = true },
        { type = 'date', label = 'Date input', icon = {'far', 'calendar'}, default = true, required = true, format = "DD/MM/YYYY"},
        { type = 'input', label = 'Nationality', placeholder = 'Indonesia', required = true }
    })

    if not input then return end

    local pid = input[1]
    local name = input[2]
    local name2 = input[3]
    local date = math.floor(input[4] / 1000)
    local nationality = input[5]

    if name:isblank() or name2:isblank() then
        return lib.notify({
            description = 'Form tidak boleh kosong',
            type = 'error',
        })
    end

    local data = {
        playerid = pid,
        name = {name, name2},
        date = date,
        nationality = nationality
    }

    TriggerServerEvent('rhd_idcard:server:changename', data)
end

local function closeCreator()
    uiBusy = false
    interface.focus(uiBusy, uiBusy)
    SetTimeout(50, function()
        if not uiBusy then
            interface.hide()
        end
    end)
end

local function headShotReady(handle)
    local ok, err = pcall(lib.waitFor, function ()
		if IsPedheadshotReady(handle) and IsPedheadshotValid(handle) then
            return true
        end
	end, 'couldn\'t load mugshot', 10000)

    if not ok then
        return err and lib.print.warn(err)
    end

    return ok
end

local function getMugshot(citizend)
    if mugshotPromise then return end
	local headShotHandle = RegisterPedheadshotTransparent(cache.ped) or RegisterPedheadshot_3(cache.ped)

    if not headShotReady(headShotHandle) then return end
	local headShotTxd = GetPedheadshotTxdString(headShotHandle)

    local mountedForMugshot = not uiBusy
    if mountedForMugshot then
        interface.show()
    end

    interface.send({
        action = 'convertImage',
        data = {
            txd = headShotTxd,
            options = {
                name = citizend
            }
        }
    })

	UnregisterPedheadshot(headShotHandle)

    mugshotPromise = promise.new()
    local result = Citizen.Await(mugshotPromise)
    mugshotPromise = nil

    if mountedForMugshot then
        interface.hide()
    end

    return result
end

interface.callback('setMugshotStatus', function (data, cb)
    if mugshotPromise then
        mugshotPromise:resolve(data)
    end
    cb('ok')
end)

interface.callback('getTemplate', function (_, cb)
    cb(sconfig.template)
end)

interface.callback('exit', function (data, cb)
    closeCreator()
    cb('ok')
end)

interface.callback('getNearbyPlayers', function (data, cb)
    local players = {}

    local coords = GetEntityCoords(cache.ped)
    local nearby = lib.getNearbyPlayers(coords, 5.0, true)

    for i=1, #nearby do
        local player = nearby[i]
        local serverId = GetPlayerServerId(player.id)

        players[#players+1] = {
            label = ('Player (%s)'):format(serverId),
            value = serverId
        }
    end

    cb(players)
end)

interface.callback('updateCard', function (data, cb)
    cb(lib.callback.await('rhd_idcard:server:update', false, data))
end)

interface.callback('getDataFromServer', function (data, cb)
    cb(lib.callback.await('rhd_idcard:server:getData', false, data))
end)

interface.callback('getUserAvatar', function (data, cb)
    cb(lib.callback.await('rhd_idcard:server:getUserAvatar', false, data))
end)

interface.callback('createCard', function (data, cb)
    card = data

    closeCreator()
    TriggerServerEvent('rhd_idcard:server:buat_kartu')

    cb('ok')
end)

local CARDS_TIMEOUT_MS = 180000
local cardsRequest

---@param str string
---@return table
local function splitLines(str)
    local out = {}
    for line in str:gmatch('[^\n]+') do
        out[#out + 1] = line
    end
    return out
end

---@param packed string
---@return table
local function expandCards(packed)
    local payload = msgpack.unpack(packed)
    local dict = payload.d
    local list = payload.c
    local management = payload.m
    local jsonDecode = json.decode

    local configs = {}
    local shapes = {}
    local cards = {}

    for i = 1, #list do
        local row = list[i]
        local citizenid, templateIdx, configIdx, profileImage, shapeIdx, values, extra = row[1], row[2], row[3], row[4], row[5], row[6], row[7]

        local card = {}

        if extra then
            for k, v in pairs(extra) do
                card[k] = v
            end
        end

        if configIdx ~= 0 then
            local base = configs[configIdx]
            if not base then
                base = jsonDecode(dict[configIdx])
                configs[configIdx] = base
            end

            local config = {}
            for k, v in pairs(base) do
                config[k] = v
            end
            if profileImage then
                config.profileImage = profileImage
            end
            card.config = config
        end

        if shapeIdx ~= 0 then
            local shape = shapes[shapeIdx]
            if not shape then
                shape = splitLines(dict[shapeIdx])
                for j = 1, #shape do
                    shape[j] = jsonDecode(shape[j])
                end
                shapes[shapeIdx] = shape
            end

            local fields = {}
            for j = 1, #shape do
                local field = {}
                for k, v in pairs(shape[j]) do
                    field[k] = v
                end
                local value = values[j]
                if value ~= false then
                    field.value = value
                end
                fields[j] = field
            end
            card.fields = fields
        end

        card.template = templateIdx ~= 0 and dict[templateIdx] or nil
        card.citizenid = citizenid
        card.management = management
        cards[i] = card
    end

    return {
        cards = cards,
        total = payload.t or #cards,
        counts = payload.k,
        facets = payload.f,
    }
end

RegisterNetEvent('rhd_idcard:client:cards', function (key, packed)
    if not (cardsRequest and cardsRequest.key == key) then return end
    local req = cardsRequest
    cardsRequest = nil

    local ok, result = pcall(expandCards, packed)
    if not ok then
        lib.print.warn(('idcard expand failed: %s'):format(result))
        result = nil
    end

    req.promise:resolve(result)
end)

RegisterNetEvent('rhd_idcard:client:cardsDenied', function (key)
    if not (cardsRequest and cardsRequest.key == key) then return end
    local req = cardsRequest
    cardsRequest = nil
    req.promise:resolve(nil)
end)

interface.callback('getPlayerCards', function (data, cb)
    if cardsRequest then
        return cb(nil)
    end

    local key = ('%s:%s'):format(GetGameTimer(), math.random(100000))
    local req = { key = key, promise = promise.new() }
    cardsRequest = req

    SetTimeout(CARDS_TIMEOUT_MS, function ()
        if cardsRequest == req then
            cardsRequest = nil
            req.promise:resolve(nil)
        end
    end)

    TriggerServerEvent('rhd_idcard:server:requestCards', {
        managementId = data.managerId,
        page = data.page,
        pageSize = data.pageSize,
        tab = data.tab,
        search = data.search,
        cardType = data.cardType,
        citizenid = data.citizenid,
        withMeta = data.withMeta,
    }, key)
    cb(Citizen.Await(req.promise))
end)

lib.callback.register('rhd_idcard:client:getUserAvatar', function (citizenid)
    return getMugshot(citizenid)
end)

lib.callback.register('rhd_idcard:client:card', function()
    local cd = card
    local cl = currentLocation
    
    card = nil
    currentLocation = nil

    return cd, cl
end)

lib.callback.register('rhd_idcard:client:showAnim', function(itemname)
    local template = itemname and sconfig.template[itemname]
    local isbadge = template and template.config and template.config.isbadge

    return showanim.start(isbadge)
end)

RegisterNetEvent('rhd_idcard:client:show', function(data)
    if source == '' or uiBusy then return end

    uiBusy = true
    interface.show()
    interface.send({ action = 'showIdCard', data = data })

    CreateThread(function()
        while uiBusy do
            Wait(0)

            DisableControlAction(0, 177, true)
            if IsDisabledControlJustPressed(0, 177) then
                interface.send({ action = 'hideIdCard', data = {} })
                break
            end
        end

        uiBusy = false
        showanim.stop()
        interface.hide()
    end)
end)


AddEventHandler('onResourceStart', function(resource)
    if resource == 'ox_inventory' then
        displayMeta()
    end
end)

local pedModule = require 'modules.pedHandle.client'
local blipModule = require 'modules.blipHandle.client'
local locations = localmodule 'config.location'

local function setupPed(pdata)
    local coords = pdata.coords
    local interact = pdata.interact
    local ped_config = pdata.ped_config

    local points = lib.points.new(coords.xyz, 10, {
        entity = nil
    })
    
    function points:onEnter()
        if self.entity then
            pcall(function (...)
                self.entity:remove()
            end)
        end

        ped_config.coords = coords
        ped_config.target = array.map(interact, function (val)
            val.onSelect = function (data)
                currentLocation = pdata.location
                if val.action_id == 'create' then
                    openCreator(pdata.cardList)
                elseif val.action_id == 'management' then
                    openManagement(pdata.management)
                elseif val.action_id == 'changename' then
                    gantiNama()
                end
            end

            val.canInteract = function ()
                return not uiBusy
            end

            return val
        end)

        self.entity = pedModule:new(ped_config)
    end
    
    function points:onExit()
        if self.entity then
            pcall(function (...)
                self.entity:remove()
            end)
        end
        self.entity = nil
    end
end

local function setupZone(zdata)
    local coords = zdata.coords
    local interact = zdata.interact

    local targetdata = array.map(interact, function (val)
        val.onSelect = function (data)
            currentLocation = zdata.location
            if val.action_id == 'create' then
                openCreator(zdata.cardList)
            elseif val.action_id == 'management' then
                openManagement(zdata.management)
            elseif val.action_id == 'changename' then
                gantiNama()
            end
        end

        val.canInteract = function ()
            return not uiBusy
        end

        return val
    end)

    ox_target:addSphereZone({
        coords = coords.xyz,
        radius = zdata.radius or 0.5,
        options = targetdata
    })
end

CreateThread(function ()
    displayMeta()

    for i=1, #locations do
        local location = locations[i]
        local ped_config = location.ped_config
        local coords = location.coords
        local interact = location.interact
        local blipconfig = location.blip

        local action = ped_config?.model and setupPed or setupZone

        if coords then
            if type(coords) == "table" and table.type(coords) == 'array' then
                array.forEach(coords, function (val)
                    action({
                        coords = val,
                        interact = interact,
                        ped_config = ped_config,
                        cardList = location.cardList,
                        location = i,
                        management = location.managementId
                    })

                    if blipconfig then
                        blipModule:new({
                            label = blipconfig.label,
                            coords = val.xyz,
                            sprite = blipconfig.sprite,
                            color = blipconfig.color,
                        })
                    end
                end)
            else
                action({
                    coords = coords,
                    interact = interact,
                    ped_config = ped_config,
                    cardList = location.cardList,
                    location = i,
                    management = location.managementId
                })

                if blipconfig then
                    blipModule:new({
                        label = blipconfig.label,
                        coords = coords.xyz,
                        sprite = blipconfig.sprite,
                        color = blipconfig.color,
                    })
                end
            end
        end
    end
end)

