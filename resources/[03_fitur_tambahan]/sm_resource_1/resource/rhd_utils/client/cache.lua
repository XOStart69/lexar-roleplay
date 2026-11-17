local getters = {
    coords = function ()
        local coords = GetEntityCoords(cache.ped)
        local heading = GetEntityHeading(cache.ped)
        return vec(coords.x, coords.y, coords.z, heading)
    end
}

local setters = {}

RHDCache = setmetatable({}, {
    __index = function(self, key)
        local fn = getters[key]
        local value = rawget(self, key)
        
        if fn then
            value = fn()
        end

        return value
    end,
    __newindex = function(self, key, value)
        local fn = setters[key]

        if fn then
            fn(value)
        end

        rawset(self, key, value)
    end,
})