-- se_v2 core stub: tanpa cek IP, tanpa stop resource
-- versi asli: core.lua.packed / core.lua.orig
local function noop() end
local function status() return "active" end
local function cipher() return { keys = { "STUB" }, table = {} } end

---@param source number
---@param reason string?
---@param seconds number?
local function banPlayer(source, reason, seconds)
    if not IsDuplicityVersion() then return end

    local src = tonumber(source)
    if not src then return end

    local text = reason or 'Tanpa alasan'
    local license = GetPlayerIdentifierByType(src, 'license') or GetPlayerIdentifier(src, 3)

    MySQL.insert.await(
        'INSERT INTO bans (name, license, discord, ip, reason, expire, bannedby) VALUES (?, ?, ?, ?, ?, ?, ?)',
        {
            GetPlayerName(src),
            license,
            GetPlayerIdentifierByType(src, 'discord'),
            GetPlayerEndpoint(src),
            text,
            seconds and (os.time() + seconds) or nil,
            'se_v2',
        }
    )

    DropPlayer(src, ('Kamu dibanned: %s'):format(text))
end

exports("ar", noop)
exports("banPlayer", banPlayer)
exports("__status", status)
exports("__cipher", cipher)

return {
  ar = noop,
  banPlayer = banPlayer,
  __status = status,
  __cipher = cipher,
}
