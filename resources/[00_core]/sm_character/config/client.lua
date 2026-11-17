return {
    debug = false,

    intro = {
        hour = 19,
        minute = 45,
        weather = 'EXTRASUNNY',
        uiDelay = 3000,
        store = 'https://satu-mimpi-roleplay.tebex.io/',
        credits = {
            speed = 60,
            sections = {
                { title = 'Founder', names = { 'SM - MR' } },
                { title = 'Ceo', names = { 'SM - GOKONG' } },
                { title = 'Management', names = { 'SM - ILMIS', 'SM - NAGA' } },
                { title = 'Community Manager', names = { 'SM - PIYOYO' } },
                { title = 'Developer', names = { 'SM - AXON', 'SM - HFZ' } },
                { title = 'Modder', names = { 'SM - NIKO', 'SM - UWA', 'SM - HANS' } },
                { title = 'Donation Handler', names = { 'SM - RYU', 'SM - MODRA' } },
                {
                    title = 'Game Master',
                    names = {
                        'SM - KASYA', 'SM - CAKECAAA', 'SM - EVE', 'SM - KING', 'SM - THEO', 'SM - SIMON', 'SM - ARDIM',
                        'SM - KYO', 'SM - RENATA', 'SM - SANTOS', 'SM - GAKU', 'SM - KIRA', 'SM - ADONISME', 'SM - NOK',
                    },
                },
                { title = 'Badside Handler', names = { 'SM - LOPEZ', 'SM - BAS', 'SM - BARA', 'SM - FEARZY', 'SM - MONTEZ', 'SM - SWEDI', 'SM - ARVA', 'SM - Ibbo' } },
                { title = 'Helper', names = { 'SM - Mikelpod', 'SM - Jonathan' } },
            },
        },
        shots = {
            { from = vec3(-1350.0, -1450.0, 260.0), to = vec3(-450.0, -1650.0, 230.0), target = vec3(-150.0, -800.0, 120.0), fov = 45.0, duration = 22000 },
            { from = vec3(650.0, -350.0, 320.0), to = vec3(250.0, 150.0, 300.0), target = vec3(-250.0, -650.0, 90.0), fov = 40.0, duration = 22000 },
            { from = vec3(-2050.0, -650.0, 180.0), to = vec3(-1550.0, -1150.0, 160.0), target = vec3(-600.0, -900.0, 60.0), fov = 50.0, duration = 22000 },
        },
    },

    selection = {
        hour = 21,
        minute = 0,
        weather = 'CLEAR',
        solo = {
            vec4(-980.1, 662.18, 165.66, 185.35),
        },
        placeholder = {
            models = { `np_m_character_select`, `np_f_character_select` },
            alpha = 200,
        },
        duo = {
            vec4(-980.1, 662.18, 165.66, 185.35),
        },
        camera = {
            solo = { position = vec3(-1.55, -2.8, 0.6), focus = vec3(-0.85, 0.0, 0.5), fov = 35.0 },
            duo = { position = vec3(-1.55, -2.8, 0.6), focus = vec3(-0.85, 0.0, 0.5), fov = 35.0 },
        },
        partnerLeave = {
            side = 6.0,
            back = 8.0,
            removeDistance = 3.0,
            waitMs = 2500,
        },
        drinking = {
            dict = 'safe@trevor@ig_5',
            clip = 'drink_3',
            idle = 'base',
            rotation = 20.67,
            props = {
                { model = 1360987401, clip = 'drink_3_beer' },
                { model = -1296774200, clip = 'drink_3_cam' },
            },
        },
        couple = {
            cp = {
                { dict = 'timetable@trevor@ig_1', male = 'ig_1_thedontknowwhy_trevor', female = 'ig_1_thedontknowwhy_patricia' },
                { dict = 'timetable@trevor@ig_1', male = 'ig_1_therearejustsomemoments_trevor', female = 'ig_1_therearejustsomemoments_patricia' },
                { dict = 'timetable@trevor@ig_1', male = 'ig_1_thedesertissobeautiful_trevor', female = 'ig_1_thedesertissobeautiful_patricia' },
            },
            bff = {
                { dict = 'anim@mp_player_intcelebrationpaired@f_f_sarcastic', left = 'sarcastic_left', right = 'sarcastic_right' },
                { dict = 'anim@mp_player_intcelebrationpaired@f_f_fist_bump', left = 'fist_bump_left', right = 'fist_bump_right' },
                { dict = 'anim@mp_player_intcelebrationpaired@m_m_manly_handshake', left = 'manly_handshake_left', right = 'manly_handshake_right' },
                { dict = 'anim@mp_player_intcelebrationpaired@m_m_bro_hug', left = 'bro_hug_left', right = 'bro_hug_right' },
            },
        },
        duoScene = { cp = 'bedroom', bff = 'rooftop' },
        bedroom = {
            {
                dict = 'switch@trevor@bed',
                coords = vec4(-595.74, 47.58, 97.0, 168.81),
                deltaZ = -1.0,
                idle = { player = 'bed_sleep_trevor', partner = 'bed_sleep_floyd' },
                exits = {
                    { player = 'bed_getup_1_trevor', partner = 'bed_getup_1_floyd' },
                    { player = 'bed_getup_2_trevor', partner = 'bed_getup_2_floyd' },
                },
                camera = { position = vec3(1.15, 0.9, 1.4), fov = 32.0, shift = 1.1 },
            },
        },
        child = {
            coords = vec4(-980.1, 662.18, 165.66, 5.35),
            dict = 'pazeee@snowzx@animations',
            clip = 'pazeee@snowzx@clip',
            flag = 51,
            camera = { position = vec3(1.1, 2.0, 0.4), fov = 40.0, shift = 0.5 },
        },
    },

    phone = {
        model = `prop_npc_phone_02`,
        render = 'poly',
        txd = 'prop_npc_phone_02',
        txn = 'phone_screen_npc',
        resolution = { x = 540, y = 1080 },
        powerCooldown = 5000,
        powerButton = { left = 1.03, top = 0.08, right = 1.10, bottom = 0.21 },
        bone = 28422,
        offset = vec3(0.0, 0.0, 0.0),
        rotation = vec3(0.0, 0.0, 0.0),
        dict = 'cellphone@',
        enter = 'cellphone_text_in',
        exit = 'cellphone_text_out',
        stance = {
            male = { dict = 'amb@world_human_stand_mobile@male@text@exit', clip = 'exit' },
            female = { dict = 'amb@world_human_hang_out_street@female_hold_arm@base', clip = 'base' },
        },
        camera = {
            distance = 0.32,
            lift = 0.02,
            fov = 38.0,
        },
        childCamera = {
            distance = 0.32,
            lift = 0.02,
            fov = 55.0,
        },
        screen = {
            inset = { x = 0.08, top = 0.1, bottom = 0.1 },
            offset = 0.0015,
            uv = { left = 0.02, top = 0.05, right = 0.99, bottom = 0.88 },
            flipX = false,
            flipY = false,
        },
    },
    
    spawn = {
        arrivalTitleMs = 5000,
    },

    hud = {
        hide = function()
            LocalPlayer.state:set('inCutscene', true, false)
            pcall(function() exports.sm_hud:setVisible(false) end)
            pcall(function() exports.sm_resource:toggleTrollUI(true) end)
        end,
        show = function()
            LocalPlayer.state:set('inCutscene', false, false)
            pcall(function() exports.sm_resource:toggleTrollUI(false) end)
        end,
    },

    weatherSync = function(enabled, weather)
        local state = LocalPlayer.state

        if state.playerWeather ~= weather then
            state:set('playerWeather', weather, false)
        end

        if state.syncWeather == enabled then return false end

        state:set('syncWeather', enabled, false)

        return true
    end,
}
