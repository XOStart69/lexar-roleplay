---@param expire number?
---@return boolean
local function expired(expire)
    return expire ~= nil and expire > 0 and expire < os.time()
end

---@param license string?
---@param ip string?
---@return table?
local function banOf(license, ip)
    if not license and not ip then return end

    return MySQL.single.await(
        'SELECT reason, expire FROM bans WHERE license = ? OR ip = ? ORDER BY id DESC LIMIT 1',
        { license or '', ip or '' }
    )
end

AddEventHandler('playerJoining', function()
    local src = source
    local license = GetPlayerIdentifierByType(src, 'license') or GetPlayerIdentifier(src, 3)

    if not license then return end

    local row = banOf(license, GetPlayerEndpoint(src))
    if not row or expired(row.expire) then return end

    local until_ = row.expire and os.date('%d/%m/%Y %H:%M', row.expire) or 'permanen'

    DropPlayer(src, ('Kamu dibanned (%s): %s'):format(until_, row.reason or 'Tanpa alasan'))
end)

---@param license string
---@return boolean
function IsLicenseBanned(license)
    local row = banOf(license)

    return row ~= nil and not expired(row.expire)
end

exports('IsLicenseBanned', IsLicenseBanned)