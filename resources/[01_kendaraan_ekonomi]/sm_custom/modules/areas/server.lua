---@class AreasServer
local areas = {}

local shared = modules.areas

---@param shape CustomArea
---@param coords vector3
---@return boolean
function areas.contains(shape, coords)
    return shared.contains(shape, coords)
end

return areas
