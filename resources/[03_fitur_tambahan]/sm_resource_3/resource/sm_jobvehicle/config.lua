return {
    useDistance = 5.0,
    pedDistance = 60.0,
    spawnDistance = 60.0,
    cooldown = 3000,
    garage = 'Garasi Kota',
    shops = {
        ['sksm'] = {
            label = 'SMK Vehicle Shop',
            job = 'sksm',

            pedLocations = {
                {
                    coords = vector4(3526.0527, 4894.8740, 37.2434, 140.1609),
                    model = 'a_m_y_business_01'
                }
            },

            spawnLocations = {
                vector4(3497.1643, 4874.9326, 36.7387, 109.8369),
            },

            vehicles = {
                ['pbus'] = {
                    label = 'Bus SMK',
                    model = 'pbus',
                    price = 100000,
                    oneTimePurchase = true,
                    requiredGrade = 1,
                    livery = -1
                },
                ['baller8pt'] = {
                    label = 'SMK baller8pt',
                    model = 'baller8pt',
                    price = 100000,
                    oneTimePurchase = true,
                    requiredGrade = 1,
                    livery = -1
                },
            }
        },
        ['reporter'] = {
            label = 'Reporter Vehicle Shop',
            job = 'reporter',

            pedLocations = {
                {
                    coords = vector4(-298.4022, -614.8630, 33.5603, 192.0017),
                    model = 'a_m_y_business_01'
                }
            },

            spawnLocations = {
                vector4(-313.0186, -635.7472, 32.8896, 339.6892),
                vector4(-308.0797, -634.6796, 32.9526, 342.7059)
            },

            vehicles = {
                ['fascalamo2'] = {
                    label = 'News Van',
                    model = 'fascalamo2',
                    price = 25000,
                    oneTimePurchase = true,
                    requiredGrade = 0,
                    livery = -1
                },
                ['smas'] = {
                    label = 'Reporter smas',
                    model = 'smas',
                    price = 25000,
                    oneTimePurchase = true,
                    requiredGrade = 0,
                    livery = -1
                },
                ['smbron'] = {
                    label = 'Reporter smbron',
                    model = 'smbron',
                    price = 25000,
                    oneTimePurchase = true,
                    requiredGrade = 0,
                    livery = -1
                },
                ['smcla'] = {
                    label = 'Reporter smcla',
                    model = 'smcla',
                    price = 25000,
                    oneTimePurchase = true,
                    requiredGrade = 0,
                    livery = -1
                },
            }
        },
        ['taxism'] = {
            label = 'SMGO Vehicle Shop',
            job = 'taxism',

            pedLocations = {
                {
                    coords = vector4(-805.2221, -1366.4602, 5.9157, 262.5421),
                    model = 'a_m_y_business_01'
                }
            },

            spawnLocations = {
                vector4(-805.1696, -1373.1176, 4.8794, 258.8430),
            },

            vehicles = {
                ['smbemo'] = {
                    label = 'Taxi Bemo',
                    model = 'smbemo',
                    price = 25000,
                    oneTimePurchase = true,
                    requiredGrade = 2,
                    livery = -1
                },
                ['hondagenio'] = {
                    label = 'Taxi Genio',
                    model = 'hondagenio',
                    price = 25000,
                    oneTimePurchase = true,
                    requiredGrade = 0,
                    livery = -1
                },
                ['smtaxicamry'] = {
                    label = 'Taxi Camry',
                    model = 'smtaxicamry',
                    price = 25000,
                    oneTimePurchase = true,
                    requiredGrade = 3,
                    livery = -1
                },
                ['smgoo'] = {
                    label = 'SMGOO Transit Bus',
                    model = 'smgoo',
                    price = 25000,
                    oneTimePurchase = true,
                    requiredGrade = 1,
                    livery = 0
                },
            }
        },
        ['government'] = {
            label = 'Kendaraan Dinas Pemerintah',
            jobs = { 'government', 'paspampres' },

            pedLocations = {
                {
                    coords = vector4(-411.2, 1165.83, 325.87, 337.39),
                    model = 'a_m_y_business_01'
                }
            },

            spawnLocations = {
                vector4(-408.96, 1174.14, 325.37, 77.54),
                vector4(-418.94, 1177.9, 325.37, 53.71)
            },

            vehicles = {
                ['pemboxcar'] = {
                    label = 'Boxcar',
                    model = 'pemboxcar',
                    price = 25000,
                    oneTimePurchase = true,
                    requiredGrade = 2,
                    livery = -1
                },
                ['2018s650pm'] = {
                    label = '2018 s650pm',
                    model = '2018s650pm',
                    price = 25000,
                    oneTimePurchase = true,
                    requiredGrade = 0,
                    livery = -1
                },
                ['buspmrnth'] = {
                    label = 'Bus',
                    model = 'buspmrnth',
                    price = 25000,
                    oneTimePurchase = true,
                    requiredGrade = 0,
                    livery = -1
                },
                ['g500police'] = {
                    label = 'G500',
                    model = 'g500police',
                    price = 25000,
                    oneTimePurchase = true,
                    requiredGrade = 3,
                    livery = -1
                },
                ['smhyd'] = {
                    label = 'smhyd',
                    model = 'smhyd',
                    price = 25000,
                    oneTimePurchase = true,
                    requiredGrade = 3,
                    livery = -1
                },
                ['smgspam'] = {
                    label = 'smgspam',
                    model = 'smgspam',
                    price = 25000,
                    oneTimePurchase = true,
                    requiredGrade = 3,
                    livery = -1
                },
                ['smbcat'] = {
                    label = 'smbcat',
                    model = 'smbcat',
                    price = 25000,
                    oneTimePurchase = true,
                    requiredGrade = 3,
                    livery = -1
                },
                ['ikx3_63sb'] = {
                    label = '63SB',
                    model = 'ikx3_63sb',
                    price = 25000,
                    oneTimePurchase = true,
                    requiredGrade = 2,
                    livery = -1
                },
            }
        },
        ['pengadilan'] = {
            label = 'Kendaraan Dinas USMS & DOJ',
            jobs = { 'pengadilan', 'usmarshal' },

            pedLocations = {
                {
                    coords = vector4(212.19, -436.77, 36.24, 154.82),
                    model = 'a_m_y_business_01'
                }
            },

            spawnLocations = {
                vector4(209.44, -442.48, 35.96, 249.67)
            },

            vehicles = {
                ['dadrivegtabmw4'] = {
                    label = 'BMW 4',
                    model = 'dadrivegtabmw4',
                    price = 25000,
                    oneTimePurchase = true,
                    requiredGrade = 3,
                    livery = -1,
                    allowedJobs = { 'pengadilan' }
                },
                ['gcmx4m40i2023'] = {
                    label = 'M42023',
                    model = 'gcmx4m40i2023',
                    price = 25000,
                    oneTimePurchase = true,
                    requiredGrade = 3,
                    livery = -1,
                    allowedJobs = { 'pengadilan' }
                },
                ['vc_m3g80custom'] = {
                    label = 'M3 G80',
                    model = 'vc_m3g80custom',
                    price = 25000,
                    oneTimePurchase = true,
                    requiredGrade = 3,
                    livery = -1,
                    allowedJobs = { 'pengadilan' }
                },
                ['sspres'] = {
                    label = 'Presidential Vehicle',
                    model = 'sspres',
                    price = 25000,
                    oneTimePurchase = true,
                    requiredGrade = 3,
                    livery = -1,
                    allowedJobs = { 'pengadilan' }
                },
                ['22g63'] = {
                    label = '22 G63',
                    model = '22g63',
                    price = 25000,
                    oneTimePurchase = true,
                    requiredGrade = 0,
                    livery = 1,
                    allowedJobs = { 'usmarshal' },
                    requiredItem = { 'badgevehusmsnew', 'badgehighcommandusms' }
                },
                ['a90pit'] = {
                    label = 'A90 Pit',
                    model = 'a90pit',
                    price = 25000,
                    oneTimePurchase = true,
                    requiredGrade = 3,
                    livery = -1,
                    allowedJobs = { 'pengadilan' }
                },
                ['BearcatRBstairs'] = {
                    label = 'Bearcat RB',
                    model = 'BearcatRBstairs',
                    price = 25000,
                    oneTimePurchase = true,
                    requiredGrade = 0,
                    livery = -1,
                    allowedJobs = { 'usmarshal' },
                    requiredItem = { 'badgevehusmsnew', 'badgehighcommandusms' }
                },
                ['USMSGranger'] = {
                    label = 'USMS Granger',
                    model = 'USMSGranger',
                    price = 25000,
                    oneTimePurchase = true,
                    requiredGrade = 0,
                    livery = -1,
                    allowedJobs = { 'usmarshal' },
                    requiredItem = { 'badgevehusmsnew', 'badgehighcommandusms' }
                },
                ['USMSPatriot'] = {
                    label = 'USMS Patriot',
                    model = 'USMSPatriot',
                    price = 25000,
                    oneTimePurchase = true,
                    requiredGrade = 0,
                    livery = -1,
                    allowedJobs = { 'usmarshal' },
                    requiredItem = { 'badgevehusmsnew', 'badgehighcommandusms' }
                },
                ['USMSCoach'] = {
                    label = 'USMS Coach',
                    model = 'USMSCoach',
                    price = 25000,
                    oneTimePurchase = true,
                    requiredGrade = 0,
                    livery = -1,
                    allowedJobs = { 'usmarshal' },
                    requiredItem = { 'badgevehusmsnew', 'badgehighcommandusms' }
                },
                ['USMSRumpo'] = {
                    label = 'USMS Rumpo',
                    model = 'USMSRumpo',
                    price = 25000,
                    oneTimePurchase = true,
                    requiredGrade = 0,
                    livery = -1,
                    allowedJobs = { 'usmarshal' },
                    requiredItem = { 'badgevehusmsnew', 'badgehighcommandusms' }
                },
                ['umkscout'] = {
                    label = 'USMS Scout',
                    model = 'umkscout',
                    price = 25000,
                    oneTimePurchase = true,
                    requiredGrade = 0,
                    livery = -1,
                    allowedJobs = { 'usmarshal' },
                    requiredItem = { 'badgevehusmsnew', 'badgehighcommandusms' }
                },
                ['swatvanr2'] = {
                    label = 'USMS SWAT Van',
                    model = 'swatvanr2',
                    price = 25000,
                    oneTimePurchase = true,
                    requiredGrade = 0,
                    livery = -1,
                    allowedJobs = { 'usmarshal' },
                    requiredItem = { 'badgevehusmsnew', 'badgehighcommandusms' }
                },
                ['polgt17'] = {
                    label = 'USMS GT17',
                    model = 'polgt17',
                    price = 25000,
                    oneTimePurchase = true,
                    requiredGrade = 0,
                    livery = -1,
                    allowedJobs = { 'usmarshal' },
                    requiredItem = { 'badgevehusmsnew', 'badgehighcommandusms' }
                },
                ['nkgauntlet4'] = {
                    label = 'USMS Gauntlet 4',
                    model = 'nkgauntlet4',
                    price = 25000,
                    oneTimePurchase = true,
                    requiredGrade = 0,
                    livery = -1,
                    allowedJobs = { 'usmarshal' },
                    requiredItem = { 'badgevehusmsnew', 'badgehighcommandusms' }
                },
                ['gl_m3adro'] = {
                    label = 'USMS M3adro',
                    model = 'gl_m3adro',
                    price = 25000,
                    oneTimePurchase = true,
                    requiredGrade = 0,
                    livery = -1,
                    allowedJobs = { 'usmarshal' },
                    requiredItem = { 'badgevehusmsnew', 'badgehighcommandusms' }
                },
            }
        },
    },
}
