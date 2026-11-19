--[[
    rhd_idcard :: server
    Kartu disimpan per citizenid. Field bertanda generateFromServer diisi server,
    field editable boleh diubah lewat update. Template tidak pernah dipilih client mentah.
]]

local sconfig = localmodule 'config.shared'

local TEMPLATES = sconfig.template
local TABLE = 'idcard_cards'
local DEFAULT_YEARS = 5
local PAGE_MAX = 50

local MANAGEMENT_JOB = sconfig.managementJob or 'government'
local MANAGEMENT_GRADE = sconfig.managementGrade or 3

local function playerOf(src)
    return qb_ecore:GetPlayer(src)
end

local function notify(src, message, kind)
    TriggerClientEvent('ox_lib:notify', src, { description = message, type = kind or 'error' })
end

local function isManager(player)
    if not player then return false end
    if player.PlayerData.job.name ~= MANAGEMENT_JOB then return false end
    return (player.PlayerData.job.grade.level or 0) >= MANAGEMENT_GRADE
end

local function stampDate(years)
    local base = os.date('*t')
    base.year = base.year + years
    return os.time(base)
end

local function generated(player, key)
    local info = player.PlayerData.charinfo
    local meta = player.PlayerData.metadata or {}

    if key == 'citizenid' then return player.PlayerData.citizenid end
    if key == 'name' then return ('%s %s'):format(info.firstname or '', info.lastname or '') end
    if key == 'dob' then return info.birthdate end
    if key == 'gender' then return info.gender end
    if key == 'bloodType' then return meta.bloodtype end

    return nil
end

local function buildData(player, template, input)
    local out = {}
    local expires
    input = type(input) == 'table' and input or {}

    for i = 1, #(template.fields or {}) do
        local field = template.fields[i]
        if field.kind == 'data' then
            local value

            if field.input and field.input.generateFromServer then
                value = generated(player, field.input.generateFromServer)
            elseif field.input and field.input.default then
                value = stampDate(DEFAULT_YEARS)
                expires = value
            elseif input[field.id] ~= nil then
                value = input[field.id]
            end

            if value == nil and field.input and field.input.required then return nil, field.label end
            out[field.id] = value
        end
    end

    return out, nil, expires
end

lib.callback.register('rhd_idcard:server:getData', function(src, data)
    local player = playerOf(src)
    if not player then return nil end
    if type(data) ~= 'table' then return nil end

    local row = MySQL.single.await('SELECT * FROM ' .. TABLE .. ' WHERE id = ?', { tonumber(data.cardId) })
    if not row then return nil end

    local manager = isManager(player)
    if row.citizenid ~= player.PlayerData.citizenid and not manager then return nil end

    return {
        id = row.id,
        itemname = row.itemname,
        citizenid = row.citizenid,
        data = json.decode(row.data or '{}'),
        created = row.created,
        updated = row.updated,
    }
end)

lib.callback.register('rhd_idcard:server:update', function(src, data)
    local player = playerOf(src)
    if not player or type(data) ~= 'table' then return false end

    local row = MySQL.single.await('SELECT * FROM ' .. TABLE .. ' WHERE id = ?', { tonumber(data.cardId) })
    if not row then return false end

    local manager = isManager(player)
    if row.citizenid ~= player.PlayerData.citizenid and not manager then return false end

    local template = TEMPLATES[row.itemname]
    if not template then return false end

    local stored = json.decode(row.data or '{}')
    local input = type(data.fields) == 'table' and data.fields or {}

    for i = 1, #(template.fields or {}) do
        local field = template.fields[i]
        if field.kind == 'data' and field.input and field.input.editable and input[field.id] ~= nil then
            stored[field.id] = input[field.id]
        end
    end

    MySQL.update('UPDATE ' .. TABLE .. ' SET data = ?, updated = ? WHERE id = ?', {
        json.encode(stored), os.time(), row.id,
    })

    return true
end)

lib.callback.register('rhd_idcard:server:getUserAvatar', function(src, citizenid)
    if not playerOf(src) then return nil end
    return lib.callback.await('rhd_idcard:client:getUserAvatar', src, tostring(citizenid or ''))
end)

RegisterNetEvent('rhd_idcard:server:buat_kartu', function()
    local src = source
    local player = playerOf(src)
    if not player then return end

    local card = lib.callback.await('rhd_idcard:client:card', src)
    if type(card) ~= 'table' then return notify(src, 'Data kartu kosong.') end

    local itemname = tostring(card.itemname or '')
    local template = TEMPLATES[itemname]
    if not template then return notify(src, 'Template tidak dikenal.') end

    if (ox_inventory:GetItemCount(src, itemname) or 0) < 1 then
        return notify(src, 'Kamu tidak memegang blangko kartu.')
    end

    local data, missing, expires = buildData(player, template, card.fields)
    if not data then return notify(src, ('Field %s wajib diisi.'):format(missing or '?')) end

    local id = MySQL.insert.await(
        ('INSERT INTO %s (citizenid, itemname, data, created, updated) VALUES (?, ?, ?, ?, ?)'):format(TABLE),
        { player.PlayerData.citizenid, itemname, json.encode(data), os.time(), os.time() }
    )

    if not id then return notify(src, 'Gagal menyimpan kartu.') end

    if not ox_inventory:RemoveItem(src, itemname, 1) then
        MySQL.update('DELETE FROM ' .. TABLE .. ' WHERE id = ?', { id })
        return notify(src, 'Gagal memakai blangko.')
    end

    if not ox_inventory:AddItem(src, itemname, 1, { cardId = id }) then
        return notify(src, 'Tas penuh, kartu gagal diberikan.')
    end

    TriggerClientEvent('rhd_idcard:client:show', src, { id = id, itemname = itemname, data = data })
    TriggerClientEvent('rhd_idcard:client:showAnim', src, itemname)
end)

RegisterNetEvent('rhd_idcard:server:requestCards', function(data, key)
    local src = source
    local player = playerOf(src)
    if not player or type(data) ~= 'table' then return end

    if not isManager(player) then
        return TriggerClientEvent('rhd_idcard:client:cardsDenied', src, key)
    end

    local where, args = {}, {}

    if data.citizenid and data.citizenid ~= '' then
        where[#where + 1] = 'citizenid = ?'
        args[#args + 1] = tostring(data.citizenid)
    end

    if data.cardType and data.cardType ~= '' then
        where[#where + 1] = 'itemname = ?'
        args[#args + 1] = tostring(data.cardType)
    end

    if data.tab == 'expired' then
        where[#where + 1] = 'expired_at IS NOT NULL AND expired_at < ?'
        args[#args + 1] = os.time()
    end

    if data.search and data.search ~= '' then
        where[#where + 1] = '(citizenid LIKE ? OR data LIKE ?)'
        local like = '%' .. tostring(data.search) .. '%'
        args[#args + 1] = like
        args[#args + 1] = like
    end

    local clause = #where > 0 and (' WHERE ' .. table.concat(where, ' AND ')) or ''

    local page = math.max(math.floor(tonumber(data.page) or 1), 1)
    local size = math.min(math.max(math.floor(tonumber(data.pageSize) or 10), 1), PAGE_MAX)

    local rows = MySQL.query.await(
        ('SELECT * FROM %s%s ORDER BY id DESC LIMIT ? OFFSET ?'):format(TABLE, clause),
        { table.unpack(args), size, (page - 1) * size }
    ) or {}

    local dict, seen = {}, {}

    local function push(value)
        local text = tostring(value or '')
        if seen[text] then return seen[text] end
        dict[#dict + 1] = text
        seen[text] = #dict
        return #dict
    end

    local list = {}

    for i = 1, #rows do
        local row = rows[i]
        local templateIdx = push(row.itemname)

        list[i] = {
            row.citizenid,
            templateIdx,
            templateIdx,
            nil,
            templateIdx,
            json.decode(row.data or '{}'),
            { id = row.id, created = row.created },
        }
    end

    TriggerClientEvent('rhd_idcard:client:cards', src, key, msgpack.encode({
        d = dict, c = list, m = true,
    }))
end)

RegisterNetEvent('rhd_idcard:server:changename', function(data)
    local src = source
    local player = playerOf(src)
    if not player or type(data) ~= 'table' then return end
    if type(data.name) ~= 'table' or #data.name < 2 then return end

    local first = tostring(data.name[1]):sub(1, 32)
    local last = tostring(data.name[2]):sub(1, 32)
    if first == '' or last == '' then return end

    local info = player.PlayerData.charinfo
    info.firstname = first
    info.lastname = last
    if tonumber(data.date) then info.birthdate = tostring(data.date) end
    if data.nationality then info.nationality = tostring(data.nationality) end

    MySQL.update('UPDATE players SET charinfo = ? WHERE citizenid = ?', {
        json.encode(info), player.PlayerData.citizenid,
    })

    notify(src, 'Nama diperbarui.', 'success')
end)

RegisterNetEvent('rhd_idcard:server:show', function(cardId)
    local src = source
    local player = playerOf(src)
    if not player then return end

    local row = MySQL.single.await('SELECT * FROM ' .. TABLE .. ' WHERE id = ?', { tonumber(cardId) })
    if not row then return end
    if row.citizenid ~= player.PlayerData.citizenid and not isManager(player) then return end

    TriggerClientEvent('rhd_idcard:client:show', src, {
        id = row.id, itemname = row.itemname, data = json.decode(row.data or '{}'),
    })
end)

CreateThread(function()
    MySQL.query.await(([[
    CREATE TABLE IF NOT EXISTS `%s` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `citizenid` varchar(64) NOT NULL,
        `itemname` varchar(48) NOT NULL,
        `data` longtext NOT NULL,
        `created` int(11) NOT NULL,
        `updated` int(11) NOT NULL,
        `expired_at` int(11) DEFAULT NULL,
        PRIMARY KEY (`id`),
        KEY `citizenid` (`citizenid`),
        KEY `itemname` (`itemname`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]]):format(TABLE))
end)

print('^2[rhd_idcard] server siap^7')