local rawList = localmodule 'data.vehicles'

local KICK_DELAY = 500

local DUTY_REQUIRED = {
    [`klx450f`] = true,
    [`kx450f`] = true,
    [`smrapt`] = true,
    [`smspeedo`] = true,
    [`derektemu`] = true,
    [`flattemu`] = true,
}

---@type table<number, table<string, boolean>>
local whitelist = {}

for hash, jobs in pairs(rawList) do
    local allowed = {}

    for i = 1, #jobs do
        allowed[jobs[i]] = true
    end

    whitelist[hash] = allowed
end

---@param vehicle number?
---@return boolean allowed
---@return string? reason
local function canDrive(vehicle)
    if not vehicle or vehicle == 0 then return true end

    local model = GetEntityModel(vehicle)
    local allowed = whitelist[model]
    if not allowed then return true end

    local job = QBPlayerData.job

    if not job or not allowed[job.name] then
        return false, 'Kendaraan ini hanya untuk pekerjaan tertentu!'
    end

    if DUTY_REQUIRED[model] and not job.onduty then
        return false, 'Anda harus On Duty untuk menggunakan kendaraan ini!'
    end

    return true
end

exports('CanDriveVehicle', canDrive)

---@param vehicle number
local function checkDriver(vehicle)
    SetTimeout(KICK_DELAY, function()
        if cache.vehicle ~= vehicle or cache.seat ~= -1 then return end

        local allowed, reason = canDrive(vehicle)
        if allowed then return end

        TaskLeaveVehicle(cache.ped, vehicle, 1)
        lib.notify({ title = 'Peringatan', description = reason, type = 'error' })
    end)
end

lib.onCache('vehicle', function(vehicle)
    if vehicle then
        checkDriver(vehicle)
    end
end)

lib.onCache('seat', function(seat)
    local vehicle = cache.vehicle

    if seat == -1 and vehicle then
        checkDriver(vehicle)
    end
end)
