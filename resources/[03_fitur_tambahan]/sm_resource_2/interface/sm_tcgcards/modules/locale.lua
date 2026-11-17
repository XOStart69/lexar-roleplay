local base = debug.getinfo(1, 'S').source:match('^@*[^/]+/(.+)/modules/locale%.lua$') or ''
local language = GetConvar('sm_tcgcards:locale', 'id')

---@type table<string, string>
local strings = {}

---@param prefix string?
---@param source table
local function flatten(prefix, source)
    for key, value in pairs(source) do
        local name = prefix and ('%s.%s'):format(prefix, key) or key

        if type(value) == 'table' then
            flatten(name, value)
        else
            strings[name] = value
        end
    end
end

---@param code string
local function load(code)
    local raw = LoadResourceFile(GetCurrentResourceName(), ('%s/locales/%s.json'):format(base, code))
    local ok, data = pcall(json.decode, raw or '')

    if ok and type(data) == 'table' then flatten(nil, data) end
end

load('en')

if language ~= 'en' then load(language) end

return setmetatable({
    all = function()
        return strings
    end,
}, {
    __call = function(_, key, ...)
        local text = strings[key]

        if not text then return key end
        if ... ~= nil then return text:format(...) end

        return text
    end,
})
