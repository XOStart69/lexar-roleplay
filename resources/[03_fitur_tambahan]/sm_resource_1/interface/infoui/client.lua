local infoui = exports.rhd_infoui

local information = {}

---@class InformationProps
---@field id string
---@field title string
---@field icon string
---@field description string|table<string, any>
---@field defaultCollapsed? boolean

---@param data InformationProps
function information.show(data)
    infoui:show(data)
end

---@param id string
function information.remove(id)
    infoui:remove(id)
end

function information.removeAll()
    infoui:removeAll()
end

_ENV.infoUI = information

local exportWrapper = require 'export_wrapper'

exportWrapper('sm_resource_1', 'infoShow', information.show)
exportWrapper('sm_resource_1', 'infoRemove', information.remove)
exportWrapper('sm_resource_1', 'infoRemoveAll', information.removeAll)
