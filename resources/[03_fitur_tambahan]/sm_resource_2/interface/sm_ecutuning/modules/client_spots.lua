local spots = ECUConfig.TuningSpots
if not spots or not spots.locations or #spots.locations == 0 then return end

local INFO_ID = 'sm_ecutuning:spot'
local JOB = spots.job
local RADIUS = spots.radius or 3.0

local inside = 0

---@return boolean
local function hasJob()
    local job = QBPlayerData.job
    return job and job.name == JOB or false
end

local keybind = lib.addKeybind({
    name = 'sm_ecutuning_spot',
    description = 'Buka ECU Tuning di bengkel remap',
    defaultKey = 'E',
    disabled = true,
    onReleased = function()
        if not hasJob() then return end
        ECU_OpenFromSpot()
    end,
})

local function showInfo()
    if not hasJob() then return end
    exports.rhd_infoui:show({
        id = INFO_ID,
        title = 'ECU Tuning',
        icon = 'fa-solid fa-microchip',
        description = 'Tekan [E] untuk membuka menu ECU Tuning',
    })
end

local function hideInfo()
    exports.rhd_infoui:remove(INFO_ID)
end

local locations = spots.locations
for i = 1, #locations do
    lib.points.new({
        coords = locations[i],
        distance = RADIUS,
        onEnter = function()
            inside = inside + 1
            keybind:disable(false)
            showInfo()
        end,
        onExit = function()
            inside = inside - 1
            if inside > 0 then return end

            inside = 0
            keybind:disable(true)
            hideInfo()
        end,
    })
end

RegisterNetEvent('QBCore:Client:OnJobUpdate', function()
    if inside <= 0 then return end

    if hasJob() then
        showInfo()
    else
        hideInfo()
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end
    hideInfo()
end)
