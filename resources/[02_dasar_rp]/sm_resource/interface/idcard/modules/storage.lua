local id_card = {}
local storage = {}

local queue = {}
local BATCH_SIZE = 5
local INTERVAL_MS = 5 * 60 * 1000 -- 5 menit

local type = type
local pairs = pairs
local jsonEncode = json.encode
local msgpackPack = msgpack.pack
local tableConcat = table.concat

local indexCache = {}

Citizen.CreateThreadNow(function ()
    local card_data = db:query_async([[
        SELECT * FROM player_idcard
    ]])

    if card_data?[1] then
        array.forEach(card_data, function (val)
            id_card[val.citizenid] = json.decode(val.card_data)
        end)
    end

    table.wipe(indexCache)
end)

local function processQueue()
    local total = #queue

    if total == 0 then
        return
    end

    local batch = {}
    for _ = 1, math.min(BATCH_SIZE, #queue) do
        batch[#batch + 1] = table.remove(queue, 1)
    end

    array.forEach(batch, function (citizenid)
        local cards = id_card[citizenid]

        if not cards then
            return
        end

        db:insert_async([[
            INSERT INTO player_idcard (citizenid, card_data)
                VALUES (:citizenid, :card_data)
                    ON DUPLICATE KEY UPDATE card_data = :card_data
        ]], {
            citizenid = citizenid,
            card_data = json.encode(cards)
        })
    end)

    -- lib.print.info(('[IDCARD] Processing %s queue, remaining: %s'):format(#batch, #total))
end

local function saveAllQueue()
    local total = #queue

    if total == 0 then
        return
    end

    array.forEach(queue, function (citizenid)
        local cards = id_card[citizenid]

        if not cards then
            return
        end

        db:insert([[
            INSERT INTO player_idcard (citizenid, card_data)
                VALUES (:citizenid, :card_data)
                    ON DUPLICATE KEY UPDATE card_data = :card_data
        ]], {
            citizenid = citizenid,
            card_data = json.encode(cards)
        })
    end)

    queue = {}
    lib.print.info(('[IDCARD] Saved all queue, Total: %s'):format(total))
end

CreateThread(function ()
    while true do
        Wait(INTERVAL_MS)
        processQueue()
    end
end)

local function addToQueue(citizenid)
    if array.includes(queue, citizenid) then
        return
    end
    queue[#queue + 1] = citizenid
end

function storage.getLicense(citizenid, license)
    if not citizenid then return end
    return id_card[citizenid]?[license]
end

function storage.getLicenses(citizenid)
    if not citizenid then return end
    return id_card[citizenid]
end

function storage.update(citizenid, license, data)
    if not (citizenid and license) then
        return false
    end

    if not id_card[citizenid] then
        id_card[citizenid] = {}
    end

    addToQueue(citizenid)

    local previous = id_card[citizenid][license]
    if previous and previous.management then
        indexCache[previous.management] = nil
    end
    if data and data.management then
        indexCache[data.management] = nil
    end

    id_card[citizenid][license] = data

    return true
end

---@param config table?
---@return string?
---@return string?
local function splitConfig(config)
    if type(config) ~= 'table' then
        return nil, nil
    end

    local profileImage = config.profileImage
    config.profileImage = nil
    local encoded = jsonEncode(config)
    config.profileImage = profileImage

    return encoded, profileImage
end

---@param fields table?
---@return string?
---@return table
local function splitFields(fields)
    local values = {}

    if type(fields) ~= 'table' then
        return nil, values
    end

    local shape = {}

    for i = 1, #fields do
        local field = fields[i]
        local value = field.value
        values[i] = value == nil and false or value
        field.value = nil
        shape[i] = jsonEncode(field)
        field.value = value
    end

    return tableConcat(shape, '\n'), values
end

---@param value string?
---@return integer?
local function parseExpiredToNum(value)
    if type(value) ~= 'string' then
        return nil
    end

    local d, m, y = value:match('^(%d%d?)-(%d%d?)-(%d%d%d%d)$')
    if d then
        return tonumber(y) * 10000 + tonumber(m) * 100 + tonumber(d)
    end

    local y2, m2, d2 = value:match('^(%d%d%d%d)-(%d%d?)-(%d%d?)$')
    if y2 then
        return tonumber(y2) * 10000 + tonumber(m2) * 100 + tonumber(d2)
    end

    return nil
end

local function todayNum()
    local t = os.date('*t')
    return t.year * 10000 + t.month * 100 + t.day
end

---@param data table
---@param today integer
---@return string
---@return boolean
local function cardMeta(data, today)
    local name, expired = 'Unknown', false
    local fields = data.fields

    if type(fields) == 'table' then
        local expiredValue
        for i = 1, #fields do
            local field = fields[i]
            local id = field.id

            if id then
                if id == 'name' then
                    name = field.value or 'Unknown'
                elseif expiredValue == nil then
                    local lid = id:lower()
                    if lid:find('expired', 1, true) or lid:find('berlaku', 1, true) then
                        expiredValue = field.value
                    end
                end
            end
        end

        local num = parseExpiredToNum(expiredValue)
        if num and num < today then
            expired = true
        end
    end

    return name, expired
end

---@param managementId string
local function buildIndex(managementId)
    local today = todayNum()
    local entries = {}
    local typeSet, cardTypes = {}, {}
    local countAll, countActive, countExpired = 0, 0, 0

    for citizenid, card in pairs(id_card) do
        for template, data in pairs(card) do
            if data.management == managementId then
                local name, expired = cardMeta(data, today)

                countAll = countAll + 1
                if expired then
                    countExpired = countExpired + 1
                else
                    countActive = countActive + 1
                end

                entries[#entries + 1] = {
                    citizenid = citizenid,
                    template = template,
                    nameLower = name:lower(),
                    cidLower = citizenid:lower(),
                    tplLower = template:lower(),
                    expired = expired,
                }

                if not typeSet[template] then
                    typeSet[template] = true
                    cardTypes[#cardTypes + 1] = {
                        label = (template:gsub('_', ' ')):upper(),
                        value = template,
                    }
                end

            end
        end
    end

    table.sort(entries, function (a, b)
        if a.nameLower ~= b.nameLower then
            return a.nameLower < b.nameLower
        end
        if a.cidLower ~= b.cidLower then
            return a.cidLower < b.cidLower
        end
        return a.tplLower < b.tplLower
    end)

    table.sort(cardTypes, function (a, b) return a.label < b.label end)

    local index = {
        entries = entries,
        facets = { cardTypes = cardTypes },
        counts = { all = countAll, active = countActive, expired = countExpired },
    }

    indexCache[managementId] = index
    return index
end

local function getIndex(managementId)
    return indexCache[managementId] or buildIndex(managementId)
end

---@param req table
---@return string
function storage.getCardsPage(req)
    local managementId = req.managementId
    local page = math.max(1, tonumber(req.page) or 1)
    local pageSize = math.max(1, tonumber(req.pageSize) or 20)
    local tab = req.tab or 'all'
    local search = req.search
    local cardType = req.cardType
    local citizenidFilter = req.citizenid

    local index = getIndex(managementId)
    local entries = index.entries

    local searchLower = (search and search ~= '') and search:lower() or nil
    if cardType == '' then cardType = nil end
    if citizenidFilter == '' then citizenidFilter = nil end

    local matched

    if tab == 'all' and not searchLower and not cardType and not citizenidFilter then
        matched = entries
    else
        matched = {}
        for i = 1, #entries do
            local e = entries[i]
            local ok = true

            if tab == 'active' and e.expired then
                ok = false
            elseif tab == 'expired' and not e.expired then
                ok = false
            end

            if ok and searchLower then
                if not (e.nameLower:find(searchLower, 1, true)
                     or e.cidLower:find(searchLower, 1, true)
                     or e.tplLower:find(searchLower, 1, true)) then
                    ok = false
                end
            end

            if ok and cardType and e.template ~= cardType then
                ok = false
            end

            if ok and citizenidFilter and e.citizenid ~= citizenidFilter then
                ok = false
            end

            if ok then
                matched[#matched + 1] = e
            end
        end
    end

    local total = #matched
    local startIdx = (page - 1) * pageSize + 1
    local endIdx = math.min(startIdx + pageSize - 1, total)

    local dict, dictIndex = {}, {}
    local list = {}
    local count = 0

    local function intern(str)
        if not str then return 0 end
        local idx = dictIndex[str]
        if not idx then
            idx = #dict + 1
            dict[idx] = str
            dictIndex[str] = idx
        end
        return idx
    end

    for i = startIdx, endIdx do
        local e = matched[i]
        local data = id_card[e.citizenid] and id_card[e.citizenid][e.template]

        if data then
            local configKey, profileImage = splitConfig(data.config)
            local shapeKey, values = splitFields(data.fields)

            local extra
            for k, v in pairs(data) do
                if k ~= 'config' and k ~= 'fields' and k ~= 'template' and k ~= 'citizenid' and k ~= 'management' then
                    extra = extra or {}
                    extra[k] = v
                end
            end

            count = count + 1
            list[count] = {
                e.citizenid,
                intern(e.template),
                intern(configKey),
                profileImage or false,
                intern(shapeKey),
                values,
                extra or false,
            }
        end
    end

    local payload = {
        m = managementId,
        d = dict,
        c = list,
        t = total,
    }

    if req.withMeta then
        payload.k = index.counts
        payload.f = index.facets
    end

    return msgpackPack(payload)
end

function storage.getCards(managementId)
    local cards = {}

    for citizenid, card in pairs(id_card) do
        for template, data in pairs(card) do
            if data.management == managementId then
                cards[#cards+1] = data
                cards[#cards].template = template
                cards[#cards].citizenid = citizenid
            end
        end
    end

    return cards
end

AddEventHandler('txAdmin:events:scheduledRestart', function(eventData)
    if eventData.secondsRemaining == 60 then
        CreateThread(function ()
            saveAllQueue()
        end)
    end
end)

AddEventHandler('txAdmin:events:serverShuttingDown', function()
    saveAllQueue()
end)

AddEventHandler('onResourceStop', function(ResourceName)
    if ResourceName == GetCurrentResourceName() then
        saveAllQueue()
    end
end)

AddEventHandler('onServerResourceStop', function(ResourceName)
    if ResourceName == GetCurrentResourceName() then
        saveAllQueue()
    end
end)


return storage