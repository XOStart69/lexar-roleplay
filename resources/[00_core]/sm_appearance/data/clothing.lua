local components = {
    HEAD = 0, -- "HEAD"
    BERD = 1, -- "BEARD"
    HAIR = 2, -- "HAIR"
    UPPR = 3, -- "UPPER"
    LOWR = 4, -- "LOWER"
    HAND = 5, -- "HAND"
    FEET = 6, -- "FEET"
    TEEF = 7, -- "TEETH"
    ACCS = 8, -- "ACCESSORIES"
    TASK = 9, -- "TASK"
    DECL = 10, -- "DECL"
    JBIB = 11 -- "JBIB"
}

local props = {
    HEAD = 0, -- "p_head"
    EYES = 1, -- "p_eyes"
    EARS = 2, -- "p_ears"
    MOUTH = 3, -- "p_mouth"
    LEFT_HAND = 4, -- "p_lhand"
    RIGHT_HAND = 5, -- "p_rhand"
    LEFT_WRIST = 6, -- "p_lwrist"
    RIGHT_WRIST = 7, -- "p_rwrist"
    HIP = 8, -- "p_lhip"
    LEFT_FOOT = 9, -- "p_lfoot"
    RIGHT_FOOT = 10, -- "p_rfoot"
    PH_L_HAND = 11, -- "ph_lhand"
    PH_R_HAND = 12 -- "ph_rhand"
}

local variations = require "data.clothingVariations"

return {
    shirt = {
        anim = {
            dict = 'clothingtie',
            clip = 'try_tie_negative_a',
            flag = 51,
            duration = 1200
        },
        components = {
            {
                componentId = components.JBIB,
                drawableId = {
                    male = 252, female = 440, custom = 0
                },
            },
            {
                componentId = components.UPPR,
                drawableId = {
                    male = 15, female = 15, custom = 0
                },
            },
            {
                componentId = components.ACCS,
                drawableId = {
                    male = 15, female = 19, custom = 0
                },
            },
            {
                componentId = components.DECL,
                drawableId = {
                    male = 0, female = 0, custom = 0
                },
            }
        },
    },
    
    pants = {
        components = {
            id = components.LOWR,
            drawable = {
                male = 61,
                female = 50,
                custom = 0
            }
        },
        anim = {
            dict = 're@construction',
            clip = 'out_of_breath',
            flag = 51,
            duration = 1300
        },
    },
    
    bag = {
        components = {
            id = components.HAND,
            variation = variations.bags
        },
        anim = {
            dict = 'anim@heists@ornate_bank@grab_cash',
            clip = 'intro',
            flag = 51,
            duration = 1600
        },
    },
    
    bagoff = {
        components = {
            id = components.HAND,
            drawable = {
                male = 0,
                female = 0,
                custom = 0
            }
        },
        anim = {
            dict = 'clothingtie',
            clip = 'try_tie_negative_a',
            flag = 51,
            duration = 1200
        },
    },
    
    shoes = {
        components = {
            id = components.FEET,
            drawable = {
                male = 34,
                female = 28,
                custom = 0
            }
        },
        anim = {
            dict = 'random@domestic',
            clip = 'pickup_low',
            flag = 0,
            duration = 1200
        },
    },

    jackets = {
        components = {
            id = components.JBIB,
            variation = variations.jackets
        },
        anim = {
            dict = 'missmic4',
            clip = 'michael_tux_fidget',
            flag = 51,
            duration = 1500
        },
    },

    gloves = {
        components = {
            id = components.UPPR,
            variation = variations.gloves
        },
        anim = {
            dict = 'nmt_3_rcm-10',
            clip = 'cs_nigel_dual-10',
            flag = 51,
            duration = 1200
        },
    },
    neck = {
        components = {
            id = components.TEEF,
            drawable = {
                male = 0,
                female = 0,
                custom = 0
            }
        },
        anim = {
            dict = 'clothingtie',
            clip = 'try_tie_positive_a',
            flag = 51,
            duration = 2100
        },
    },
    
    hair = {
        components = {
            id = components.HAIR,
            variation = variations.hair
        },
        anim = {
            dict = 'clothingtie',
            clip = 'check_out_a',
            flag = 51,
            duration = 2000
        },
    },

    vest = {
        components = {
            id = components.TASK,
            drawable = {
                male = 0,
                female = 0,
                custom = 0
            }
        },
        anim = {
            dict = 'clothingtie',
            clip = 'try_tie_negative_a',
            flag = 51,
            duration = 1200
        },
    },
    mask = {
        components = {
            id = components.BERD,
            drawable = {
                male = 0,
                female = 0,
                custom = 0
            }
        },
        anim = {
            dict = 'mp_masks@standard_car@ds@',
            clip = 'put_on_mask',
            flag = 51,
            duration = 800
        },
    },
    visor = {
        props = {
            id = props.HEAD,
            variation = variations.visor
        },
        anim = {
            {
                dict = 'mp_masks@standard_car@ds@', --- on anim (toggle proccess) 
                clip = 'put_on_mask',
                flag = 51,
                duration = 600
            },
            {
                dict = 'missheist_agency2ahelmet', --- off anim (toggle proccess)
                clip = 'take_off_helmet_stand',
                flag = 51,
                duration = 1200
            },
        },
    },
    
    hat = {
        props = {
            id = props.HEAD,
            drawable = {
                male = -1,
                female = -1,
                custom = -1
            }
        },
        anim = {
            {
                dict = 'mp_masks@standard_car@ds@', --- on anim (toggle proccess) 
                clip = 'put_on_mask',
                flag = 51,
                duration = 600
            },
            {
                dict = 'missheist_agency2ahelmet', --- off anim (toggle proccess)
                clip = 'take_off_helmet_stand',
                flag = 51,
                duration = 1200
            },
        },
    },
    glasses = {
        props = {
            id = props.EYES,
            drawable = {
                male = -1,
                female = -1,
                custom = -1
            }
        },
        anim = {
            dict = 'clothingspecs',
            clip = 'take_off',
            flag = 51,
            duration = 1400
        },
    },
    ear = {
        props = {
            id = props.EARS,
            drawable = {
                male = -1,
                female = -1,
                custom = -1
            }
        },
        anim = {
            dict = 'mp_cp_stolen_tut',
            clip = 'b_think',
            flag = 51,
            duration = 900
        },
    },
    watch = {
        props = {
            id = props.LEFT_WRIST,
            drawable = {
                male = -1,
                female = -1,
                custom = -1
            }
        },
        anim = {
            dict = 'nmt_3_rcm-10',
            clip = 'cs_nigel_dual-10',
            flag = 51,
            duration = 1200
        },
    },
    bracelet = {
        props = {
            id = props.RIGHT_WRIST,
            drawable = {
                male = -1,
                female = -1,
                custom = -1
            }
        },
        anim = {
            dict = 'nmt_3_rcm-10',
            clip = 'cs_nigel_dual-10',
            flag = 51,
            duration = 1200
        },
    }
}