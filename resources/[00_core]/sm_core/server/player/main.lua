-- Rekonstruksi sm_core/server/player/main.lua (qb-core compatible)
-- Inventory TIDAK disimpan di sini: kolom `players.inventory` dikelola ox_inventory.

QBCore.Players = QBCore.Players or {}
QBCore.Player = QBCore.Player or {}

-- Tabel lain yang berisi citizenid dan ikut terhapus saat karakter dihapus.
-- Tambahkan sesuai hasil analisis resource sm_* (format: tabel = kolom).
QBCore.Player.CitizenTables = { players = 'citizenid' }

---------------------------------------------------------------------------
-- helpers
---------------------------------------------------------------------------

local function resolve(value)
    local kind = type(value)
    if kind == 'function' then return value() end
    if kind == 'table' then
        local copy = {}
        for k, v in pairs(value) do copy[k] = resolve(v) end
        return copy
    end
    return value
end

local function fillDefaults(data, defaults)
    for key, default in pairs(defaults) do
        local current = data[key]
        if current == nil then
            data[key] = resolve(default)
        elseif type(current) == 'table' and type(default) == 'table' then
            fillDefaults(current, default)
        end
    end
    return data
end

local function toVec4(pos)
    local kind = type(pos)
    if kind == 'vector4' then return pos end
    if kind == 'vector3' then return vec4(pos.x, pos.y, pos.z, 0.0) end
    if kind == 'table' and pos.x and pos.y and pos.z then
        return vec4(pos.x + 0.0, pos.y + 0.0, pos.z + 0.0, (pos.w or pos.h or 0.0) + 0.0)
    end
    return QBConfig.DefaultSpawn
end

local function safeDecode(raw, fallback)
    if type(raw) ~= 'string' or raw == '' then return fallback end
    local ok, decoded = pcall(json.decode, raw)
    if ok and decoded ~= nil then return decoded end
    return fallback
end

local function uniqueMeta(path, generate)
    local value
    repeat
        value = generate()
        local taken = db.scalar_async(
            "SELECT 1 FROM players WHERE JSON_UNQUOTE(JSON_EXTRACT(metadata, '" .. path .. "')) = ? LIMIT 1",
            { value })
    until not taken
    return value
end

---------------------------------------------------------------------------
-- id generators (dipakai oleh config.lua -> PlayerDefaults)
---------------------------------------------------------------------------

function QBCore.Player.CreateCitizenId()
    local id
    repeat
        id = lib.string.random('AAA11111')
        local taken = db.scalar_async('SELECT 1 FROM players WHERE citizenid = ? LIMIT 1', { id })
    until not taken
    return id
end

function QBCore.Player.CreateFingerId()
    return uniqueMeta('$.fingerprint', function() return lib.string.random('Aa111AAa11AAA1111') end)
end

function QBCore.Player.CreateWalletId()
    return uniqueMeta('$.walletid', function() return 'SM-' .. math.random(11111111, 99999999) end)
end

function QBCore.Player.CreateSerialNumber()
    return uniqueMeta('$.phonedata.SerialNumber', function() return tostring(math.random(11111111, 99999999)) end)
end

---------------------------------------------------------------------------
-- job / gang builders (dibaca ulang dari QBShared supaya selalu sinkron)
---------------------------------------------------------------------------

---@return table?
function QBCore.Player.BuildJob(name, grade, onDuty)
    local job = QBShared.Jobs[name]
    if not job then return end
    local gradeKey = tostring(grade or 0)
    local gradeData = job.grades[gradeKey]
    if not gradeData then return end

    if onDuty == nil then onDuty = job.defaultDuty end

    return {
        name = name,
        label = job.label,
        payment = gradeData.payment or 30,
        type = job.type or 'none',
        onduty = onDuty and true or false,
        isboss = gradeData.isboss or false,
        grade = { name = gradeData.name, level = tonumber(gradeKey) },
    }
end

---@return table?
function QBCore.Player.BuildGang(name, grade)
    local gang = QBShared.Gangs[name]
    if not gang then return end
    local gradeKey = tostring(grade or 0)
    local gradeData = gang.grades[gradeKey]
    if not gradeData then return end

    return {
        name = name,
        label = gang.label,
        isboss = gradeData.isboss or false,
        grade = { name = gradeData.name, level = tonumber(gradeKey) },
    }
end

---------------------------------------------------------------------------
-- player data
---------------------------------------------------------------------------

local function decodeRow(row)
    return {
        citizenid = row.citizenid,
        cid = tonumber(row.cid) or 1,
        license = row.license,
        name = row.name,
        money = safeDecode(row.money, {}),
        charinfo = safeDecode(row.charinfo, {}),
        job = safeDecode(row.job, {}),
        gang = safeDecode(row.gang, {}),
        position = toVec4(safeDecode(row.position, nil)),
        metadata = safeDecode(row.metadata, {}),
        items = {},
    }
end

---@param source? Source nil => offline
---@param PlayerData? table
function QBCore.Player.CheckPlayerData(source, PlayerData)
    PlayerData = PlayerData or {}
    local offline = true

    if source then
        PlayerData.source = source
        PlayerData.license = PlayerData.license or QBCore.Functions.GetIdentifier(source, QBConfig.LicenseType)
        PlayerData.name = GetPlayerName(tostring(source))
        offline = false
    end

    -- money: pastikan semua tipe uang ada
    PlayerData.money = type(PlayerData.money) == 'table' and PlayerData.money or {}
    for moneytype, start in pairs(QBConfig.Money.MoneyTypes) do
        if PlayerData.money[moneytype] == nil then PlayerData.money[moneytype] = start end
    end

    fillDefaults(PlayerData, QBConfig.Player.PlayerDefaults)

    -- job / gang divalidasi terhadap QBShared (kalau sudah dihapus => reset)
    local job = PlayerData.job
    local builtJob = job and job.name and QBCore.Player.BuildJob(job.name, job.grade and job.grade.level, job.onduty)
    if builtJob then
        if QBShared.ForceJobDefaultDutyAtLogin and not offline then
            builtJob.onduty = QBShared.Jobs[builtJob.name].defaultDuty and true or false
        end
        PlayerData.job = builtJob
    else
        PlayerData.job = QBCore.Player.BuildJob('unemployed', 0)
    end

    local gang = PlayerData.gang
    local builtGang = gang and gang.name and QBCore.Player.BuildGang(gang.name, gang.grade and gang.grade.level)
    PlayerData.gang = builtGang or QBCore.Player.BuildGang('none', 0)

    PlayerData.position = toVec4(PlayerData.position)
    PlayerData.items = PlayerData.items or {}

    return QBCore.Player.CreatePlayer(PlayerData, offline)
end

function QBCore.Player.CreatePlayer(PlayerData, Offline)
    local self = { Functions = {}, PlayerData = PlayerData, Offline = Offline }

    SetupPlayerMethods(self) -- server/player/method.lua

    if self.Offline then return self end

    local src = self.PlayerData.source
    QBCore.Players[src] = self
    Player(src).state:set('isLoggedIn', true, true)
    QBCore.Player.Save(src)

    -- instance siap dipakai resource lain (ox_inventory bridge mendengarkan event ini)
    TriggerEvent('QBCore:Server:PlayerLoaded', self)
    self.Functions.UpdatePlayerData()

    return self
end

---@param source Source|string|number
---@param key? string
function QBCore.Player.GetPlayerData(source, key)
    local player = QBCore.Players[tonumber(source)]
    if not player then return end
    if key then return player.PlayerData[key] end
    return player.PlayerData
end

function QBCore.Player.GetOfflinePlayer(citizenid)
    if not citizenid then return end
    local row = db.single_async('SELECT * FROM players WHERE citizenid = ?', { citizenid })
    if not row then return end
    return QBCore.Player.CheckPlayerData(nil, decodeRow(row))
end

---@return boolean
function QBCore.Player.Login(source, citizenid, newData)
    if not source or source == '' then return false end

    if citizenid then
        local license = QBCore.Functions.GetIdentifier(source, QBConfig.LicenseType)
        local row = db.single_async('SELECT * FROM players WHERE citizenid = ?', { citizenid })
        if row and license and row.license == license then
            QBCore.Player.CheckPlayerData(source, decodeRow(row))
            return true
        end
        DropPlayer(tostring(source), Lang:t('info.exploit_dropped'))
        return false
    end

    QBCore.Player.CheckPlayerData(source, newData)
    return true
end

---------------------------------------------------------------------------
-- saving
---------------------------------------------------------------------------

local SAVE_QUERY = [[
    INSERT INTO players (citizenid, cid, license, name, money, charinfo, job, gang, position, metadata)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ON DUPLICATE KEY UPDATE
        name = VALUES(name), money = VALUES(money), charinfo = VALUES(charinfo),
        job = VALUES(job), gang = VALUES(gang), position = VALUES(position), metadata = VALUES(metadata)
]]

local LIGHT_QUERY = 'UPDATE players SET money = ?, position = ?, metadata = ? WHERE citizenid = ?'

local function syncFromPed(player)
    local data = player.PlayerData
    local ped = GetPlayerPed(tostring(data.source))
    if not ped or ped == 0 or not DoesEntityExist(ped) then return end

    local coords = GetEntityCoords(ped)
    if coords.x ~= 0.0 or coords.y ~= 0.0 then
        data.position = vec4(coords.x, coords.y, coords.z, GetEntityHeading(ped))
    end

    if not data.metadata.isdead and not data.metadata.inlaststand then
        local health = GetEntityHealth(ped)
        if health and health > 100 then data.metadata.health = health end
        data.metadata.armor = GetPedArmour(ped)
    end
end

local function fullParams(data)
    return {
        data.citizenid, data.cid, data.license, data.name,
        json.encode(data.money), json.encode(data.charinfo), json.encode(data.job), json.encode(data.gang),
        json.encode(data.position), json.encode(data.metadata),
    }
end

---Simpan semua kolom (kecuali inventory).
function QBCore.Player.Save(source)
    local player = QBCore.Players[tonumber(source)]
    if not player then return false end
    syncFromPed(player)
    db.insert_async(SAVE_QUERY, fullParams(player.PlayerData))
    return true
end

---Simpan ringan (money + position + metadata). Dipakai di siklus QBConfig.UpdateInterval biasa.
function QBCore.Player.SaveLight(source)
    local player = QBCore.Players[tonumber(source)]
    if not player then return false end
    syncFromPed(player)
    local data = player.PlayerData
    db.update_async(LIGHT_QUERY, {
        json.encode(data.money), json.encode(data.position), json.encode(data.metadata), data.citizenid,
    })
    return true
end

function QBCore.Player.SaveOffline(PlayerData)
    if not PlayerData then return false end
    db.insert_async(SAVE_QUERY, fullParams(PlayerData))
    return true
end

---------------------------------------------------------------------------
-- logout / delete
---------------------------------------------------------------------------

function QBCore.Player.Logout(source)
    source = tonumber(source)
    local player = QBCore.Players[source]
    if not player then return end

    QBCore.Player.Save(source)

    TriggerClientEvent('QBCore:Client:OnPlayerUnload', source)
    TriggerEvent('QBCore:Server:OnPlayerUnload', source)
    TriggerClientEvent('QBCore:Player:setPData', source, 'all', {})
    Player(source).state:set('isLoggedIn', false, true)

    Wait(200)
    QBCore.Players[source] = nil
end

function QBCore.Player.ForceDeleteCharacter(citizenid)
    local online = QBCore.Functions.GetPlayerByCitizenId(citizenid)
    if online then
        DropPlayer(tostring(online.PlayerData.source), 'Karakter kamu dihapus oleh server.')
    end

    for tableName, column in pairs(QBCore.Player.CitizenTables) do
        local ok, err = pcall(function()
            db.update_async(('DELETE FROM `%s` WHERE `%s` = ?'):format(tableName, column), { citizenid })
        end)
        if not ok then lib.print.warn(('delete %s.%s gagal: %s'):format(tableName, column, err)) end
    end

    TriggerEvent('QBCore:Server:OnPlayerDeleted', citizenid)
    return true
end

function QBCore.Player.DeleteCharacter(source, citizenid)
    local license = QBCore.Functions.GetIdentifier(source, QBConfig.LicenseType)
    local ownerLicense = db.scalar_async('SELECT license FROM players WHERE citizenid = ?', { citizenid })

    if ownerLicense and license and ownerLicense == license then
        return QBCore.Player.ForceDeleteCharacter(citizenid)
    end

    DropPlayer(tostring(source), Lang:t('info.exploit_dropped'))
    return false
end
