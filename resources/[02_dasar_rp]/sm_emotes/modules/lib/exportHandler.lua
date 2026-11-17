---@param name string
---@param cb fun(...): any
local function exportHandler (name, cb)
    AddEventHandler('__cfx_export_rpemotes_'..name, function(setCb)
        setCb(function(...)
            return cb(...)
        end)
    end)
    exports(name, cb)
end

_ENV.exportWrapper = exportHandler