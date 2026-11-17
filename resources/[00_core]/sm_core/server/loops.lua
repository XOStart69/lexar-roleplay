-- Rekonstruksi sm_core/server/loops.lua

-- Simpan berkala + penurunan hunger/thirst.
-- Siklus biasa  : SaveLight (money, position, metadata)
-- Tiap FullSaveEvery siklus: Save penuh (semua kolom kecuali inventory)
CreateThread(function()
    local cycle = 0
    while true do
        Wait(QBConfig.UpdateInterval * 60000)
        cycle += 1
        local full = cycle % QBConfig.FullSaveEvery == 0

        local sources = {}
        for src in pairs(QBCore.Players) do sources[#sources + 1] = src end

        for i = 1, #sources do
            local src = sources[i]
            local player = QBCore.Players[src]
            if player then
                local meta = player.PlayerData.metadata
                if not meta.isdead then
                    player.Functions.SetMetaData('thirst', math.max(0, (meta.thirst or 100) - QBConfig.Player.ThirstRate))
                    player.Functions.SetMetaData('hunger', math.max(0, (meta.hunger or 100) - QBConfig.Player.HungerRate))
                    TriggerClientEvent('hud:client:UpdateNeeds', src, meta.hunger, meta.thirst)
                end
                if full then QBCore.Player.Save(src) else QBCore.Player.SaveLight(src) end
                Wait(10)
            end
        end
    end
end)

-- Gaji berkala
CreateThread(function()
    if QBConfig.Money.PayCheckSociety then
        lib.print.warn('PayCheckSociety=true belum didukung di rekonstruksi ini; gaji dibayar langsung ke bank.')
    end

    while true do
        Wait(QBConfig.Money.PayCheckTimeOut * 60000)

        for src, player in pairs(QBCore.Players) do
            local job = player.PlayerData.job
            local shared = job and QBShared.Jobs[job.name]
            local payment = job and job.payment or 0

            if shared and payment > 0 and (job.onduty or shared.offDutyPay) then
                if player.Functions.AddMoney('bank', payment, 'paycheck') then
                    QBCore.Functions.Notify(src, Lang:t('info.received_paycheck', { value = payment }), 'success')
                end
            end
        end
    end
end)
