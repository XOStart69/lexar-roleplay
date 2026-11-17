return {
    interactDistance = 2.0,

    bags = {
        tas_reporter = {
            label = 'Tas Reporter',
            stashPrefix = 'tas_reporter_',
            export = 'useTasReporter',
            slots = 8,
            weight = 50000,
            allowedItems = {
                newspaper = true,
                tablet_media = true,
            },
        },
        tas_ambulance = {
            label = 'Tas Ambulance',
            stashPrefix = 'tas_ambulance_',
            export = 'useTasAmbulance',
            slots = 12,
            weight = 50000,
            allowedItems = {
                paracetamol = true,
                bandage = true,
                paracetamol_syrup = true,
                perban_anak = true,
            },
        },
    },
}
