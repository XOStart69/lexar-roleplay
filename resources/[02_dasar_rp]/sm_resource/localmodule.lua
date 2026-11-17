---Get caller's resource and base path
---@return string resource
---@return string basePath
local function getCallerInfo()
    for level = 1, 20 do
        local info = debug.getinfo(level, 'S')
        if not info then break end

        local src = info.source
        local validsource = src and src:match('^@@[^/]+/.+%.lua$') and
                                not src:find('localmodule') and not src:find('citizen:')

        if validsource then
            local path = src:gsub('^@@', '')

            local resource = path:match('^([^/]+)')
            if not resource then goto continue end

            local fullPath = path:match('^[^/]+/(.+)$')
            if not fullPath then
                return resource, ''
            end

            local basePath = fullPath:match('(.+)/[^/]+%.lua$') or ''

            if basePath:match('/client$') or basePath:match('/server$') or basePath:match('/shared$') or basePath:match('/utils$') or basePath:match('/modules$') then
                basePath = basePath:match('(.+)/[^/]+$') or basePath
            end

            return resource, basePath
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
        error(("localmodule: failed to load '%s'\n\nResource: %s\nBase: %s\n\n%s"):format(
            modName, resource, basePath ~= '' and basePath or '(root)', err
        ), 2)
    end

    self.loaded[cacheKey] = result
    return result
end

_ENV.localmodule = setmetatable({
    loaded = {}
}, {
    __call = localrequire
})