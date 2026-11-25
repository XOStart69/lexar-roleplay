-- sm_character/server/init.lua  (revisi 2)
-- Direkonstruksi dan DICOCOKKAN ke kontrak client/*.lua + web UI.
-- Tabel yang dipakai : players, playerskins (sudah ada)
-- Tabel baru         : sm_character_partners, sm_character_invites (dibuat otomatis)
-- Tabel lama character_partners / character_invites tidak disentuh (partner lama dimigrasi sekali).

local QBCore = exports['qb-core']:GetCoreObject()

local RESOURCE        <const> = GetCurrentResourceName()
local DEFAULT_SLOTS   <const> = 4
local INVITE_TTL      <const> = 60   -- detik
local INVITE_COOLDOWN <const> = 3    -- detik antar undangan per pemain
local LINK_TYPES      <const> = { cp = true, bff = true } -- UI: Pasangan / Sahabat

local DEFAULT_POS = { x = -1042.57, y = -2745.72, z = 21.36, w = 330.0 }

-- Daftar lokasi spawn untuk "phone" pemilihan lokasi.
-- type WAJIB salah satu: 'default' | 'house' | 'motel' | 'vip'  ('last' dibuat otomatis).
-- Rumah (bcs_housing) / motel (sm_wiwang_motel_v2) / VIP belum terhubung: tambahkan manual di sini
-- atau sambungkan lewat resource masing-masing.
local Locations = {
    { id = 'bandara', label = 'Bandara', type = 'default', coords = vec4(-1042.57, -2745.72, 21.36, 330.0) },
    -- { id = 'motel1', label = 'Motel', type = 'motel', coords = vec4(0.0, 0.0, 0.0, 0.0), freezeControl = true },
}

local SlotOverrides = {
    -- ['license:xxxxxxxxxxxxxxxxx'] = 8,
}

-- Aturan registrasi: baca config/register.lua (sama dengan yang dipakai UI) supaya server tidak beda aturan.
local Register = { name = { min = 2, max = 20 }, birthYear = { min = 1950, max = 2007 }, nationalities = {} }
do
    local raw = LoadResourceFile(RESOURCE, 'config/register.lua')
    local fn = raw and load(raw, '@config/register.lua')
    if fn then
        local ok, res = pcall(fn)
        if ok and type(res) == 'table' then Register = res end
    end
end

local NATIONALITY = {}
for _, n in ipairs(Register.nationalities or {}) do NATIONALITY[n] = true end

-- ----------------------------------------------------------------------------
-- Helper
-- ----------------------------------------------------------------------------

local function getSlots(license)
    local override = SlotOverrides[license]
    if override then return override end
    local convar = tonumber(GetConvar('sm_characters_slots', ''))
    return math.max(1, convar or DEFAULT_SLOTS)
end

local function notify(src, message, kind)
    -- client: RegisterNetEvent('sm_characters:client:notify', function(data) lib.notify(data) end)
    TriggerClientEvent('sm_characters:client:notify', src, { description = message, type = kind or 'error' })
end

local function decode(value)
    if type(value) == 'table' then return value end
    if type(value) ~= 'string' or value == '' then return {} end
    local ok, result = pcall(json.decode, value)
    if ok and type(result) == 'table' then return result end
    return {}
end

local function getLicense(src)
    return QBCore.Functions.GetIdentifier(src, 'license') or GetPlayerIdentifierByType(src, 'license')
end

local function fullName(charinfo)
    if not charinfo then return 'Warga' end
    local name = ('%s %s'):format(charinfo.firstname or '', charinfo.lastname or ''):gsub('^%s*(.-)%s*$', '%1')
    return name
end

local function placeholders(n)
    local t = {}
    for i = 1, n do t[i] = '?' end
    return table.concat(t, ',')
end

local function generatePhone()
    for _ = 1, 25 do
        local phone = ('%03d%04d'):format(math.random(100, 999), math.random(0, 9999))
        local taken = MySQL.scalar.await('SELECT citizenid FROM players WHERE JSON_UNQUOTE(JSON_EXTRACT(charinfo, "$.phone")) = ?', { phone })
        if not taken then return phone end
    end
    return ('%03d%04d'):format(math.random(100, 999), math.random(0, 9999))
end

local function sourcesForLicense(license)
    local found = {}
    for _, id in ipairs(GetPlayers()) do
        local src = tonumber(id)
        if src and getLicense(src) == license then found[#found + 1] = src end
    end
    return found
end

local function licenseOf(citizenid)
    return MySQL.scalar.await('SELECT license FROM players WHERE citizenid = ?', { citizenid })
end

local function ownedBy(license, citizenid)
    if not license or type(citizenid) ~= 'string' or citizenid == '' then return false end
    local owner = licenseOf(citizenid)
    return owner ~= nil and owner == license
end

local function infoOf(citizenid)
    local row = MySQL.single.await('SELECT charinfo, metadata FROM players WHERE citizenid = ?', { citizenid })
    if not row then return nil, nil end
    return decode(row.charinfo), decode(row.metadata)
end

local function nameOf(citizenid)
    local charinfo = infoOf(citizenid)
    return fullName(charinfo)
end

local function partnerRow(citizenid)
    return MySQL.single.await('SELECT partner, type, since FROM sm_character_partners WHERE citizenid = ?', { citizenid })
end

-- Bentuk objek partner yang dibaca client: character.partner = { citizenid, name, type, child }
local function partnerObject(citizenid, linkType)
    local charinfo, metadata = infoOf(citizenid)
    return {
        citizenid = citizenid,
        name = fullName(charinfo),
        type = linkType or 'cp',
        child = metadata and metadata.child == true or false,
    }
end

local function pushToLicense(license, kind, payload)
    if not license then return end
    for _, src in ipairs(sourcesForLicense(license)) do
        TriggerClientEvent('sm_characters:client:partnerSync', src, kind, payload)
    end
end

-- ----------------------------------------------------------------------------
-- Tabel
-- ----------------------------------------------------------------------------

CreateThread(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `sm_character_partners` (
            `citizenid` VARCHAR(50) NOT NULL,
            `partner`   VARCHAR(50) NOT NULL,
            `type`      VARCHAR(8)  NOT NULL DEFAULT 'cp',
            `since`     INT NOT NULL DEFAULT 0,
            PRIMARY KEY (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `sm_character_invites` (
            `id`      INT NOT NULL AUTO_INCREMENT,
            `sender`  VARCHAR(50) NOT NULL,
            `target`  VARCHAR(50) NOT NULL,
            `type`    VARCHAR(8)  NOT NULL DEFAULT 'cp',
            `expires` BIGINT NOT NULL DEFAULT 0,
            PRIMARY KEY (`id`),
            KEY `sender` (`sender`),
            KEY `target` (`target`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Migrasi satu kali dari tabel lama (diabaikan jika tabel lama tidak ada).
    pcall(function()
        MySQL.query.await("INSERT IGNORE INTO sm_character_partners (citizenid, partner, type, since) SELECT citizenid, partner, 'cp', since FROM character_partners")
    end)

    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `playerskins` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `citizenid` varchar(255) NOT NULL,
            `model` varchar(255) NOT NULL,
            `skin` text NOT NULL,
            `active` tinyint(4) NOT NULL DEFAULT 1,
            PRIMARY KEY (`id`),
            KEY `citizenid` (`citizenid`),
            KEY `active` (`active`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])
end)

-- ----------------------------------------------------------------------------
-- Lokasi spawn
-- ----------------------------------------------------------------------------

local function validPosition(pos)
    if type(pos) ~= 'table' or not pos.x or not pos.y or not pos.z then return false end
    return not (pos.x == 0 and pos.y == 0 and pos.z == 0)
end

-- Bentuk entri yang dibaca phone UI: { id:string, label:string, type:string, coords:vector4, freezeControl? }
local function buildLocations(position)
    local list = {}

    if validPosition(position) then
        list[#list + 1] = {
            id = 'last',
            label = 'Posisi terakhir',
            type = 'last',
            coords = vec4(position.x + 0.0, position.y + 0.0, position.z + 0.0, (position.w or position.a or 0.0) + 0.0),
        }
    end

    for i = 1, #Locations do
        local loc = Locations[i]
        list[#list + 1] = { id = loc.id, label = loc.label, type = loc.type, coords = loc.coords, freezeControl = loc.freezeControl }
    end

    return list
end

-- ----------------------------------------------------------------------------
-- Fetch daftar karakter
-- ----------------------------------------------------------------------------

RegisterNetEvent('sm_characters:server:fetch', function()
    local src = source
    local license = getLicense(src)

    local payload = { characters = {}, incoming = {}, outgoing = {}, slots = 0, canDelete = false }

    if not license then
        TriggerClientEvent('sm_characters:client:characters', src, payload)
        TriggerClientEvent('sm_characters:client:skins', src, {})
        return
    end

    MySQL.query.await('DELETE FROM sm_character_invites WHERE expires < ?', { os.time() })

    local rows = MySQL.query.await('SELECT * FROM players WHERE license = ? ORDER BY id ASC', { license }) or {}

    local characters, ids, byCitizen = {}, {}, {}
    for i = 1, #rows do
        ids[#ids + 1] = rows[i].citizenid
        byCitizen[rows[i].citizenid] = true
    end

    local partners = {}
    if #ids > 0 then
        local prow = MySQL.query.await(
            ('SELECT citizenid, partner, type FROM sm_character_partners WHERE citizenid IN (%s)'):format(placeholders(#ids)), ids) or {}
        for _, r in ipairs(prow) do partners[r.citizenid] = r end
    end

    for i = 1, #rows do
        local row = rows[i]
        local entry = {}
        for key, value in pairs(row) do entry[key] = value end

        entry.charinfo = decode(row.charinfo)
        entry.money    = decode(row.money)
        entry.job      = decode(row.job)
        entry.gang     = decode(row.gang)
        entry.position = decode(row.position)
        entry.metadata = decode(row.metadata)

        entry.firstname   = entry.charinfo.firstname
        entry.lastname    = entry.charinfo.lastname
        entry.gender      = entry.charinfo.gender
        entry.birthdate   = entry.charinfo.birthdate
        entry.phone       = entry.charinfo.phone
        entry.nationality = entry.charinfo.nationality

        entry.child   = entry.metadata.child == true
        entry.partner = partners[row.citizenid] and partnerObject(partners[row.citizenid].partner, partners[row.citizenid].type) or nil

        characters[#characters + 1] = entry
    end

    -- Client menunggu skins[citizenid] ~= nil untuk SETIAP karakter; tanpa skin kirim false
    -- (kalau dikosongkan, client menunggu sampai timeout untuk tiap karakter).
    local skins = {}
    for i = 1, #ids do skins[ids[i]] = false end

    if #ids > 0 then
        local skinOk, skinRows = pcall(function()
            return MySQL.query.await(
                ('SELECT citizenid, skin FROM playerskins WHERE active = 1 AND citizenid IN (%s)'):format(placeholders(#ids)), ids) or {}
        end)
        if skinOk then
            for _, row in ipairs(skinRows) do
                if row.skin and row.skin ~= '' then skins[row.citizenid] = row.skin end
            end
        end
    end

    -- Undangan: item = { id, sender, target, type, expires, name }
    if #ids > 0 then
        local params = {}
        for i = 1, #ids do params[#params + 1] = ids[i] end
        for i = 1, #ids do params[#params + 1] = ids[i] end
        params[#params + 1] = os.time()

        local inv = MySQL.query.await(
            ('SELECT id, sender, target, type, expires FROM sm_character_invites WHERE (sender IN (%s) OR target IN (%s)) AND expires > ?')
                :format(placeholders(#ids), placeholders(#ids)), params) or {}

        for _, row in ipairs(inv) do
            local item = { id = row.id, sender = row.sender, target = row.target, type = row.type, expires = tonumber(row.expires) or 0 }

            if byCitizen[row.target] then
                item.name = nameOf(row.sender)
                payload.incoming[#payload.incoming + 1] = item
            elseif byCitizen[row.sender] then
                item.name = nameOf(row.target)
                payload.outgoing[#payload.outgoing + 1] = item
            end
        end
    end

    payload.characters = characters
    payload.slots = getSlots(license)
    payload.canDelete = #characters > 1

    TriggerClientEvent('sm_characters:client:skins', src, skins)
    TriggerClientEvent('sm_characters:client:characters', src, payload)
end)

-- ----------------------------------------------------------------------------
-- Buat karakter  -> client butuh { coords } atau { error = kode }
-- ----------------------------------------------------------------------------

local function sanitizeName(value)
    if type(value) ~= 'string' then return nil end
    value = value:match('^%s*(.-)%s*$')
    local min, max = Register.name and Register.name.min or 2, Register.name and Register.name.max or 20
    if #value < min or #value > max then return nil end
    if not value:match('^[%a][%a%s%-]*$') then return nil end
    return value
end

local function daysIn(y, m)
    if m == 2 then return ((y % 4 == 0 and y % 100 ~= 0) or y % 400 == 0) and 29 or 28 end
    return ({ 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 })[m]
end

local function sanitizeBirthdate(value)
    if type(value) ~= 'string' then return nil end
    value = value:match('^%s*(.-)%s*$')

    local ys, ms, ds = value:match('^(%d%d%d%d)%-(%d%d?)%-(%d%d?)$')
    if not ys then return nil end

    local y, m, d = tonumber(ys), tonumber(ms), tonumber(ds)
    local range = Register.birthYear or { min = 1950, max = 2007 }

    if y < range.min or y > range.max or m < 1 or m > 12 or d < 1 or d > daysIn(y, m) then return nil end

    return ('%04d-%02d-%02d'):format(y, m, d)
end

local function sanitizeGender(value)
    if value == true or value == 1 or value == 'male' or value == 'm' or value == 'M' then return 'male' end
    if value == false or value == 0 or value == 'female' or value == 'f' or value == 'F' then return 'female' end
    return nil
end

lib.callback.register('sm_characters:create', function(source, input)
    if type(input) ~= 'table' then return { error = 'invalid' } end

    local license = getLicense(source)
    if not license then return { error = 'failed' } end

    local firstname = sanitizeName(input.firstname)
    local lastname  = sanitizeName(input.lastname)
    local gender    = sanitizeGender(input.gender)
    local birthdate = sanitizeBirthdate(input.birthdate)

    if not firstname or not lastname or not gender or not birthdate then return { error = 'invalid' } end

    local nationality = input.nationality
    if next(NATIONALITY) then
        if not NATIONALITY[nationality] then return { error = 'invalid' } end
    else
        nationality = type(nationality) == 'string' and nationality:sub(1, 32) or 'Indonesian'
    end

    local count = MySQL.scalar.await('SELECT COUNT(*) FROM players WHERE license = ?', { license }) or 0
    if count >= getSlots(license) then return { error = 'full' } end

    local citizenid = QBCore.Player.CreateCitizenId()

    local charinfo = {
        firstname = firstname,
        lastname = lastname,
        birthdate = birthdate,
        gender = gender,
        nationality = nationality,
        cid = math.random(10000, 99999),
        phone = generatePhone(),
    }

    local money = { cash = 500, bank = 5000, crypto = 0 }
    local job = { name = 'unemployed', label = 'Pengangguran', payment = 10, onduty = true, isboss = false, grade = { name = 'Freelancer', level = 0 } }
    local gang = { name = 'none', label = 'Tidak ada', grade = { name = 'Tidak ada', level = 0 } }
    local metadata = { callsign = 'NO CALLSIGN', licences = {} }

    local nextId = MySQL.scalar.await('SELECT COALESCE(MAX(id), 0) + 1 FROM players') or 1

    local params = {
        nextId, citizenid, charinfo.cid, license, ('%s %s'):format(firstname, lastname),
        json.encode(money), json.encode(charinfo), json.encode(job), json.encode(gang),
        json.encode(DEFAULT_POS), json.encode(metadata),
    }

    local ok, err = pcall(function()
        MySQL.insert.await([[
            INSERT INTO players (id, citizenid, cid, license, name, money, charinfo, job, gang, position, metadata)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ]], params)
    end)

    if not ok then
        -- Skema tanpa kolom cid/name.
        ok, err = pcall(function()
            MySQL.insert.await([[
                INSERT INTO players (id, citizenid, license, money, charinfo, job, gang, position, metadata)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            ]], { nextId, citizenid, license, params[6], params[7], params[8], params[9], params[10], params[11] })
        end)
    end

    if not ok then
        lib.print.error(('gagal membuat karakter: %s'):format(err))
        return { error = 'failed' }
    end

    -- Client langsung spawn + buka sm_appearance setelah ini; pemain harus sudah ter-login
    -- (select tidak dipanggil di jalur "buat karakter baru").
    local loginOk, player = pcall(QBCore.Player.Login, source, citizenid)
    if not loginOk or not player then
        lib.print.error(('login karakter baru gagal: %s'):format(tostring(player)))
        return { error = 'failed' }
    end

    SetPlayerRoutingBucket(source, 0)

    return { coords = vec4(DEFAULT_POS.x, DEFAULT_POS.y, DEFAULT_POS.z, DEFAULT_POS.w), citizenid = citizenid }
end)

-- ----------------------------------------------------------------------------
-- Pilih karakter -> client mengharapkan DAFTAR LOKASI SPAWN (atau false)
-- ----------------------------------------------------------------------------

lib.callback.register('sm_characters:select', function(source, citizenid)
    local license = getLicense(source)
    if not license then return false end

    if QBCore.Functions.GetPlayer(source) then return false end
    if not ownedBy(license, citizenid) then return false end

    local ok, result = pcall(QBCore.Player.Login, source, citizenid)
    if not ok or not result then
        lib.print.error(('login gagal: %s'):format(tostring(result)))
        return false
    end

    local player = QBCore.Functions.GetPlayer(source)
    return buildLocations(player and player.PlayerData.position)
end)

-- ----------------------------------------------------------------------------
-- Hapus karakter
-- ----------------------------------------------------------------------------

lib.callback.register('sm_characters:delete', function(source, citizenid)
    local license = getLicense(source)
    if not ownedBy(license, citizenid) then return false end

    local total = MySQL.scalar.await('SELECT COUNT(*) FROM players WHERE license = ?', { license }) or 0
    if total <= 1 then return false end

    local player = QBCore.Functions.GetPlayer(source)
    if player and player.PlayerData.citizenid == citizenid then
        TriggerEvent('QBCore:Server:OnPlayerUnload', source)
        QBCore.Players[source] = nil
    end

    local partner = partnerRow(citizenid)

    MySQL.query.await('DELETE FROM players WHERE citizenid = ?', { citizenid })
    MySQL.query.await('DELETE FROM playerskins WHERE citizenid = ?', { citizenid })
    MySQL.query.await('DELETE FROM sm_character_partners WHERE citizenid = ? OR partner = ?', { citizenid, citizenid })
    MySQL.query.await('DELETE FROM sm_character_invites WHERE sender = ? OR target = ?', { citizenid, citizenid })

    if partner then pushToLicense(licenseOf(partner.partner), 'unlinked', { citizenid = partner.partner }) end

    return true
end)

-- ----------------------------------------------------------------------------
-- Spawn -> client mengharapkan { label, coords = vector4, freezeControl? } (client yang teleport)
-- ----------------------------------------------------------------------------

lib.callback.register('sm_characters:spawn', function(source, id)
    local player = QBCore.Functions.GetPlayer(source)
    if not player or type(id) ~= 'string' then return false end

    local list = buildLocations(player.PlayerData.position)

    for i = 1, #list do
        if list[i].id == id then
            SetPlayerRoutingBucket(source, 0)
            return { label = list[i].label, coords = list[i].coords, freezeControl = list[i].freezeControl }
        end
    end

    return false
end)

RegisterNetEvent('sm_characters:server:spawned', function()
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end

    player.PlayerData.metadata.invBusy = false
    TriggerClientEvent('QBCore:Player:SetPlayerData', src, player.PlayerData)
    TriggerEvent('QBCore:Server:OnPlayerSpawned', src)
end)

-- ----------------------------------------------------------------------------
-- Partner / Sahabat
-- Pemain berada di layar pilih karakter (belum ter-login), jadi karakter diidentifikasi lewat
-- citizenid yang dikirim client dan DIVERIFIKASI milik license pemain.
-- Kode error = kunci kamus UI: invalid, cooldown, self, notfound, ownchar,
-- hasPartner, targetHasPartner, exists, failed.
-- ----------------------------------------------------------------------------

local lastInvite = {}

AddEventHandler('playerDropped', function()
    lastInvite[source] = nil
end)

lib.callback.register('sm_characters:partner:invite', function(source, from, target, linkType)
    local license = getLicense(source)
    if not license then return { error = 'failed' } end

    local now = os.time()
    if (lastInvite[source] or 0) + INVITE_COOLDOWN > now then return { error = 'cooldown' } end
    lastInvite[source] = now

    if type(from) ~= 'string' or type(target) ~= 'string' or not LINK_TYPES[linkType] then
        return { error = 'invalid' }
    end

    target = (target:gsub('%s', ''))
    if target == '' then return { error = 'invalid' } end

    if not ownedBy(license, from) then return { error = 'invalid' } end

    local targetRow = MySQL.single.await('SELECT citizenid, license FROM players WHERE citizenid = ?', { target })
    if not targetRow then return { error = 'notfound' } end

    target = targetRow.citizenid -- bentuk kanonik dari DB

    if target == from then return { error = 'self' } end
    if targetRow.license == license then return { error = 'ownchar' } end

    if partnerRow(from) then return { error = 'hasPartner' } end
    if partnerRow(target) then return { error = 'targetHasPartner' } end

    local exists = MySQL.scalar.await(
        'SELECT id FROM sm_character_invites WHERE sender = ? AND target = ? AND expires > ?', { from, target, now })
    if exists then return { error = 'exists' } end

    local expires = now + INVITE_TTL
    local id = MySQL.insert.await(
        'INSERT INTO sm_character_invites (sender, target, type, expires) VALUES (?, ?, ?, ?)', { from, target, linkType, expires })
    if not id then return { error = 'failed' } end

    local incoming = { id = id, sender = from, target = target, type = linkType, expires = expires, name = nameOf(from) }
    pushToLicense(targetRow.license, 'incoming', incoming)
    for _, src in ipairs(sourcesForLicense(targetRow.license)) do
        notify(src, 'Undangan masuk dari ' .. incoming.name, 'inform')
    end

    return { invite = { id = id, sender = from, target = target, type = linkType, expires = expires, name = nameOf(target) } }
end)

lib.callback.register('sm_characters:partner:respond', function(source, id, accept)
    local license = getLicense(source)
    id = math.tointeger(id)
    if not license or not id then return { error = 'invalid' } end

    local inv = MySQL.single.await('SELECT id, sender, target, type, expires FROM sm_character_invites WHERE id = ?', { id })
    if not inv then return { error = 'notfound' } end
    if not ownedBy(license, inv.target) then return { error = 'invalid' } end

    MySQL.query.await('DELETE FROM sm_character_invites WHERE id = ?', { id })

    local senderLicense = licenseOf(inv.sender)

    if accept ~= true then
        pushToLicense(senderLicense, 'outgoingRemoved', { id = id })
        return { ok = true }
    end

    if (tonumber(inv.expires) or 0) < os.time() then return { error = 'failed' } end
    if partnerRow(inv.target) then return { error = 'hasPartner' } end
    if partnerRow(inv.sender) then return { error = 'targetHasPartner' } end

    local now = os.time()
    MySQL.insert.await(
        'INSERT INTO sm_character_partners (citizenid, partner, type, since) VALUES (?, ?, ?, ?), (?, ?, ?, ?)',
        { inv.target, inv.sender, inv.type, now, inv.sender, inv.target, inv.type, now })

    MySQL.query.await('DELETE FROM sm_character_invites WHERE sender IN (?, ?) OR target IN (?, ?)',
        { inv.sender, inv.target, inv.sender, inv.target })

    pushToLicense(senderLicense, 'linked', { citizenid = inv.sender, partner = partnerObject(inv.target, inv.type) })
    for _, src in ipairs(sourcesForLicense(senderLicense)) do
        notify(src, 'Undangan diterima', 'success')
    end

    return { ok = true, citizenid = inv.target, partner = partnerObject(inv.sender, inv.type) }
end)

lib.callback.register('sm_characters:partner:cancel', function(source, id)
    local license = getLicense(source)
    id = math.tointeger(id)
    if not license or not id then return false end

    local inv = MySQL.single.await('SELECT id, sender, target FROM sm_character_invites WHERE id = ?', { id })
    if not inv or not ownedBy(license, inv.sender) then return false end

    MySQL.query.await('DELETE FROM sm_character_invites WHERE id = ?', { id })
    pushToLicense(licenseOf(inv.target), 'incomingRemoved', { id = id })

    return true
end)

-- client mengirim citizenid karakter MILIK SENDIRI yang ingin diputus hubungannya.
lib.callback.register('sm_characters:partner:remove', function(source, citizenid)
    local license = getLicense(source)
    if not ownedBy(license, citizenid) then return false end

    local row = partnerRow(citizenid)
    if not row then return false end

    MySQL.query.await('DELETE FROM sm_character_partners WHERE citizenid IN (?, ?)', { citizenid, row.partner })
    MySQL.query.await('DELETE FROM sm_character_invites WHERE sender IN (?, ?) OR target IN (?, ?)',
        { citizenid, row.partner, citizenid, row.partner })

    local partnerLicense = licenseOf(row.partner)
    pushToLicense(partnerLicense, 'unlinked', { citizenid = row.partner })
    for _, src in ipairs(sourcesForLicense(partnerLicense)) do
        notify(src, 'Hubungan Anda diputus', 'inform')
    end

    return true
end)

lib.print.info('sm_character server siap')