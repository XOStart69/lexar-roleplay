return {
    stages = {
        main = { scene = 'main', actions = { 'wrench', 'syringe', 'jerrycan', 'pullTooth', 'electrocute' } },
        wrench = { scene = 'wrench', actions = { 'wrench-left', 'wrench-middle', 'wrench-right' }, exit = 'wrench-exit' },
        jerrycan = { scene = 'jerrycan', actions = { 'jerrycan-drown' }, exit = 'jerrycan-exit' },
        jerrycanDrown = { scene = 'jerrycan', actions = { 'jerrycan-stop' } },
        pullTooth = { scene = 'pullTooth', actions = { 'pullTooth-pull' }, exit = 'pullTooth-exit' },
        pullToothPull = { scene = 'pullTooth', actions = { 'pullTooth-stop' } },
        electrocute = { scene = 'electrocute', actions = { 'electrocute-left', 'electrocute-both', 'electrocute-right' }, exit = 'electrocute-exit' },
        electrocuteClamp = { scene = 'electrocute', actions = { 'electrocute-spark-stop' } },
        electrocuteBoth = { scene = 'electrocute', actions = { 'electrocute-both-stop' } },
    },

    results = {
        wrench = 'wrench',
        syringe = 'main',
        jerrycan = 'jerrycan',
        pullTooth = 'pullTooth',
        electrocute = 'electrocute',

        ['wrench-left'] = 'wrench',
        ['wrench-middle'] = 'wrench',
        ['wrench-right'] = 'wrench',
        ['wrench-exit'] = 'main',

        ['jerrycan-drown'] = 'jerrycanDrown',
        ['jerrycan-stop'] = 'jerrycan',
        ['jerrycan-exit'] = 'main',

        ['pullTooth-pull'] = 'pullToothPull',
        ['pullTooth-stop'] = 'pullTooth',
        ['pullTooth-exit'] = 'main',

        ['electrocute-left'] = 'electrocuteClamp',
        ['electrocute-right'] = 'electrocuteClamp',
        ['electrocute-both'] = 'electrocuteBoth',
        ['electrocute-spark-stop'] = 'electrocute',
        ['electrocute-both-stop'] = 'electrocute',
        ['electrocute-exit'] = 'main',
    },
}
