local Config = localmodule 'config'

local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = QBCore.Functions.GetPlayerData()
local isMenuOpen = false
local billingUiOpen = false
local incomingFocused = false
local companyLogsOpen = false
local tabletProp = nil

interface.init(false)
local frameMounted = false
local frameReady = false
local frameGen = 0
local openSenders = {}
local pendingOneShots = {}

local function anyBillingOpen()
    return billingUiOpen or incomingFocused or companyLogsOpen
end

local function openSurface(key, sender)
    frameGen = frameGen + 1
    openSenders[key] = sender
    if not frameMounted then
        frameReady = false
        interface.show()
        frameMounted = true
    elseif frameReady then
        sender()
    end
end

local function sendOnce(sender)
    frameGen = frameGen + 1
    if not frameMounted then
        frameReady = false
        interface.show()
        frameMounted = true
        pendingOneShots[#pendingOneShots + 1] = sender
    elseif frameReady then
        sender()
    else
        pendingOneShots[#pendingOneShots + 1] = sender
    end
end

local function closeSurface(key)
    openSenders[key] = nil
    if not frameMounted or anyBillingOpen() then return end
    local gen = frameGen
    SetTimeout(50, function()
        if gen == frameGen and frameMounted and not anyBillingOpen() then
            interface.hide()
            frameMounted = false
            frameReady = false
        end
    end)
end

interface.callback('billingReady', function(_, cb)
    cb('ok')
    frameReady = true
    for _, sender in pairs(openSenders) do
        sender()
    end
    local shots = pendingOneShots
    pendingOneShots = {}
    for i = 1, #shots do
        shots[i]()
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    SetupCompanyLogTargets()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerData.job = JobInfo
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(data)
    PlayerData = data
    if frameReady and (billingUiOpen or incomingFocused) and PlayerData.money then
        interface.send({
            action = 'billingUpdateBalance',
            data = { cash = PlayerData.money.cash or 0, bank = PlayerData.money.bank or 0 }
        })
    end
end)

function CanCreateInvoice()
    if not PlayerData.job then return false end
    for _, allowedJob in ipairs(Config.AllowedJobsCreateInvoice) do
        if PlayerData.job.name == allowedJob then return true end
    end
    return false
end

function SetupCompanyLogTargets()
    if not Config.CompanyLogs then return end

    for jobName, config in pairs(Config.CompanyLogs) do
        if config.enabled and config.locations then
            for i, location in ipairs(config.locations) do
                exports['ox_target']:addBoxZone({
                    coords = location.coords,
                    size = vec3(1.5, 1.5, 2.0),
                    rotation = location.heading,
                    options = {
                        {
                            name = jobName .. "_company_log_" .. i,
                            event = "xx-billing:client:OpenCompanyLogs",
                            icon = "fas fa-chart-line",
                            label = location.label,
                            jobs = jobName,
                            canInteract = function()
                                return PlayerData.job and PlayerData.job.name == jobName and PlayerData.job.grade.level >= config.minGrade
                            end,
                        },
                    },
                    distance = location.distance,
                })
            end
        end
    end
end

RegisterNetEvent('xx-billing:client:OpenCompanyLogs', function()
    if not PlayerData.job then return end

    local jobName = PlayerData.job.name
    local jobConfig = Config.CompanyLogs[jobName]

    if not jobConfig or not jobConfig.enabled then
        lib.notify({title = 'Error', description = 'Company logs tidak tersedia untuk job Anda', type = 'error'})
        return
    end

    if PlayerData.job.grade.level < jobConfig.minGrade then
        lib.notify({title = 'Access Denied', description = 'Anda tidak memiliki akses ke company logs', type = 'error'})
        return
    end

    companyLogsOpen = true
    local fname = PlayerData.charinfo.firstname .. ' ' .. PlayerData.charinfo.lastname
    local grade = PlayerData.job.grade.name
    openSurface('companyLogs', function()
        interface.send({
            action = 'openCompanyLogs',
            jobName = jobName,
            playerName = fname,
            grade = grade
        })
    end)
    interface.focus(true, true)
end)

interface.callback('closeCompanyLogs', function(_, cb)
    cb('ok')
    companyLogsOpen = false
    interface.focus(false, false)
    closeSurface('companyLogs')
end)

interface.callback('getCompanyData', function(data, cb)
    local filters = {}
    if data.filters and type(data.filters) == 'table' then
        if data.filters.search then filters.search = tostring(data.filters.search) end
        if data.filters.status then filters.status = tostring(data.filters.status) end
        if data.filters.dateFrom then filters.dateFrom = tostring(data.filters.dateFrom) end
        if data.filters.dateTo then filters.dateTo = tostring(data.filters.dateTo) end
        if data.filters.employee then filters.employee = tostring(data.filters.employee) end
        if data.filters.period then filters.period = tostring(data.filters.period) end
        if data.filters.type then filters.type = tostring(data.filters.type) end
    end

    local result = lib.callback.await('xx-billing:server:GetCompanyData', false, data.jobName, filters, data.page or 1, data.limit or 20)
    cb(result)
end)

interface.callback('getInvoiceDetails', function(data, cb)
    local result = lib.callback.await('xx-billing:server:GetInvoiceDetails', false, data.invoiceId)
    cb(result)
end)

function FormatMoneyClient(amount)
    if not amount then return "$0" end
    local num = tonumber(amount)
    if not num then return "$0" end

    local formatted = ""
    local str = tostring(math.floor(num))
    local len = string.len(str)

    for i = len, 1, -1 do
        formatted = string.sub(str, i, i) .. formatted
        if (len - i + 1) % 3 == 0 and i > 1 then
            formatted = "." .. formatted
        end
    end

    return "$" .. formatted
end

function PlayBillingAnimation()
    local playerPed = PlayerPedId()

    if tabletProp and DoesEntityExist(tabletProp) then
        DeleteEntity(tabletProp)
        tabletProp = nil
    end

    RequestAnimDict("amb@code_human_in_bus_passenger_idles@female@tablet@idle_a")
    while not HasAnimDictLoaded("amb@code_human_in_bus_passenger_idles@female@tablet@idle_a") do Wait(100) end

    RequestModel("prop_cs_tablet")
    while not HasModelLoaded("prop_cs_tablet") do Wait(100) end

    local coords = GetEntityCoords(playerPed)
    tabletProp = CreateObject(GetHashKey("prop_cs_tablet"), coords.x, coords.y, coords.z, true, true, false)
    SetEntityAsMissionEntity(tabletProp, true, true)
    AttachEntityToEntity(tabletProp, playerPed, GetPedBoneIndex(playerPed, 28422), -0.05, 0.0, 0.0, 0.0, -90.0, 0.0, true, true, false, true, 1, true)

    TaskPlayAnim(playerPed, "amb@code_human_in_bus_passenger_idles@female@tablet@idle_a", "idle_a", 3.0, 3.0, -1, 49, 0, false, false, false)
    isMenuOpen = true
end

function StopBillingAnimation()
    local playerPed = PlayerPedId()

    ClearPedTasks(playerPed)
    StopAnimTask(playerPed, "amb@code_human_in_bus_passenger_idles@female@tablet@idle_a", "idle_a", 1.0)

    if tabletProp then
        if DoesEntityExist(tabletProp) then
            DetachEntity(tabletProp, true, true)
            DeleteEntity(tabletProp)
            DeleteObject(tabletProp)
        end
        tabletProp = nil
    end

    isMenuOpen = false
    RemoveAnimDict("amb@code_human_in_bus_passenger_idles@female@tablet@idle_a")
    SetModelAsNoLongerNeeded("prop_cs_tablet")
end

function GetNearbyPlayers()
    local players = {}
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    local nearbyPlayers = {}
    for _, player in pairs(GetActivePlayers()) do
        if player ~= PlayerId() then
            local targetPed = GetPlayerPed(player)
            local distance = #(playerCoords - GetEntityCoords(targetPed))
            if distance <= 10.0 then
                table.insert(nearbyPlayers, GetPlayerServerId(player))
            end
        end
    end

    if #nearbyPlayers == 0 then return players end

    local playerData = lib.callback.await('xx-billing:server:GetPlayersData', false, nearbyPlayers)
    if playerData then
        for _, data in pairs(playerData) do
            table.insert(players, {value = data.citizenid, label = 'Warga (ID: ' .. data.source .. ')'})
        end
    end

    return players
end

local function BuildBillingContext()
    local jobName = PlayerData.job and PlayerData.job.name or 'unemployed'
    local jobLabel = PlayerData.job and PlayerData.job.label or jobName
    local dueDays = Config.AutoCollectionDays[jobName] or Config.AutoCollectionDays['default'] or 7

    local presetItems = {}
    for _, item in ipairs(Config.PresetItems[jobName] or {}) do
        presetItems[#presetItems + 1] = {
            label = item.label,
            description = item.description or '',
            price = item.price
        }
    end

    return {
        jobName = jobName,
        jobLabel = jobLabel,
        playerName = PlayerData.charinfo.firstname .. ' ' .. PlayerData.charinfo.lastname,
        grade = PlayerData.job and PlayerData.job.grade.name or '',
        canCreateInvoice = CanCreateInvoice(),
        cash = PlayerData.money and PlayerData.money.cash or 0,
        bank = PlayerData.money and PlayerData.money.bank or 0,
        dueDateLabel = dueDays .. ' hari dari sekarang',
        presetItems = presetItems,
        minAmount = Config.MinInvoiceAmount,
        maxAmount = Config.MaxInvoiceAmount
    }
end

local function CloseBillingUi()
    if not billingUiOpen then return end
    billingUiOpen = false
    interface.focus(false, false)
    if not incomingFocused then StopBillingAnimation() end
    closeSurface('billingMenu')
end

RegisterCommand(Config.Command, function()
    OpenBillingMenu()
end)

RegisterKeyMapping(Config.Command, 'Buka menu billing', 'keyboard', 'F7')

function OpenBillingMenu()
    PlayerData = QBCore.Functions.GetPlayerData()
    if PlayerData.metadata['isdead'] or PlayerData.metadata['inlaststand'] then
        lib.notify({title = 'Error', description = 'Tidak bisa membuka billing saat ini.', type = 'error'})
        return
    end

    if billingUiOpen then return end

    billingUiOpen = true
    frameGen = frameGen + 1

    PlayBillingAnimation()
    Wait(100)

    if not billingUiOpen then return end

    openSurface('billingMenu', function()
        interface.send({ action = 'openBillingMenu', data = BuildBillingContext() })
    end)
    interface.focus(true, true)
end

interface.callback('closeBillingMenu', function(_, cb)
    cb('ok')
    CloseBillingUi()
end)

interface.callback('billingNotify', function(data, cb)
    lib.notify({
        title = 'Billing',
        description = data.message,
        type = data.type or 'inform'
    })
    cb('ok')
end)

interface.callback('billingGetNearbyPlayers', function(_, cb)
    cb({ players = GetNearbyPlayers() })
end)

interface.callback('billingCreateInvoice', function(data, cb)
    if not data.targetId or not data.title or not data.amount then
        cb({ success = false })
        return
    end

    TriggerServerEvent('xx-billing:server:CreateInvoice', {
        targetId = data.targetId,
        title = data.title,
        description = data.description or '',
        amount = data.amount,
        items = data.items or {}
    })

    cb({ success = true })
end)

interface.callback('getCompanyDataCreated', function(data, cb)
    local result = lib.callback.await('xx-billing:server:GetMyCreatedInvoices', false, data.page or 1, data.limit or 20)
    cb(result or { invoices = {}, total = 0, page = 1, pages = 1 })
end)

interface.callback('getCompanyDataMine', function(data, cb)
    local result = lib.callback.await('xx-billing:server:GetMyInvoices', false, data.page or 1, data.limit or 20)
    cb(result or { invoices = {}, total = 0, page = 1, pages = 1 })
end)

interface.callback('getCompanyDataHistory', function(data, cb)
    local result = lib.callback.await('xx-billing:server:GetPaymentHistory', false, data.page or 1, data.limit or 20)
    cb(result or { history = {}, total = 0, page = 1, pages = 1 })
end)

interface.callback('billingPayInvoice', function(data, cb)
    if not data.invoiceId or (data.method ~= 'cash' and data.method ~= 'bank') then
        cb({ success = false })
        return
    end
    TriggerTokenEvent('xx-billing:server:PayInvoiceWithMethod', data.invoiceId, data.method)
    cb({ success = true })
end)

interface.callback('billingCancelInvoice', function(data, cb)
    if not data.invoiceId then
        cb({ success = false })
        return
    end
    TriggerServerEvent('xx-billing:server:CancelInvoice', data.invoiceId)
    cb({ success = true })
end)

local function CloseIncomingFocus()
    if not incomingFocused then return end
    incomingFocused = false
    if not billingUiOpen then
        interface.focus(false, false)
        StopBillingAnimation()
    end
    closeSurface('incoming')
end

interface.callback('billingIncomingLater', function(_, cb)
    cb('ok')
    lib.notify({title = 'Invoice Disimpan', description = 'Anda bisa membayar nanti melalui menu billing (F7)', type = 'inform'})
    CloseIncomingFocus()
end)

interface.callback('billingIncomingDone', function(_, cb)
    cb('ok')
    CloseIncomingFocus()
end)

interface.callback('billingForceClose', function(_, cb)
    cb('ok')
    CloseIncomingFocus()
    CloseBillingUi()
end)

RegisterNetEvent('xx-billing:client:InvoiceReceived', function()
    lib.notify({title = 'Invoice Diterima', description = 'Anda menerima invoice baru', type = 'inform'})
end)

RegisterNetEvent('xx-billing:client:InvoicePaid', function()
    lib.notify({title = 'Invoice Dibayar', description = 'Invoice Anda telah dibayar', type = 'success'})
end)

RegisterNetEvent('xx-billing:client:InvoiceOverdue', function(invoiceData)
    lib.notify({title = 'Invoice Terlambat', description = 'Invoice Anda sudah terlambat: ' .. invoiceData.title, type = 'warning'})
end)

RegisterNetEvent('xx-billing:client:InvoiceConfirmation', function(invoiceData)
    PlayerData = QBCore.Functions.GetPlayerData()

    if not billingUiOpen then
        incomingFocused = true
    end

    local cash = PlayerData.money and PlayerData.money.cash or 0
    local bank = PlayerData.money and PlayerData.money.bank or 0

    sendOnce(function()
        interface.send({
            action = 'billingUpdateBalance',
            data = { cash = cash, bank = bank }
        })
        interface.send({
            action = 'billingIncomingInvoice',
            data = {
                id = invoiceData.id,
                title = invoiceData.title,
                description = invoiceData.description,
                amount = invoiceData.amount,
                amount_formatted = invoiceData.amount_formatted,
                sender = invoiceData.sender,
                sender_job = invoiceData.sender_job,
                due_date_formatted = invoiceData.due_date_formatted
            }
        })
    end)

    if incomingFocused and not billingUiOpen then
        interface.focus(true, true)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    if isMenuOpen then StopBillingAnimation() end
    if billingUiOpen or incomingFocused then SetNuiFocus(false, false) end

    Wait(100)
    local playerPed = PlayerPedId()
    local tabletHash = GetHashKey("prop_cs_tablet")
    for _, object in ipairs(GetGamePool('CObject')) do
        if GetEntityModel(object) == tabletHash and IsEntityAttachedToEntity(object, playerPed) then
            DetachEntity(object, true, true)
            DeleteEntity(object)
        end
    end
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    PlayerData = QBCore.Functions.GetPlayerData()
    Wait(1000)
    SetupCompanyLogTargets()
end)
