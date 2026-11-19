--[[
    brofx_mansion_06 :: env
    Map murni. Berkas ini menjaga entry server_scripts tetap valid
    dan menyediakan daftar shell untuk validasi offset housing.
]]

local RESOURCE = GetCurrentResourceName()

local SHELLS = {
    { id = 'brofx_mansion06', ytyp = 'brofx_mansion06_ytyp', rooms = 24, garage = true },
}

CreateThread(function()
    Wait(0)
    print(('^2[%s] %d shell terdaftar^7'):format(RESOURCE, #SHELLS))
end)

exports('GetShells', function() return SHELLS end)

exports('GetShell', function(id)
    for i = 1, #SHELLS do
        if SHELLS[i].id == id then return SHELLS[i] end
    end
end)