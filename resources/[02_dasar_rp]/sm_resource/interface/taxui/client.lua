local QBCore = exports['qb-core']:GetCoreObject()
local Config = require 'interface.taxui.config'

local isUIOpen                 = false
local currentNotificationActive = false
local currentNotificationId     = 0

local function formatNumber(amount)
    if not amount or amount == 0 then return '0' end
    local formatted = tostring(math.floor(amount))
    local k
    while true do  
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if (k==0) then
            break
        end
    end
    return formatted
end

local function ShowTaxNotification(data)
    if not data then return end

    currentNotificationActive = true
    isUIOpen = true
    currentNotificationId = currentNotificationId + 1
    local myNotifId = currentNotificationId

    local icon = 'fa-solid fa-coins'
    local title = data.title or 'Pajak'
    local desc = {}

    if data.type == 'deduction' then
        icon = 'fa-solid fa-coins'
        title = data.title or 'Pajak Kekayaan'
        desc['Keterangan'] = 'Pajak harian berhasil dipotong'
        desc['Jumlah'] = '-$' .. formatNumber(data.amount)
        if data.wealth and data.wealth.total then
            desc['Saldo Sebelumnya'] = '$' .. formatNumber(data.wealth.total)
        end

    elseif data.type == 'insufficient' then
        icon = 'fa-solid fa-circle-exclamation'
        title = data.title or 'Pajak Tertunggak'
        desc['Keterangan'] = data.message or 'Saldo tidak mencukupi'
        if data.amount then
            desc['Jumlah'] = '$' .. formatNumber(data.amount)
        end
        if data.available then
            desc['Saldo Tersedia'] = '$' .. formatNumber(data.available)
        end

    elseif data.type == 'pending' then
        icon = 'fa-solid fa-circle-check'
        title = data.title or 'Pajak Tertunggak Terbayar'
        desc['Keterangan'] = data.message or 'Pajak tertunggak berhasil dibayar!'
        if data.amount then
            desc['Jumlah'] = '-$' .. formatNumber(data.amount)
        end



    elseif data.type == 'login_info' then
        local totalDays     = tonumber(data.totalDays) or 0
        local paidDays      = tonumber(data.paidDays) or 0
        local failedDays    = tonumber(data.failedDays) or 0
        local pendingDays   = tonumber(data.pendingDays) or 0
        local paidAmount    = tonumber(data.paidAmount) or 0
        local totalPaid     = tonumber(data.totalPaid) or 0
        local failedAmount  = tonumber(data.failedAmount) or 0
        local pendingAmount = tonumber(data.pendingAmount) or 0

        title = data.title or 'Informasi Pajak'

        if not data.hasData and totalDays == 0 then
            icon = 'fa-solid fa-circle-info'
            desc['Keterangan'] = 'Pajak dipotong otomatis setiap hari'
            desc['Tarif'] = '0.5% dari total kekayaan'
        elseif totalDays > 0 then
            local multi = totalDays > 1
            if paidDays > 0 and failedDays == 0 and pendingDays == 0 then
                icon = 'fa-solid fa-circle-check'
                desc['Status'] = multi and ('Pajak %d hari berhasil dipotong!'):format(totalDays) or 'Pajak hari ini berhasil dipotong!'
                desc['Dipotong'] = '$' .. formatNumber(paidAmount)
                desc['Total Terbayar'] = '$' .. formatNumber(totalPaid)
            elseif paidDays > 0 and failedDays > 0 then
                icon = 'fa-solid fa-circle-exclamation'
                desc['Status'] = ('%d hari terbayar, %d hari tertunggak'):format(paidDays, failedDays)
                desc['Dipotong'] = '$' .. formatNumber(paidAmount)
                desc['Kurang'] = '$' .. formatNumber(failedAmount)
            elseif failedDays > 0 then
                icon = 'fa-solid fa-circle-xmark'
                desc['Status'] = multi and ('%d hari pajak tertunggak! (Saldo kurang)'):format(failedDays) or 'Pajak hari ini tertunggak! (Saldo kurang)'
                desc['Tertunggak'] = '$' .. formatNumber(failedAmount)
                desc['Tindakan'] = 'Bayar pajak segera'
            elseif pendingDays > 0 then
                icon = 'fa-solid fa-hourglass-half'
                desc['Status'] = multi and ('%d hari pajak masih tertunda'):format(pendingDays) or 'Pajak hari ini masih tertunda'
                desc['Menunggu'] = '$' .. formatNumber(pendingAmount)
                desc['Keterangan'] = 'Akan diproses otomatis'
            end
        else
            icon = 'fa-solid fa-circle-check'
            desc['Status'] = 'Tidak ada pajak baru hari ini'
            if totalPaid > 0 then
                desc['Total Terbayar'] = ('$%s (%d hari)'):format(formatNumber(totalPaid), tonumber(data.taxDays) or 0)
            else
                desc['Keterangan'] = 'Belum ada history pembayaran'
            end
        end
    end

    infoUI.show({
        id = 'tax_notification',
        icon = icon,
        title = title,
        description = desc
    })

    local duration = data.type == 'login_info' and Config.UIDisplayTime or 6000

    CreateThread(function()
        Wait(duration)
        if currentNotificationId == myNotifId then
            infoUI.remove('tax_notification')
            isUIOpen = false
            currentNotificationActive = false
        end
    end)
end

local function GetTaxInfo()
    local attempts = 0
    CreateThread(function()
        while attempts < 10 do
            attempts = attempts + 1
            local ok, err = pcall(function()
                lib.callback('tax-system:server:getTaxInfo', false, function(data)
                    if not data then return end

                    local todayTaxAmount = data.todayTax and tonumber(data.todayTax.tax_amount) or 0
                    local todayStatus    = data.todayTax and data.todayTax.status or nil
                    local totalPaid      = tonumber(data.summary.total_paid) or 0
                    local paidDays       = tonumber(data.summary.paid_days) or 0

                    ShowTaxNotification({
                        type        = 'login_info',
                        title       = 'Informasi Pajak',
                        wealth      = data.wealth,
                        totalPaid   = totalPaid,
                        taxDays     = paidDays,
                        totalDays   = todayStatus and 1 or 0,
                        paidDays    = todayStatus == 'paid' and 1 or 0,
                        failedDays  = todayStatus == 'failed' and 1 or 0,
                        pendingDays = todayStatus == 'pending' and 1 or 0,
                        paidAmount  = todayStatus == 'paid' and todayTaxAmount or 0,
                        failedAmount  = todayStatus == 'failed' and todayTaxAmount or 0,
                        pendingAmount = todayStatus == 'pending' and todayTaxAmount or 0,
                        hasData     = todayStatus ~= nil or paidDays > 0
                    })
                end)
            end)
            if ok then return end
            Wait(1000)
        end
    end)
end

AddEventHandler('rhd_spawn:client:onSpawn', function()
    if Config.ShowUIOnSpawn then
        Wait(3000)
        GetTaxInfo()
    end
end)

RegisterNetEvent('tax-system:client:notification', function(data)
    ShowTaxNotification(data)
end)

RegisterCommand('cekpajak', function() GetTaxInfo() end, false)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    currentNotificationActive = false
    isUIOpen = false
    infoUI.remove('tax_notification')
end)