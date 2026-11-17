return {
    mopping = {
        enabled = true,
        label = 'Mengepel Lantai',
        icon = 'fas fa-broom',
        blipSprite = 446,
        blipColor = 3,
        blipScale = 0.6,
        progressDuration = 12000,
        timeReduction = 1,
        cooldown = 10 * 60000,
        interactionRadius = 1.0,
        interactionDistance = 2.0,
        
        animation = {
            dict = "move_mop",
            clip = "idle_scrub_small_player",
            flag = 51,
            prop = "prop_cs_mop_s",
            propBone = 28422,
            propPlacement = { 0.0, 0.0, 0.12, 0.0, 0.0, 0.0 }
        },
        
        locations = {
            police = {
                vec3(1782.2985, 2553.4817, 45.6731),
                vec3(1788.3303, 2548.7847, 45.6732),
                vec3(1786.2599, 2558.5530, 45.6732),
                vec3(1777.7981, 2558.1045, 45.6732),
                vec3(1742.8304, 2487.7634, 45.8159),
                vec3(1760.5822, 2493.5220, 45.8202),
                vec3(1776.8101, 2496.4080, 45.8232),
                vec3(1779.1196, 2492.0198, 45.8220),
                vec3(1698.2590, 2451.5576, 45.8423),
                vec3(1676.1871, 2454.1838, 45.8407),
                vec3(1581.8160, 2551.8982, 45.9880),
                vec3(1578.9071, 2562.0305, 45.9880),
                vec3(1764.8938, 2593.4019, 45.7299),
                vec3(1769.2699, 2597.7568, 45.7299),
                vec3(1769.8557, 2591.6497, 45.7299),
            }
        }
    },
    
    cooking = {
        enabled = true,
        label = 'Memasak',
        icon = 'fas fa-utensils',
        blipSprite = 93,
        blipColor = 1,
        blipScale = 0.6,
        progressDuration = 18000,
        timeReduction = 5,
        cooldown = 15 * 60000,
        interactionRadius = 1.5,
        interactionDistance = 2.0,
        
        animation = {
            scenario = "PROP_HUMAN_BBQ",
            scenarioType = "MaleScenario"
        },
        
        locations = {
            police = {
                vec3(1780.892822, 2564.897949, 45.597652)
            }
        }
    },
    
    dishwashing = {
        enabled = true,
        label = 'Cuci Piring',
        icon = 'fas fa-sink',
        blipSprite = 93,
        blipColor = 26,
        blipScale = 0.6,
        progressDuration = 18000,
        timeReduction = 7,
        cooldown = 15 * 60000,
        interactionRadius = 1.5,
        interactionDistance = 2.0,

        animation = {
            dict = "missheist_agency3aig_23",
            clip = "urinal_sink_loop",
            flag = 51
        },

        locations = {
            police = {
                vec3(1778.212646, 2565.125977, 45.209293)
            }
        }
    },

    electrician = {
        enabled = true,
        label = 'Perbaiki Kabel',
        icon = 'fas fa-bolt-lightning',
        blipSprite = 354,
        blipColor = 5,
        blipScale = 0.6,
        progressDuration = 15000,
        timeReduction = 1,
        cooldown = 10 * 60000,
        interactionRadius = 1.0,
        interactionDistance = 2.0,
        
        animation = {
            dict = "anim@gangops@facility@servers@",
            clip = "hotwire",
            flag = 16
        },
        
        locations = {
            police = {
                vec3(1723.356201, 2505.819092, 45.783882),
                vec3(1767.009033, 2531.015869, 45.783619),
                vec3(1652.581543, 2564.720703, 45.742390),
                vec3(1629.974731, 2564.720703, 45.712116),
                vec3(1618.697510, 2521.287354, 45.791718),
                vec3(1657.344238, 2488.868164, 45.838779),
                vec3(1668.133057, 2488.285645, 45.801281),
                vec3(1718.590088, 2488.268311, 45.884277),
                vec3(1721.704712, 2501.429688, 45.750954),
            }
        }
    }
}
