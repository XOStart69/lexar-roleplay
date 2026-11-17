local Nui = localmodule 'modules.nui'
local Pull = localmodule 'modules.pull'

local Catalog = {}

---@type integer?
local version

---@return boolean
function Catalog.sync()
    local current = GlobalState['sm_tcgcards:catalog']

    if current and current == version then return true end

    local payload = Pull.await('catalog')

    if type(payload) ~= 'table' then return false end

    version = payload.version
    Nui.send('catalog', payload)

    return true
end

return Catalog
