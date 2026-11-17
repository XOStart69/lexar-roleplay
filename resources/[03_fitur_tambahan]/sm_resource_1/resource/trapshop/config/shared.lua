local function attach(bone, pos, rot, rotOrder, fixedRot)
    return {
        bone = bone,
        pos = pos,
        rot = rot,
        rotOrder = rotOrder or 2,
        fixedRot = fixedRot ~= false
    }
end

return {
    wearDuration = 4000,
    wearAnim = { dict = 'missmic4', clip = 'michael_tux_fidget' },

    attachPoints = {
        back = attach(24818, vector3(-0.28, 0.02, 0.0), vector3(180.0, 90.0, 0.0)),
        lbmujer = attach(64729, vector3(0.06, 0.05, 0.48), vector3(175.55, 346.69, 18.67))
    },

    items = {
        { name = 'trap_lbone', model = 'trap_lbone', point = 'back' },
        { name = 'trap_lbtwo', model = 'trap_lbtwo', point = 'back' },
        { name = 'trap_lbtree', model = 'trap_lbtree', point = 'back' },
        { name = 'trap_lbfort', model = 'trap_lbfort', point = 'lbmujer' },
        { name = 'tr_cerdito', model = 'tr_cerdito', point = 'back' },
        { name = 'trap_juniorh', model = 'trap_juniorh', point = 'back' },
        { name = 'trap_bichota', model = 'trap_bichota', point = 'back' },
        { name = 'trap_dogshark', model = 'trap_dogshark', point = 'back' },
        { name = 'trap_catpurple', model = 'trap_catpurple', point = 'back' },
        { name = 'trap_conejowep', model = 'trap_conejowep', point = 'back' },
        { name = 'trap_maquinita', model = 'trap_maquinita', point = 'back' },
        { name = 'trap_conejogamer', model = 'trap_conejogamer', point = 'back' },
        { name = 'trap_osofn', model = 'trap_osofn', point = 'back' },
        { name = 'trap_bananin', model = 'trap_bananin', point = 'back' },
        { name = 'trap_kawsito', model = 'trap_kawsito', point = 'back' },
        { name = 'trap_ardillita', model = 'trap_ardillita', point = 'back' },
        { name = 'trap_dinoos', model = 'trap_dinoos', point = 'back' },
        { name = 'trap_axolote', model = 'trap_axolote', point = 'back' },
        { name = 'trap_ardillaxm', model = 'trap_ardillaxm', point = 'back' },
        { name = 'trap_patitogang', model = 'trap_patitogang', point = 'back' },
        --baru
        { name = 'nk_alienbag', model = 'nk_alienbag', point = 'back' },
        { name = 'nk_astrobag', model = 'nk_astrobag', point = 'back' },
        { name = 'nk_dogbag', model = 'nk_dogbag', point = 'back' },
        { name = 'nk_gothbag', model = 'nk_gothbag', point = 'back' },
        { name = 'nk_heartbag', model = 'nk_heartbag', point = 'back' },
        { name = 'nk_kittybag', model = 'nk_kittybag', point = 'back' },
        { name = 'nk_monkebag', model = 'nk_monkebag', point = 'back' },
        { name = 'nk_rickbag', model = 'nk_rickbag', point = 'back' },
        { name = 'nk_streetbag', model = 'nk_streetbag', point = 'back' },
        { name = 'nk_survivalbag', model = 'nk_survivalbag', point = 'back' },
    }
} --[[@as TrapshopConfig]]
