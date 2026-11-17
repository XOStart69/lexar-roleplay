local function createReedemInput()
    local input = lib.inputDialog('Buat kode reedem', {
        { type = 'input', label = 'Kode reedem', placeholder = 'xxxxxx', required = true },
        { type = 'number', label = 'Max reedem', min = 1, max = 10, default = 1 },
        { type = 'input', label = 'Nama item', required = true },
        { type = 'number', label = 'Jumlah item', default = 1, min = 1 }
    })

    if not input then return end
    if input[1]:isblank() then return end
    if input[3]:isblank() then return end

    local validItems = ox_items[input[3]]

    if not validItems then
        return lib.notify({
            description = ('Item %s tidak terdaftar di server'):format(input[3]),
            type = 'error'
        })
    end

    return {
        kode = input[1],
        maxReedem = input[2],
        itemname = input[3],
        itemcount = input[4]
    }
end

local function reedemCodeInput()
    local input = lib.inputDialog('Kode Reedem', {
        { type = 'input', label = 'Masukkan kode', placeholder = 'xxxx', required = true },
    })

    if not input then return end
    if input[1]:isblank() then return end
    
    local kodeReedem = input[1]
    TriggerTokenEvent('sm_reedemcode:reedem', kodeReedem)
end

local function createReedemList(code)
    local ctx = {
        id = 'reedem:listmenu',
        title = 'Daftar Kode',
        options = {
            {
                title = 'Buat baru',
                icon = 'fas fa-plus',
                description = 'Buat kode reedem baru',
                onSelect = function ()
                    local reedem_data = createReedemInput()
                    if not reedem_data then return end
                    TriggerTokenEvent('sm_reedemcode:create', reedem_data)
                end
            }
        }
    }

    print(code and type(code), json.encode(code, {indent = true}))
    if code and type(code) == "table" then
        for k, v in pairs(code) do
            print(k)
            ctx.options[#ctx.options+1] = {
                title = k,
                icon = 'fas fa-code',
                metadata = {
                    Pembuat = ('%s (%s)'):format(v.creator, v.identifier),
                    ['Max Reedem'] = v.maxReedem,
                    ['Dibuat Pada'] = v.created
                },
                description = 'Klik untuk menghapus',
                onSelect = function ()
                    local alert = lib.alertDialog({
                        header = 'Hapus Reedem Code',
                        content = 'Apakah kamu yakin mau hapus reedem code ini?',
                        centered = true,
                        cancel = true,
                        labels = {
                            confirm = 'Ya',
                            cancel = 'Tidak'
                        }
                    })

                    if alert == 'confirm' then
                        TriggerTokenEvent('sm_reedemcode:delete', k)
                    end
                end
            }
        end
    end

    lib.registerContext(ctx)
    lib.showContext('reedem:listmenu')
end

RegisterNetEvent('sm_reedemcode:reedem', function ()
    if source == '' then return end

    reedemCodeInput()
end)

RegisterNetEvent('sm_reedemcode:list', function (code)
    if source == '' then return end

    createReedemList(code)
end)