local data = lib.load('rhd_addon.data.backpack')

local Backpack = {}

---@param name string
---@return boolean
function Backpack.isItem(name)
    return data[name] ~= nil
end

return Backpack