RegisterNetEvent('sm_megaphones:client:usemegaphone', function()
    megaphoneEnabled = not megaphoneEnabled
    toggleMegaphone('handHeld', megaphoneEnabled)
end)


