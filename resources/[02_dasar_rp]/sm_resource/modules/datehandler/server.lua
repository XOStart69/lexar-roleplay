local date = {}

---@alias DateFormat
---| 'DD-MM-YYYY'  # Format: 21-01-2026
---| 'MM-DD-YYYY'  # Format: 01-21-2026
---| 'YYYY-MM-DD'  # Format: 2026-01-21
---| 'DD/MM/YYYY'  # Format: 21/01/2026
---| 'MM/DD/YYYY'  # Format: 01/21/2026
---| 'YYYY/MM/DD'  # Format: 2026/01/21
---| 'id-ID'       # Format: 21 Januari 2026
---| 'en-US'       # Format: January 21, 2026

local MONTH_NAMES = {
    ['id-ID'] = {
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    },
    ['en-US'] = {
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
    }
}

local function pad(num)
    return num < 10 and '0' .. num or tostring(num)
end

---Convert timestamp or current time to formatted string
---@param format DateFormat
---@param timestamp? number Unix timestamp (optional, defaults to current time)
---@return string
function date.tostring(format, timestamp)
    if not format then return '' end
    
    local t = timestamp and os.date('*t', timestamp) or os.date('*t')
    local day = pad(t.day)
    local month = pad(t.month)
    local year = tostring(t.year)
    
    if format == 'DD-MM-YYYY' then
        return ('%s-%s-%s'):format(day, month, year)
    elseif format == 'MM-DD-YYYY' then
        return ('%s-%s-%s'):format(month, day, year)
    elseif format == 'YYYY-MM-DD' then
        return ('%s-%s-%s'):format(year, month, day)
    elseif format == 'DD/MM/YYYY' then
        return ('%s/%s/%s'):format(day, month, year)
    elseif format == 'MM/DD/YYYY' then
        return ('%s/%s/%s'):format(month, day, year)
    elseif format == 'YYYY/MM/DD' then
        return ('%s/%s/%s'):format(year, month, day)
    elseif format == 'id-ID' then
        local monthName = MONTH_NAMES['id-ID'][t.month]
        return ('%s %s %s'):format(t.day, monthName, year)
    elseif format == 'en-US' then
        local monthName = MONTH_NAMES['en-US'][t.month]
        return ('%s %s, %s'):format(monthName, t.day, year)
    end
    
    return ''
end

---Check if a date string is valid
---@param dateStr string Date string to validate
---@param format DateFormat Format to validate against
---@return boolean
function date.check(dateStr, format)
    if not dateStr or not format then return false end
    
    local day, month, year
    
    if format == 'DD-MM-YYYY' then
        day, month, year = dateStr:match('^(%d%d)-(%d%d)-(%d%d%d%d)$')
    elseif format == 'MM-DD-YYYY' then
        month, day, year = dateStr:match('^(%d%d)-(%d%d)-(%d%d%d%d)$')
    elseif format == 'YYYY-MM-DD' then
        year, month, day = dateStr:match('^(%d%d%d%d)-(%d%d)-(%d%d)$')
    elseif format == 'DD/MM/YYYY' then
        day, month, year = dateStr:match('^(%d%d)/(%d%d)/(%d%d%d%d)$')
    elseif format == 'MM/DD/YYYY' then
        month, day, year = dateStr:match('^(%d%d)/(%d%d)/(%d%d%d%d)$')
    elseif format == 'YYYY/MM/DD' then
        year, month, day = dateStr:match('^(%d%d%d%d)/(%d%d)/(%d%d)$')
    elseif format == 'id-ID' or format == 'en-US' then
        local monthNames = MONTH_NAMES[format]
        for i, monthName in ipairs(monthNames) do
            if dateStr:find(monthName) then
                month = i
                day, year = dateStr:match('^(%d+)%s+' .. monthName .. '%s+(%d%d%d%d)$')
                break
            end
        end
    else
        return false
    end
    
    if not day or not month or not year then return false end
    
    day = tonumber(day)
    month = tonumber(month)
    year = tonumber(year)
    
    if not day or not month or not year then return false end
    if month < 1 or month > 12 then return false end
    if day < 1 or day > 31 then return false end
    if year < 1900 or year > 2100 then return false end
    
    local daysInMonth = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
    
    if year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0) then
        daysInMonth[2] = 29
    end
    
    return day <= daysInMonth[month]
end

---Parse date string and convert to timestamp
---@param dateStr string Date string to parse
---@param format DateFormat Format of the date string
---@return number? timestamp Unix timestamp or nil if invalid
function date.parse(dateStr, format)
    if not date.check(dateStr, format) then return nil end
    
    local day, month, year
    
    if format == 'DD-MM-YYYY' then
        day, month, year = dateStr:match('^(%d%d)-(%d%d)-(%d%d%d%d)$')
    elseif format == 'MM-DD-YYYY' then
        month, day, year = dateStr:match('^(%d%d)-(%d%d)-(%d%d%d%d)$')
    elseif format == 'YYYY-MM-DD' then
        year, month, day = dateStr:match('^(%d%d%d%d)-(%d%d)-(%d%d)$')
    elseif format == 'DD/MM/YYYY' then
        day, month, year = dateStr:match('^(%d%d)/(%d%d)/(%d%d%d%d)$')
    elseif format == 'MM/DD/YYYY' then
        month, day, year = dateStr:match('^(%d%d)/(%d%d)/(%d%d%d%d)$')
    elseif format == 'YYYY/MM/DD' then
        year, month, day = dateStr:match('^(%d%d%d%d)/(%d%d)/(%d%d)$')
    elseif format == 'id-ID' or format == 'en-US' then
        local monthNames = MONTH_NAMES[format]
        for i, monthName in ipairs(monthNames) do
            if dateStr:find(monthName) then
                month = i
                day, year = dateStr:match('^(%d+)%s+' .. monthName .. '%s+(%d%d%d%d)$')
                break
            end
        end
    end

    return os.time({
        ---@diagnostic disable-next-line: assign-type-mismatch
        year = tonumber(year), month = tonumber(month), day = tonumber(day),
        hour = 0, min = 0, sec = 0
    })
end

---Get difference between two dates in days
---@param date1 string|number First date (string or timestamp)
---@param date2 string|number Second date (string or timestamp)
---@param format DateFormat Format if dates are strings
---@return number days Difference in days
function date.diff(date1, date2, format)
    local ts1 = type(date1) == 'string' and date.parse(date1, format) or date1
    local ts2 = type(date2) == 'string' and date.parse(date2, format) or date2
    
    if not ts1 or not ts2 then return 0 end
    
    return math.floor(math.abs(ts2 - ts1) / 86400)
end

---Add days to a date
---@param timestamp number Unix timestamp
---@param days number Number of days to add (can be negative)
---@return number timestamp New timestamp
function date.add(timestamp, days)
    return timestamp + (days * 86400)
end

---Get current timestamp
---@return number timestamp Unix timestamp
function date.now()
    return os.time()
end

---Convert between date formats
---@param dateStr string Date string to convert
---@param fromFormat DateFormat Source format
---@param toFormat DateFormat Target format
---@return string? convertedDate Converted date string or nil if invalid
function date.convert(dateStr, fromFormat, toFormat)
    local timestamp = date.parse(dateStr, fromFormat)
    if not timestamp then return nil end
    return date.tostring(toFormat, timestamp)
end

return date