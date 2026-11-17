return {
    item = 'hightable_contract',
    signedItem = 'signedhightable_contract',
    requiredJob = 'hightable',
    requiredGrade = 4,
    nearbyRadius = 10.0,
    contractTimeout = 120,
    targetOpenDelay = 2800,
    completeDelay = 3500,

    anim = {
        dict = 'missheistdockssetup1clipboard@base',
        name = 'base',
        flag = 51,
        props = {
            { model = 'prop_notepad_01', bone = 18905, offset = vec3(0.1, 0.02, 0.05), rotation = vec3(10.0, 0.0, 0.0) },
            { model = 'prop_pencil_01', bone = 58866, offset = vec3(0.11, -0.02, 0.001), rotation = vec3(-120.0, 0.0, 0.0) },
        },
    },
}
