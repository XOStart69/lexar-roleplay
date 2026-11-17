local Storage = {}
Storage.spender = {}

local tablesReady = false
local jsonLocks = {}

---@param label string
---@param fn function
---@param fallback any
---@return any
local function safeCall(label, fn, fallback)
    local success, result = pcall(fn)
    if not success then
        lib.print.warn(('[CasinoStorage] %s failed'):format(label))
        lib.print.error(result)
        return fallback
    end
    return result
end

Storage.safeCall = safeCall

---@param key string
---@param label string
---@param fn function
---@param fallback any
---@return any
local function withJsonLock(key, label, fn, fallback)
    while jsonLocks[key] do
        Wait(0)
    end

    jsonLocks[key] = true
    local success, result = pcall(fn)
    jsonLocks[key] = nil

    if not success then
        lib.print.warn(('[CasinoStorage] %s failed'):format(label))
        lib.print.error(result)
        return fallback
    end

    return result
end

local function ensureTables()
    if tablesReady then return true end

    local ok = safeCall('ensure tables', function()
        db:execute_async([[
            create table if not exists rhd_casino_players (
                identifier varchar(64) not null,
                name varchar(128) null,
                buyin json null,
                image varchar(512) null,
                totalchipwin bigint unsigned not null default 0,
                luckywheel json null,
                metadata json null,
                created_at timestamp not null default current_timestamp,
                updated_at timestamp not null default current_timestamp on update current_timestamp,
                primary key (identifier)
            )
        ]])

        db:execute_async([[
            create table if not exists rhd_casino_top_spenders (
                id varchar(128) not null,
                name varchar(128) not null,
                image varchar(512) null,
                amount bigint unsigned not null default 0,
                updated_at timestamp not null default current_timestamp on update current_timestamp,
                primary key (id)
            )
        ]])

        db:execute_async([[
            create table if not exists rhd_casino_sportsbook_rankings (
                id varchar(64) not null,
                board varchar(16) not null,
                name varchar(128) not null,
                image varchar(512) null,
                wins int unsigned not null default 0,
                losses int unsigned not null default 0,
                points int unsigned not null default 0,
                updated_at timestamp not null default current_timestamp on update current_timestamp,
                primary key (id),
                key board (board)
            )
        ]])

        return true
    end, false)

    tablesReady = ok == true
    return tablesReady
end

Citizen.CreateThreadNow(ensureTables)

local function encodeJson(value)
    return json.encode(value or {})
end

local function decodeJson(value)
    if not value or value == '' then return {} end

    local ok, decoded = pcall(json.decode, value)
    if not ok or type(decoded) ~= 'table' then return {} end
    return decoded
end

---@param identifier string?
---@param name string?
---@return boolean
local function ensurePlayerRow(identifier, name)
    if not identifier or not ensureTables() then return false end

    return safeCall('ensure casino player row', function()
        db:execute_async([[
            insert into rhd_casino_players (identifier, name)
            values (@identifier, @name)
            on duplicate key update
                name = coalesce(values(name), name)
        ]], {
            identifier = identifier,
            name = name
        })
        return true
    end, false)
end

---@param source number
---@param amount number
---@param game string?
---@return boolean
function Storage.recordChipWinnings(source, amount, game)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end

    local identifier = shared.getIdentifier(source)
    if not identifier then return false end
    if not ensureTables() then return false end

    return safeCall('record chip winnings', function()
        db:execute_async([[
            insert into rhd_casino_players (
                identifier, name, totalchipwin
            ) values (
                @identifier, @player_name, @amount
            )
            on duplicate key update
                name = values(name),
                totalchipwin = totalchipwin + values(totalchipwin)
        ]], {
            identifier = identifier,
            player_name = shared.getPlayerName(source),
            amount = amount,
        })
        return true
    end, false)
end

---@param identifier string?
---@return integer
function Storage.getTotalChipWinnings(identifier)
    if not identifier or not ensureTables() then return 0 end

    local total = safeCall('get total chip winnings', function()
        return db:scalar_async([[
            select totalchipwin
            from rhd_casino_players
            where identifier = @identifier
            limit 1
        ]], {
            identifier = identifier
        })
    end, 0)

    return tonumber(total) or 0
end

---@param top number?
---@return table[]
function Storage.getTopChipWinners(top)
    if not ensureTables() then return {} end

    top = math.floor(tonumber(top) or 10)
    if top < 1 then top = 10 end
    if top > 100 then top = 100 end

    return safeCall('get top chip winners', function()
        return db:query_async([[
            select
                identifier,
                name,
                name as player_name,
                image,
                totalchipwin,
                totalchipwin as total_chip_winnings,
                totalchipwin as amount
            from rhd_casino_players
            where totalchipwin > 0
            order by totalchipwin desc
            limit @top
        ]], {
            top = top
        })
    end, {}) or {}
end

---@return boolean
function Storage.resetChipWinnings()
    if not ensureTables() then return false end

    return safeCall('reset chip winnings', function()
        db:execute_async([[
            update rhd_casino_players
            set totalchipwin = 0
            where totalchipwin > 0
        ]])
        return true
    end, false)
end

---@param identifier string?
---@return string?
function Storage.getPokerImage(identifier)
    if not identifier or not ensureTables() then return nil end

    return safeCall('get poker image', function()
        return db:scalar_async([[
            select image
            from rhd_casino_players
            where identifier = @identifier
            limit 1
        ]], {
            identifier = identifier
        })
    end, nil)
end

---@param identifier string?
---@param image string
---@return boolean
function Storage.setPokerImage(identifier, image)
    if not identifier or not ensureTables() then return false end

    return safeCall('set poker image', function()
        db:execute_async([[
            insert into rhd_casino_players (identifier, image)
            values (@identifier, @image)
            on duplicate key update image = values(image)
        ]], {
            identifier = identifier,
            image = image
        })
        return true
    end, false)
end

---@param identifier string?
---@param tableId integer
---@param chips integer
---@return boolean
function Storage.saveBuyIn(identifier, tableId, chips)
    if not identifier or not tableId or not ensureTables() then return false end

    chips = math.floor(tonumber(chips) or 0)
    tableId = math.floor(tonumber(tableId) or 0)
    if tableId <= 0 then return false end

    return withJsonLock(('buyin:%s'):format(identifier), 'save poker buy-in', function()
        ensurePlayerRow(identifier)
        local current = db:scalar_async([[
            select buyin
            from rhd_casino_players
            where identifier = @identifier
            limit 1
        ]], {
            identifier = identifier
        })
        local buyin = decodeJson(current)
        buyin[tostring(tableId)] = {
            chips = chips,
            updated_at = os.time()
        }

        db:execute_async([[
            update rhd_casino_players
            set buyin = @buyin
            where identifier = @identifier
        ]], {
            identifier = identifier,
            buyin = encodeJson(buyin)
        })
        return true
    end, false)
end

---@param identifier string?
---@param tableId integer?
---@return BuyInData?
function Storage.loadBuyIn(identifier, tableId)
    if not identifier or not ensureTables() then return nil end

    local data = safeCall('load poker buy-in', function()
        local stored = db:scalar_async([[
            select buyin
            from rhd_casino_players
            where identifier = @identifier
            limit 1
        ]], {
            identifier = identifier
        })
        local buyin = decodeJson(stored)

        if tableId then
            return buyin[tostring(math.floor(tonumber(tableId) or 0))]
        end

        local latest
        for _, value in pairs(buyin) do
            if type(value) == 'table' and value.chips then
                if not latest or (tonumber(value.updated_at) or 0) > (tonumber(latest.updated_at) or 0) then
                    latest = value
                end
            end
        end
        return latest
    end, nil)

    if not data then return nil end
    return { chips = tonumber(data.chips) or 0 }
end

---@param identifier string?
---@param tableId integer?
---@return boolean
function Storage.clearBuyIn(identifier, tableId)
    if not identifier or not ensureTables() then return false end

    return withJsonLock(('buyin:%s'):format(identifier), 'clear poker buy-in', function()
        local stored = db:scalar_async([[
            select buyin
            from rhd_casino_players
            where identifier = @identifier
            limit 1
        ]], {
            identifier = identifier
        })
        local buyin = decodeJson(stored)

        if tableId then
            buyin[tostring(math.floor(tonumber(tableId) or 0))] = nil
        else
            buyin = {}
        end

        db:execute_async([[
            update rhd_casino_players
            set buyin = @buyin
            where identifier = @identifier
        ]], {
            identifier = identifier,
            buyin = encodeJson(buyin)
        })
        return true
    end, false)
end

---@param identifier string?
---@param cooldownType string
---@return integer?
function Storage.getLuckyWheelTimestamp(identifier, cooldownType)
    if not identifier or not ensureTables() then return nil end

    local value = safeCall('get lucky wheel timestamp', function()
        local stored = db:scalar_async([[
            select luckywheel
            from rhd_casino_players
            where identifier = @identifier
            limit 1
        ]], {
            identifier = identifier
        })
        local luckywheel = decodeJson(stored)
        return luckywheel[cooldownType]
    end, nil)

    return tonumber(value)
end

---@param identifier string?
---@param cooldownType string
---@param timestamp integer
---@return boolean
function Storage.setLuckyWheelTimestamp(identifier, cooldownType, timestamp)
    if not identifier or not ensureTables() then return false end

    return withJsonLock(('luckywheel:%s'):format(identifier), 'set lucky wheel timestamp', function()
        ensurePlayerRow(identifier)
        local stored = db:scalar_async([[
            select luckywheel
            from rhd_casino_players
            where identifier = @identifier
            limit 1
        ]], {
            identifier = identifier
        })
        local luckywheel = decodeJson(stored)
        luckywheel[cooldownType] = math.floor(tonumber(timestamp) or os.time())

        db:execute_async([[
            update rhd_casino_players
            set luckywheel = @luckywheel
            where identifier = @identifier
        ]], {
            identifier = identifier,
            luckywheel = encodeJson(luckywheel)
        })
        return true
    end, false)
end

---@param count number?
---@return table[]
function Storage.spender.getTopSpender(count)
    if not ensureTables() then return {} end

    count = math.floor(tonumber(count) or 10)
    if count < 1 then count = 10 end
    if count > 100 then count = 100 end

    return safeCall('get top spender', function()
        return db:query_async([[
            select name, image, amount
            from rhd_casino_top_spenders
            order by amount desc
            limit @count
        ]], {
            count = count
        })
    end, {}) or {}
end

function Storage.spender.getSpenders()
    if not ensureTables() then return {} end

    return safeCall('get all spenders', function()
        return db:query_async([[
            select id, name, image, amount
            from rhd_casino_top_spenders
        ]], {})
    end, {}) or {}
end

local function generateUUID()
    local id

    repeat
        id = ('cs-%s-%s'):format(
            math.random(100000, 999999),
            math.random(100000, 999999)
        )
    until db:scalar_async([[
        select 1 from rhd_casino_top_spenders where id = ? limit 1
    ]], { id }) == nil

    return id
end

---@param data { id: string, name: string, image: string?, amount: number }
---@return boolean
function Storage.spender.insertOrUpdate(data)
    if type(data) ~= 'table' then return false end

    data.id = data.id or generateUUID()
    if type(data.id) ~= 'string' or data.id == '' then return false end
    if type(data.name) ~= 'string' or data.name == '' then return false end

    local amount = math.floor(tonumber(data.amount) or 0)
    if amount < 0 then amount = 0 end

    return safeCall('insert or update top spender', function()
        db:execute_async([[
            insert into rhd_casino_top_spenders (id, name, image, amount)
            values (@id, @name, @image, @amount)
            on duplicate key update
                id = coalesce(values(id), id),
                name = coalesce(values(name), name),
                image = coalesce(values(image), image),
                amount = values(amount)
        ]], {
            id = data.id,
            name = data.name,
            image = data.image,
            amount = amount
        })
        return true
    end, false)
end

function Storage.spender.remove(id)
    if not id or not ensureTables() then return false end

    return safeCall('remove top spender', function()
        db:execute_async([[
            delete from rhd_casino_top_spenders
            where id = @id
        ]], {
            id = id
        })
        return true
    end, false)
end

Storage.getAllSpenders = Storage.spender.getSpenders
Storage.getTopSpender = Storage.spender.getTopSpender
Storage.insertOrUpdateSpender = Storage.spender.insertOrUpdate
Storage.removeSpender = Storage.spender.remove

Storage.ranking = {}

---@param board string
---@param limit number?
---@return table[]
function Storage.ranking.list(board, limit)
    if not ensureTables() then return {} end

    limit = math.floor(tonumber(limit) or 100)
    if limit < 1 or limit > 100 then limit = 100 end

    return safeCall('list sportsbook ranking', function()
        return db:query_async([[
            select id, name, image, wins, losses, points
            from rhd_casino_sportsbook_rankings
            where board = @board
            order by points desc, wins desc, losses asc, name asc
            limit @limit
        ]], {
            board = board,
            limit = limit
        })
    end, {}) or {}
end

---@param data { id: string?, board: string, name: string, image: string?, wins: number, losses: number, points: number }
---@return string?
function Storage.ranking.save(data)
    if type(data) ~= 'table' or not ensureTables() then return nil end

    local id = data.id
    if not id then
        repeat
            id = ('rk-%s-%s'):format(math.random(100000, 999999), math.random(100000, 999999))
        until db:scalar_async([[
            select 1 from rhd_casino_sportsbook_rankings where id = ? limit 1
        ]], { id }) == nil
    end

    local saved = safeCall('save sportsbook ranking', function()
        db:execute_async([[
            insert into rhd_casino_sportsbook_rankings (id, board, name, image, wins, losses, points)
            values (@id, @board, @name, @image, @wins, @losses, @points)
            on duplicate key update
                name = values(name),
                image = values(image),
                wins = values(wins),
                losses = values(losses),
                points = values(points)
        ]], {
            id = id,
            board = data.board,
            name = data.name,
            image = data.image,
            wins = data.wins,
            losses = data.losses,
            points = data.points
        })
        return true
    end, false)

    return saved and id or nil
end

---@param board string
---@param id string
---@return boolean
function Storage.ranking.exists(board, id)
    if not ensureTables() then return false end

    return safeCall('check sportsbook ranking', function()
        return db:scalar_async([[
            select 1 from rhd_casino_sportsbook_rankings where id = ? and board = ? limit 1
        ]], { id, board }) ~= nil
    end, false)
end

---@param board string
---@param id string
---@return boolean
function Storage.ranking.remove(board, id)
    if not ensureTables() then return false end

    return safeCall('remove sportsbook ranking', function()
        db:execute_async([[
            delete from rhd_casino_sportsbook_rankings
            where id = @id and board = @board
        ]], {
            id = id,
            board = board
        })
        return true
    end, false)
end

---@param plate string
---@return boolean
function Storage.vehiclePlateExists(plate)
    if not ensureTables() then return false end

    local exists = safeCall('check vehicle plate', function()
        return db:scalar_async([[
            select 1 from player_vehicles
            where plate = @plate or fakeplate = @plate
            limit 1
        ]], {
            plate = plate
        })
    end, nil)

    return exists ~= nil
end

---@param data table
---@return boolean
function Storage.insertVehiclePrize(data)
    if not ensureTables() then return false end

    return safeCall('insert lucky wheel vehicle', function()
        db:insert_async([[
            insert into player_vehicles (
                license, citizenid, vehicle, hash, mods, plate, garage, state
            ) values (
                @license, @citizenid, @model, @hash, @mods, @plate, @garage, @state
            )
        ]], data)
        return true
    end, false)
end

return Storage
