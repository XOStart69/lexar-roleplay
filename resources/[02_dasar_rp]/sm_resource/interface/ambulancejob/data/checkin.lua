return {
    {
        coords = vector4(-254.2731, 6328.1875, 32.4273, 306.0902),
        model = 's_m_m_doctor_01',
        scenario = 'WORLD_HUMAN_CLIPBOARD',
        target = {
            {
                label = 'Berbicara dengan Resepsionis',
                icon = 'fas fa-clipboard',
                distance = 1.5,
                canInteract = function ()
                    return not playerState.inMedicBed
                end
            }
        },
        cost = 50000,
        treatmentCost = 34000,
        checkinId = 'puskesmas',
        healTime = 20
    },
    {
        coords = vector4(-554.1847, 7388.2207, 12.8352, 230.1713),
        model = 's_m_m_doctor_01',
        scenario = 'WORLD_HUMAN_CLIPBOARD',
        target = {
            {
                label = 'Berbicara dengan Resepsionis',
                icon = 'fas fa-clipboard',
                distance = 1.5,
                canInteract = function ()
                    return not playerState.inMedicBed
                end
            }
        },
        cost = 50000,
        treatmentCost = 34000,
        checkinId = 'rsroxwood',
        healTime = 20
    },
    {
        cost = 50000,
        treatmentCost = 34000,
        coords = vec(1144.50, -1539.30, 34.98),
        checkinId = 'rskota',
        healTime = 20
    }
}