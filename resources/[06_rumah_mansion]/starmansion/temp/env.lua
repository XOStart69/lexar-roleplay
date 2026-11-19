--[[
    starmansion :: env
    Map Stark Mansion. Daftar interior untuk validasi housing.
]]

local SHELLS = {
    { id = 'starkmansion_interior_1', exterior = 'starkmansion_exterior', rooms = 14, garage = true },
    { id = 'starkmansion_interior_2', exterior = 'starkmansion_exterior', rooms = 6, garage = false },
}

CreateThread(function()
    Wait(0)
    print(('^2[%s] %d interior terdaftar^7'):format(GetCurrentResourceName(), #SHELLS))
end)

exports('GetShells', function() return SHELLS end)