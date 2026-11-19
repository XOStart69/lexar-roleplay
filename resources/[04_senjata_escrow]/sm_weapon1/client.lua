CreateThread(function()
    for hash, label in pairs(WeaponNames) do
        AddTextEntryByHash(hash, label)
    end
end)