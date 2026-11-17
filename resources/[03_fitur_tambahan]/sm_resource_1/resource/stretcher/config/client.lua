return {
    model = 'trump-stretcher',
    item = 'stretcher',
    allowedJobs = { 'ambulance', 'rsroxwood', 'puskesmas', 'banmeskota' },
    extras = {
        { id = 3, label = 'Backboard' },
        { id = 5, label = 'Lifepak' },
        { id = 6, label = 'Tas medis' },
        { id = 7, label = 'Backpack' }
    },
    anim = {
        sit1 = {
            dict = 'amb@world_human_stupor@male_looking_left@base',
            clip = 'base',
            coords = vec(0.0, 0.3, 1.5, 180.0)
        },
        sit2 = {
            dict = 'amb@prop_human_seat_chair_food@male@base',
            clip = 'base',
            coords = vec(0.0, -0.2, 0.55, 90.0)
        },
        sit3 = {
            dict = 'amb@prop_human_seat_chair_food@male@base',
            clip = 'base',
            coords = vec(0.0, -0.2, 0.55, -90.0)
        },
        sleep = {
            dict = 'savecouch@',
            clip = 't_sleep_loop_couch',
            coords = vec(0.0, 0.2, 1.1, 180.0)
        },
        take = {
            dict = 'anim@heists@box_carry@',
            clip = 'idle',
        }
    }
}