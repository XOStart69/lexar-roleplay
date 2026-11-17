local config = require 'config.shared'
local settings = config.self_service

local serviceId = 'motel'
local cachedRental
local mutationPending = false

local function getRental()
    if not cachedRental then
        cachedRental = Storage.getSelfServiceRental(serviceId)
    end

    if cachedRental.expiresAt <= os.time() then
        cachedRental.expiresAt = 0
        cachedRental.paused = false
    end

    return cachedRental
end

local function serialize()
    local rental = getRental()
    local active = rental.expiresAt > os.time()
    local staffOnDuty = Staff.isActive()

    return {
        active = active,
        paused = active and rental.paused or false,
        operational = active and not rental.paused and not staffOnDuty,
        staffOnDuty = staffOnDuty,
        expiresAt = rental.expiresAt,
        remainingSeconds = math.max(0, rental.expiresAt - os.time()),
        dailyPrice = math.max(0, tonumber(settings.dailyPrice) or 0),
        maxRentalDays = math.max(1, tonumber(settings.maxRentalDays) or 30),
        rentedBy = rental.rentedBy,
    }
end

local function sync()
    Staff.syncEvent('rhd_motel:selfservice:stateChanged', serialize())
end

lib.callback.register('rhd_motel:management:rentSelfService', function(source, payload)
    local allowed = Staff.hasPermission(source, 'manageSelfService')
    
    if not allowed then
        return { success = false, message = 'You do not have access to this service.' }
    end
    if mutationPending then
        return { success = false, message = 'The service is being updated. Please wait.' }
    end

    local days = math.floor(tonumber(payload and payload.days) or 0)
    local maxDays = math.max(1, tonumber(settings.maxRentalDays) or 30)
    if days < 1 or days > maxDays then
        return { success = false, message = ('Rental duration must be between 1 and %s days.'):format(maxDays) }
    end

    local amount = days * math.max(0, tonumber(settings.dailyPrice) or 0)
    mutationPending = true

    Inventory:SetLogContext(source, 'money', ('motel-rental:%sd'):format(days))

    local paid = Inventory:RemoveItem(source, 'money', amount)

    if not paid then
        mutationPending = false
        return { success = false, message = 'Insufficient balance for this rental.' }
    end

    local rental = getRental()
    rental.expiresAt = math.max(os.time(), rental.expiresAt) + (days * 86400)
    rental.paused = false
    rental.rentedBy = Staff.getName(source)
    Storage.saveSelfServiceRental(serviceId, rental)
    mutationPending = false
    sync()

    return {
        success = true,
        message = ('Self-service hired for %s day%s.'):format(days, days > 1 and 's' or ''),
        service = serialize(),
    }
end)

lib.callback.register('rhd_motel:management:setSelfServicePaused', function(source, payload)
    local allowed = Staff.hasPermission(source, 'manageSelfService')
    if not allowed then
        return { success = false, message = 'You do not have access to this service.' }
    end
    if mutationPending then
        return { success = false, message = 'The service is being updated. Please wait.' }
    end

    local rental = getRental()
    if rental.expiresAt <= os.time() then
        return { success = false, message = 'There is no active self-service rental.' }
    end

    mutationPending = true
    rental.paused = payload and payload.paused == true
    Storage.saveSelfServiceRental(serviceId, rental)
    mutationPending = false
    sync()

    return {
        success = true,
        message = rental.paused and 'Self-service has been paused.' or 'Self-service has been resumed.',
        service = serialize(),
    }
end)


CreateThread(function()
    while true do
        sync()
        Wait(math.max(5000, tonumber(config.statusRefreshInterval) or 15000))
    end
end)

return {
    getStatus = serialize,
    isOperational = function()
        return serialize().operational
    end,
}
