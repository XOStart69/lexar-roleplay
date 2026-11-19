local levels = { debug = 1, info = 2, warn = 3, error = 4 }
local tags = { '^5', '^2', '^3', '^1' }

---@param kind string
---@param message string
function Debug(kind, message)
    if not Config.Debug then return end

    print(('%s[racing:%s]^7 %s'):format(tags[levels[kind]] or '^7', kind, message))
end

---@param message string
function DebugInfo(message) Debug('info', message) end

---@param message string
function DebugWarn(message) Debug('warn', message) end

---@param message string
function DebugError(message) Debug('error', message) end