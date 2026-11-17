local TABLET_MODEL = `prop_cs_tablet`
local TABLET_DICT = 'amb@code_human_in_bus_passenger_idles@female@tablet@base'
local SCAN_RADIUS = 2.0
local UNKNOWN = 'TIDAK DIKETAHUI'

local tablet = 0
local scanning = false

local function removeTablet()
    ClearPedSecondaryTask(cache.ped)

    if tablet ~= 0 and DoesEntityExist(tablet) then
        DetachEntity(tablet, true, false)
        DeleteEntity(tablet)
    end

    tablet = 0
end

local function holdTablet()
    if not lib.requestAnimDict(TABLET_DICT, 2000) or not lib.requestModel(TABLET_MODEL, 2000) then return end

    local ped = cache.ped
    tablet = CreateObject(TABLET_MODEL, 0.0, 0.0, 0.0, true, true, false)

    AttachEntityToEntity(tablet, ped, GetPedBoneIndex(ped, 60309), 0.03, 0.002, -0.0, 10.0, 160.0, 0.0, true, false, false, false, 2, true)
    TaskPlayAnim(ped, TABLET_DICT, 'base', 3.0, 3.0, -1, 49, 0, false, false, false)
    SetModelAsNoLongerNeeded(TABLET_MODEL)
    RemoveAnimDict(TABLET_DICT)
end

---@param text string
---@param label string
local function copy(text, label)
    lib.setClipboard(text)
    lib.notify({ description = label, type = 'success' })
end

local showSummary

---@param data table
local function showDetail(data)
    local info = data.charinfo
    local name = ('%s %s'):format(info.firstname, info.lastname)
    local bloodType = data.metadata.bloodtype or UNKNOWN
    local birthdate = info.birthdate or UNKNOWN
    local nationality = info.nationality or UNKNOWN
    local gender = info.gender == 0 and 'LAKI-LAKI' or 'PEREMPUAN'
    local phone = info.phone or 'TIDAK TERDAFTAR'
    local fingerprint = data.metadata.fingerprint

    lib.registerContext({
        id = 'sm_fingerprint:detail',
        title = 'Detail Biometrik - ' .. name,
        menu = 'sm_fingerprint:summary',
        options = {
            {
                title = 'Identitas',
                description = ('Nama: %s\nCitizen ID: %s\nState ID: %s'):format(name, data.citizenid, data.source),
                icon = 'fa-solid fa-id-card',
                onSelect = function()
                    copy(data.citizenid, 'Citizen ID Copied: ' .. data.citizenid)
                end,
            },
            {
                title = 'Data Biometrik',
                description = ('Fingerprint: %s\nGolongan Darah: %s'):format(fingerprint, bloodType),
                icon = 'fa-solid fa-microscope',
                onSelect = function()
                    copy(('%s | %s'):format(fingerprint, bloodType), 'Biometric Data Copied')
                end,
            },
            {
                title = 'Informasi Personal',
                description = ('Tanggal Lahir: %s\nJenis Kelamin: %s\nKewarganegaraan: %s\nNo. Telepon: %s'):format(birthdate, gender, nationality, phone),
                icon = 'fa-solid fa-user',
                onSelect = function()
                    copy(('%s | %s | %s | %s'):format(birthdate, gender, nationality, phone), 'Personal Info Copied')
                end,
            },
            {
                title = 'Kembali ke Menu Utama',
                description = 'Kembali ke menu fingerprint scanner',
                icon = 'fa-solid fa-arrow-left',
                onSelect = function()
                    showSummary(data)
                end,
            },
        },
    })

    lib.showContext('sm_fingerprint:detail')
end

---@param data table
function showSummary(data)
    local info = data.charinfo
    local name = ('%s %s'):format(info.firstname, info.lastname)
    local bloodType = data.metadata.bloodtype or UNKNOWN
    local fingerprint = data.metadata.fingerprint

    lib.registerContext({
        id = 'sm_fingerprint:summary',
        title = 'Fingerprint Scanner',
        options = {
            {
                title = 'Nama: ' .. name,
                description = ('Print ID: %s \nCitizen ID: %s \nState ID: %s \n\nKlik menu ini untuk copy print ID'):format(fingerprint, data.citizenid, data.source),
                icon = 'fa-solid fa-fingerprint',
                onSelect = function()
                    copy(fingerprint, 'Fingerprint Copied: ' .. fingerprint)
                    showSummary(data)
                end,
            },
            {
                title = 'Golongan Darah: ' .. bloodType,
                description = 'Informasi golongan darah dari hasil scan biometrik',
                icon = 'fa-solid fa-droplet',
                onSelect = function()
                    copy(bloodType, 'Blood Type Copied: ' .. bloodType)
                    showSummary(data)
                end,
            },
            {
                title = 'Detail Lengkap',
                description = 'Tampilkan semua informasi biometrik dan identitas',
                icon = 'fa-solid fa-list',
                onSelect = function()
                    showDetail(data)
                end,
            },
        },
    })

    lib.showContext('sm_fingerprint:summary')
end

RegisterNetEvent('sm_fingerprint:client:scan', function()
    if scanning then return end

    local target = lib.getClosestPlayer(GetEntityCoords(cache.ped), SCAN_RADIUS, false)

    if not target then
        return lib.notify({ description = 'Tidak ada orang yang cukup dekat untuk discan.', type = 'error' })
    end

    scanning = true
    holdTablet()

    local done = lib.progressBar({
        duration = 5000,
        label = 'Mencoba memindai sidik jari..',
        canCancel = true,
        disable = { car = true },
    })

    removeTablet()

    if not done then
        scanning = false
        return lib.notify({ description = 'cancel', type = 'error' })
    end

    local ok, data = pcall(lib.callback.await, 'sm_fingerprint:server:scan', false, GetPlayerServerId(target))
    scanning = false

    if ok and type(data) == 'table' then
        showSummary(data)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource or tablet == 0 then return end

    removeTablet()
end)
