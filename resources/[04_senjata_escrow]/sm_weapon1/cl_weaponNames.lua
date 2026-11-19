WeaponNames = {}

for i = 1, #Config.weapons do
    local weapon = Config.weapons[i]

    WeaponNames[GetHashKey(weapon.name)] = weapon.label
end