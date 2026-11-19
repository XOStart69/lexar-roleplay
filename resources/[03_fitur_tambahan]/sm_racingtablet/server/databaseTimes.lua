local units = { 'ms', 's', 'm', 'h' }

---@param ms number
---@return string
function formatTime(ms)
    if ms < 1000 then return ('%d ms'):format(ms) end

    local value, unit = ms, 1

    while value >= 1000 and unit < #units do
        value = value / 1000
        unit = unit + 1
    end

    return ('%.3f %s'):format(value, units[unit])
end

---@param ms number
---@return string
function formatClock(ms)
    local minutes = math.floor(ms / 60000)
    local seconds = math.floor((ms % 60000) / 1000)
    local hundredths = math.floor((ms % 1000) / 10)

    return ('%02d:%02d.%02d'):format(minutes, seconds, hundredths)
end

---@param timestamp number
---@return string
function formatAge(timestamp)
    local diff = os.time() - timestamp

    if diff < 60 then return 'baru saja' end
    if diff < 3600 then return ('%d menit lalu'):format(math.floor(diff / 60)) end
    if diff < 86400 then return ('%d jam lalu'):format(math.floor(diff / 3600)) end

    return ('%d hari lalu'):format(math.floor(diff / 86400))
end