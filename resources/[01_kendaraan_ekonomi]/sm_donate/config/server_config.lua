Settings.Debug = false
Settings.DebugPrint = function(...)
    if not Settings.Debug then return end

    print('[sm_donate]', ...)
end

Settings.GiveItemOnCollect = true
Settings.SellCoinsPerTier = {
    common = 5,
    rare = 15,
    mythical = 40,
    legendary = 120,
    divine = 400,
}
