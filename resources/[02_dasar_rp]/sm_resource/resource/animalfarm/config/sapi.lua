return {
    blip = {
        cow = {
            label = "Peternakan Sapi",
            color = 5,
            sprite = 238,
            category = 25,
            coords = vector3(-3492.4199, 8711.1211, 38.5205),
        },
        proccess = {
            label = "Proses susu Sapi",
            color = 5,
            sprite = 238,
            category = 25,
            coords = vector3(-3601.9346, 7961.6479, 45.5533),
        },
        -- proccess2 = {
        --     label = "Animal Farmer - Proses susu Sapi #2",
        --     color = 5,
        --     sprite = 238,
        --     coords = vector3(2554.410889, 4667.783203, 34.290241),
        -- },
    },
    cow = {
        model = 'a_c_cow',
        coords = {
            vector4(-3490.3040, 8723.7109, 38.5105, 188.8048),
            vector4(-3499.9419, 8721.7705, 38.5105, 188.0742),
            vector4(-3510.0276, 8720.3418, 38.5106, 188.5274),
        },
        item = {
            remove = {
                bucket = 1
            },
            add = {
                bucketmilk = 1
            }
        },
        anim = { dict = 'mini@repair', clip = 'fixing_a_ped' }
    },
    proccess = {
        {
            boxzone = {
                coords = vec3(-3602.184082, 7962.002930, 45.749527),
                size = vec3(1.7999999523163, 1.6499999761581, 3.7999999523163),
                rotation = 316.5,
            },
            item = {
                remove = {
                    bucketmilk = 1,
                    bottle = 5
                },
                add = {
                    homemademilk = 3
                }
            },
            anim = { dict = 'mini@repair', clip = 'fixing_a_ped' }
        },
        -- {
        --     boxzone = {
        --         coords = vec3(2554.410889, 4667.783203, 34.290241),
        --         size = vec3(1.7999999523163, 1.6499999761581, 3.7999999523163),
        --         rotation = 0,
        --     },
        --     item = {
        --         remove = {
        --             bucketmilk = 1,
        --             bottle = 5
        --         },
        --         add = {
        --             homemademilk = 3
        --         }
        --     },
        --     anim = { dict = 'mini@repair', clip = 'fixing_a_ped' }
        -- }
    }
}