local activePlayers = {}
local pendingClaims = {}
local config = require 'casino.luckywheel.config'
local storage = require 'modules.storage'

math.randomseed(os.time() + GetGameTimer())

local function getPrizeChanceTotal()
    local total = 0.0
    for i = 1, #config.Prizes do
        total += math.max(tonumber(config.Prizes[i].chance) or 0, 0)
    end
    return total
end

local function getMachineStorageId()
    local pos = config.WheelPos
    return ('__luckywheel_machine:%s:%s:%s'):format(
        math.floor((pos.x or 0) * 100),
        math.floor((pos.y or 0) * 100),
        math.floor((pos.z or 0) * 100)
    )
end

local prizeChanceTotal = getPrizeChanceTotal()
if math.abs(prizeChanceTotal - 100.0) > 0.001 then
    lib.print.warn(('[Lucky Wheel] Total prize chance is %.2f, expected 100.00. Chances will be normalized by total weight.'):format(prizeChanceTotal))
end

---@param prize table?
---@return boolean
local function isVehiclePrize(prize)
    if type(prize) ~= 'table' then return false end
    if prize.type == 'vehicle' then return true end

    local cooldownConfig = config.VehiclePrizeCooldown or {}
    local names = cooldownConfig.prizeNames or {}
    return names[prize.name] == true
end

---@return boolean
local function isVehiclePrizeOnCooldown()
    local cooldownConfig = config.VehiclePrizeCooldown or {}
    if not cooldownConfig.enabled then return false end

    local last = storage.getLuckyWheelTimestamp(getMachineStorageId(), 'vehicle_prize')
    if not last then return false end

    local cooldownSecs = math.max(tonumber(cooldownConfig.hours) or 0, 0) * 3600
    return cooldownSecs > 0 and (os.time() - last) < cooldownSecs
end

local function markVehiclePrizeWon()
    local cooldownConfig = config.VehiclePrizeCooldown or {}
    if not cooldownConfig.enabled then return end

    storage.setLuckyWheelTimestamp(getMachineStorageId(), 'vehicle_prize', os.time())
end

---Generates a unique vehicle plate that does not conflict with existing DB records.
---@return string|nil
local function generatePlate()
    for _ = 1, 30 do
        local plate = 'LW ' .. math.random(1000, 9999)
        if not storage.vehiclePlateExists(plate) then
            return plate
        end
    end

    return nil
end

---@param source number
---@return boolean
local function hasFreeSpin(source)
    if not config.FreeSpin.enabled then return false end
    local id = shared.getIdentifier(source)
    if not id then return false end
    local last = storage.getLuckyWheelTimestamp(id, 'free')
    if not last then return true end
    local cooldownSecs = config.FreeSpin.cooldownHours * 3600
    return (os.time() - last) >= cooldownSecs
end

---@param source number
---@return number seconds remaining, 0 if not on cooldown
local function freeSpinCooldownLeft(source)
    if not config.FreeSpin.enabled then return 0 end
    local id = shared.getIdentifier(source)
    if not id then return 0 end
    local last = storage.getLuckyWheelTimestamp(id, 'free')
    if not last then return 0 end
    local cooldownSecs = config.FreeSpin.cooldownHours * 3600
    local elapsed = os.time() - last
    if elapsed >= cooldownSecs then return 0 end
    return cooldownSecs - elapsed
end

---Checks if the player has already used their daily spin today.
---@param source number
---@return boolean true jika masih bisa spin hari ini
local function hasDailySpinLeft(source)
    if not config.DailySpin.enabled then return true end
    local id = shared.getIdentifier(source)
    if not id then return false end
    local last = storage.getLuckyWheelTimestamp(id, 'daily')
    if not last then return true end
    return (os.time() - last) >= 86400
end

---Records that the player has used their daily spin.
---@param source number
local function markDailySpin(source)
    local id = shared.getIdentifier(source)
    if not id then return end
    storage.setLuckyWheelTimestamp(id, 'daily', os.time())
end

---Returns seconds remaining before daily spin resets, 0 if available.
---@param source number
---@return number
local function dailySpinCooldownLeft(source)
    if not config.DailySpin.enabled then return 0 end
    local id = shared.getIdentifier(source)
    if not id then return 0 end
    local last = storage.getLuckyWheelTimestamp(id, 'daily')
    if not last then return 0 end
    local elapsed = os.time() - last
    if elapsed >= 86400 then return 0 end
    return 86400 - elapsed
end

---@param source number
---@return boolean
local function isNearWheel(source)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return false end
    local pos = GetEntityCoords(ped)
    local wheelPos = config.WheelPos
    local dist = #(vector3(pos.x, pos.y, pos.z) - vector3(wheelPos.x, wheelPos.y, wheelPos.z))
    return dist <= config.MaxDistance
end

---@param prize table
---@param isVip boolean
---@return number
local function prizeWeight(prize, isVip)
    return math.max(tonumber(isVip and prize.vipChance or prize.chance) or 0, 0)
end

---Rolls a weighted random prize from config.Prizes.
---@param isVip boolean
---@return integer prizeIndex
---@return table prize
local function rollPrize(isVip)
    local vehicleOnCooldown = isVehiclePrizeOnCooldown()
    local total = 0.0
    for i = 1, #config.Prizes do
        local prize = config.Prizes[i]
        if not (vehicleOnCooldown and isVehiclePrize(prize)) then
            total += prizeWeight(prize, isVip)
        end
    end

    if total <= 0 and vehicleOnCooldown then
        total = prizeChanceTotal
        vehicleOnCooldown = false
    end

    if total <= 0 then
        return #config.Prizes, config.Prizes[#config.Prizes]
    end

    local rnd = math.random() * total
    local cumulative = 0.0
    for k = 1, #config.Prizes do
        local prize = config.Prizes[k]
        if not (vehicleOnCooldown and isVehiclePrize(prize)) then
            cumulative += prizeWeight(prize, isVip)
            if rnd <= cumulative then
                return k, prize
            end
        end
    end
    return #config.Prizes, config.Prizes[#config.Prizes]
end

---@return integer?
local function pickZonkIndex()
    local zonks = {}
    for i = 1, #config.Prizes do
        if config.Prizes[i].type == 'zonk' then
            zonks[#zonks + 1] = i
        end
    end
    if #zonks == 0 then return nil end
    return zonks[math.random(1, #zonks)]
end

---@param source number
---@return boolean
local function canAffordSpin(source)
    local cash = ox_inventory:GetItemCount(source, shared.chipItemName)
    return cash >= config.SpinPrice
end

---Inserts a vehicle prize into the database for the player.
---@param source number
---@return boolean success
local function giveVehiclePrize(source)
    local plate = generatePlate()
    if not plate then
        lib.print.error('Lucky Wheel: gagal membuat plate unik, hadiah kendaraan dibatalkan')
        return false
    end

    local playerdata = sm_core:GetPlayerData(source)
    if not playerdata then return false end
    local license = playerdata.license
    local citizenid = playerdata.citizenid
    local props = {
        model = joaat(config.Vehicle.model),
        fuelLevel = 100.0,
        bodyHealth = 1000.0,
        engineHealth = 1000.0,
        plate = plate,
    }
    local veh_color = config.Vehicle.color
    if veh_color?.primary then
        local rgb = lib.math.tovector(veh_color.primary)
        props.color1 = {rgb.x, rgb.y, rgb.z}
    end
    if veh_color?.secondary then
        local rgb = lib.math.tovector(veh_color.secondary)
        props.color2 = {rgb.x, rgb.y, rgb.z}
    end
    return storage.insertVehiclePrize({
        license = license,
        citizenid = citizenid,
        model = config.Vehicle.model,
        hash = joaat(config.Vehicle.model),
        mods = json.encode(props),
        plate = plate,
        garage = config.Vehicle.default_garage,
        state = 1
    })
end

lib.callback.register('rhd_casino_luckywheel:callback:canSpin', function(source)
    if not isNearWheel(source) then
        lib.notify(source, {
            id = 'lw_far',
            title = 'Lucky Wheel',
            description = 'Kamu terlalu jauh dari roda!',
            type = 'error',
        })
        return { allowed = false }
    end
    if next(activePlayers) ~= nil then
        lib.notify(source, {
            id = 'lw_busy',
            title = 'Lucky Wheel',
            description = 'Roda sedang digunakan, tunggu sebentar.',
            type = 'error',
        })
        return { allowed = false }
    end
    if not hasDailySpinLeft(source) then
        local remaining = dailySpinCooldownLeft(source)
        local hours = math.floor(remaining / 3600)
        local mins = math.floor((remaining % 3600) / 60)
        lib.notify(source, {
            id = 'lw_daily_limit',
            title = 'Lucky Wheel',
            description = ('Kamu sudah spin hari ini! Kembali dalam %dj %dm.'):format(hours, mins),
            type = 'error',
        })
        return { allowed = false, dailyLimitReached = true, cooldownLeft = remaining }
    end
    local isFree = hasFreeSpin(source)
    local cooldownLeft = freeSpinCooldownLeft(source)
    return {
        allowed = true,
        freeSpin = isFree,
        cooldownLeft = cooldownLeft,
        spinPrice = config.SpinPrice,
    }
end)

lib.callback.register('rhd_casino_luckywheel:callback:startSpin', function(source)
    if not isNearWheel(source) then return false end
    if activePlayers[source] then return false end
    if next(activePlayers) ~= nil then return false end
    if not hasDailySpinLeft(source) then return false end
    local isFree = hasFreeSpin(source)
    if not isFree then
        if not canAffordSpin(source) then
            lib.notify(source, {
                id = 'lw_nomoney',
                title = 'Lucky Wheel',
                description = ('Kamu butuh $%s untuk spin!'):format(config.SpinPrice),
                type = 'error',
            })
            return false
        end
        if not ox_inventory:RemoveItem(source, shared.chipItemName, config.SpinPrice) then
            return false
        end
        shared.depositCasinoIncome(config.SpinPrice, 'luckywheel_spin')
    end
    activePlayers[source] = true
    local prizeIndex, prize = rollPrize(shared.checkVIP(source))
    if prize.type ~= 'zonk' and not shared.rollDifficulty(config.Difficulty) then
        local zonkIndex = pickZonkIndex()
        if zonkIndex then
            prizeIndex = zonkIndex
            prize = config.Prizes[zonkIndex]
        end
    end
    pendingClaims[source] = {
        prizeIndex = prizeIndex,
        prize = prize,
        timestamp = os.time(),
        isFree = isFree,
        claiming = false,
    }
    if isFree and config.FreeSpin.enabled then
        local id = shared.getIdentifier(source)
        if id then
            storage.setLuckyWheelTimestamp(id, 'free', os.time())
        end
    end
    markDailySpin(source)
    local jitter = math.random(-3, 3)
    BroadcastCasinoPlayers('rhd_casino_luckywheel:client:spinWheel', source, prizeIndex, jitter)
    return true
end)

lib.callback.register('rhd_casino_luckywheel:callback:claimPrize', function(source)
    local claim = pendingClaims[source]
    if not claim then
        lib.notify(source, {
            id = 'lw_noclaim',
            title = 'Lucky Wheel',
            description = 'Tidak ada hadiah yang bisa diklaim.',
            type = 'error',
        })
        activePlayers[source] = nil
        return false
    end
    if claim.claiming then return false end

    claim.claiming = true

    if (os.time() - claim.timestamp) > 90 then
        lib.notify(source, {
            id = 'lw_timeout',
            title = 'Lucky Wheel',
            description = 'Waktu klaim hadiah habis.',
            type = 'error',
        })
        pendingClaims[source] = nil
        activePlayers[source] = nil
        return false
    end
    CreateThread(function ()
        local lastWheelAngle = ((claim.prizeIndex - 1) * 18 + (config.WheelOffset or 0)) % 360
        BroadcastCasinoPlayers('rhd_casino_luckywheel:client:syncAngle', lastWheelAngle)
    end)
    local prize = claim.prize
    local delivered = false

    if prize.type == 'money' then
        local paid = shared.payCasinoMoneyPrize(source, prize.count, 'luckywheel_money')
        if not paid then
            lib.notify(source, {
                id = 'lw_win_money_failed',
                title = 'Lucky Wheel',
                description = 'Selamat! Kamu menang uang, namun rekening casino gagal membayar hadiah. Hubungi staff.',
                duration = 12000,
                type = 'warning',
            })
            claim.claiming = false
            return false
        end
        delivered = true
        lib.notify(source, {
            id = 'lw_win_money',
            title = 'Lucky Wheel',
            description = ('Selamat! Kamu menang $%s!'):format(prize.count),
            duration = 12000,
            type = 'success',
        })
    elseif prize.type == 'item' then
        local added
        if prize.name == shared.chipItemName then
            added = shared.payCasinoChipPrize(source, prize.count, 'luckywheel')
        else
            added = ox_inventory:AddItem(source, prize.name, prize.count)
        end
        if not added then
            lib.notify(source, {
                id = 'lw_win_item_failed',
                title = 'Lucky Wheel',
                description = 'Selamat! Kamu menang hadiah, namun rekening casino gagal membayar hadiah. Hubungi staff.',
                duration = 12000,
                type = 'warning',
            })
            claim.claiming = false
            return false
        end
        delivered = true
        if isVehiclePrize(prize) then
            markVehiclePrizeWon()
        end
        lib.notify(source, {
            id = 'lw_win_item',
            title = 'Lucky Wheel',
            description = ('Selamat! Kamu menang %s x%s!'):format(prize.label or prize.name, prize.count),
            duration = 12000,
            type = 'success',
        })
    elseif prize.type == 'vehicle' then
        local success = giveVehiclePrize(source)
        if not success then
            lib.notify(source, {
                id = 'lw_win_vehicle_failed',
                title = 'Lucky Wheel',
                description = 'Selamat! Kamu menang kendaraan! Namun terjadi kesalahan saat memberikan hadiah, silakan hubungi staff.',
                duration = 12000,
                type = 'warning',
            })
            claim.claiming = false
            return false
        end
        delivered = true
        markVehiclePrizeWon()
        lib.notify(source, {
            id = 'lw_win_vehicle',
            title = 'Lucky Wheel',
            description = 'Selamat! Kamu menang kendaraan!',
            duration = 12000,
            type = 'success',
        })
    elseif prize.type == 'zonk' then
        delivered = true
        lib.notify(source, {
            id = 'lw_zonk',
            title = 'Lucky Wheel',
            description = 'Zonk! Lebih beruntung lain kali.',
            duration = 12000,
            type = 'error',
        })
    end

    if delivered then
        pendingClaims[source] = nil
        activePlayers[source] = nil
        return true
    end

    claim.claiming = false
    return false
end)

AddEventHandler('playerDropped', function()
    local src = source
    pendingClaims[src] = nil
    activePlayers[src] = nil
end)

AddEventHandler('rhd_casino:releasePlayer', function(playerId)
    pendingClaims[playerId] = nil
    activePlayers[playerId] = nil
end)
