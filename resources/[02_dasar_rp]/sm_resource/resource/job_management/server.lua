--[[
    job_management :: server
    Otoritas boss menu. Grade >= lockedFrom dikunci untuk admin.
]]

local QBCore = qb_ecore or exports['qb-core']:GetCoreObject()

local shops = localmodule 'config.shops'
local locations = localmodule 'config.location'
local whitelistjob = localmodule 'config.whitelistjob'
local limits = localmodule 'config.employee_limit'
local topGrades = localmodule 'config.top_grades'

local ADMIN_GROUP = topGrades.adminGroup or 'admin'
local LOCKED = topGrades.jobs or {}

local function notify(src, message, kind)
    TriggerClientEvent('ox_lib:notify', src, { description = message, type = kind or 'error' })
end

local function playerOf(src)
    return QBCore.Functions.GetPlayer(src)
end

local function isAdmin(player)
    return player and QBCore.Functions.HasPermission(player.PlayerData.source, ADMIN_GROUP)
end

local function bossOf(src)
    local player = playerOf(src)
    if not player then return nil end

    local job = player.PlayerData.job
    if not job.isboss and not isAdmin(player) then return nil end

    return player, job
end

local function gradeName(jobName, level)
    local shared = QBCore.Shared.Jobs[jobName]
    local grade = shared and shared.grades and shared.grades[tostring(level)]
    return grade and grade.name or ('Grade %d'):format(level)
end

local function onlineSource(citizenid)
    for _, raw in ipairs(GetPlayers()) do
        local player = QBCore.Functions.GetPlayer(tonumber(raw))
        if player and player.PlayerData.citizenid == citizenid then return tonumber(raw) end
    end
    return 0
end

local function jobOf(player)
    return player.PlayerData.job
end

local function memberCount(jobName)
    return MySQL.scalar.await(
        'SELECT COUNT(*) FROM players WHERE JSON_UNQUOTE(JSON_EXTRACT(job, "$.name")) = ?', { jobName }
    ) or 0
end

local function whitelisted(jobName)
    for i = 1, #whitelistjob do
        if whitelistjob[i] == jobName then return true end
    end
    return false
end

lib.callback.register('job_management:getEmployees', function(src)
    local player, job = bossOf(src)
    if not player then return {}, nil end

    local lockedFrom = LOCKED[job.name]

    local rows = MySQL.query.await(
        'SELECT citizenid, charinfo, job FROM players WHERE JSON_UNQUOTE(JSON_EXTRACT(job, "$.name")) = ? ORDER BY CAST(JSON_UNQUOTE(JSON_EXTRACT(job, "$.grade")) AS UNSIGNED) DESC',
        { job.name }
    ) or {}

    local employees = {}

    for i = 1, #rows do
        local row = rows[i]

        local ok, info = pcall(json.decode, row.charinfo or '{}')
        local okj, jobData = pcall(json.decode, row.job or '{}')

        if ok and okj and type(jobData) == 'table' then
            local level = tonumber(jobData.grade) or 0

            employees[#employees + 1] = {
                name = ('%s %s'):format((info and info.firstname) or '?', (info and info.lastname) or ''):gsub('^%s+', ''),
                citizenid = row.citizenid,
                empSource = onlineSource(row.citizenid),
                grade = { name = gradeName(job.name, level), level = level },
            }
        end
    end

    return employees, lockedFrom
end)

lib.callback.register('job_management:getmembercount', function(src)
    local player, job = bossOf(src)
    if not player then return 0, 0 end

    return memberCount(job.name), limits[job.name] or 0
end)

lib.callback.register('job_management:getDiscountCodes', function(src)
    local player, job = bossOf(src)
    if not player then return {} end

    return MySQL.query.await(
        'SELECT code, percent, max_uses, uses FROM job_management_discounts WHERE job = ? ORDER BY id DESC', { job.name }
    ) or {}
end)

RegisterNetEvent('job_management:createDiscountCode', function(percent, count)
    local src = source
    local player, job = bossOf(src)
    if not player then return end

    percent = math.floor(tonumber(percent) or 0)
    count = math.floor(tonumber(count) or 0)
    if percent < 1 or percent > 100 or count < 1 or count > 100 then return end

    local code = ('%s%02d%s'):format(job.name:sub(1, 4):upper(), percent, ('%05d'):format(math.random(0, 99999)))

    MySQL.insert('INSERT INTO job_management_discounts (job, code, percent, max_uses, uses, created_by, created_at) VALUES (?, ?, ?, ?, 0, ?, ?)', {
        job.name, code, percent, count, player.PlayerData.citizenid, os.time(),
    })

    notify(src, ('Kode %s dibuat (%d%%, %dx).'):format(code, percent, count), 'success')
end)

RegisterNetEvent('job_management:deleteDiscountCode', function(code)
    local src = source
    local player, job = bossOf(src)
    if not player then return end

    MySQL.update('DELETE FROM job_management_discounts WHERE job = ? AND code = ?', { job.name, tostring(code or '') })
end)

RegisterNetEvent('job_management:HireEmployee', function(targetSource)
    local src = source
    local player, job = bossOf(src)
    if not player then return end

    local target = playerOf(tonumber(targetSource) or 0)
    if not target then return notify(src, 'Pemain tidak ditemukan.') end
    if target.PlayerData.citizenid == player.PlayerData.citizenid then return notify(src, 'Tidak bisa merekrut diri sendiri.') end
    if jobOf(target).name == job.name then return notify(src, 'Sudah anggota.') end

    local max = limits[job.name] or 0
    if max > 0 and memberCount(job.name) >= max then return notify(src, 'Kuota karyawan penuh.') end

    if whitelisted(job.name) then
        local licences = target.PlayerData.metadata and target.PlayerData.metadata.licences or {}
        if not licences[job.name] then return notify(src, 'Pemain belum punya whitelist job ini.') end
    end

    local grade = 0
    for level in pairs(QBCore.Shared.Jobs[job.name].grades) do
        grade = math.min(grade, tonumber(level) or 0)
    end

    target.Functions.SetJob(job.name, grade)
    notify(src, ('%s direkrut.'):format(target.PlayerData.charinfo.firstname), 'success')
    notify(target.PlayerData.source, ('Kamu direkrut di %s.'):format(job.label), 'success')
end)

RegisterNetEvent('job_management:FireEmployee', function(targetSource)
    local src = source
    local player, job = bossOf(src)
    if not player then return end

    local target = playerOf(tonumber(targetSource) or 0)
    if not target then return notify(src, 'Pemain harus online.') end
    if jobOf(target).name ~= job.name then return notify(src, 'Bukan anggota job ini.') end

    local myLevel = job.grade.level or 0
    local theirLevel = jobOf(target).grade.level or 0

    if theirLevel > myLevel then return notify(src, 'Grade target lebih tinggi.') end

    local lockedFrom = LOCKED[job.name]
    if lockedFrom and theirLevel >= lockedFrom and not isAdmin(player) then
        return notify(src, 'Grade terkunci untuk admin.')
    end

    target.Functions.SetJob('unemployed', 0)
    notify(src, 'Karyawan dipecat.', 'success')
    notify(target.PlayerData.source, ('Kamu dipecat dari %s.'):format(job.label))
end)

RegisterNetEvent('job_management:GradeUpdate', function(data)
    local src = source
    local player, job = bossOf(src)
    if not player or type(data) ~= 'table' then return end

    local target = playerOf(tonumber(data.cid) or 0)
    if not target then return notify(src, 'Pemain harus online.') end
    if jobOf(target).name ~= job.name then return notify(src, 'Bukan anggota job ini.') end

    local level = tonumber(data.grade)
    if not level or not QBCore.Shared.Jobs[job.name].grades[tostring(level)] then
        return notify(src, 'Grade tidak dikenal.')
    end

    if level > (job.grade.level or 0) then return notify(src, 'Melebihi grade kamu.') end

    local lockedFrom = LOCKED[job.name]
    if lockedFrom and level >= lockedFrom and not isAdmin(player) then
        return notify(src, 'Grade terkunci untuk admin.')
    end

    target.Functions.SetJob(job.name, level)
    notify(src, ('Grade %s diubah ke %s.'):format(target.PlayerData.charinfo.firstname, gradeName(job.name, level)), 'success')
end)

RegisterNetEvent('job_management:openShop', function(shopId)
    local src = source
    local player, job = bossOf(src)
    if not player then return end

    local list = shops[job.name]
    if not list or not list[shopId] then return notify(src, 'Toko tidak tersedia.') end

    TriggerClientEvent('job_management:openShop', src, shopId)
end)

RegisterNetEvent('job_management:openStash', function()
    local src = source
    if not bossOf(src) then return end
    if GetResourceState('qb-bossmenu') ~= 'started' then return notify(src, 'qb-bossmenu tidak aktif.') end
    TriggerEvent('qb-bossmenu:server:stash', src)
end)

CreateThread(function()
    MySQL.query.await([[
    CREATE TABLE IF NOT EXISTS `job_management_discounts` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `job` varchar(64) NOT NULL,
        `code` varchar(32) NOT NULL,
        `percent` int(11) NOT NULL,
        `max_uses` int(11) NOT NULL,
        `uses` int(11) NOT NULL DEFAULT 0,
        `created_by` varchar(64) DEFAULT NULL,
        `created_at` int(11) NOT NULL,
        PRIMARY KEY (`id`),
        UNIQUE KEY `code` (`code`),
        KEY `job` (`job`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end)

print('^2[job_management] server siap^7')