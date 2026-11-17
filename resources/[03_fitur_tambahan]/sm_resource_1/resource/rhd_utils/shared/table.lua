---Check if table is empty
---@param t table
---@return boolean
function table.isempty(t)
    return next(t) == nil
end

---Get table size (works for non-sequential tables)
---@param t table
---@return number
function table.size(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

---Get table keys as array
---@param t table
---@return table
function table.keys(t)
    local result = {}
    for k in pairs(t) do
        result[#result + 1] = k
    end
    return result
end

---Get table values as array
---@param t table
---@return table
function table.values(t)
    local result = {}
    for _, v in pairs(t) do
        result[#result + 1] = v
    end
    return result
end

---Invert table (swap keys and values)
---@param t table
---@return table
function table.invert(t)
    local result = {}
    for k, v in pairs(t) do
        result[v] = k
    end
    return result
end

---Iterate with callback, return first match with truthy result
---@param t table
---@param fn fun(value: any, key: any): boolean?
---@return any? value
---@return any? key
function table.forEach(t, fn)
    for k, v in pairs(t) do
        local res = fn and fn(v, k)
        if res then return v, k end
    end
end

---Check if any element matches predicate
---@param t table
---@param fn fun(value: any, key: any): boolean
---@return boolean
function table.some(t, fn)
    for k, v in pairs(t) do
        if fn(v, k) then
            return true
        end
    end
    return false
end

---Find all elements matching predicate
---@param t table
---@param fn fun(value: any, key: any): boolean
---@return table
function table.findAll(t, fn)
    local result = {}
    
    for k, v in pairs(t) do
        if fn(v, k) then
            result[#result + 1] = v
        end
    end
    
    return result
end

---Pick specific keys from table
---@param t table
---@param keys table
---@return table
function table.pick(t, keys)
    local result = {}
    
    for _, key in ipairs(keys) do
        if t[key] ~= nil then
            result[key] = t[key]
        end
    end
    
    return result
end

---Omit specific keys from table
---@param t table
---@param keys table
---@return table
function table.omit(t, keys)
    local result = table.clone(t)
    local keySet = {}
    
    for _, key in ipairs(keys) do
        keySet[key] = true
    end
    
    for k in pairs(result) do
        if keySet[k] then
            result[k] = nil
        end
    end
    
    return result
end

---Get value by path (dot notation)
---@param t table
---@param path string
---@return any?
function table.get(t, path)
    local keys = {}
    for key in path:gmatch('[^.]+') do
        keys[#keys + 1] = key
    end
    
    local current = t
    for _, key in ipairs(keys) do
        if type(current) ~= 'table' then
            return nil
        end
        current = current[key]
    end
    
    return current
end

---Set value by path (dot notation)
---@param t table
---@param path string
---@param value any
function table.set(t, path, value)
    local keys = {}
    for key in path:gmatch('[^.]+') do
        keys[#keys + 1] = key
    end
    
    local current = t
    for i = 1, #keys - 1 do
        local key = keys[i]
        if type(current[key]) ~= 'table' then
            current[key] = {}
        end
        current = current[key]
    end
    
    current[keys[#keys]] = value
end

---Delete value by path (dot notation)
---@param t table
---@param path string
function table.delete(t, path)
    local keys = {}
    for key in path:gmatch('[^.]+') do
        keys[#keys + 1] = key
    end
    
    local current = t
    for i = 1, #keys - 1 do
        local key = keys[i]
        if type(current[key]) ~= 'table' then
            return
        end
        current = current[key]
    end
    
    current[keys[#keys]] = nil
end

---Convert table to JSON string
---@param t table
---@return string
function table.toJSON(t)
    local function serialize(val)
        local valType = type(val)
        
        if valType == 'table' then
            local isArray = #val > 0
            local result = {}
            
            if isArray then
                for i, v in ipairs(val) do
                    result[#result + 1] = serialize(v)
                end
                return '[' .. table.concat(result, ',') .. ']'
            else
                for k, v in pairs(val) do
                    result[#result + 1] = '"' .. tostring(k) .. '":' .. serialize(v)
                end
                return '{' .. table.concat(result, ',') .. '}'
            end
        elseif valType == 'string' then
            return '"' .. val:gsub('"', '\\"') .. '"'
        elseif valType == 'number' or valType == 'boolean' then
            return tostring(val)
        else
            return 'null'
        end
    end
    
    return serialize(t)
end

---Print table structure (for debugging)
---@param t table
---@param indent? number
---@return string
function table.print(t, indent)
    indent = indent or 0
    local result = {}
    local prefix = string.rep('  ', indent)
    
    for k, v in pairs(t) do
        if type(v) == 'table' then
            result[#result + 1] = prefix .. tostring(k) .. ' = {'
            result[#result + 1] = table.print(v, indent + 1)
            result[#result + 1] = prefix .. '}'
        else
            result[#result + 1] = prefix .. tostring(k) .. ' = ' .. tostring(v)
        end
    end
    
    return table.concat(result, '\n')
end

---Flatten nested array by one level
---@param t table
---@return table
function array.flatten(t)
    local result = {}
    
    for _, v in ipairs(t) do
        if type(v) == 'table' then
            for _, inner in ipairs(v) do
                result[#result + 1] = inner
            end
        else
            result[#result + 1] = v
        end
    end
    
    return result
end

---Deep flatten nested arrays
---@param t table
---@return table
function array.deepflatten(t)
    local result = {}
    
    local function flatten_recursive(tbl_inner)
        for _, v in ipairs(tbl_inner) do
            if type(v) == 'table' then
                flatten_recursive(v)
            else
                result[#result + 1] = v
            end
        end
    end
    
    flatten_recursive(t)
    return result
end

---Get unique values from array
---@param t table
---@return table
function array.unique(t)
    local seen = {}
    local result = {}
    
    for _, v in ipairs(t) do
        if not seen[v] then
            seen[v] = true
            result[#result + 1] = v
        end
    end
    
    return result
end

---Get intersection of two arrays
---@param t1 table
---@param t2 table
---@return table
function array.intersection(t1, t2)
    local result = {}
    local set = {}
    
    for _, v in ipairs(t2) do
        set[v] = true
    end
    
    for _, v in ipairs(t1) do
        if set[v] then
            result[#result + 1] = v
        end
    end
    
    return result
end

---Get difference between two arrays (elements in t1 but not in t2)
---@param t1 table
---@param t2 table
---@return table
function array.difference(t1, t2)
    local result = {}
    local set = {}
    
    for _, v in ipairs(t2) do
        set[v] = true
    end
    
    for _, v in ipairs(t1) do
        if not set[v] then
            result[#result + 1] = v
        end
    end
    
    return result
end

---Get union of two arrays
---@param t1 table
---@param t2 table
---@return table
function array.union(t1, t2)
    local combined = {}
    for _, v in ipairs(t1) do
        combined[#combined + 1] = v
    end
    for _, v in ipairs(t2) do
        combined[#combined + 1] = v
    end
    return array.unique(combined)
end

---Get last index of value in array
---@param t table
---@param value any
---@return number?
function array.lastIndexOf(t, value)
    for i = #t, 1, -1 do
        if t[i] == value then
            return i
        end
    end
    return nil
end

---Remove first occurrence of value from array
---@param t table
---@param value any
---@return boolean success
function array.removeValue(t, value)
    for i = 1, #t do
        if t[i] == value then
            table.remove(t, i)
            return true
        end
    end
    return false
end

---Remove all occurrences of value from array
---@param t table
---@param value any
---@return number count
function array.removeAll(t, value)
    local count = 0
    
    for i = #t, 1, -1 do
        if t[i] == value then
            table.remove(t, i)
            count = count + 1
        end
    end
    
    return count
end

---Get random element from array
---@param t table
---@return any?
function array.random(t)
    if #t == 0 then return nil end
    return t[math.random(#t)]
end

---Get random elements from array (without duplicates)
---@param t table
---@param count number
---@return table
function array.sample(t, count)
    local result = {}
    local indices = {}
    local len = #t
    
    count = math.min(count, len)
    
    while #indices < count do
        local idx = math.random(len)
        if not indices[idx] then
            indices[idx] = true
            result[#result + 1] = t[idx]
        end
    end
    
    return result
end

---Chunk array into smaller arrays
---@param t table
---@param size number
---@return table
function array.chunk(t, size)
    local result = {}
    
    for i = 1, #t, size do
        local chunk = {}
        for j = i, math.min(i + size - 1, #t) do
            chunk[#chunk + 1] = t[j]
        end
        result[#result + 1] = chunk
    end
    
    return result
end

---Partition array by predicate
---@param t table
---@param fn fun(value: any, key: any): boolean
---@return table truthy
---@return table falsy
function array.partition(t, fn)
    local truthy = {}
    local falsy = {}
    
    for k, v in pairs(t) do
        if fn(v, k) then
            truthy[#truthy + 1] = v
        else
            falsy[#falsy + 1] = v
        end
    end
    
    return truthy, falsy
end

---Group array elements by key function
---@param t table
---@param fn fun(value: any): any
---@return table
function array.groupBy(t, fn)
    local result = {}
    
    for _, v in ipairs(t) do
        local key = fn(v)
        if not result[key] then
            result[key] = {}
        end
        result[key][#result[key] + 1] = v
    end
    
    return result
end

---Count occurrences of each value
---@param t table
---@return table
function array.countBy(t)
    local result = {}
    
    for _, v in pairs(t) do
        result[v] = (result[v] or 0) + 1
    end
    
    return result
end

---Zip multiple arrays together
---@param ... table
---@return table
function array.zip(...)
    local args = {...}
    local result = {}
    local maxLen = 0
    
    for _, t in ipairs(args) do
        maxLen = math.max(maxLen, #t)
    end
    
    for i = 1, maxLen do
        local row = {}
        for _, t in ipairs(args) do
            row[#row + 1] = t[i]
        end
        result[#result + 1] = row
    end
    
    return result
end

---Unzip array of arrays
---@param t table
---@return table ...
function array.unzip(t)
    if #t == 0 then return {} end
    
    local result = {}
    local maxLen = 0
    
    for _, row in ipairs(t) do
        maxLen = math.max(maxLen, #row)
    end
    
    for i = 1, maxLen do
        result[i] = {}
        for _, row in ipairs(t) do
            result[i][#result[i] + 1] = row[i]
        end
    end
    
    return table.unpack(result)
end

---Create array from range
---@param start_val number
---@param end_val number
---@param step? number
---@return table
function array.range(start_val, end_val, step)
    step = step or 1
    local result = {}
    
    if step > 0 then
        for i = start_val, end_val, step do
            result[#result + 1] = i
        end
    else
        for i = start_val, end_val, step do
            result[#result + 1] = i
        end
    end
    
    return result
end

---Create array filled with value
---@param count number
---@param value any
---@return table
function array.create(count, value)
    local result = {}
    for i = 1, count do
        result[i] = value
    end
    return result
end

---Sort array and return new table (non-mutating)
---@param t table
---@param compareFn? fun(a: any, b: any): boolean
---@return table
function array.sorted(t, compareFn)
    local result = table.clone(t)
    table.sort(result, compareFn)
    return result
end

---Concatenate multiple arrays
---@param ... table
---@return table
function array.concat(...)
    local result = {}
    
    for i = 1, select('#', ...) do
        local t = select(i, ...)
        for j = 1, #t do
            result[#result + 1] = t[j]
        end
    end
    
    return result
end
