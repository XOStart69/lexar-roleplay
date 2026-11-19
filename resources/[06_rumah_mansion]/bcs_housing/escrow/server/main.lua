local T = Config.Server.tables
local schema = require 'escrow.server.schema'

Housing = Housing or {}
Housing.homes = Housing.homes or {}
Housing.players = Housing.players or {}
Housing.starter = Housing.starter or {}
Housing.booted = false

---@param identifier string?
---@return table?
function Housing:GetHome(identifier)
    if not identifier then return nil end
    return self.homes[identifier]
end

---@param src number
---@return string?
function Housing:GetIdentifier(src)
    local player = QBCore.Functions.GetPlayer(src)
    return player and player.PlayerData.citizenid or nil
end

---@param src number
---@return string?, string?
function Housing:GetPlayerContext(src)
    local data = self.players[src]
    if not data then return nil, nil end
    return data.identifier, data.homeId
end

---@param src number
---@return boolean
function Housing:IsAdmin(src)
    if IsPlayerAceAllowed(src, Config.Server.ace) then return true end

    local player = QBCore.Functions.GetPlayer(src)
    if not player then return false end

    local job = player.PlayerData.job
    if job and Config.Admin.Jobs and Config.Admin.Jobs[job.name] then
        local minGrade = Config.Admin.Jobs[job.name]
        if type(minGrade) == 'number' then
            return job.grade.level >= minGrade
        end
        return true
    end

    for _, group in ipairs(Config.Admin.Groups or {}) do
        if IsPlayerAceAllowed(src, ('group.%s'):format(group)) then return true end
    end
    return false
end

---@param src number
---@return table?, string?
function Housing:GetAgentJob(src)
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return nil, nil end

    local job = player.PlayerData.job
    if not job then return nil, nil end

    local cfg = JobConfig.jobs[job.name]
    if not cfg then return nil, nil end
    return cfg, job.name
end

---@param src number
---@param permission string
---@return boolean
function Housing:IsAgent(src, permission)
    local cfg, jobName = self:GetAgentJob(src)
    if not cfg then return false end

    local minGrade = cfg.permission and cfg.permission[permission]
    if not minGrade then return false end

    local player = QBCore.Functions.GetPlayer(src)
    return player.PlayerData.job.grade.level >= minGrade
end

---@param src number
---@param home table
---@param permission string
---@return boolean
function Housing:CanManage(src, home, permission)
    if self:IsAdmin(src) then return true end
    local cfg, jobName = self:GetAgentJob(src)
    if not cfg or home.realestate ~= jobName then return false end
    return self:IsAgent(src, permission)
end

---@param identifier string
---@return number
function Housing:GetOwnedCount(identifier)
    local count = 0
    for _, home in pairs(self.homes) do
        if home.owner == identifier then count = count + 1 end
        for i = 1, #home.apartments do
            if home.apartments[i].owner == identifier then count = count + 1 end
        end
    end
    return count
end

---@param identifier string
---@return table[]
function Housing:GetHomesByOwner(identifier)
    local list = {}
    for _, home in pairs(self.homes) do
        if home:IsOwner(identifier) then list[#list + 1] = home end
    end
    return list
end

---@param jobName string
---@return table[]
function Housing:GetHomesByRealestate(jobName)
    local list = {}
    for _, home in pairs(self.homes) do
        if home.realestate == jobName then list[#list + 1] = home end
    end
    return list
end

---@param src number
function Housing:SendHomeList(src)
    local list = {}
    for _, home in pairs(self.homes) do
        list[#list + 1] = Minify(home:Snapshot())
    end
    TriggerClientEvent('Housing:client:LoadHomeList', src, msgpack.pack(list))
end

---@param src number
---@param home table
function Housing:SendHome(src, home)
    TriggerClientEvent('Housing:client:LoadHome', src, Minify(home:Snapshot()))
end

function Housing:BroadcastHome(home)
    TriggerClientEvent('Housing:client:LoadHome', -1, Minify(home:Snapshot()))
end

---@param action string
---@param message string
---@param home table|string|nil
---@param author string|nil
function Housing:Log(action, message, home, author)
    local identifier = type(home) == 'table' and home.identifier or home
    local enabled = Config.Server.log.enabled and Config.Server.log.events[action]

    MySQL.insert(('INSERT INTO `%s` (`home`, `action`, `message`, `author`, `created_at`) VALUES (?, ?, ?, ?, ?)'):format(T.logs),
        { identifier, action, message, author, os.time() })

    if not enabled or Config.Server.log.webhook == '' then return end

    PerformHttpRequest(Config.Server.log.webhook, function() end, 'POST', json.encode({
        username = 'Housing',
        embeds = { {
            title = action,
            description = message,
            color = 3447003,
            footer = { text = ('%s | %s'):format(identifier or '-', author or '-') },
        } },
    }), { ['Content-Type'] = 'application/json' })
end

---@param tableName string
---@return table[]
local function fetchChildren(tableName)
    return MySQL.query(('SELECT * FROM `%s`'):format(tableName)) or {}
end

local function groupChildren(rows)
    local grouped = {}
    for _, row in ipairs(rows) do
        local list = grouped[row.home]
        if not list then
            list = {}
            grouped[row.home] = list
        end
        list[#list + 1] = row
    end
    return grouped
end

---@param value string?
---@return table
local function decode(value)
    if type(value) == 'table' then return value end
    if type(value) == 'string' and value ~= '' then
        local ok, parsed = pcall(json.decode, value)
        if ok and type(parsed) == 'table' then return parsed end
    end
    return {}
end

local function loadHomes()
    local rows = MySQL.query(('SELECT * FROM `%s`'):format(T.homes)) or {}
    if #rows == 0 then return end

    local doors = groupChildren(fetchChildren(T.doors))
    local garages = groupChildren(fetchChildren(T.garages))
    local teleports = groupChildren(fetchChildren(T.teleports))
    local storages = groupChildren(fetchChildren(T.storages))
    local wardrobes = groupChildren(fetchChildren(T.wardrobes))
    local furniture = groupChildren(fetchChildren(T.furniture))
    local keyRows = groupChildren(fetchChildren(T.keys))
    local apartmentRows = groupChildren(fetchChildren(T.apartments))
    local mortgageRows = groupChildren(fetchChildren(T.mortgages))

    for _, row in ipairs(rows) do
        local home = HousingHome:new(row)
        local id = home.identifier

        for _, door in ipairs(doors[id] or {}) do
            home.doors[#home.doors + 1] = {
                name = door.name, coords = decode(door.coords), model = door.model, state = door.state == 1,
            }
        end

        for _, garage in ipairs(garages[id] or {}) do
            home.garages[#home.garages + 1] = {
                name = garage.name, coords = decode(garage.coords), type = garage.type and decode(garage.type) or nil,
            }
        end

        for _, teleport in ipairs(teleports[id] or {}) do
            home.teleports[#home.teleports + 1] = {
                name = teleport.name, inside = decode(teleport.inside),
                outside = decode(teleport.outside), locked = teleport.locked == 1,
            }
        end

        for _, storage in ipairs(storages[id] or {}) do
            home.storages[#home.storages + 1] = {
                id = storage.storageId, coords = decode(storage.coords), area = storage.area,
                weight = storage.weight, slots = storage.slots, type = storage.type,
            }
        end

        for _, wardrobe in ipairs(wardrobes[id] or {}) do
            home.wardrobes[#home.wardrobes + 1] = {
                name = wardrobe.name, coords = decode(wardrobe.coords), outfits = decode(wardrobe.outfits),
            }
        end

        for _, item in ipairs(furniture[id] or {}) do
            home.furniture[#home.furniture + 1] = {
                model = item.model, label = item.label, coords = decode(item.coords),
                rotation = decode(item.rotation), heading = item.heading,
                area = item.area, identifier = item.identifier,
            }
        end

        local keyList, keyHolders = {}, {}
        for _, key in ipairs(keyRows[id] or {}) do
            local entry = { name = key.name, permissions = decode(key.permissions) }
            if key.isList == 1 then
                keyList[#keyList + 1] = entry
            else
                entry.identifier = key.holder
                keyHolders[#keyHolders + 1] = entry
            end
        end
        home.keys = HousingKeys:new(id, keyList, keyHolders)

        for _, apt in ipairs(apartmentRows[id] or {}) do
            home.apartments[#home.apartments + 1] = HousingApartment:new(apt)
        end

        for _, mortgage in ipairs(mortgageRows[id] or {}) do
            home.mortgages[#home.mortgages + 1] = mortgage
        end

        Housing.homes[id] = home
    end
end

local function loadStarter()
    local rows = MySQL.query(('SELECT `home` FROM `%s`'):format(T.starter)) or {}
    for _, row in ipairs(rows) do
        Housing.starter[row.home] = true
    end
end

---@param days number
---@return number
local function daysAgo(days)
    return os.time() - (days * 86400)
end

local function rentLoop()
    while true do
        Wait(600000)

        for _, home in pairs(Housing.homes) do
            local rent = home.rent
            if rent and rent.isRented and rent.dueAt and rent.dueAt < os.time() then
                rent.overdue = (rent.overdue or 0) + 1

                if rent.overdue > (rent.autoRemove or Config.configuration.AutoRemove) then
                    rent.isRented = false
                    rent.tenant = nil
                    rent.overdue = 0
                    home:SetProperty('data', home.data)
                    Housing:Log('rent', ('Tenant evicted from %s'):format(home.name), home)
                end
            end
        end
    end
end

local function mortgageLoop()
    while true do
        Wait(3600000)

        for _, home in pairs(Housing.homes) do
            if home.bought_at > 0 and home.payment > 0 then
                local deadline = home.bought_at + (Config.Server.mortgage.removeAfter * 86400)
                if home.lastPayment > 0 and home.lastPayment + 86400 * 30 < os.time() and home.lastPayment < deadline then
                    home:ClearOwner()
                    Housing:Log('mortgage', ('Ownership revoked from %s'):format(home.name), home)
                end
            end
        end
    end
end

MySQL.ready(function()
    if Housing.booted then return end

    for _, statement in ipairs(schema) do
        MySQL.query(statement)
    end

    loadHomes()
    loadStarter()

    Housing.booted = true
    print(('[bcs_housing] %d rumah dimuat'):format((function()
        local count = 0
        for _ in pairs(Housing.homes) do count = count + 1 end
        return count
    end)()))

    CreateThread(rentLoop)
    CreateThread(mortgageLoop)
end)

AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
    local src = player.PlayerData.source
    local identifier = player.PlayerData.citizenid
    Housing.players[src] = { identifier = identifier, homeId = nil }
end)

AddEventHandler('QBCore:Server:PlayerDropped', function(source)
    local data = Housing.players[source]
    if data then
        local home = Housing:GetHome(data.homeId)
        if home then home:RemoveInside(source) end
        Housing.players[source] = nil
    end
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if not Housing.booted then return end
    for _, player in pairs(QBCore.Functions.GetPlayers()) do
        local ped = GetPlayerPed(player)
        if ped and ped ~= 0 then
            TriggerClientEvent('Housing:initialize', player)
        end
    end
end)

exports('GetHomes', function()
    return Housing.homes
end)