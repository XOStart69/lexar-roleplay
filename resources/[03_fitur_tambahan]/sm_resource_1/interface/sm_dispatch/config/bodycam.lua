---@class BodycamConfig
local Bodycam = {}

Bodycam.Jobs = {
    police = true,
    ambulance = true,
    government = true,
    paspampres = true,
    usmarshal = true,
}

Bodycam.Item = 'bodycam'
Bodycam.DashcamItem = 'dashcam'

Bodycam.DashcamClasses = {
    [18] = true,
}

Bodycam.RecordTime = 30
Bodycam.ForceFirstPerson = false
Bodycam.ExitKey = 'BACK'
Bodycam.SupervisorGrade = 3

Bodycam.Position = { x = 79, y = 27 }

Bodycam.CameraEffect = {
    bodycam = 'Island_CCTV_ChannelFuzz',
    dashcam = 'TinyRacerMoBlur',
}

Bodycam.Portals = {
    {
        coords = vec3(2472.986816, 1612.152954, 30.397867),
        radius = 1.5,
        bodycamJobs = { police = true, ambulance = true },
        dashcam = {
            jobs = { police = true },
            classes = { [18] = true },
        },
        access = { police = true },
    },
}

Bodycam.DefaultVehicleOffset = vec3(0.0, 0.35, 0.79)

Bodycam.VehicleOffsets = {
    [`pitbullbb`] = vec3(0.0, 0.33, 0.53),
    [`riot`] = vec3(0.0, 0.33, 0.53),
    [`polbmwm7`] = vec3(0.0, 0.33, 0.53),
    [`jeepranger`] = vec3(0.0, 0.33, 0.53),
    [`polbmwm3`] = vec3(0.0, 0.33, 0.53),
    [`polmustang`] = vec3(0.0, 0.33, 0.53),
    [`polsilverado19`] = vec3(0.0, 0.33, 0.53),
    [`polbmwm5`] = vec3(0.0, 0.33, 0.53),
    [`polrs6`] = vec3(0.0, 0.33, 0.53),
    [`triton`] = vec3(0.0, 0.33, 0.53),
    [`08evoscpd`] = vec3(0.0, 0.33, 0.53),
    [`hurcop`] = vec3(0.0, 0.33, 0.53),
    [`hp_m8`] = vec3(0.0, 0.33, 0.53),
    [`amrevu23mg`] = vec3(0.0, 0.33, 0.53),
    [`polc63s`] = vec3(0.0, 0.33, 0.53),
}

return Bodycam
