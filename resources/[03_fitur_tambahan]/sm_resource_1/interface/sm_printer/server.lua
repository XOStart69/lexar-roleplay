--[[
    sm_printer :: server
    Printer per job. Baris printer disimpan di DB, isi laci lewat ox_inventory stash.
    Akses kelola dibatasi allowedJobs (job + grade minimum).
]]

local config = localmodule 'config.shared'

local printItem = config.printItem or 'paper'
local paperItem = config.refillPaperItem or 'paper'
local inkItem = config.refillInkItem or 'printer_ink'
local paperAmount = config.refillPaperAmount or 25
local inkMax = config.inkMax or 100
local maxPaper = config.maxPaper or 100
local maxCopies = config.maxCopies or 50
local stashCfg = config.stash or { slots = 10, weight = 5000 }
local allowedJobs = config.allowedJobs or {}

local QBCore = exports['qb-core']:GetCoreObject()

local printers = {}

local SCHEMA = [[
CREATE TABLE IF NOT EXISTS `sm_printer_printers` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `kind` varchar(16) NOT NULL DEFAULT 'coords',
    `model` varchar(64) NOT NULL,
    `x` double NOT NULL,
    `y` double NOT NULL,
    `z` double NOT NULL,
    `heading` double NOT NULL DEFAULT 0,
    `job` varchar(64) NOT NULL,
    `public` tinyint(4) NOT NULL DEFAULT 0,
    `paper` int(11) NOT NULL DEFAULT 0,
    `ink` int(11) NOT NULL DEFAULT 100,
    `queue` longtext NULL,
    PRIMARY KEY (`id`),
    KEY `job` (`job`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
]]

local function stashId(id)
    return ('printer_%s'):format(id)
end

local function notify(src, message, nType)
    lib.notify(src, { title = 'Printer', description = message, type = nType or 'info' })
end

local function playerJob(src)
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return nil end

    local job = player.PlayerData.job
    if not job then return nil end

    return job.name, tonumber(type(job.grade) == 'table' and (job.grade.level or 0) or job.grade) or 0
end

local function isManager(src, row)
    local name, grade = playerJob(src)
    if not name or name ~= row.job then return false end

    return grade >= (allowedJobs[row.job] or 0)
end

local function canUse(src, row)
    if row.public == 1 or row.public == true then return true end

    local name = playerJob(src)
    return name ~= nil and name == row.job
end

local function toClient(row)
    return {
        id = row.id,
        kind = row.kind,
        model = row.model,
        coords = { x = row.x, y = row.y, z = row.z },
        heading = row.heading,
        group = row.job,
        public = row.public == 1
    }
end

local function save(row)
    MySQL.update('UPDATE sm_printer_printers SET paper = ?, ink = ?, queue = ? WHERE id = ?', {
        row.paper, row.ink, row.queue, row.id
    })
end

local function registerStash(row)
    exports.ox_inventory:RegisterStash(
        stashId(row.id),
        ('Printer %s'):format(row.model),
        stashCfg.slots,
        stashCfg.weight,
        nil,
        { [row.job] = allowedJobs[row.job] or 0 }
    )
end

local function decodeQueue(row)
    if not row.queue or row.queue == '' then return {} end

    local ok, list = pcall(json.decode, row.queue)
    return ok and type(list) == 'table' and list or {}
end

lib.callback.register('sm_printer:server:getStorage', function(src, id)
    local row = printers[id]
    if not row or not canUse(src, row) then return end

    return { paper = row.paper, ink = row.ink }
end)

lib.callback.register('sm_printer:server:refill', function(src, id, kind)
    local row = printers[id]
    if not row or not isManager(src, row) then return false end

    if kind == 'paper' then
        if row.paper >= maxPaper then return false end

        local need = math.min(paperAmount, maxPaper - row.paper)
        if not exports.ox_inventory:RemoveItem(src, paperItem, need) then
            notify(src, ('Butuh %d %s.'):format(need, paperItem), 'error')
            return false
        end

        row.paper = row.paper + need
        save(row)
        return true, need
    end

    if kind ~= 'ink' then return false end
    if row.ink >= inkMax then return false end

    if not exports.ox_inventory:RemoveItem(src, inkItem, 1) then
        notify(src, ('Butuh 1 %s.'):format(inkItem), 'error')
        return false
    end

    row.ink = inkMax
    save(row)
    return true
end)

lib.callback.register('sm_printer:server:startPrint', function(src, id, copies)
    local row = printers[id]
    if not row or not canUse(src, row) then return false end

    copies = math.floor(tonumber(copies) or 0)
    if copies < 1 or copies > maxCopies then return false end

    if row.paper < copies then
        notify(src, 'Kertas tidak cukup.', 'error')
        return false
    end

    if row.ink <= 0 then
        notify(src, 'Tinta habis.', 'error')
        return false
    end

    row.paper = row.paper - copies
    save(row)
    return true
end)

lib.callback.register('sm_printer:server:completePrint', function(src, id, title, description, link)
    local row = printers[id]
    if not row or not canUse(src, row) then return false end

    if type(title) ~= 'string' or title == '' or type(link) ~= 'string' or link == '' then return false end

    local entry = {
        label = title:sub(1, 64),
        description = (type(description) == 'string' and description or ''):sub(1, 256),
        imagelink = link:sub(1, 512)
    }

    if exports.ox_inventory:AddItem(src, printItem, 1, entry) then
        row.ink = math.max(0, row.ink - 1)
        save(row)
        return 'given'
    end

    local queue = decodeQueue(row)
    queue[#queue + 1] = entry
    row.queue = json.encode(queue)
    save(row)

    return 'queued'
end)

lib.callback.register('sm_printer:server:collect', function(src, id)
    local row = printers[id]
    if not row or not canUse(src, row) then return false end

    local queue = decodeQueue(row)
    if #queue == 0 then
        notify(src, 'Tidak ada hasil print.')
        return false
    end

    local taken = 0
    for i = 1, #queue do
        if not exports.ox_inventory:AddItem(src, printItem, 1, queue[i]) then break end
        taken = taken + 1
    end

    if taken == 0 then
        notify(src, 'Inventory penuh.', 'error')
        return false
    end

    local rest = {}
    for i = taken + 1, #queue do rest[#rest + 1] = queue[i] end

    row.queue = json.encode(rest)
    save(row)

    return true
end)

lib.callback.register('sm_printer:server:getAll', function()
    local list = {}

    for id in pairs(printers) do list[#list + 1] = toClient(printers[id]) end

    return list
end)

lib.callback.register('sm_printer:server:listOwned', function(src)
    local name = playerJob(src)
    if not name or not allowedJobs[name] then return end

    local list = {}

    for id, row in pairs(printers) do
        if row.job == name then
            list[#list + 1] = {
                id = id,
                kind = row.kind,
                model = row.model,
                paper = row.paper,
                ink = row.ink
            }
        end
    end

    return list
end)

lib.callback.register('sm_printer:server:create', function(src, data)
    local name, grade = playerJob(src)
    if not name then return false end
    if not allowedJobs[name] then
        notify(src, 'Job ini tidak boleh punya printer.', 'error')
        return false
    end
    if grade < allowedJobs[name] then
        notify(src, 'Grade job terlalu rendah.', 'error')
        return false
    end
    if type(data) ~= 'table' or type(data.coords) ~= 'table' then return false end

    local model = tostring(data.model or ''):sub(1, 64)
    if model == '' then return false end

    local kind = data.kind == 'object' and 'object' or 'coords'
    local coords = data.coords

    local id = MySQL.insert.await([[
        INSERT INTO sm_printer_printers (kind, model, x, y, z, heading, job, public, paper, ink)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0, ?)
    ]], {
        kind, model,
        tonumber(coords.x) or 0.0, tonumber(coords.y) or 0.0, tonumber(coords.z) or 0.0,
        tonumber(data.heading) or 0.0, name, data.public and 1 or 0, inkMax
    })

    if not id then return false end

    local row = {
        id = id, kind = kind, model = model,
        x = tonumber(coords.x) or 0.0, y = tonumber(coords.y) or 0.0, z = tonumber(coords.z) or 0.0,
        heading = tonumber(data.heading) or 0.0,
        job = name, public = data.public and 1 or 0,
        paper = 0, ink = inkMax, queue = '[]'
    }

    printers[id] = row
    registerStash(row)
    TriggerClientEvent('sm_printer:client:add', -1, toClient(row))

    return true
end)

lib.callback.register('sm_printer:server:delete', function(src, id)
    local row = printers[id]
    if not row or not isManager(src, row) then return false end

    printers[id] = nil
    MySQL.update('DELETE FROM sm_printer_printers WHERE id = ?', { id })
    pcall(function() exports.ox_inventory:ClearStash(stashId(id)) end)
    TriggerClientEvent('sm_printer:client:remove', -1, id)

    return true
end)

lib.addCommand('printer', { help = 'Kelola printer job' }, function(src)
    local name = playerJob(src)
    if not name or not allowedJobs[name] then
        return notify(src, 'Job ini tidak punya akses printer.')
    end

    TriggerClientEvent('sm_printer:client:openMenu', src)
end)

CreateThread(function()
    MySQL.query.await(SCHEMA)

    local rows = MySQL.query.await('SELECT * FROM sm_printer_printers') or {}

    for i = 1, #rows do
        local row = rows[i]
        row.public = tonumber(row.public) or 0
        printers[row.id] = row
        registerStash(row)
    end

    print(('^2[sm_printer] %d printer dimuat^7'):format(#rows))

    local list = {}
    for id in pairs(printers) do list[#list + 1] = toClient(printers[id]) end

    TriggerClientEvent('sm_printer:client:sync', -1, list)
end)