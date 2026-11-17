local recentLogsLimit = 5
local logsPageSize = 8

local config = require 'config.shared'
local Layout = require 'modules.layout'
local SelfService = require 'modules.self_service.server'

local management = config.management

local DATA = {
    rooms = {},
    roomById = {},
    dashboardLogs = {},
    logsTotal = 0,
    revenueToday = 0,
    priceOverrides = { rooms = {}, floors = {} },
}

local checkoutMonitorRunning = false
local pendingInvoices = {}
local invoiceSequence = 0

local function today()
    return os.date('%Y-%m-%d')
end

local function buildVisitorSeries(countsByDate)
    local series = {}
    local now = os.time()

    for offset = 6, 0, -1 do
        local ts = now - offset * 86400
        local date = os.date('%Y-%m-%d', ts)

        series[#series + 1] = {
            label = os.date('%a', ts),
            value = countsByDate[date] or 0,
        }
    end

    return series
end

local function getPlayerName(player, fallback)
    local data = player and player.PlayerData
    local charinfo = data and data.charinfo

    if charinfo then
        local firstName = charinfo.firstname or charinfo.firstName
        local lastName = charinfo.lastname or charinfo.lastName

        if firstName or lastName then
            return ('%s %s'):format(firstName or '', lastName or ''):gsub('^%s+', ''):gsub('%s+$', '')
        end
    end

    return data and data.name or fallback
end

local function notify(source, notifyType, description)
    return lib.notify(source, {
        type = notifyType,
        description = description,
        duration = 4500,
    })
end

local function getLogPage(page)
    return Storage.getLogs(page, logsPageSize, DATA.logsTotal)
end

local function roomPrice(room)
    local override = DATA.priceOverrides.rooms[room.id] or DATA.priceOverrides.floors[room.floor]

    if override then
        return override
    end

    local customFloorPrices = management.customRoomPrices and management.customRoomPrices[room.floor]
    local customPrice = customFloorPrices and customFloorPrices[room.number]

    if customPrice ~= nil then
        return math.max(0, tonumber(customPrice) or 0)
    end

    local floorPrice = management.floorPrices and management.floorPrices[room.floor]

    return math.max(0, tonumber(floorPrice or management.roomBasePrice) or 450)
end

local function normalizePrice(value)
    local price = tonumber(value)

    if not price or price < 0 then
        return nil
    end

    return math.floor(price)
end

local function dateToTimestamp(value, hour)
    local year, month, day = tostring(value):match('^(%d%d%d%d)%-(%d%d)%-(%d%d)$')

    if not year then
        return
    end

    return os.time({
        year = tonumber(year),
        month = tonumber(month),
        day = tonumber(day),
        hour = hour or 12,
        min = 0,
        sec = 0,
    })
end

local function checkoutDeadline(date)
    local hour = math.min(23, math.max(0, math.floor(tonumber(management.checkoutHour) or 18)))

    return dateToTimestamp(date, hour)
end

local function getStayDays(checkinDate, checkoutDate)
    local checkinTimestamp = dateToTimestamp(checkinDate)
    local checkoutTimestamp = dateToTimestamp(checkoutDate)

    if not checkinTimestamp or not checkoutTimestamp then
        return 0
    end

    return math.max(0, math.floor(((checkoutTimestamp - checkinTimestamp) / 86400) + 0.5))
end

---@return Array
local function newOccupantList()
    ---@diagnostic disable-next-line: invisible
    return lib.array:new()
end

local function findOccupant(room, citizenId)
    return room.occupants:find(function(occupant)
        return occupant.citizenId == citizenId
    end)
end

local function hasOccupantSlot(room)
    return #room.occupants + 1 < room.maxOccupants
end

local function buildRooms()
    local builtRooms = {}
    local roomById = {}
    local entries = Layout.list()

    for index = 1, #entries do
        local entry = entries[index]
        local basePrice = roomPrice(entry)

        local room = {
            id = entry.id,
            doorId = entry.id,
            floor = entry.floor,
            number = entry.number,
            status = 'available',
            basePrice = basePrice,
            price = basePrice,
            maxOccupants = Layout.getMaxOccupants(entry.id),
            occupantPrice = Layout.getExtraOccupantPrice(),
            occupants = newOccupantList(),
        }

        builtRooms[#builtRooms + 1] = room
        roomById[room.id] = room
    end

    DATA.rooms = builtRooms
    DATA.roomById = roomById
end

local function findRoom(roomId)
    return DATA.roomById[roomId]
end

local function getCitizenId(player)
    local data = player and player.PlayerData

    return data and data.citizenid
end

local function dashboard()
    local occupied = 0
    local available = 0
    local checkout = 0
    local visitorSeries = buildVisitorSeries(Storage.getVisitorTrend(7))

    for index = 1, #DATA.rooms do
        local room = DATA.rooms[index]

        if room.status == 'occupied' then
            occupied = occupied + 1
            if room.checkoutDate == today() then
                checkout = checkout + 1
            end
        elseif room.status == 'available' then
            available = available + 1
        end
    end

    return {
        visitors = visitorSeries,
        logs = DATA.dashboardLogs,
        stats = {
            occupiedRooms = occupied,
            availableRooms = available,
            expectedCheckout = checkout,
            revenueToday = DATA.revenueToday,
        },
    }
end

local function resetReservedRoom(room)
    room.status = 'available'
    room.citizenId = nil
    room.guestName = nil
    room.checkinDate = nil
    room.checkoutDate = nil
    room.basePrice = roomPrice(room)
    room.price = room.basePrice
    room.note = nil
    room.occupants = newOccupantList()
end

local function syncRooms(rooms, includeLogs)
    local payload = {
        rooms = rooms,
        dashboard = dashboard(),
    }

    if includeLogs then
        payload.logs = getLogPage(1)
    end

    Staff.syncEvent('rhd_motel:management:sync', payload)
end

local function syncRoom(room, includeLogs)
    return syncRooms({ room }, includeLogs)
end

local function applyRoomPrice(room)
    room.basePrice = roomPrice(room)

    if room.status == 'available' then
        room.price = room.basePrice
    end

    Storage.saveRoom(room)
end

local function expireInvoice(invoiceId, reason)
    local invoice = pendingInvoices[invoiceId]

    if not invoice or invoice.status ~= 'pending' then
        return false
    end

    invoice.status = reason or 'expired'
    pendingInvoices[invoiceId] = nil

    local room = findRoom(invoice.roomId)

    if room and invoice.kind == 'room' and room.status == 'reserved' then
        resetReservedRoom(room)
        syncRoom(room, false)
    end

    Event.emitLatentClient('rhd_motel:invoice:closed', invoice.targetSource, {
        id = invoice.id,
        status = invoice.status,
    })

    return true
end

local function createInvoice(source, payload, selfService)
    if type(payload) ~= 'table' then
        return { success = false, message = 'Invalid invoice data.' }
    end

    local targetSource = selfService and source or tonumber(payload.playerId)
    local targetPlayer = targetSource and Core:GetPlayer(targetSource)
    local room = findRoom(payload.roomId)

    if not targetPlayer then
        return { success = false, message = 'Target player is not available.' }
    end

    if not room or room.status ~= 'available' then
        return { success = false, message = 'Room is no longer available.' }
    end

    local checkinDate = tostring(payload.checkinDate or '')
    local checkoutDate = tostring(payload.checkoutDate or '')
    local stayDays = getStayDays(checkinDate, checkoutDate)

    if checkinDate < today() or stayDays < 1 then
        return { success = false, message = 'Invalid check-in or checkout date.' }
    end

    invoiceSequence = invoiceSequence + 1

    local timeoutSeconds = math.max(10, tonumber(management.invoiceTimeout) or 60)
    local basePrice = roomPrice(room)
    local invoiceId = ('motel-%s-%s'):format(os.time(), invoiceSequence)

    local invoice = {
        id = invoiceId,
        kind = 'room',
        roomId = room.id,
        roomNumber = room.number,
        targetSource = targetSource,
        targetCitizenId = getCitizenId(targetPlayer),
        guestName = tostring(payload.guestName or getPlayerName(targetPlayer, 'Guest')),
        checkinDate = checkinDate,
        checkoutDate = checkoutDate,
        stayDays = stayDays,
        basePrice = basePrice,
        amount = basePrice * stayDays,
        note = payload.note and tostring(payload.note) or nil,
        senderSource = source,
        selfService = selfService == true,
        status = 'pending',
        expiresAt = os.time() + timeoutSeconds,
    }

    pendingInvoices[invoiceId] = invoice

    room.status = 'reserved'
    room.citizenId = invoice.targetCitizenId
    room.guestName = invoice.guestName
    room.checkinDate = checkinDate
    room.checkoutDate = checkoutDate
    room.basePrice = basePrice
    room.price = invoice.amount
    room.note = invoice.note

    syncRoom(room, false)

    Event.emitLatentClient('rhd_motel:invoice:open', targetSource, {
        id = invoice.id,
        kind = invoice.kind,
        roomNumber = invoice.roomNumber,
        guestName = invoice.guestName,
        checkinDate = invoice.checkinDate,
        checkoutDate = invoice.checkoutDate,
        stayDays = invoice.stayDays,
        basePrice = invoice.basePrice,
        amount = invoice.amount,
        expiresAt = invoice.expiresAt,
        timeout = timeoutSeconds,
    })

    SetTimeout(timeoutSeconds * 1000, function()
        expireInvoice(invoiceId, 'expired')
    end)

    return {
        success = true,
        invoiceId = invoice.id,
        expiresAt = invoice.expiresAt,
    }
end

local function createOccupantInvoice(source, payload)
    if type(payload) ~= 'table' then
        return { success = false, message = 'Invalid occupant data.' }
    end

    local room = findRoom(payload.roomId)

    if not room or room.status ~= 'occupied' then
        return { success = false, message = 'This room is not rented.' }
    end

    if not hasOccupantSlot(room) then
        return { success = false, message = 'Room occupant capacity is full.' }
    end

    local targetSource = tonumber(payload.playerId)
    local targetPlayer = targetSource and Core:GetPlayer(targetSource)
    local targetCitizenId = targetPlayer and getCitizenId(targetPlayer)

    if not targetCitizenId then
        return { success = false, message = 'Target player is not available.' }
    end

    if targetCitizenId == room.citizenId or findOccupant(room, targetCitizenId) then
        return { success = false, message = 'This player already has access to the room.' }
    end

    for _, pending in pairs(pendingInvoices) do
        if pending.status == 'pending'
            and pending.roomId == room.id
            and pending.occupantCitizenId == targetCitizenId
        then
            return { success = false, message = 'An occupant invoice for this player is still pending.' }
        end
    end

    local renter = room.citizenId and Core:GetPlayerByCitizenId(room.citizenId)
    local renterSource = renter and renter.PlayerData and renter.PlayerData.source

    if not renterSource then
        return { success = false, message = 'The main tenant of this room is offline.' }
    end

    invoiceSequence = invoiceSequence + 1

    local timeoutSeconds = math.max(10, tonumber(management.invoiceTimeout) or 60)
    local invoiceId = ('motel-occupant-%s-%s'):format(os.time(), invoiceSequence)
    local basePrice = normalizePrice(payload.price) or Layout.getExtraOccupantPrice()
    local stayDays = math.max(1, getStayDays(today(), room.checkoutDate))
    local occupantName = payload.guestName and tostring(payload.guestName):match('^%s*(.-)%s*$')

    if not occupantName or occupantName == '' then
        occupantName = getPlayerName(targetPlayer, ('Player %s'):format(targetSource))
    end

    local invoice = {
        id = invoiceId,
        kind = 'occupant',
        roomId = room.id,
        roomNumber = room.number,
        targetSource = renterSource,
        targetCitizenId = room.citizenId,
        occupantCitizenId = targetCitizenId,
        guestName = occupantName,
        checkinDate = today(),
        checkoutDate = room.checkoutDate,
        stayDays = stayDays,
        basePrice = basePrice,
        amount = basePrice * stayDays,
        senderSource = source,
        status = 'pending',
        expiresAt = os.time() + timeoutSeconds,
    }

    pendingInvoices[invoiceId] = invoice

    Event.emitLatentClient('rhd_motel:invoice:open', renterSource, {
        id = invoice.id,
        kind = invoice.kind,
        roomNumber = invoice.roomNumber,
        guestName = invoice.guestName,
        checkinDate = invoice.checkinDate,
        checkoutDate = invoice.checkoutDate,
        stayDays = invoice.stayDays,
        basePrice = invoice.basePrice,
        amount = invoice.amount,
        expiresAt = invoice.expiresAt,
        timeout = timeoutSeconds,
    })

    SetTimeout(timeoutSeconds * 1000, function()
        expireInvoice(invoiceId, 'expired')
    end)

    return {
        success = true,
        invoiceId = invoice.id,
        expiresAt = invoice.expiresAt,
    }
end

local function createExtendInvoice(source, payload)
    if type(payload) ~= 'table' then
        return { success = false, message = 'Invalid extension data.' }
    end

    local room = findRoom(payload.roomId)

    if not room or room.status ~= 'occupied' then
        return { success = false, message = 'This room is not rented.' }
    end

    local checkoutDate = tostring(payload.checkoutDate or '')
    local extraDays = getStayDays(room.checkoutDate, checkoutDate)

    if extraDays < 1 then
        return { success = false, message = 'The new checkout date must be later than the current one.' }
    end

    for _, pending in pairs(pendingInvoices) do
        if pending.status == 'pending' and pending.kind == 'extend' and pending.roomId == room.id then
            return { success = false, message = 'An extension invoice for this room is still pending.' }
        end
    end

    local renter = room.citizenId and Core:GetPlayerByCitizenId(room.citizenId)
    local renterSource = renter and renter.PlayerData and renter.PlayerData.source

    if not renterSource then
        return { success = false, message = 'The main tenant of this room is offline.' }
    end

    invoiceSequence = invoiceSequence + 1

    local timeoutSeconds = math.max(10, tonumber(management.invoiceTimeout) or 60)
    local invoiceId = ('motel-extend-%s-%s'):format(os.time(), invoiceSequence)
    local basePrice = normalizePrice(payload.price) or room.basePrice or roomPrice(room)

    local invoice = {
        id = invoiceId,
        kind = 'extend',
        roomId = room.id,
        roomNumber = room.number,
        targetSource = renterSource,
        targetCitizenId = room.citizenId,
        guestName = room.guestName or 'Guest',
        checkinDate = room.checkoutDate,
        checkoutDate = checkoutDate,
        stayDays = extraDays,
        basePrice = basePrice,
        amount = basePrice * extraDays,
        senderSource = source,
        status = 'pending',
        expiresAt = os.time() + timeoutSeconds,
    }

    pendingInvoices[invoiceId] = invoice

    Event.emitLatentClient('rhd_motel:invoice:open', renterSource, {
        id = invoice.id,
        kind = invoice.kind,
        roomNumber = invoice.roomNumber,
        guestName = invoice.guestName,
        checkinDate = invoice.checkinDate,
        checkoutDate = invoice.checkoutDate,
        stayDays = invoice.stayDays,
        basePrice = invoice.basePrice,
        amount = invoice.amount,
        expiresAt = invoice.expiresAt,
        timeout = timeoutSeconds,
    })

    SetTimeout(timeoutSeconds * 1000, function()
        expireInvoice(invoiceId, 'expired')
    end)

    return {
        success = true,
        invoiceId = invoice.id,
        expiresAt = invoice.expiresAt,
    }
end

local function recordBilling(invoice, title, description)
    local staff = not invoice.selfService and invoice.senderSource and Core:GetPlayer(invoice.senderSource)
    local staffCitizenId = getCitizenId(staff)

    if not staffCitizenId or not invoice.targetCitizenId then
        return
    end

    local ok, result = pcall(function()
        return exports[management.billingResource]:createPaidInvoice({
            senderCitizenId = staffCitizenId,
            senderJob = config.motelJob,
            targetCitizenId = invoice.targetCitizenId,
            title = title,
            description = description,
            amount = invoice.amount,
            items = {
                {
                    label = title,
                    description = ('%s night(s)'):format(invoice.stayDays),
                    price = invoice.basePrice,
                },
            },
        })
    end)

    if not ok then
        return lib.print.error(('[rhd_motel] Billing export failed: %s'):format(result))
    end

    if type(result) ~= 'table' or not result.success then
        lib.print.error(('[rhd_motel] Billing rejected the invoice: %s'):format(type(result) == 'table' and result.message or 'no response'))
    end
end

local function payInvoice(source, invoiceId)
    local invoice = pendingInvoices[invoiceId]

    if not invoice or invoice.status ~= 'pending' or invoice.targetSource ~= source then
        return { success = false, message = 'Invoice is no longer available.' }
    end

    if os.time() >= invoice.expiresAt then
        expireInvoice(invoiceId, 'expired')
        return { success = false, message = 'Invoice has expired.' }
    end

    invoice.status = 'processing'

    local room = findRoom(invoice.roomId)
    local player = Core:GetPlayer(source)
    local expectedStatus = (invoice.kind == 'occupant' or invoice.kind == 'extend') and 'occupied' or 'reserved'

    if not room or room.status ~= expectedStatus or not player then
        invoice.status = 'pending'
        expireInvoice(invoiceId, 'cancelled')
        return { success = false, message = 'Room reservation is no longer available.' }
    end

    if invoice.kind == 'occupant' and (not hasOccupantSlot(room) or findOccupant(room, invoice.occupantCitizenId)) then
        invoice.status = 'pending'
        expireInvoice(invoiceId, 'cancelled')
        return { success = false, message = 'Room occupant capacity is full.' }
    end

    local paymentAccount = management.paymentAccount or 'bank'
    local paid = player.Functions.RemoveMoney(paymentAccount, invoice.amount, 'motel-room-invoice')

    if not paid then
        invoice.status = 'pending'
        return { success = false, message = 'Insufficient balance.' }
    end

    invoice.status = 'paid'
    pendingInvoices[invoiceId] = nil

    DATA.revenueToday = DATA.revenueToday + invoice.amount

    if invoice.kind == 'extend' then
        room.checkoutDate = invoice.checkoutDate
        room.price = (tonumber(room.price) or 0) + invoice.amount

        Storage.saveRoom(room)

        local extendLogId = Storage.addLog(
            room.id,
            ('Room %03d extended'):format(room.number),
            ('%s extended the stay until %s'):format(invoice.guestName, room.checkoutDate),
            'payment',
            invoice.amount
        )

        if extendLogId then
            DATA.logsTotal = DATA.logsTotal + 1
        end

        DATA.dashboardLogs = Storage.getRecentLogs(recentLogsLimit)
        syncRoom(room, true)

        recordBilling(
            invoice,
            ('Motel Room %03d Extension'):format(room.number),
            ('Stay extended until %s'):format(room.checkoutDate)
        )

        Event.emitLatentClient('rhd_motel:invoice:closed', source, {
            id = invoice.id,
            status = 'paid',
        })

        return { success = true, room = room }
    end

    if invoice.kind == 'occupant' then
        local occupant = {
            citizenId = invoice.occupantCitizenId,
            name = invoice.guestName,
        }

        room.occupants:push(occupant)
        Storage.addRoomOccupant(room.id, occupant.citizenId, occupant.name)

        local occupantLogId = Storage.addLog(
            room.id,
            ('Room %03d occupant added'):format(room.number),
            ('%s was added as an occupant until %s'):format(occupant.name, room.checkoutDate),
            'checkin',
            invoice.amount
        )

        if occupantLogId then
            DATA.logsTotal = DATA.logsTotal + 1
        end

        DATA.dashboardLogs = Storage.getRecentLogs(recentLogsLimit)
        syncRoom(room, true)

        recordBilling(
            invoice,
            ('Motel Room %03d Occupant'):format(room.number),
            ('%s was added as an occupant until %s'):format(invoice.guestName, room.checkoutDate)
        )

        Event.emitLatentClient('rhd_motel:invoice:closed', source, {
            id = invoice.id,
            status = 'paid',
        })

        return { success = true, room = room }
    end

    room.status = 'occupied'
    room.citizenId = invoice.targetCitizenId
    room.guestName = invoice.guestName
    room.checkinDate = invoice.checkinDate
    room.checkoutDate = invoice.checkoutDate
    room.basePrice = invoice.basePrice
    room.price = invoice.amount
    room.note = invoice.note

    Storage.saveRoom(room)

    local logId = Storage.addLog(
        room.id,
        ('Room %03d check-in'):format(room.number),
        ('%s paid the room invoice until %s'):format(room.guestName, room.checkoutDate),
        'checkin',
        room.price
    )

    if logId then
        DATA.logsTotal = DATA.logsTotal + 1
    end

    DATA.dashboardLogs = Storage.getRecentLogs(recentLogsLimit)
    syncRoom(room, true)

    recordBilling(
        invoice,
        ('Motel Room %03d'):format(room.number),
        ('Stay from %s until %s'):format(room.checkinDate, room.checkoutDate)
    )

    Event.emitLatentClient('rhd_motel:invoice:closed', source, {
        id = invoice.id,
        status = 'paid',
    })

    return { success = true, room = room }
end

local function clearRoomCheckout(room, forced)
    local guestName = room.guestName or 'Guest'
    local checkoutDate = room.checkoutDate

    room.status = 'available'
    room.citizenId = nil
    room.guestName = nil
    room.checkinDate = nil
    room.checkoutDate = nil
    room.basePrice = roomPrice(room)
    room.price = room.basePrice
    room.note = nil
    room.occupants = newOccupantList()

    Storage.saveRoom(room)
    Storage.clearRoomOccupants(room.id)

    local logId = Storage.addLog(
        room.id,
        forced and ('Room %03d force checkout'):format(room.number) or ('Room %03d checkout'):format(room.number),
        forced
            and ('%s was forced out by %s: %s'):format(guestName, forced.staffName, forced.reason)
            or ('%s checked out on %s'):format(guestName, checkoutDate or today()),
        'checkout',
        0
    )

    if logId then
        DATA.logsTotal = DATA.logsTotal + 1
    end

    TriggerEvent('rhd_motel:doorlock:setStateInternal', room.doorId, true)
end

local function monitorRoomCheckouts()
    if checkoutMonitorRunning then
        return
    end

    checkoutMonitorRunning = true

    local success, errorMessage = pcall(function()
        local now = os.time()
        local checkedOutRooms = {}

        for index = 1, #DATA.rooms do
            local room = DATA.rooms[index]
            local dueAt = room.checkoutDate and checkoutDeadline(room.checkoutDate)

            if room.status == 'occupied' and dueAt and now >= dueAt then
                clearRoomCheckout(room)
                checkedOutRooms[#checkedOutRooms + 1] = room
            end
        end

        if #checkedOutRooms > 0 then
            DATA.dashboardLogs = Storage.getRecentLogs(recentLogsLimit)

            Staff.syncEvent('rhd_motel:management:sync', {
                rooms = checkedOutRooms,
                dashboard = dashboard(),
                logs = getLogPage(1),
            })

            lib.print.info(('[rhd_motel] processed %s room checkout(s)'):format(#checkedOutRooms))
        end
    end)

    checkoutMonitorRunning = false

    if not success then
        lib.print.error(('[rhd_motel] checkout monitor failed: %s'):format(errorMessage))
    end
end

Citizen.CreateThreadNow(function ()
    Storage.ensureTables()
    DATA.priceOverrides = Storage.loadPriceOverrides()
    buildRooms()
    Storage.loadRooms(DATA.roomById)
    Storage.loadRoomOccupants(DATA.roomById)
    DATA.dashboardLogs = Storage.getRecentLogs(recentLogsLimit)
    DATA.logsTotal = Storage.getLogTotal()
    DATA.revenueToday = Storage.getRevenueToday()
end)

lib.cron.new(('*/%s * * * *'):format(management.checkoutCron), function()
    monitorRoomCheckouts()
end, {
    debug = management.checkoutCronDebug == true,
    maxDelay = 60,
})

SetTimeout(1000, monitorRoomCheckouts)

AddEventHandler('playerDropped', function()
    local droppedSource = source

    local expired = {}
    for invoiceId, invoice in pairs(pendingInvoices) do
        if invoice.targetSource == droppedSource or invoice.senderSource == droppedSource then
            expired[#expired + 1] = invoiceId
        end
    end

    for index = 1, #expired do
        expireInvoice(expired[index], 'cancelled')
    end
end)

local function canForceCheckout(source)
    return Staff.hasPermission(source, 'forceCheckout')
end

local function canSetRoomPrice(source)
    return Staff.hasPermission(source, 'setRoomPrice')
end

lib.callback.register('rhd_motel:management:bootstrap', function(source)
    if not Staff.isOnduty(source) then
        notify(source, 'error', 'You do not have access to motel management.')
        return false
    end

    local currentStaff = Staff.getData(source)
    currentStaff.canForceCheckout = canForceCheckout(source)
    currentStaff.canSetRoomPrice = canSetRoomPrice(source)
    currentStaff.canManageSelfService = Staff.hasPermission(source, 'manageSelfService')

    return {
        currentStaff = currentStaff,
        dashboard = dashboard(),
        rooms = DATA.rooms,
        selfService = SelfService.getStatus(),
    }
end)

lib.callback.register('rhd_motel:management:getLogs', function(source, payload)
    if not Staff.isOnduty(source) then
        notify(source, 'error', 'You do not have access to motel management.')
        return false
    end

    return getLogPage(payload and payload.page)
end)

lib.callback.register('rhd_motel:management:sendInvoice', function(source, payload)
    if not Staff.isOnduty(source) then
        return { success = false, message = 'You do not have access to motel management.' }
    end

    return createInvoice(source, payload, false)
end)

lib.callback.register('rhd_motel:management:addOccupant', function(source, payload)
    if not Staff.isOnduty(source) then
        return { success = false, message = 'You do not have access to motel management.' }
    end

    return createOccupantInvoice(source, payload)
end)

lib.callback.register('rhd_motel:management:extendStay', function(source, payload)
    if not Staff.isOnduty(source) then
        return { success = false, message = 'You do not have access to motel management.' }
    end

    return createExtendInvoice(source, payload)
end)

lib.callback.register('rhd_motel:management:removeOccupant', function(source, payload)
    if not Staff.isOnduty(source) then
        return { success = false, message = 'You do not have access to motel management.' }
    end

    local room = type(payload) == 'table' and findRoom(payload.roomId)
    local citizenId = type(payload) == 'table' and payload.citizenId
    local occupant = room and type(citizenId) == 'string' and findOccupant(room, citizenId)

    if not room or not occupant then
        return { success = false, message = 'Occupant is no longer registered.' }
    end

    room.occupants = room.occupants:filter(function(entry)
        return entry.citizenId ~= citizenId
    end) --[[@as Array]]

    Storage.removeRoomOccupant(room.id, citizenId)

    local logId = Storage.addLog(
        room.id,
        ('Room %03d occupant removed'):format(room.number),
        ('%s was removed from the room'):format(occupant.name),
        'checkout',
        0
    )

    if logId then
        DATA.logsTotal = DATA.logsTotal + 1
    end

    DATA.dashboardLogs = Storage.getRecentLogs(recentLogsLimit)
    syncRoom(room, true)

    return { success = true }
end)

lib.callback.register('rhd_motel:management:forceCheckout', function(source, payload)
    if not canForceCheckout(source) then
        return { success = false, message = 'Your rank cannot force a checkout.' }
    end

    local room = type(payload) == 'table' and findRoom(payload.roomId)

    if not room or room.status ~= 'occupied' then
        return { success = false, message = 'This room is not rented.' }
    end

    local reason = type(payload.reason) == 'string' and payload.reason:match('^%s*(.-)%s*$')

    if not reason or reason == '' then
        return { success = false, message = 'A checkout reason is required.' }
    end

    clearRoomCheckout(room, {
        reason = reason,
        staffName = Staff.getName(source) or 'Staff',
    })

    DATA.dashboardLogs = Storage.getRecentLogs(recentLogsLimit)
    syncRoom(room, true)

    return { success = true }
end)

lib.callback.register('rhd_motel:management:setRoomPrice', function(source, payload)
    if not canSetRoomPrice(source) then
        return { success = false, message = 'Your rank cannot change room prices.' }
    end

    local room = type(payload) == 'table' and findRoom(payload.roomId)

    if not room then
        return { success = false, message = 'Room is no longer available.' }
    end

    local price = normalizePrice(payload.price)

    DATA.priceOverrides.rooms[room.id] = price

    if price then
        Storage.savePriceOverride('room', room.id, price)
    else
        Storage.deletePriceOverride('room', room.id)
    end

    applyRoomPrice(room)
    syncRoom(room, false)

    return { success = true, price = room.basePrice }
end)

lib.callback.register('rhd_motel:management:setFloorPrice', function(source, payload)
    if not canSetRoomPrice(source) then
        return { success = false, message = 'Your rank cannot change room prices.' }
    end

    local floor = tonumber(type(payload) == 'table' and payload.floor)

    if not floor then
        return { success = false, message = 'Floor does not exist.' }
    end

    local rooms = {}
    local roomIds = {}

    for index = 1, #DATA.rooms do
        local room = DATA.rooms[index]

        if room.floor == floor then
            rooms[#rooms + 1] = room
            roomIds[#roomIds + 1] = room.id
            DATA.priceOverrides.rooms[room.id] = nil
        end
    end

    if #rooms == 0 then
        return { success = false, message = 'Floor does not exist.' }
    end

    local price = normalizePrice(payload.price)

    Storage.deleteRoomPriceOverrides(roomIds)
    DATA.priceOverrides.floors[floor] = price

    if price then
        Storage.savePriceOverride('floor', floor, price)
    else
        Storage.deletePriceOverride('floor', floor)
    end

    for index = 1, #rooms do
        applyRoomPrice(rooms[index])
    end

    syncRooms(rooms, false)

    return { success = true, price = rooms[1].basePrice }
end)

lib.callback.register('rhd_motel:selfservice:getData', function(source)
    local service = SelfService.getStatus()

    if not service.operational then
        local message = 'Motel self service is currently unavailable.'
        if not service.active then
            message = 'Motel self service has not been hired.'
        elseif service.paused then
            message = 'Motel self service is paused.'
        elseif service.staffOnDuty then
            message = 'Hotel staff is currently available.'
        end

        return {
            available = false,
            message = message,
            rooms = json.empty_array,
        }
    end

    local availableRooms = {}

    for index = 1, #DATA.rooms do
        local room = DATA.rooms[index]

        if room.status == 'available' then
            availableRooms[#availableRooms + 1] = room
        end
    end

    local player = Core:GetPlayer(source)
    local playerName = getPlayerName(player, GetPlayerName(source) or 'Guest')

    return {
        available = true,
        rooms = availableRooms,
        playerName = playerName,
    }
end)

lib.callback.register('rhd_motel:selfservice:sendInvoice', function(source, payload)
    if not SelfService.isOperational() then
        return { success = false, message = 'Motel self service is currently unavailable.' }
    end

    return createInvoice(source, payload, true)
end)

lib.callback.register('rhd_motel:invoice:pay', function(source, payload)
    return payInvoice(source, payload and payload.invoiceId)
end)

lib.callback.register('rhd_motel:invoice:decline', function(source, payload)
    local invoiceId = payload and payload.invoiceId
    local invoice = invoiceId and pendingInvoices[invoiceId]

    if not invoice or invoice.targetSource ~= source then
        return { success = false }
    end

    expireInvoice(invoiceId, 'declined')

    return { success = true }
end)

lib.callback.register('rhd_motel:management:selfServiceStatus', function (source)
    return SelfService.isOperational()
end)

lib.addCommand('motel_tablet', {
    help = 'Toggle the motel management tablet.',

}, function (source, args)
    if not Staff.isOnduty(source) then
        notify(source, 'error', 'You do not have access to motel management.')
        return
    end

    Event.emitLatentClient('rhd_motel:management:toggleTablet', source)
end)
