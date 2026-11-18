-- se_v2 core stub: tanpa cek IP, tanpa stop resource
-- versi asli: core.lua.packed / core.lua.orig
local function noop() end
local function status() return "active" end
local function cipher() return { keys = { "STUB" }, table = {} } end

exports("ar", noop)
exports("banPlayer", noop)
exports("__status", status)
exports("__cipher", cipher)

return {
  ar = noop,
  banPlayer = noop,
  __status = status,
  __cipher = cipher,
}