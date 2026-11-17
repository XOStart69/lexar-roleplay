local CARRY = { dict = 'anim@heists@box_carry@', clip = 'idle' }
local MECHANIC = { dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', clip = 'machinic_loop_mechandplayer' }
local REPAIR = { dict = 'mini@repair', clip = 'fixing_a_ped' }
local SPRAY = {
    dict = 'anim@scripted@freemode@postertag@graffiti_spray@male@',
    clip = 'spray_can_var_01_male',
    flag = 8193,
}
local TAG = {
    dict = 'switch@franklin@lamar_tagging_wall',
    clip = 'lamar_tagging_wall_loop_lamar',
    flag = 8192,
    time = 2500,
}
local CLEAN = { dict = 'amb@world_human_maid_clean@', clip = 'base' }
local UNDER = { dict = 'amb@world_human_vehicle_mechanic@male@base', clip = 'base' }
local PUSH = { dict = 'missfinale_c2ig_11', clip = 'pushcar_offcliff_m' }

local BOX = { model = 'hei_prop_heist_box', bone = 60309, pos = vec3(0.025, 0.08, 0.255), rot = vec3(-145.0, 290.0, 0.0), anim = CARRY }
local RIM = { model = 'prop_wheel_rim_01', bone = 57005, pos = vec3(0.169, -0.018, -0.22), rot = vec3(-90.0, -110.0, 282.0), anim = CARRY }
local TUBE = { model = 'xs_prop_arena_lights_tube_l_a', bone = 57005, pos = vec3(0.169, -0.018, -0.22), rot = vec3(90.0, -110.0, 282.0), anim = CARRY }
local PLATE = { model = 'p_num_plate_01', bone = 57005, pos = vec3(0.119, -0.072, -0.05), rot = vec3(-90.0, 120.0, 12.0), anim = CARRY }
local CAN = { model = 'prop_cs_spray_can', bone = 57005, pos = vec3(0.119, -0.072, -0.05), rot = vec3(-90.0, 120.0, 12.0) }
local CAN_SPRAY = {
    model = 'prop_cs_spray_can',
    bone = 28422,
    pos = vec3(0.0, 0.0, 0.07),
    rot = vec3(0.0017365, 0.0, 0.0),
    ped = false,
    order = 2,
}
local WRENCH = { model = 'prop_tool_wrench', bone = 57005, pos = vec3(0.119, -0.072, -0.05), rot = vec3(-90.0, 120.0, 12.0) }
local SPONGE = { model = 'prop_sponge_01', bone = 28422, pos = vec3(0.0, 0.0, -0.01), rot = vec3(90.0, 0.0, 0.0) }

---@param model string
local function panel(model)
    return { model = model, bone = 57005, pos = vec3(0.36, 0.078, -0.195), rot = vec3(-20.0, -110.0, 10.0), anim = CARRY }
end

local WHEELS = { { wheel = 'wheel_lf' }, { wheel = 'wheel_lr' }, { wheel = 'wheel_rf' }, { wheel = 'wheel_rr' } }
local REAR_WHEELS = { { wheel = 'wheel_lr' }, { wheel = 'wheel_rr' } }
local SIDES = { { side = 'left' }, { side = 'right' } }
local AROUND = { { side = 'front' }, { side = 'left' }, { side = 'rear' }, { side = 'right' } }
local BELOW = { { side = 'rear', offset = vec3(0.4, 0.1, 0.0) }, { side = 'front', offset = vec3(0.0, -0.1, 0.0) } }

local under = { anim = UNDER, time = 8000, tool = WRENCH, under = true }

local paint = {
    kind = 'paint',
    reuse = true,
    carry = CAN,
    spots = AROUND,
    work = { intro = TAG, anim = SPRAY, time = 5000, grip = CAN_SPRAY },
}
local cabinPaint = {
    kind = 'paint',
    reuse = true,
    carry = CAN,
    spots = { { side = 'door' } },
    work = { intro = TAG, anim = SPRAY, time = 6000, grip = CAN_SPRAY, doors = { 0 } },
}
local cabin = { carry = BOX, spots = { { side = 'door' } }, work = { anim = REPAIR, time = 6000, doors = { 0 } } }
local bay = { carry = BOX, spots = { { side = 'engine' } }, work = { anim = REPAIR, time = 6000, doors = { 4 } } }
local trunk = { carry = BOX, spots = { { side = 'rear' } }, work = { anim = REPAIR, time = 6000, doors = { 5 } } }
local chassis = { jack = true, carry = BOX, spots = BELOW, work = under }
local wheel = {
    kind = 'wheels',
    group = 'wheels',
    jack = true,
    carry = RIM,
    spots = WHEELS,
    work = { anim = MECHANIC, time = 6000 },
}
local wrap = { reuse = true, carry = BOX, spots = SIDES, work = { anim = CLEAN, time = 5000, tool = SPONGE } }
local xenon = { carry = BOX, spots = { { side = 'front-left' }, { side = 'front-right' } }, work = { anim = REPAIR, time = 5000 } }
local neon = { carry = TUBE, spots = SIDES, work = { anim = MECHANIC, time = 5000 } }
local smoke = { carry = BOX, spots = REAR_WHEELS, work = { anim = MECHANIC, time = 4000, tool = WRENCH } }
local plate = { carry = PLATE, spots = { { side = 'rear' } }, work = { anim = MECHANIC, time = 6000 } }

return {
    jack = {
        stand = 'xs_prop_x18_axel_stand_01a',
        carry = {
            { model = 'xs_prop_x18_axel_stand_01a', bone = 28422, pos = vec3(0.07, -0.44, -0.1), rot = vec3(-80.0, 20.0, 0.0), anim = MECHANIC },
            { model = 'xs_prop_x18_axel_stand_01a', bone = 60309, pos = vec3(0.0, -0.44, 0.275), rot = vec3(-120.0, -20.0, 0.0) },
        },
        spot = { side = 'front-left' },
        work = { anim = MECHANIC, time = 5000 },
        placements = { vec3(0.5, 1.0, 0.0), vec3(-0.5, 1.0, 0.0), vec3(0.5, -1.0, 0.0), vec3(-0.5, -1.0, 0.0) },
        height = 0.2,
    },

    hoist = {
        carry = { model = 'prop_engine_hoist', bone = 57005, pos = vec3(-0.085, 0.24, -1.3), rot = vec3(10.0, 30.0, 100.0), anim = PUSH, slow = true },
        engine = { model = 'prop_car_engine_01', pos = vec3(-0.1, -1.6, 1.4), rot = vec3(0.0, 0.0, 0.0) },
        offset = vec3(0.0, 0.2, 0.0),
        drop = 1.0,
        work = { anim = REPAIR, time = 10000 },
    },

    spray = { asset = 'scr_playerlamgraff', effect = 'scr_lamgraff_paint_spray', scale = 1.0, alpha = 0.25 },
    creeper = 'prop_carcreeper',

    default = { carry = BOX, spots = { { side = 'left' } }, work = { anim = MECHANIC, time = 6000 } },

    parts = {
        repair = {
            carry = BOX,
            spots = { { side = 'engine' } },
            work = { anim = REPAIR, time = 10000, tool = WRENCH, doors = { 4 } },
            item = locale('install.toolkit'),
            prompt = locale('menu.repair_vehicle'),
            progress = locale('install.repairing'),
        },

        clean = {
            carry = BOX,
            spots = SIDES,
            work = { anim = CLEAN, time = 5000, tool = SPONGE },
            item = locale('install.cleaning_kit'),
            prompt = locale('menu.clean_vehicle'),
            progress = locale('install.cleaning'),
        },

        modEngine = { kind = 'engine', group = 'engine' },
        engineSound = { kind = 'engine', group = 'engine' },
        modTurbo = { carry = BOX, spots = { { side = 'engine' } }, work = { anim = REPAIR, time = 8000, tool = WRENCH, doors = { 4 } } },
        modBrakes = chassis,
        modSuspension = chassis,
        modTransmission = { jack = true, carry = BOX, spots = { { side = 'front', offset = vec3(0.0, -0.1, 0.0) } }, work = under },
        modArmor = { carry = BOX, spots = SIDES, work = { anim = MECHANIC, time = 6000, tool = WRENCH } },
        nitrousFlame = bay,
        nitrousPurge = bay,

        modSpoilers = { carry = panel('imp_prop_impexp_spoiler_02a'), spots = { { side = 'rear' } }, work = { anim = REPAIR, time = 10000 } },
        modFrontBumper = { carry = panel('imp_prop_impexp_front_bumper_01a'), spots = { { side = 'front' } }, work = { anim = MECHANIC, time = 10000 } },
        modRearBumper = { carry = panel('imp_prop_impexp_rear_bumper_02a'), spots = { { side = 'rear' } }, work = { anim = MECHANIC, time = 10000 } },
        modExhaust = {
            carry = { model = 'imp_prop_impexp_exhaust_06', bone = 57005, pos = vec3(-0.04, -0.03, 0.09), rot = vec3(200.0, 220.0, 12.0) },
            spots = { { side = 'rear', offset = vec3(0.4, 0.1, 0.0) } },
            work = under,
        },
        modHood = {
            carry = { model = 'prop_car_bonnet_02', bone = 60309, pos = vec3(0.025, 0.08, 0.255), rot = vec3(-145.0, 290.0, 0.0), anim = CARRY, slow = true },
            spots = { { side = 'front' } },
            work = { anim = REPAIR, time = 10000 },
        },
        modSideSkirt = { carry = BOX, spots = SIDES, work = { anim = MECHANIC, time = 6000, tool = WRENCH } },
        modGrille = { carry = BOX, spots = { { side = 'front' } }, work = { anim = MECHANIC, time = 6000 } },
        modFender = { carry = BOX, spots = { { side = 'front-left' } }, work = { anim = MECHANIC, time = 8000 } },
        modRightFender = { carry = BOX, spots = { { side = 'front-right' } }, work = { anim = MECHANIC, time = 8000 } },
        modRoof = { carry = BOX, spots = { { side = 'left' } }, work = { anim = REPAIR, time = 8000 } },
        modWindows = { carry = BOX, spots = { { side = 'door' } }, work = { anim = MECHANIC, time = 6000 } },
        modDoorR = { carry = BOX, spots = { { side = 'right' } }, work = { anim = MECHANIC, time = 6000 } },
        modTrunk = trunk,
        modHydrolic = trunk,
        modEngineBlock = bay,
        modAirFilter = bay,
        modStruts = bay,
        modArchCover = { carry = BOX, spots = WHEELS, work = { anim = MECHANIC, time = 3000 } },
        modAerials = { carry = BOX, spots = { { side = 'left' } }, work = { anim = REPAIR, time = 6000 } },
        modLightbar = { carry = BOX, spots = { { side = 'left' } }, work = { anim = REPAIR, time = 6000 } },
        modTrimB = { carry = BOX, spots = SIDES, work = { anim = MECHANIC, time = 5000 } },
        modTank = { carry = BOX, spots = { { side = 'rear' } }, work = { anim = MECHANIC, time = 6000 } },

        modFrame = cabin,
        modTrimA = cabin,
        modOrnaments = cabin,
        modDashboard = cabin,
        modDial = cabin,
        modDoorSpeaker = cabin,
        modSeats = cabin,
        modSteeringWheel = cabin,
        modShifterLeavers = cabin,
        modAPlate = cabin,
        modSpeakers = trunk,
        interiorColor = cabinPaint,
        dashboardColor = cabinPaint,

        color1 = paint,
        paintType1 = paint,
        color2 = paint,
        paintType2 = paint,
        pearlescentColor = paint,

        wheels = wheel,
        modFrontWheels = wheel,
        modBackWheels = wheel,
        modCustomTiresF = wheel,
        modCustomTiresR = wheel,
        wheelColor = {
            kind = 'paint',
            reuse = true,
            carry = CAN,
            spots = WHEELS,
            work = { intro = TAG, anim = SPRAY, time = 3000, grip = CAN_SPRAY },
        },
        modSmokeEnabled = smoke,
        tyreSmokeColor = smoke,
        fitment = { jack = true, spots = WHEELS, work = { anim = MECHANIC, time = 4000, tool = WRENCH } },

        modXenon = xenon,
        xenonColor = xenon,
        neonEnabled = neon,
        neonColor = neon,

        modHorns = bay,
        plateIndex = plate,
        modPlateHolder = plate,
        modVanityPlate = { carry = PLATE, spots = { { side = 'front' } }, work = { anim = MECHANIC, time = 6000 } },
        windowTint = wrap,
        livery = wrap,
        modRoofLivery = wrap,
        modLivery = wrap,
        extras = { carry = BOX, spots = { { side = 'left' } }, work = { anim = MECHANIC, time = 5000 } },
    },
}
