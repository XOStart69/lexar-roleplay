RegisterNetEvent('Housing:server:ViewCCTV', function(homeId, aptId)
    local src = source
    local home = Housing:GetHome(homeId)
    if not home then return end
    if not home.configuration.cctv then
        Housing:Notify(src, 'Rumah ini tidak punya CCTV', 'error')
        return
    end

    local identifier = Housing:GetIdentifier(src)
    if not home:HasAccess(identifier, 'doorlock', aptId) and not Housing:IsPolice(src) and not Housing:IsAdmin(src) then
        Housing:Notify(src, 'Kamu tidak punya akses CCTV', 'error')
        return
    end

    local cameras = home.data.cctv or {}
    if #cameras == 0 then
        Housing:Notify(src, 'Belum ada kamera terpasang', 'error')
        return
    end

    TriggerClientEvent('Housing:client:ViewCCTV', src, homeId, cameras[1].coords, cameras[1].rotation,
        cameras[1].pitch, cameras[1].yaw)
end)