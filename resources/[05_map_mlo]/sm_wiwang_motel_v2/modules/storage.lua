
local config = require 'config.shared'

local checkoutTime = ('%02d:00:00'):format(
    math.min(23, math.max(0, math.floor(tonumber(config.management.checkoutHour) or 18)))
)

local function mapLog(row)
    return {
        id = ('log-%s'):format(row.id),
        roomId = row.room_id,
        title = row.title,
        description = row.description,
        details = row.description,
        at = row.at,
        date = row.date,
        type = row.log_type,
        amount = tonumber(row.amount) or 0,
    }
end

local function decodeBoolean(value, default)
    if value == nil then return default end
    if type(value) == 'boolean' then return value end
    return tonumber(value) == 1
end

local db = exports.oxmysql
local storage = {}

function storage.ensureTables()
    print('Ensuring database tables...')
    db:execute_async([[
        CREATE TABLE IF NOT EXISTS `rhd_motel_self_service` (
            `service_id` varchar(32) NOT NULL,
            `expires_at` bigint NOT NULL DEFAULT 0,
            `paused` tinyint(1) NOT NULL DEFAULT 0,
            `rented_by` varchar(64) DEFAULT NULL,
            `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`service_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]], {})

    db:execute([[
        CREATE TABLE IF NOT EXISTS `rhd_motel_rooms` (
            `room_id` varchar(32) NOT NULL,
            `door_id` varchar(64) NOT NULL,
            `floor` int NOT NULL,
            `room_number` int NOT NULL,
            `status` varchar(24) NOT NULL DEFAULT 'available',
            `citizen_id` varchar(64) DEFAULT NULL,
            `guest_name` varchar(128) DEFAULT NULL,
            `checkin_date` date DEFAULT NULL,
            `checkout_date` date DEFAULT NULL,
            `price` int NOT NULL DEFAULT 0,
            `note` text DEFAULT NULL,
            `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`room_id`),
            KEY `floor` (`floor`),
            KEY `citizen_id` (`citizen_id`),
            KEY `status` (`status`),
            KEY `checkout_date` (`checkout_date`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {})

    db:execute([[
        CREATE TABLE IF NOT EXISTS `rhd_motel_room_logs` (
            `id` int NOT NULL AUTO_INCREMENT,
            `room_id` varchar(32) NOT NULL,
            `log_type` varchar(32) NOT NULL,
            `title` varchar(128) NOT NULL,
            `description` text NOT NULL,
            `amount` int NOT NULL DEFAULT 0,
            `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `room_id` (`room_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {})

    db:execute([[
        CREATE TABLE IF NOT EXISTS `rhd_motel_furniture` (
            `id` int NOT NULL AUTO_INCREMENT,
            `room_id` varchar(32) NOT NULL,
            `item_id` varchar(64) NOT NULL,
            `model` varchar(96) NOT NULL,
            `label` varchar(128) NOT NULL,
            `price` int NOT NULL DEFAULT 0,
            `visible` tinyint(1) NOT NULL DEFAULT 1,
            `position` longtext NOT NULL,
            `rotation` longtext NOT NULL,
            `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `room_id` (`room_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {})

    db:execute([[
        CREATE TABLE IF NOT EXISTS `rhd_motel_room_occupants` (
            `id` int NOT NULL AUTO_INCREMENT,
            `room_id` varchar(32) NOT NULL,
            `citizen_id` varchar(64) NOT NULL,
            `name` varchar(128) NOT NULL,
            `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `room_occupant` (`room_id`, `citizen_id`),
            KEY `citizen_id` (`citizen_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {})

    db:execute_async([[
        CREATE TABLE IF NOT EXISTS `rhd_motel_room_prices` (
            `scope` varchar(8) NOT NULL,
            `scope_key` varchar(32) NOT NULL,
            `price` int NOT NULL DEFAULT 0,
            `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`scope`, `scope_key`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {})
end

function storage.getSelfServiceRental(serviceId)
    local row = db:single_async([[
        SELECT expires_at, paused, rented_by
        FROM rhd_motel_self_service
        WHERE service_id = ?
        LIMIT 1
    ]], { serviceId })

    if not row then
        return {
            expiresAt = 0,
            paused = false,
            rentedBy = nil,
        }
    end

    return {
        expiresAt = tonumber(row.expires_at) or 0,
        paused = decodeBoolean(row.paused, false),
        rentedBy = row.rented_by,
    }
end

function storage.saveSelfServiceRental(serviceId, rental)
    db:insert_async([[
        INSERT INTO rhd_motel_self_service (service_id, expires_at, paused, rented_by)
        VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            expires_at = VALUES(expires_at),
            paused = VALUES(paused),
            rented_by = VALUES(rented_by)
    ]], {
        serviceId,
        rental.expiresAt or 0,
        rental.paused and 1 or 0,
        rental.rentedBy,
    })
end

function storage.roomExists(roomId)
    return db:scalar_async(
        'SELECT 1 FROM `rhd_motel_rooms` WHERE `room_id` = ? LIMIT 1',
        { roomId }
    ) ~= nil
end

function storage.getPlayerRoomId(citizenId)
    if type(citizenId) ~= "string" then return end

    local roomIds = {}
    local results = db:query_async(([[
        SELECT room.room_id
        FROM rhd_motel_rooms room
        LEFT JOIN rhd_motel_room_occupants occupant
            ON occupant.room_id = room.room_id AND occupant.citizen_id = @citizenId
        WHERE room.status = 'occupied'
            AND room.checkin_date <= CURDATE()
            AND TIMESTAMP(room.checkout_date, '%s') > NOW()
            AND (room.citizen_id = @citizenId OR occupant.citizen_id IS NOT NULL)
    ]]):format(checkoutTime), {
        citizenId = citizenId
    })

    if results and #results > 0 then
        for i=1, #results do
            local result = results[i]
            roomIds[#roomIds+1] = result.room_id
        end
    end

    return roomIds
end

function storage.canAccessRoom(roomId, citizenId)
    if type(roomId) ~= 'string' or type(citizenId) ~= 'string' then
        return false
    end

    local row = db:single_async(([[
        SELECT room.room_id
        FROM rhd_motel_rooms room
        LEFT JOIN rhd_motel_room_occupants occupant
            ON occupant.room_id = room.room_id AND occupant.citizen_id = ?
        WHERE room.door_id = ?
            AND room.status = 'occupied'
            AND room.checkin_date <= CURDATE()
            AND TIMESTAMP(room.checkout_date, '%s') > NOW()
            AND (room.citizen_id = ? OR occupant.citizen_id IS NOT NULL)
        LIMIT 1
    ]]):format(checkoutTime), {
        citizenId,
        roomId,
        citizenId,
    })

    return row ~= nil
end

function storage.loadRoomOccupants(roomById)
    local rows = db:query_async([[
        SELECT room_id, citizen_id, name
        FROM rhd_motel_room_occupants
        ORDER BY id ASC
    ]])

    if type(rows) ~= 'table' then
        return
    end

    for index = 1, #rows do
        local row = rows[index]
        local room = roomById[row.room_id]

        if room then
            room.occupants:push({
                citizenId = row.citizen_id,
                name = row.name,
            })
        end
    end
end

function storage.addRoomOccupant(roomId, citizenId, name)
    db:insert_async([[
        INSERT INTO rhd_motel_room_occupants (room_id, citizen_id, name)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE name = VALUES(name)
    ]], {
        roomId,
        citizenId,
        name,
    })
end

function storage.removeRoomOccupant(roomId, citizenId)
    db:update_async(
        'DELETE FROM `rhd_motel_room_occupants` WHERE `room_id` = ? AND `citizen_id` = ?',
        { roomId, citizenId }
    )
end

function storage.clearRoomOccupants(roomId)
    db:update_async(
        'DELETE FROM `rhd_motel_room_occupants` WHERE `room_id` = ?',
        { roomId }
    )
end

function storage.loadPriceOverrides()
    local rows = db:query_async('SELECT scope, scope_key, price FROM rhd_motel_room_prices')
    local overrides = { rooms = {}, floors = {} }

    if type(rows) ~= 'table' then
        return overrides
    end

    for index = 1, #rows do
        local row = rows[index]
        local price = tonumber(row.price)

        if price then
            if row.scope == 'floor' then
                overrides.floors[tonumber(row.scope_key)] = price
            else
                overrides.rooms[row.scope_key] = price
            end
        end
    end

    return overrides
end

function storage.savePriceOverride(scope, key, price)
    db:insert_async([[
        INSERT INTO rhd_motel_room_prices (scope, scope_key, price)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE price = VALUES(price)
    ]], { scope, tostring(key), price })
end

function storage.deletePriceOverride(scope, key)
    db:update_async('DELETE FROM rhd_motel_room_prices WHERE scope = ? AND scope_key = ?', { scope, tostring(key) })
end

function storage.deleteRoomPriceOverrides(roomIds)
    if type(roomIds) ~= 'table' or #roomIds == 0 then
        return
    end

    db:update_async(
        ("DELETE FROM rhd_motel_room_prices WHERE scope = 'room' AND scope_key IN (%s)"):format(string.rep('?', #roomIds, ',')),
        roomIds
    )
end

function storage.loadRooms(roomById)
    local rows = db:query_async([[
        SELECT room_id, status, citizen_id, guest_name, DATE_FORMAT(checkin_date, '%Y-%m-%d') AS checkin_date,
            DATE_FORMAT(checkout_date, '%Y-%m-%d') AS checkout_date, price, note
        FROM rhd_motel_rooms
    ]])

    if type(rows) ~= 'table' then
        return
    end

    for index = 1, #rows do
        local row = rows[index]
        local room = roomById[row.room_id]

        if room then
            room.status = row.status or room.status
            room.citizenId = row.citizen_id
            room.guestName = row.guest_name
            room.checkinDate = row.checkin_date
            room.checkoutDate = row.checkout_date
            room.price = tonumber(row.price) or room.price
            room.note = row.note
        end
    end
end

function storage.getRecentLogs(limit)
    local rows = db:query_async([[
        SELECT id, room_id, log_type, title, description, amount, DATE_FORMAT(created_at, '%H:%i') AS at,
            DATE_FORMAT(created_at, '%Y-%m-%d') AS date
        FROM rhd_motel_room_logs
        ORDER BY id DESC
        LIMIT ?
    ]], { limit or 5 })

    local logs = {}

    if type(rows) == 'table' then
        for index = 1, #rows do
            logs[#logs + 1] = mapLog(rows[index])
        end
    end

    return logs
end

function storage.getLogTotal()
    local total = db:scalar_async('SELECT COUNT(*) FROM rhd_motel_room_logs')

    return tonumber(total) or 0
end

function storage.getVisitorTrend(days)
    days = math.max(1, tonumber(days) or 7)
    local since = os.date('%Y-%m-%d', os.time() - (days - 1) * 86400)

    local rows = db:query_async([[
        SELECT DATE_FORMAT(created_at, '%Y-%m-%d') AS date, COUNT(*) AS total
        FROM rhd_motel_room_logs
        WHERE log_type = 'checkin' AND DATE(created_at) >= ?
        GROUP BY DATE(created_at)
    ]], { since })

    local counts = {}

    if type(rows) == 'table' then
        for index = 1, #rows do
            local row = rows[index]
            counts[row.date] = tonumber(row.total) or 0
        end
    end

    return counts
end

function storage.getLogs(page, pageSize, total)
    page = math.max(1, tonumber(page) or 1)
    pageSize = math.max(1, tonumber(pageSize) or 8)
    total = tonumber(total) or 0

    local offset = (page - 1) * pageSize
    local rows = db:query_async([[
        SELECT id, room_id, log_type, title, description, amount, DATE_FORMAT(created_at, '%H:%i') AS at,
            DATE_FORMAT(created_at, '%Y-%m-%d') AS date
        FROM rhd_motel_room_logs
        ORDER BY id DESC
        LIMIT ? OFFSET ?
    ]], { pageSize, offset })

    local items = {}

    if type(rows) == 'table' then
        for index = 1, #rows do
            items[#items + 1] = mapLog(rows[index])
        end
    end

    return {
        items = items,
        page = page,
        pageSize = pageSize,
        total = total,
        numberOfPages = math.max(math.ceil(total / pageSize), 1),
    }
end

function storage.getRevenueToday()
    local revenue = db:scalar_async([[
        SELECT COALESCE(SUM(amount), 0)
        FROM rhd_motel_room_logs
        WHERE log_type = 'checkin' AND DATE(created_at) = CURDATE()
    ]])

    return tonumber(revenue) or 0
end

function storage.saveRoom(room)
    db:insert_async([[
        INSERT INTO rhd_motel_rooms
            (room_id, door_id, floor, room_number, status, citizen_id, guest_name, checkin_date, checkout_date, price, note)
        VALUES
            (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            door_id = VALUES(door_id),
            floor = VALUES(floor),
            room_number = VALUES(room_number),
            status = VALUES(status),
            citizen_id = VALUES(citizen_id),
            guest_name = VALUES(guest_name),
            checkin_date = VALUES(checkin_date),
            checkout_date = VALUES(checkout_date),
            price = VALUES(price),
            note = VALUES(note)
    ]], {
        room.id,
        room.doorId,
        room.floor,
        room.number,
        room.status,
        room.citizenId,
        room.guestName,
        room.checkinDate,
        room.checkoutDate,
        room.price,
        room.note,
    })
end

function storage.addLog(roomId, title, description, logType, amount)
    return db:insert_async([[
        INSERT INTO rhd_motel_room_logs (room_id, log_type, title, description, amount)
        VALUES (?, ?, ?, ?, ?)
    ]], {
        roomId,
        logType,
        title,
        description,
        amount or 0,
    })
end

return storage
