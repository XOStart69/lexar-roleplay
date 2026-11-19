--[[
    crestview_Mansion :: patcher
    Mansion ini menimpa chunk ch2_04. Daftar interior dipakai housing
    untuk validasi sebelum memindahkan pemain ke bucket interior.
]]

local SHELLS = {
    { id = 'int_srg_crest_02', exterior = 'crestview_02', rooms = 12, garage = true },
}

CreateThread(function()
    Wait(0)
    print(('^2[%s] patcher siap, %d interior^7'):format(GetCurrentResourceName(), #SHELLS))
end)

exports('GetShells', function() return SHELLS end)