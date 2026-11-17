---@type IDCARD_CONFIG
local config = {
    image = 'ktp_background.png',
    stamp = true,
    stamp_path = 'ttd_cap.png',
    signature = true,
    userProfile = true,
    textColor = 'black',
    description = {},
    outline = '#ED6F00'
}

---@type IDCARD_FIELD[]
local fields = {
    {
        id = 'id_karyawan',
        kind = 'data',
        label = 'ID Karyawan',
        input = {
            type = 'text',
            label = 'ID Karyawan',
            required = true,
        }
    },
    {
        id = 'spacer_1',
        kind = 'spacer',
    },
    {
        kind = 'data',
        id = 'name',
        label = 'Nama',
        input = {
            type = 'text',
            label = 'Nama Lengkap',
            disabled = true,
            editable = true,
            generateFromServer = 'name'
        }
    },
    {
        kind = 'data',
        id = 'jobtitle',
        label = 'Jabatan',
        input = {
            type = 'text',
            label = 'Jabatan',
            disabled = true,
            editable = true,
            generateFromServer = 'jobtitle'
        }
    },
    {
        kind = 'data',
        id = 'tanggal_lahir',
        label = 'Tanggal Lahir',
        input = {
            type = 'date',
            label = 'Tanggal Lahir',
            disabled = true,
            editable = true,
            generateFromServer = 'dob',
        }
    },
    {
        kind = 'data',
        id = 'kewarganegaraan',
        label = 'kewarganegaraan',
        input = {
            type = 'text',
            label = 'kewarganegaraan',
            disabled = true,
            generateFromServer = 'citizenship',
        }
    },
    {
        kind = 'data',
        id = 'createdate',
        label = 'Dikeluarkan',
        input = {
            type = 'date',
            label = 'Dikeluarkan',
            default = true,
            disabled = true,
            editable = true
        }
    },
    {
        kind = 'data',
        id = 'expired',
        label = 'Berlaku hingga',
        input = {
            type = 'date',
            label = 'Berlaku Hingga',
            default = true,
            required = true
        }
    },
    {
        kind = 'data',
        id = 'createdby',
        label = 'Diterbitkan Oleh',
        input = {
            type = 'text',
            label = 'Diterbitkan Oleh',
            disabled = true,
            generateFromServer = 'releasedBy'
        }
    }
}

local function getConfig(t)
    return tbl.map(config, function (value, key)
        if t[key] then
            value = t[key]
        end
        return value
    end)
end

local template = {}

template.kta_reporter = {
    config = getConfig({
        image = 'ktamedia_background.png',
        description = {
            { text = 'KARTU ANGGOTA SATU MEDIA', size = 'sm', bold = false }
        },
    }),
    fields = fields
}

template.kta_mechanic = {
    config = getConfig({
        image = 'kta_tekno.png',
        description = {
            { text = 'KARTU ANGGOTA TEKNO GARAGE', size = 'sm', bold = false }
        },
        outline = '#23DBE8'
    }),
    fields = fields
}

template.kta_pabrik = {
    config = getConfig({
        image = 'kta_pabrik.png',
        description = {
            { text = 'KARTU ANGGOTA SUMBER REZEKI', size = 'sm', bold = false }
        },
    }),
    fields = fields
}

template.kta_taxi = {
    config = getConfig({
        image = 'ktataxi_background.png',
        description = {
            { text = 'KARTU ANGGOTA PINK PANDA', size = 'sm', bold = false }
        },
        outline = '#F76DAB'
    }),
    fields = fields
}

template.kta_taxism = {
    config = getConfig({
        image = 'ktataxism_background.png',
        description = {
            { text = 'KARTU ANGGOTA SMGO', size = 'sm', bold = false }
        },
        outline = 'FFE1D822'
    }),
    fields = fields
}

template.kta_doj = {
    config = getConfig({
        image = 'kta_doj.png',
        description = {
            { text = 'KARTU ANGGOTA DOJ', size = 'sm', bold = false }
        },
        outline = '#0D2E07'
    }),
    fields = fields
}

template.kta_usms = {
    config = getConfig({
        image = 'kta_usms.png',
        description = {
            { text = 'KARTU ANGGOTA USMS', size = 'sm', bold = false }
        },
        outline = '#0D2E07'
    }),
    fields = fields
}

template.kta_statebar = {
    config = getConfig({
        image = 'kta_statebar.png',
        description = {
            { text = 'STATE BAR OF SAN ANDREAS', size = 'sm', bold = false }
        },
        outline = '#6B5418'
    }),
    fields = fields
}

template.kta_police = {
    config = getConfig({
        image = 'kta_smpdbackground.png',
        description = {
            { text = 'KARTU ANGGOTA POLICE DEPARTMENT', size = 'sm', bold = false }
        },
        outline = '#0D2E07'
    }),
    fields = fields
}

template.kta_criminal = {
    config = getConfig({
        image = 'kta_criminal.png',
        description = {
            { text = 'KARTU ANGGOTA CRIMINAL INV', size = 'sm', bold = false }
        },
        outline = '#1A0A0A'
    }),
    fields = fields
}

template.kta_detective = {
    config = getConfig({
        image = 'kta_detective.png',
        description = {
            { text = 'KARTU ANGGOTA DETECTIVE', size = 'sm', bold = false }
        },
        outline = '#1A1A0A'
    }),
    fields = fields
}

template.kta_fib = {
    config = getConfig({
        image = 'kta_fib.png',
        description = {
            { text = 'KARTU ANGGOTA FIB', size = 'sm', bold = false }
        },
        outline = '#0A1A0A'
    }),
    fields = fields
}

template.kta_lspd = {
    config = getConfig({
        image = 'kta_lspd.png',
        description = {
            { text = 'KARTU ANGGOTA LSPD', size = 'sm', bold = false }
        },
        outline = '#0D2E07'
    }),
    fields = fields
}

template.kta_sheriff = {
    config = getConfig({
        image = 'kta_sheriff.png',
        description = {
            { text = 'KARTU ANGGOTA SHERIFF', size = 'sm', bold = false }
        },
        outline = '#2E1A07'
    }),
    fields = fields
}

template.kta_smsp = {
    config = getConfig({
        image = 'kta_smsp.png',
        description = {
            { text = 'KARTU ANGGOTA SMSP', size = 'sm', bold = false }
        },
        outline = '#07202E'
    }),
    fields = fields
}

template.kta_sort = {
    config = getConfig({
        image = 'kta_sort.png',
        description = {
            { text = 'KARTU ANGGOTA SORT', size = 'sm', bold = false }
        },
        outline = '#1A071A'
    }),
    fields = fields
}

template.kta_specialrespon = {
    config = getConfig({
        image = 'kta_specialrespon.png',
        description = {
            { text = 'KARTU ANGGOTA SPECIAL RESPONSE', size = 'sm', bold = false }
        },
        outline = '#2E0707'
    }),
    fields = fields
}

template.kta_specialweapon = {
    config = getConfig({
        image = 'kta_specialweapon.png',
        description = {
            { text = 'KARTU ANGGOTA SPECIAL WEAPON', size = 'sm', bold = false }
        },
        outline = '#07072E'
    }),
    fields = fields
}

template.kta_ambulance = {
    config = getConfig({
        image = 'kta_ems.png',
        description = {
            { text = 'KARTU ANGGOTA MEDIS', size = 'sm', bold = false }
        },
        outline = '#23DBE8'
    }),
    fields = fields
}

template.kta_government = {
    config = getConfig({
        image = 'kta_govbackground.png',
        description = {
            { text = 'KARTU ANGGOTA GOVERNMENT OF LOS SANTOS', size = 'sm', bold = false }
        },
        outline = '#4DFFCD'
    }),
    fields = fields
}

template.kta_969_garage = {
    config = getConfig({
        image = 'kta_969_garage.png',
        description = {
            { text = 'KARTU ANGGOTA 969 GARAGE', size = 'sm', bold = false }
        },
        outline = '#000000'
    }),
    fields = fields
}

template.kta_969_resto = {
    config = getConfig({
        image = 'kta_969_resto.png',
        description = {
            { text = 'KARTU ANGGOTA 969 RESTO', size = 'sm', bold = false }
        },
        outline = '#f7942e'
    }),
    fields = fields
}

template.kta_resto = {
    config = getConfig({
        image = 'kta_resto.png',
        description = {
            { text = 'KARTU ANGGOTA RESTO', size = 'sm', bold = false }
        },
        outline = '#f7942e'
    }),
    fields = fields
}

template.kta_kungkungkap = {
    config = getConfig({
        image = 'kta_kungkungkap.png',
        description = {
            { text = 'KARTU ANGGOTA KUNGKUNGKAP', size = 'sm', bold = false }
        },
        outline = '#f7942e'
    }),
    fields = fields
}

template.kta_max_speed = {
    config = getConfig({
        image = 'kta_max_speed.png',
        description = {
            { text = 'KARTU ANGGOTA MAX SPEED GARAGE', size = 'sm', bold = false }
        },
        outline = '#ffffff'
    }),
    fields = fields
}

template.kta_rs_roxwood = {
    config = getConfig({
        image = 'kta_rs_roxwood.png',
        description = {
            { text = 'KARTU ANGGOTA ROX WOOD HOSPITAL', size = 'sm', bold = false }
        },
        outline = '#ccae34'
    }),
    fields = fields
}

template.kta_stunberg = {
    config = getConfig({
        image = 'kta_stunberg.png',
        description = {
            { text = 'KARTU ANGGOTA STUNBERG GARAGE', size = 'sm', bold = false }
        },
        outline = '#ffffff'
    }),
    fields = fields
}

template.kta_atomburger = {
    config = getConfig({
        image = 'kta_atomburger.png',
        description = {
            { text = 'KARTU ANGGOTA ATOM BURGER', size = 'sm', bold = false }
        },
        outline = '#ffffff'
    }),
    fields = fields
}

template.kta_digitalden_roxwood = {
    config = getConfig({
        image = 'kta_digitalden_roxwood.png',
        description = {
            { text = 'KARTU ANGGOTA DIGITALDEN ROXWOOD', size = 'sm', bold = false }
        },
        outline = '#ffffff'
    }),
    fields = fields
}

template.kta_rainhart = {
    config = getConfig({
        image = 'kta_rainhart.png',
        description = {
            { text = 'KARTU ANGGOTA RAINHART', size = 'sm', bold = false }
        },
        outline = '#ffffff'
    }),
    fields = fields
}

template.kta_maxclub = {
    config = getConfig({
        image = 'kta_maxclub.png',
        description = {
            { text = 'KARTU ANGGOTA MAX CLUB', size = 'sm', bold = false }
        },
        outline = '#ffffff'
    }),
    fields = fields
}

template.kta_yclub = {
    config = getConfig({
        image = 'kta_yclub.png',
        description = {
            { text = 'KARTU ANGGOTA ECLUB', size = 'sm', bold = false }
        },
        outline = '#ffffff'
    }),
    fields = fields
}

template.kta_kedai_ygm = {
    config = getConfig({
        image = 'kta_kedai_ygm.png',
        description = {
            { text = 'KARTU ANGGOTA ECL Kedai', size = 'sm', bold = false }
        },
        outline = '#ffffff'
    }),
    fields = fields
}

template.kta_wartel = {
    config = getConfig({
        image = 'kta_wartel.png',
        description = {
            { text = 'KARTU ANGGOTA WARTEL', size = 'sm', bold = false }
        },
        outline = '#ffffff'
    }),
    fields = fields
}

template.kta_smmotel = {
    config = getConfig({
        image = 'kta_smmotel.png',
        description = {
            { text = 'KARTU ANGGOTA SM MOTEL', size = 'sm', bold = false }
        },
        outline = '#ffffff'
    }),
    fields = fields
}

template.kta_paud = {
    config = getConfig({
        image = 'kta_paud.png',
        description = {
            { text = 'KARTU ANGGOTA SCHOOL KIDS', size = 'sm', bold = false }
        },
        outline = '#ffffff'
    }),
    fields = fields
}

template.kta_digitaldenroxwood = {
    config = getConfig({
        image = 'kta_digitaldenroxwood.png',
        description = {
            { text = 'KARTU ANGGOTA DIGITALDEN ROXWOOD', size = 'sm', bold = false }
        },
        outline = '#ffffff'
    }),
    fields = fields
}

template.kta_ygmcenter = {
    config = getConfig({
        image = 'kta_ygmcenter.png',
        description = {
            { text = 'KARTU ANGGOTA YGM CENTER', size = 'sm', bold = false }
        },
        outline = '#ffffff'
    }),
    fields = fields
}

template.kta_kkpgarage = {
    config = getConfig({
        image = 'kta_kkpgarage.png',
        description = {
            { text = 'KARTU ANGGOTA KKP GARAGE', size = 'sm', bold = false }
        },
        outline = '#ffffff'
    }),
    fields = fields
}

return template