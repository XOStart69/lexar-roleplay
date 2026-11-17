local config = Config
local limits = config.limits
local appearance = exports.sm_appearance

local PAID_RESUME_DELAY = 1000
local SCISSORS = config.items.scissors
local PREPARE_TIMEOUT = 8000
local SERVICE_REACH = 5.0

---@type table<string, table<number, BarberSession>>
local sessions = {}
---@type table<number, BarberSession>
local byCustomer = {}
---@type table<number, BarberSession>
local byBarber = {}
---@type table<number, table<string, number>>
local cooldowns = {}
local invoiceSequence = 0

---@type table<string, boolean>
local methods = {}

for i = 1, #config.payment.methods do
    methods[config.payment.methods[i]] = true
end

local function notify(source, notifyType, description)
    TriggerClientEvent('ox_lib:notify', source, {
        type = notifyType,
        description = description,
        duration = 4500,
    })
end

---@param message string
---@return BarberActionResult
local function fail(message)
    return { success = false, message = message }
end

local function playerExists(source)
    return DoesPlayerExist(tostring(source))
end

local function cooldown(source, key, ms)
    local now = GetGameTimer()
    local entry = cooldowns[source]

    if not entry then
        entry = {}
        cooldowns[source] = entry
    end

    if (entry[key] or 0) > now then
        return false
    end

    entry[key] = now + ms

    return true
end

---@param source number
---@param chair vector4
---@return boolean
local function nearChair(source, chair)
    local ped = GetPlayerPed(source)

    return ped ~= 0 and #(GetEntityCoords(ped) - chair.xyz) <= SERVICE_REACH
end

---@param shopId string
local function syncChairs(shopId)
    ---@type table<string, BarberChairStatus>
    local occupied = {}

    for index, session in pairs(sessions[shopId] or {}) do
        occupied[tostring(index)] = session.stage == 'waiting' and 'waiting' or 'busy'
    end

    Sync.setChairs(shopId, occupied)
end

---@param shop BarberShop
---@param chair number
---@param customer number
---@param stage BarberStage
---@return BarberSession
local function createSession(shop, chair, customer, stage)
    local list = sessions[shop.id]

    if not list then
        list = {}
        sessions[shop.id] = list
    end

    ---@type BarberSession
    local session = { shop = shop.id, chair = chair, customer = customer, stage = stage, mode = stage == 'self' and 'self' or 'barber' }

    list[chair] = session
    byCustomer[customer] = session
    syncChairs(shop.id)

    return session
end

---@param session BarberSession
local function detachBarber(session)
    if not session.barber then return end

    byBarber[session.barber] = nil
    session.barber = nil
end

---@param session BarberSession
---@param reason string
local function endSession(session, reason)
    if sessions[session.shop][session.chair] ~= session then return end

    sessions[session.shop][session.chair] = nil
    byCustomer[session.customer] = nil
    session.invoice = nil
    syncChairs(session.shop)

    if playerExists(session.customer) then
        TriggerClientEvent('sm_barbershop:session:ended', session.customer, reason)
    end

    if session.barber and playerExists(session.barber) then
        TriggerClientEvent('sm_barbershop:session:ended', session.barber, reason)
    end

    detachBarber(session)
    TriggerEvent('sm_barbershop:internal:sessionEnded', session.shop, session.chair)
end

---@param session BarberSession
---@param message string
local function releaseBarber(session, message)
    local barber = session.barber

    detachBarber(session)
    session.invoice = nil
    session.stage = 'waiting'
    session.original = nil
    session.prices = nil
    syncChairs(session.shop)

    if playerExists(session.customer) then
        TriggerClientEvent('sm_barbershop:customer:revert', session.customer)
        notify(session.customer, 'warning', message)
    end

    if barber and playerExists(barber) then
        TriggerClientEvent('sm_barbershop:session:ended', barber, 'released')
    end
end

---@param source number
---@return table? appearance
---@return string? reason
local function storedAppearance(source)
    if Player(source).state.forcedOutfit then
        return nil, 'Penampilan tidak bisa diubah saat memakai seragam.'
    end

    local stored = appearance:getAppearance(source)

    if type(stored) ~= 'table' or type(stored.hair) ~= 'table' or type(stored.headOverlays) ~= 'table' then
        return nil, 'Data penampilan tidak ditemukan.'
    end

    return stored
end

---@param player table
---@param source number
---@param method string
---@param amount integer
---@param final table
---@param reason string
---@return BarberActionResult
local function chargeAndSave(player, source, method, amount, final, reason)
    if amount > 0 and player.Functions.RemoveMoney(method, amount, reason) ~= true then
        return fail(method == 'cash' and 'Uang tunai tidak cukup.' or 'Saldo bank tidak cukup.')
    end

    if appearance:saveHead(source, Pricing.barberFields(final)) ~= true then
        if amount > 0 then
            player.Functions.AddMoney(method, amount, reason .. '-refund')
        end

        return fail('Penampilan gagal disimpan, uang dikembalikan.')
    end

    return { success = true }
end

---@param value any
---@return string?
local function methodOf(value)
    return type(value) == 'string' and methods[value] and value or nil
end

---@param target number
---@param baseline BarberAppearanceFields
---@return BarberCustomerSnapshot?
local function prepareCustomer(target, baseline)
    local result = promise.new()
    local settled = false

    local function settle(value)
        if settled then return end

        settled = true
        result:resolve(value)
    end

    lib.callback('sm_barbershop:customer:prepare', target, settle, baseline)
    SetTimeout(PREPARE_TIMEOUT, function() settle(false) end)

    return Citizen.Await(result) or nil
end

---@param session BarberSession
local function resumeSelf(session)
    session.stage = 'self'

    if playerExists(session.customer) then
        TriggerClientEvent('sm_barbershop:selfservice:resume', session.customer, Pricing.barberFields(session.original))
    end
end

---@param session BarberSession
local function resumeService(session)
    local customer, barber = session.customer, session.barber

    if not barber or not playerExists(barber) then return end

    session.stage = 'preparing'
    session.invoice = nil

    local snapshot = prepareCustomer(customer, Pricing.barberFields(session.original))

    if byCustomer[customer] ~= session or session.barber ~= barber then return end

    if type(snapshot) ~= 'table' or type(snapshot.appearance) ~= 'table' then
        return releaseBarber(session, 'Pelanggan tidak merespons, layanan dihentikan.')
    end

    session.stage = 'service'

    TriggerClientEvent('sm_barbershop:service:resume', barber, snapshot)
end

---@param session BarberSession
local function resume(session)
    if session.mode == 'self' then
        resumeSelf(session)
    else
        resumeService(session)
    end
end

---@param session BarberSession
---@param cut boolean
local function startCutting(session, cut)
    local customer = session.customer
    local duration = cut and limits.cutDuration or PAID_RESUME_DELAY

    session.stage = 'cutting'
    session.invoice = nil

    if cut then
        TriggerClientEvent('sm_barbershop:session:cutting', customer, duration)

        if session.barber then
            TriggerClientEvent('sm_barbershop:session:cutting', session.barber, duration)
        end
    end

    SetTimeout(duration, function()
        if byCustomer[customer] == session and session.stage == 'cutting' then
            resume(session)
        end
    end)
end

---@param session BarberSession
---@param message string
local function declineInvoice(session, message)
    session.invoice = nil

    if playerExists(session.customer) then
        notify(session.customer, 'warning', message)
    end

    CreateThread(function()
        resumeService(session)
    end)
end

---@param session BarberSession
---@param source number
---@return string?
local function serviceBlocked(session, source)
    if not Wear.slot(source, SCISSORS) then return 'Anda harus membawa gunting cukur yang masih bisa dipakai.' end
    if not Portable.usable(session.shop, session.chair) then return 'Kursi cukur ini sudah habis pakai.' end
end

lib.callback.register('sm_barbershop:chair:sit', function(source, shopId, chairIndex)
    if not cooldown(source, 'chair', 1000) then return fail('Tunggu sebentar.') end

    local shop = Shops.get(shopId)

    if not shop or not Shops.chair(shop, chairIndex) then return fail('Kursi tidak ditemukan.') end
    if byCustomer[source] then return fail('Anda sudah berada di kursi.') end
    if byBarber[source] then return fail('Anda sedang melayani pelanggan.') end
    if not Shops.isOperational(shop) then return fail('Tidak ada barber yang bertugas.') end
    if sessions[shop.id] and sessions[shop.id][chairIndex] then return fail('Kursi sedang dipakai.') end
    if not Portable.usable(shop.id, chairIndex) then return fail('Kursi cukur ini sudah habis pakai.') end

    createSession(shop, chairIndex, source, 'seating')

    return { success = true }
end)

lib.callback.register('sm_barbershop:chair:seated', function(source)
    local session = byCustomer[source]

    if not session or session.stage ~= 'seating' then return false end

    session.stage = 'waiting'
    syncChairs(session.shop)

    return true
end)

lib.callback.register('sm_barbershop:selfservice:start', function(source, shopId, chairIndex)
    if not cooldown(source, 'chair', 1000) then return fail('Tunggu sebentar.') end
    if type(chairIndex) ~= 'number' then return fail('Self service hanya tersedia di kursi toko.') end

    local shop = Shops.get(shopId)

    if not shop or not Shops.chair(shop, chairIndex) then return fail('Kursi tidak ditemukan.') end
    if byCustomer[source] then return fail('Anda sudah berada di kursi.') end
    if not Shops.selfServiceAllowed(shop) then return fail('Barber sedang bertugas, silakan duduk untuk dilayani.') end
    if sessions[shop.id] and sessions[shop.id][chairIndex] then return fail('Kursi sedang dipakai.') end

    local stored, reason = storedAppearance(source)

    if not stored then return fail(reason --[[@as string]]) end

    local session = createSession(shop, chairIndex, source, 'self')

    session.original = stored
    session.prices = Shops.priceList(shop, 'self')

    SetTimeout(limits.selfServiceTimeout * 1000, function()
        if byCustomer[source] == session and session.stage == 'self' then
            endSession(session, 'timeout')
        end
    end)

    return {
        success = true,
        chair = shop.chairs[chairIndex],
        prices = session.prices,
        appearance = Pricing.barberFields(stored),
        shopLabel = shop.label,
        customerName = Staff.nameOf(Staff.getPlayer(source)),
    }
end)

lib.callback.register('sm_barbershop:selfservice:pay', function(source, values, method)
    local session = byCustomer[source]

    if not session or session.stage ~= 'self' or not session.original then
        return fail('Sesi self service tidak ditemukan.')
    end

    method = methodOf(method)

    if not method then return fail('Metode pembayaran tidak valid.') end

    local final, items, total = Pricing.apply(session.original, Pricing.sanitize(values), session.prices)

    if #items == 0 then return fail('Belum ada perubahan yang dibayar.') end

    local shop = Shops.get(session.shop)
    local player = Staff.getPlayer(source)

    if not shop or not player then return fail('Data pemain tidak ditemukan.') end

    session.stage = 'paying'

    local result = chargeAndSave(player, source, method, total, final, 'barbershop-selfservice')

    if byCustomer[source] ~= session then return fail('Sesi self service sudah berakhir.') end

    if not result.success then
        session.stage = 'self'

        return result
    end

    local citizenId = Staff.citizenIdOf(player)
    local name = Staff.nameOf(player)

    if Shops.isOwned(shop) and total > 0 then
        Shops.addBalance(shop, total)
        Storage.addTransaction({
            shopId = shop.id,
            type = 'service',
            amount = total,
            balanceAfter = shop.balance,
            actorCitizenId = citizenId,
            actorName = name,
            note = ('Self service · %d item'):format(#items),
        })
    end

    Storage.addService({
        shopId = shop.id,
        mode = 'self',
        customerCitizenId = citizenId,
        customerName = name,
        amount = total,
        items = Pricing.describe(items),
    })

    TriggerEvent('sm_barbershop:internal:serviceRecorded', shop.id)
    session.original = final
    startCutting(session, Pricing.needsCut(items))

    return { success = true }
end)

lib.callback.register('sm_barbershop:chair:leave', function(source)
    local session = byCustomer[source]

    if not session then return true end

    if session.stage == 'cutting' or session.stage == 'paying' then
        return false
    end

    local barber = session.barber

    endSession(session, 'left')

    if barber and playerExists(barber) then
        notify(barber, 'warning', 'Pelanggan meninggalkan kursi.')
    end

    return true
end)

lib.callback.register('sm_barbershop:service:start', function(source, shopId, chairIndex)
    if not cooldown(source, 'service', 1000) then return fail('Tunggu sebentar.') end

    local shop = Shops.get(shopId)
    local chair = shop and Shops.chair(shop, chairIndex)

    if not shop or not chair then return fail('Kursi tidak ditemukan.') end

    local session = sessions[shop.id] and sessions[shop.id][chairIndex]

    if not session or session.stage ~= 'waiting' then
        return fail('Tidak ada pelanggan yang menunggu di kursi ini.')
    end

    if byBarber[source] or byCustomer[source] then
        return fail('Anda sedang dalam sesi lain.')
    end

    if not Staff.isOnDuty(source, shop.id) then
        return fail('Anda tidak bertugas di barbershop ini.')
    end

    if not nearChair(source, chair) then
        return fail('Anda terlalu jauh dari kursi.')
    end

    local blocked = serviceBlocked(session, source)

    if blocked then return fail(blocked) end

    local customerId = session.customer
    local customer = Staff.getPlayer(customerId)
    local barber = Staff.getPlayer(source)

    if not customer or not barber then
        return fail('Data pemain tidak ditemukan.')
    end

    local stored, reason = storedAppearance(customerId)

    if not stored then return fail(reason --[[@as string]]) end

    session.stage = 'preparing'
    session.barber = source
    byBarber[source] = session
    syncChairs(shop.id)

    local snapshot = prepareCustomer(customerId, Pricing.barberFields(stored))

    if byCustomer[customerId] ~= session or session.barber ~= source then
        return fail('Pelanggan sudah meninggalkan kursi.')
    end

    if type(snapshot) ~= 'table' or type(snapshot.appearance) ~= 'table' then
        detachBarber(session)
        session.stage = 'waiting'
        syncChairs(shop.id)

        return fail('Pelanggan tidak merespons.')
    end

    session.stage = 'service'
    session.original = stored
    session.prices = Shops.priceList(shop, 'barber')

    return {
        success = true,
        customerId = customerId,
        customerName = Staff.nameOf(customer),
        shopLabel = shop.label,
        prices = session.prices,
        snapshot = snapshot,
    }
end)

RegisterNetEvent('sm_barbershop:service:preview', function(values)
    local source = source
    local session = byBarber[source]

    if not session or session.stage ~= 'service' then return end

    local clean = Pricing.sanitizePreview(values)

    if clean then
        TriggerClientEvent('sm_barbershop:customer:applyPreview', session.customer, clean)
    end
end)

RegisterNetEvent('sm_barbershop:service:ready', function()
    local source = source
    local session = byBarber[source]

    if not session or session.stage ~= 'service' then return end

    local shop = Shops.get(session.shop)

    TriggerClientEvent('sm_barbershop:customer:serviceStarted', session.customer, Staff.nameOf(Staff.getPlayer(source)), shop and shop.label or '', session.prices)
end)

RegisterNetEvent('sm_barbershop:service:hat', function(hidden)
    local source = source
    local session = byBarber[source]

    if not session or session.stage ~= 'service' then return end

    TriggerClientEvent('sm_barbershop:customer:hat', session.customer, hidden == true)
end)

lib.callback.register('sm_barbershop:service:cancel', function(source)
    local session = byBarber[source]

    if not session or session.stage ~= 'service' then return false end

    releaseBarber(session, 'Barber membatalkan layanan.')

    return true
end)

lib.callback.register('sm_barbershop:service:finish', function(source, values)
    local session = byBarber[source]

    if not session or session.stage ~= 'service' or not session.original then
        return fail('Sesi layanan tidak ditemukan.')
    end

    local shop = Shops.get(session.shop)
    local barber = Staff.getPlayer(source)

    if not shop or not barber then
        return fail('Data tidak ditemukan.')
    end

    local final, items, total = Pricing.apply(session.original, Pricing.sanitize(values), session.prices)

    if #items == 0 then return fail('Belum ada perubahan untuk ditagih.') end

    local blocked = serviceBlocked(session, source)

    if blocked then return fail(blocked) end

    invoiceSequence += 1

    local invoiceId = ('barber-%s-%s'):format(os.time(), invoiceSequence)
    local timeout = limits.invoiceTimeout

    session.stage = 'invoice'
    session.invoice = {
        id = invoiceId,
        amount = total,
        items = items,
        final = final,
        expiresAt = os.time() + timeout,
    }

    TriggerClientEvent('sm_barbershop:customer:invoice', session.customer, {
        id = invoiceId,
        amount = total,
        items = Pricing.describe(items),
        methods = config.payment.methods,
        shopLabel = shop.label,
        barberName = Staff.nameOf(barber),
        expiresAt = session.invoice.expiresAt,
        timeout = timeout,
    })

    SetTimeout(timeout * 1000, function()
        if byCustomer[session.customer] ~= session then return end
        if session.stage ~= 'invoice' or not session.invoice or session.invoice.id ~= invoiceId then return end

        if session.barber and playerExists(session.barber) then
            notify(session.barber, 'warning', 'Pelanggan tidak merespons tagihan.')
        end

        declineInvoice(session, 'Tagihan kedaluwarsa, penampilan dikembalikan.')
    end)

    return { success = true }
end)

lib.callback.register('sm_barbershop:invoice:pay', function(source, invoiceId, method)
    local session = byCustomer[source]
    local invoice = session and session.invoice

    if not session or session.stage ~= 'invoice' or not invoice or invoice.id ~= invoiceId then
        return fail('Tagihan tidak ditemukan.')
    end

    if os.time() >= invoice.expiresAt then
        declineInvoice(session, 'Tagihan kedaluwarsa, penampilan dikembalikan.')

        return fail('Tagihan sudah kedaluwarsa.')
    end

    method = methodOf(method)

    if not method then return fail('Metode pembayaran tidak valid.') end

    local shop = Shops.get(session.shop)
    local customer = Staff.getPlayer(source)
    local barber = session.barber and Staff.getPlayer(session.barber)

    if not shop or not customer or not barber then
        return fail('Barber tidak tersedia.')
    end

    session.stage = 'paying'

    local amount = invoice.amount
    local result = chargeAndSave(customer, source, method, amount, invoice.final, 'barbershop-service')

    if byCustomer[source] ~= session then return fail('Sesi sudah berakhir.') end

    if not result.success then
        session.stage = 'invoice'

        return result
    end

    local barberCitizenId = Staff.citizenIdOf(barber)
    local barberName = Staff.nameOf(barber)
    local customerName = Staff.nameOf(customer)
    local commission = 0

    if shop.ownerCitizenId ~= barberCitizenId then
        commission = math.floor(amount * shop.commissionRate / 100)

        if commission > 0 then
            barber.Functions.AddMoney('bank', commission, 'barbershop-commission')
        end
    end

    local net = amount - commission

    Shops.addBalance(shop, net)
    Storage.addTransaction({
        shopId = shop.id,
        type = 'service',
        amount = net,
        balanceAfter = shop.balance,
        actorCitizenId = barberCitizenId,
        actorName = barberName,
        note = ('Layanan untuk %s · %d item'):format(customerName, #invoice.items),
    })

    if commission > 0 then
        Storage.addTransaction({
            shopId = shop.id,
            type = 'commission',
            amount = commission,
            balanceAfter = shop.balance,
            actorCitizenId = barberCitizenId,
            actorName = barberName,
            note = ('Komisi layanan untuk %s'):format(customerName),
        })
    end

    Storage.addService({
        shopId = shop.id,
        mode = 'barber',
        customerCitizenId = Staff.citizenIdOf(customer),
        customerName = customerName,
        employeeCitizenId = barberCitizenId,
        employeeName = barberName,
        amount = amount,
        commission = commission,
        items = Pricing.describe(invoice.items),
    })

    TriggerEvent('sm_barbershop:internal:serviceRecorded', shop.id)

    if commission > 0 then
        notify(session.barber, 'success', ('Komisi $%s masuk ke rekening bank.'):format(commission))
    end

    session.original = invoice.final

    local scissorsLeft = Wear.consume(session.barber, SCISSORS)
    local chairLeft = Portable.consume(session.shop, session.chair)

    if scissorsLeft then
        notify(session.barber, scissorsLeft > 0 and 'inform' or 'warning',
            scissorsLeft > 0 and ('Sisa pemakaian gunting cukur: %d.'):format(scissorsLeft) or 'Gunting cukur Anda sudah habis pakai.')
    end

    if chairLeft then
        notify(session.barber, chairLeft > 0 and 'inform' or 'warning',
            chairLeft > 0 and ('Sisa pemakaian kursi cukur: %d.'):format(chairLeft) or 'Kursi cukur sudah habis pakai, akan dibereskan setelah pelanggan berdiri.')
    end

    startCutting(session, Pricing.needsCut(invoice.items))

    return { success = true }
end)

lib.callback.register('sm_barbershop:invoice:decline', function(source, invoiceId)
    local session = byCustomer[source]

    if not session or session.stage ~= 'invoice' or not session.invoice or session.invoice.id ~= invoiceId then
        return false
    end

    if session.barber and playerExists(session.barber) then
        notify(session.barber, 'warning', 'Pelanggan menolak tagihan.')
    end

    declineInvoice(session, 'Tagihan ditolak, penampilan dikembalikan.')

    return true
end)

AddEventHandler('sm_barbershop:internal:chairRemoved', function(shopId, index)
    local session = sessions[shopId] and sessions[shopId][index]

    if session then
        endSession(session, 'chair_removed')
    end
end)

AddEventHandler('sm_barbershop:internal:ready', function()
    for i = 1, #Shops.list do
        syncChairs(Shops.list[i].id)
    end
end)

AddEventHandler('playerDropped', function()
    local source = source

    cooldowns[source] = nil

    local customerSession = byCustomer[source]

    if customerSession then
        local barber = customerSession.barber

        endSession(customerSession, 'customer_left')

        if barber and playerExists(barber) then
            notify(barber, 'warning', 'Pelanggan terputus dari server.')
        end
    end

    local barberSession = byBarber[source]

    if barberSession then
        releaseBarber(barberSession, 'Barber terputus, silakan menunggu barber lain.')
    end
end)
