local function normalizeSource(src)
    if type(src) ~= 'string' then return nil end
    if src:find('citizen:', 1, true) or src:find('localmodule', 1, true) then return nil end

    src = src:gsub('\\', '/'):gsub('^@+', '')
    if not src:match('^[^/]+/.+%.lua$') then return nil end

    return src
end

local function getModuleBasePath(fullPath)
    local basePath = fullPath:match('(.+)/[^/]+%.lua$') or ''

    local scope, name = fullPath:match('^([^/]+)/([^/]+)/')
    if scope and name then
        return ('%s/%s'):format(scope, name)
    end

    return basePath
end

---Get caller's resource and base path
---@return string resource
---@return string basePath
local function getCallerInfo()
    for level = 1, 20 do
        local info = debug.getinfo(level, 'S')
        if not info then break end

        local path = normalizeSource(info.source)

        if path then
            local resource = path:match('^([^/]+)')
            if resource ~= cache.resource --[[@as string]] then goto continue end

            local fullPath = path:match('^[^/]+/(.+)$')
            if not fullPath then
                return resource, ''
            end

            return resource, getModuleBasePath(fullPath)
        end

        ::continue::
    end
    
    return cache.resource, ''
end

---Load module from file
---@param modName string
---@param resource string
---@param basePath string
---@return any? result
---@return string? error
local function loadModule(modName, resource, basePath)
    local modPath = modName:gsub('%.', '/')
    local filePath = basePath ~= '' and (basePath .. '/' .. modPath .. '.lua') or (modPath .. '.lua')

    local chunk = LoadResourceFile(resource, filePath)

    if not chunk then
        return nil, ("file not found: @%s/%s"):format(resource, filePath)
    end

    local chunkName = ('@@%s/%s'):format(resource, filePath)
    local fn, loadErr = load(chunk, chunkName, 't', _ENV)

    if not fn then
        return nil, ("syntax error in '%s': %s"):format(filePath, loadErr)
    end

    local success, result = pcall(fn)

    if not success then
        return nil, ("runtime error in '%s': %s"):format(filePath, result)
    end

    return result ~= nil and result or true, nil
end

---Main require function
---@param self table
---@param modName string
---@return any
local function localrequire(self, modName)
    if type(modName) ~= 'string' then
        error(("module name must be a string (received '%s')"):format(type(modName)), 2)
    end

    local resource, basePath = getCallerInfo()
    local cacheKey = ('%s:%s:%s'):format(resource, basePath, modName)

    if self.loaded[cacheKey] then
        return self.loaded[cacheKey]
    end

    local result, err = loadModule(modName, resource, basePath)

    if not result then
        error(("module: failed to load '%s'\n\nResource: %s\nBase: %s\n\n%s"):format(
            modName, resource, basePath ~= '' and basePath or '(root)', err
        ), 2)
    end

    self.loaded[cacheKey] = result
    return result
end

_ENV.module = setmetatable({
    loaded = {}
}, {
    __call = localrequire
})
