local Text = {}

---@param value any
---@param min integer
---@param max integer
---@return string?
function Text.name(value, min, max)
    if type(value) ~= 'string' then return end

    local name = value:gsub('%s+', ' '):match('^%s*(.-)%s*$')

    if #name < min or #name > max or not name:match("^[%w %.'&%-]+$") then return end

    return name
end

return Text
