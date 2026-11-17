-- Rekonstruksi sm_core/server/connecting.lua

local function nowUnix() return os.time() end

local function checkBan(src)
    local license = PlayerIdentifier(src, 'license')
    local alt = PlayerIdentifier(src, QBConfig.LicenseType)
    local discord = PlayerIdentifier(src, 'discord')
    local ip = PlayerIdentifier(src, 'ip')

    local row = db.single_async(
        'SELECT id, reason, expire FROM bans WHERE license = ? OR license = ? OR discord = ? OR ip = ? ORDER BY expire DESC LIMIT 1',
        { license or '', alt or '', discord or '', ip or '' })
    if not row then return end

    local expire = tonumber(row.expire) or 0
    if expire > 2147483646 or expire > nowUnix() then
        local remaining = expire > 2147483646 and 'permanen' or os.date('%d-%m-%Y %H:%M', expire)
        return ('Kamu dibanned.\nAlasan: %s\nBerakhir: %s\nDiscord: %s'):format(
            row.reason or '-', remaining, QBConfig.Server.Discord)
    end

    db.update_async('DELETE FROM bans WHERE id = ?', { row.id }) -- ban kedaluwarsa
end

local function onPlayerConnecting(name, setKickReason, deferrals)
    local src = source
    deferrals.defer()
    Wait(0) -- wajib sebelum deferrals.update/done

    if QBConfig.Server.Closed and not IsPlayerAceAllowed(tostring(src), 'qbadmin.join') then
        return deferrals.done(QBConfig.Server.ClosedReason)
    end

    local license = PlayerIdentifier(src, QBConfig.LicenseType)
    if not license then
        if QBConfig.LicenseType == 'steam' then
            return deferrals.done('Steam tidak terdeteksi. Buka Steam, lalu jalankan ulang FiveM.')
        end
        return deferrals.done(Lang:t('error.no_valid_license'))
    end

    if QBConfig.Server.CheckDuplicateLicense and QBCore.Functions.IsLicenseInUse(license) then
        return deferrals.done(Lang:t('error.duplicate_license'))
    end

    deferrals.update(Lang:t('info.checking_ban'):format(name))
    local ok, banReason = pcall(checkBan, src)
    if not ok then
        lib.print.error(banReason)
        return deferrals.done(Lang:t('error.connecting_database_error'))
    end
    if banReason then return deferrals.done(banReason) end

    if QBConfig.Server.Whitelist then
        deferrals.update(Lang:t('info.checking_whitelisted'):format(name))
        if not QBCore.Functions.IsWhitelisted(src) then
            return deferrals.done(Lang:t('error.not_whitelisted'))
        end
    end

    deferrals.done()
end

AddEventHandler('playerConnecting', onPlayerConnecting)
