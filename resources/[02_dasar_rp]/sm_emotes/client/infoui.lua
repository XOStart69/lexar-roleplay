local info = {}
local cached = {}

---@class InformationProps
---@field id string
---@field title string
---@field icon string
---@field description string|table<string, any>
---@field defaultCollapsed? boolean

---@param data InformationProps|InformationProps[]
function info.show(data)
    pcall(function (...)
        exports.rhd_infoui:show(data)
    end)
end

function info.remove(id)
    pcall(function (...)
        exports.rhd_infoui:remove(id)
    end)
end

function info.removeAll()
    pcall(function (...)
        exports.rhd_infoui:removeAll()
    end)
end

_ENV.info = info