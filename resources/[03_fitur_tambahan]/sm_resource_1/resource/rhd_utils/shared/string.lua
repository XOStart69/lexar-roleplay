
---@alias CaseType
---| 'upper'      # UPPERCASE
---| 'lower'      # lowercase
---| 'title'      # Title Case
---| 'sentence'   # Sentence case
---| 'camel'      # camelCase
---| 'pascal'     # PascalCase
---| 'snake'      # snake_case
---| 'kebab'      # kebab-case
---| 'constant'   # CONSTANT_CASE

---Return empty string
---@return string
function string.empty()
    return ''
end

---Check if string is empty or nil
---@param s string?
---@return boolean
function string.isempty(s)
    return not s or s == ''
end

---Check if string is blank (empty or only whitespace)
---@param s string?
---@return boolean
function string.isblank(s)
    return not s or s:match('^%s*$') ~= nil
end

---Trim whitespace from both ends
---@param s string
---@return string
function string.trim(s)
    return s:match('^%s*(.-)%s*$')
end

---Trim whitespace from start
---@param s string
---@return string
function string.ltrim(s)
    return s:match('^%s*(.-)$')
end

---Trim whitespace from end
---@param s string
---@return string
function string.rtrim(s)
    return s:match('^(.-)%s*$')
end

---Split string by delimiter
---@param s string
---@param delimiter string
---@param plain? boolean Use plain text matching (default: true)
---@return table
function string.split(s, delimiter, plain)
    if plain == nil then plain = true end
    
    local result = {}
    local from = 1
    local delim_from, delim_to = s:find(delimiter, from, plain)
    
    while delim_from do
        result[#result + 1] = s:sub(from, delim_from - 1)
        from = delim_to + 1
        delim_from, delim_to = s:find(delimiter, from, plain)
    end
    
    result[#result + 1] = s:sub(from)
    return result
end

---Join table elements with delimiter
---@param tbl table
---@param delimiter string
---@return string
function string.join(tbl, delimiter)
    return table.concat(tbl, delimiter)
end

---Check if string starts with prefix
---@param s string
---@param prefix string
---@return boolean
function string.startswith(s, prefix)
    return s:sub(1, #prefix) == prefix
end

---Check if string ends with suffix
---@param s string
---@param suffix string
---@return boolean
function string.endswith(s, suffix)
    return s:sub(-#suffix) == suffix
end

---Check if string contains substring
---@param s string
---@param substr string
---@param plain? boolean Use plain text matching (default: true)
---@return boolean
function string.contains(s, substr, plain)
    if plain == nil then plain = true end
    return s:find(substr, 1, plain) ~= nil
end

---Count occurrences of substring
---@param s string
---@param substr string
---@param plain? boolean Use plain text matching (default: true)
---@return number
function string.count(s, substr, plain)
    if plain == nil then plain = true end
    
    local count = 0
    local pos = 1
    
    while true do
        local found = s:find(substr, pos, plain)
        if not found then break end
        count = count + 1
        pos = found + 1
    end
    
    return count
end

---Replace all occurrences
---@param s string
---@param old string
---@param new string
---@param plain? boolean Use plain text matching (default: true)
---@return string
function string.replace(s, old, new, plain)
    if plain == nil then plain = true end
    if plain then
        old = old:gsub('[%^%$%(%)%%%.%[%]%*%+%-%?]', '%%%1')
    end
    ---@diagnostic disable-next-line: redundant-return-value
    return s:gsub(old, new)
end

---Capitalize first character
---@param s string
---@return string
function string.capitalize(s)
    return s:sub(1, 1):upper() .. s:sub(2)
end

---Convert to title case
---@param s string
---@return string
function string.title(s)
    ---@diagnostic disable-next-line: redundant-return-value
    return s:gsub('(%a)([%w_]*)', function(first, rest)
        return first:upper() .. rest:lower()
    end)
end

---Convert to camelCase
---@param s string
---@return string
function string.camelcase(s)
    local result = s:gsub('[%s_-]+(%w)', function(c) return c:upper() end)
    return result:sub(1, 1):lower() .. result:sub(2)
end

---Convert to PascalCase
---@param s string
---@return string
function string.pascalcase(s)
    local result = s:gsub('[%s_-]+(%w)', function(c) return c:upper() end)
    return result:sub(1, 1):upper() .. result:sub(2)
end

---Convert to snake_case
---@param s string
---@return string
function string.snakecase(s)
    local result = s:gsub('([A-Z])', '_%1'):lower()
    result = result:gsub('[%s-]+', '_')
    ---@diagnostic disable-next-line: redundant-return-value
    return result:gsub('^_', '')
end

---Convert to kebab-case
---@param s string
---@return string
function string.kebabcase(s)
    local result = s:gsub('([A-Z])', '-%1'):lower()
    result = result:gsub('[%s_]+', '-')
    ---@diagnostic disable-next-line: redundant-return-value
    return result:gsub('^-', '')
end

---Convert to CONSTANT_CASE
---@param s string
---@return string
function string.constantcase(s)
    return string.snakecase(s):upper()
end

---Convert to specified case
---@param s string
---@param caseType CaseType
---@return string
function string.tocase(s, caseType)
    if caseType == 'upper' then
        return s:upper()
    elseif caseType == 'lower' then
        return s:lower()
    elseif caseType == 'title' then
        return string.title(s)
    elseif caseType == 'sentence' then
        return string.capitalize(s:lower())
    elseif caseType == 'camel' then
        return string.camelcase(s)
    elseif caseType == 'pascal' then
        return string.pascalcase(s)
    elseif caseType == 'snake' then
        return string.snakecase(s)
    elseif caseType == 'kebab' then
        return string.kebabcase(s)
    elseif caseType == 'constant' then
        return string.constantcase(s)
    end
    return s
end

---Repeat string n times
---@param s string
---@param count number
---@param separator? string
---@return string
function string.repeatstr(s, count, separator)
    separator = separator or ''
    local result = {}
    for i = 1, count do
        result[#result + 1] = s
    end
    return table.concat(result, separator)
end

---Pad string to length
---@param s string
---@param length number
---@param char? string Character to pad with (default: ' ')
---@param direction? 'left'|'right'|'both' Direction to pad (default: 'right')
---@return string
function string.pad(s, length, char, direction)
    char = char or ' '
    direction = direction or 'right'
    
    local len = #s
    if len >= length then return s end
    
    local padding = string.rep(char, length - len)
    
    if direction == 'left' then
        return padding .. s
    elseif direction == 'right' then
        return s .. padding
    elseif direction == 'both' then
        local leftPad = math.floor((length - len) / 2)
        local rightPad = length - len - leftPad
        return string.rep(char, leftPad) .. s .. string.rep(char, rightPad)
    end
    
    return s
end

---Truncate string to length
---@param s string
---@param length number
---@param suffix? string Suffix to add (default: '...')
---@return string
function string.truncate(s, length, suffix)
    suffix = suffix or '...'
    if #s <= length then return s end
    return s:sub(1, length - #suffix) .. suffix
end

---Get substring between two delimiters
---@param s string
---@param start_delim string
---@param end_delim string
---@return string?
function string.between(s, start_delim, end_delim)
    local start_pos = s:find(start_delim, 1, true)
    if not start_pos then return nil end
    
    start_pos = start_pos + #start_delim
    local end_pos = s:find(end_delim, start_pos, true)
    if not end_pos then return nil end
    
    return s:sub(start_pos, end_pos - 1)
end

---Extract all matches of pattern
---@param s string
---@param pattern string
---@return table
function string.extract(s, pattern)
    local result = {}
    for match in s:gmatch(pattern) do
        result[#result + 1] = match
    end
    return result
end

---Remove all whitespace
---@param s string
---@return string
function string.removewhitespace(s)
    ---@diagnostic disable-next-line: redundant-return-value
    return s:gsub('%s+', '')
end

---Collapse multiple spaces to single space
---@param s string
---@return string
function string.collapsespaces(s)
    ---@diagnostic disable-next-line: redundant-return-value
    return s:gsub('%s+', ' ')
end

---Check if string is numeric
---@param s string
---@return boolean
function string.isnumeric(s)
    return tonumber(s) ~= nil
end

---Check if string is alphabetic
---@param s string
---@return boolean
function string.isalpha(s)
    return s:match('^%a+$') ~= nil
end

---Check if string is alphanumeric
---@param s string
---@return boolean
function string.isalnum(s)
    return s:match('^%w+$') ~= nil
end

---Check if string is uppercase
---@param s string
---@return boolean
function string.isupper(s)
    return s == s:upper() and s ~= s:lower()
end

---Check if string is lowercase
---@param s string
---@return boolean
function string.islower(s)
    return s == s:lower() and s ~= s:upper()
end

---Escape special pattern characters
---@param s string
---@return string
function string.escape(s)
    ---@diagnostic disable-next-line: redundant-return-value
    return s:gsub('[%^%$%(%)%%%.%[%]%*%+%-%?]', '%%%1')
end

---Remove special characters
---@param s string
---@param keep? string Characters to keep
---@return string
function string.removespecial(s, keep)
    keep = keep or ''
    local pattern = '[^%w%s' .. string.escape(keep) .. ']'
    ---@diagnostic disable-next-line: redundant-return-value
    return s:gsub(pattern, '')
end

---Slugify string (URL-friendly)
---@param s string
---@return string
function string.slugify(s)
    s = s:lower()
    s = s:gsub('[àáâãäå]', 'a')
    s = s:gsub('[èéêë]', 'e')
    s = s:gsub('[ìíîï]', 'i')
    s = s:gsub('[òóôõö]', 'o')
    s = s:gsub('[ùúûü]', 'u')
    s = s:gsub('[ñ]', 'n')
    s = s:gsub('[ç]', 'c')
    s = s:gsub('[^%w%s-]', '')
    s = s:gsub('%s+', '-')
    s = s:gsub('-+', '-')
    s = s:gsub('^-', '')
    s = s:gsub('-$', '')
    return s
end

---Calculate Levenshtein distance
---@param str1 string
---@param str2 string
---@return number
function string.levenshtein(str1, str2)
    if str1 == str2 then return 0 end
    if #str1 == 0 then return #str2 end
    if #str2 == 0 then return #str1 end
    
    local matrix = {}
    
    for i = 0, #str1 do
        matrix[i] = { [0] = i }
    end
    
    for j = 0, #str2 do
        matrix[0][j] = j
    end
    
    for i = 1, #str1 do
        for j = 1, #str2 do
            local cost = str1:sub(i, i) == str2:sub(j, j) and 0 or 1
            matrix[i][j] = math.min(
                matrix[i - 1][j] + 1,
                matrix[i][j - 1] + 1,
                matrix[i - 1][j - 1] + cost
            )
        end
    end
    
    return matrix[#str1][#str2]
end

---Calculate similarity percentage
---@param str1 string
---@param str2 string
---@return number percentage 0-100
function string.similarity(str1, str2)
    local distance = string.levenshtein(str1, str2)
    local maxLen = math.max(#str1, #str2)
    if maxLen == 0 then return 100 end
    return (1 - distance / maxLen) * 100
end

---Word wrap text
---@param s string
---@param width number
---@return string
function string.wordwrap(s, width)
    local result = {}
    local line = ''
    
    for word in s:gmatch('%S+') do
        if #line + #word + 1 > width then
            result[#result + 1] = line
            line = word
        else
            line = line == '' and word or line .. ' ' .. word
        end
    end
    
    if #line > 0 then
        result[#result + 1] = line
    end
    
    return table.concat(result, '\n')
end

---Get lines from string
---@param s string
---@return table
function string.lines(s)
    local result = {}
    for line in s:gmatch('[^\r\n]+') do
        result[#result + 1] = line
    end
    return result
end

---Encode to base64
---@param s string
---@return string
function string.base64encode(s)
    local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    return ((s:gsub('.', function(x)
        local r, b = '', x:byte()
        for i = 8, 1, -1 do r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and '1' or '0') end
        return r
    end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if #x < 6 then return '' end
        local c = 0
        for i = 1, 6 do c = c + (x:sub(i, i) == '1' and 2 ^ (6 - i) or 0) end
        return b:sub(c + 1, c + 1)
    end) .. ({ '', '==', '=' })[#s % 3 + 1])
end

---Decode from base64
---@param s string
---@return string
function string.base64decode(s)
    local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    s = s:gsub('[^' .. b .. '=]', '')
    return (s:gsub('.', function(x)
        if x == '=' then return '' end
        local r, f = '', b:find(x) - 1
        for i = 6, 1, -1 do r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and '1' or '0') end
        return r
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if #x ~= 8 then return '' end
        local c = 0
        for i = 1, 8 do c = c + (x:sub(i, i) == '1' and 2 ^ (8 - i) or 0) end
        return string.char(c)
    end))
end

---Generate UUID v4
---@return string
function string.uuid()
    local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    ---@diagnostic disable-next-line: redundant-return-value
    return template:gsub('[xy]', function(c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

---Convert string to bytes table
---@param s string
---@return table
function string.bytes(s)
    local result = {}
    for i = 1, #s do
        result[#result + 1] = s:byte(i)
    end
    return result
end

---Convert bytes table to string
---@param bytes table
---@return string
function string.frombytes(bytes)
    return string.char(table.unpack(bytes))
end

---Format string with template
---@param template string Template with {key} placeholders
---@param data table Data to insert
---@return string
function string.template(template, data)
    ---@diagnostic disable-next-line: redundant-return-value
    return template:gsub('{(%w+)}', function(key)
        return tostring(data[key] or '')
    end)
end

---Hash string (simple djb2)
---@param s string
---@return number
function string.hash(s)
    local hash = 5381
    for i = 1, #s do
        hash = ((hash * 33) + s:byte(i)) % 2147483647
    end
    return hash
end