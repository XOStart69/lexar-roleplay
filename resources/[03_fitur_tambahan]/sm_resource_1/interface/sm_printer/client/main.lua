local config = localmodule 'config.shared'
local exportWrapper = require 'export_wrapper'
local hasFrame = interface.init(false)

local Wait = Wait
local GetEntityCoords = GetEntityCoords
local SetEntityCoords = SetEntityCoords
local SetEntityHeading = SetEntityHeading
local PlaceObjectOnGroundProperly = PlaceObjectOnGroundProperly
local SetEntityDrawOutline = SetEntityDrawOutline
local IsControlJustReleased = IsControlJustReleased
local IsDisabledControlJustReleased = IsDisabledControlJustReleased
local DisableControlAction = DisableControlAction
local GetFinalRenderedCamCoord = GetFinalRenderedCamCoord
local GetFinalRenderedCamRot = GetFinalRenderedCamRot
local StartExpensiveSynchronousShapeTestLosProbe = StartExpensiveSynchronousShapeTestLosProbe
local GetShapeTestResult = GetShapeTestResult
local GetInvokingResource = GetInvokingResource
local DoesEntityExist = DoesEntityExist
local DeleteEntity = DeleteEntity
local mathSin = math.sin
local mathCos = math.cos
local mathAbs = math.abs
local mathRad = math.rad
local mathFloor = math.floor
local pairs = pairs

local interactDistance = config.interactDistance
local spawnDistance = config.spawnDistance
local placeDistance = config.placeDistance
local printerModels = config.printerModels
local maxPaper = config.maxPaper
local maxCopies = config.maxCopies
local msPerPage = config.waitPerPage * 1000

local INTERACT_PREFIX = 'sm_printer_'
local MODEL_IMAGE = 'https://gta-objects.xyz/gallery/objects/%s.jpg'

local printers = {}
local loaded = false
local placing = false

---@param message string
---@param nType string?
local function notify(message, nType)
    lib.notify({ title = 'Printer', description = message, type = nType or 'info' })
end

---@param group string?
---@return boolean
local function isMember(group)
    local job = QBPlayerData.job
    return group ~= nil and job ~= nil and job.name == group
end

---@param ink number
---@return string
local function inkColor(ink)
    if ink >= 75 then return 'green' end
    if ink >= 50 then return 'yellow' end
    if ink >= 25 then return 'orange' end
    return 'red'
end

---@param id number
local function supplyMenu(id)
    local storage = lib.callback.await('sm_printer:server:getStorage', false, id)
    if not storage then
        return notify('Gagal membaca isi printer.', 'error')
    end

    local paper, ink = storage.paper or 0, storage.ink or 0

    lib.registerContext({
        id = 'sm_printer_supply',
        title = 'Kertas & Tinta',
        options = {
            {
                title = ('Kertas: %d lembar'):format(paper),
                icon = 'file',
                description = 'Klik untuk isi ulang',
                readOnly = paper >= maxPaper,
                onSelect = function()
                    local ok, amount = lib.callback.await('sm_printer:server:refill', false, id, 'paper')
                    if ok then notify(('Menambah %d lembar kertas.'):format(amount), 'success') end
                end,
            },
            {
                title = ('Tinta: %d%%'):format(ink),
                icon = 'pen-nib',
                colorScheme = inkColor(ink),
                progress = ink,
                description = 'Klik untuk ganti tinta',
                readOnly = ink > 0,
                onSelect = function()
                    if lib.callback.await('sm_printer:server:refill', false, id, 'ink') then
                        notify('Tinta diisi penuh.', 'success')
                    end
                end,
            },
        },
    })
    lib.showContext('sm_printer_supply')
end

---@param id number
local function printDocument(id)
    local input = lib.inputDialog('Printer', {
        { type = 'input', label = 'Judul', description = 'Judul dokumen', required = true, max = 64 },
        { type = 'input', label = 'Deskripsi', description = 'Deskripsi dokumen', max = 256 },
        { type = 'input', label = 'Link', description = 'Link gambar yang dicetak', required = true, max = 512 },
        { type = 'number', label = 'Salinan', description = 'Jumlah salinan', min = 1, max = maxCopies, default = 1, required = true },
    })
    if not input then return end

    local copies = mathFloor(tonumber(input[4]) or 0)
    if copies < 1 or copies > maxCopies then return end

    if not lib.callback.await('sm_printer:server:startPrint', false, id, copies) then
        return notify('Tidak bisa memakai printer ini.', 'error')
    end

    if not lib.progressCircle({
        label = 'Mencetak...',
        duration = copies * msPerPage,
        position = 'bottom',
        canCancel = false,
        disable = { car = true },
    }) then return end

    local result = lib.callback.await('sm_printer:server:completePrint', false, input[1], input[2], input[3])
    if result == 'given' then
        notify('Print selesai.', 'success')
    elseif result == 'queued' then
        notify('Print selesai, ambil hasilnya di printer.', 'success')
    else
        notify('Print gagal.', 'error')
    end
end

---@param printer table
---@return table
local function buildOptions(printer)
    local id = printer.id
    local group = printer.group
    local public = printer.public
    local prefix = printer.kind == 'coords' and ('[%s] '):format(printer.model) or ''

    local function canUse()
        return public or isMember(group)
    end

    local function canManage()
        return isMember(group)
    end

    return {
        {
            name = 'sm_printer_print',
            label = prefix .. 'Print',
            icon = 'fa-solid fa-print',
            distance = interactDistance,
            canInteract = canUse,
            onSelect = function() printDocument(id) end,
        },
        {
            name = 'sm_printer_collect',
            label = prefix .. 'Ambil Hasil Print',
            icon = 'fa-solid fa-check',
            distance = interactDistance,
            canInteract = canUse,
            onSelect = function()
                if lib.callback.await('sm_printer:server:collect', false, id) then
                    notify('Hasil print diambil.', 'success')
                end
            end,
        },
        {
            name = 'sm_printer_stash',
            label = prefix .. 'Buka Laci Printer',
            icon = 'fa-solid fa-box-open',
            distance = interactDistance,
            canInteract = canManage,
            onSelect = function()
                ox_inventory:openInventory('stash', { id = ('printer_%s'):format(id) })
            end,
        },
        {
            name = 'sm_printer_supply',
            label = prefix .. 'Kertas & Tinta',
            icon = 'fa-solid fa-gear',
            distance = interactDistance,
            canInteract = canManage,
            onSelect = function() supplyMenu(id) end,
        },
    }
end

---@param point table
local function spawnObject(point)
    local printer = point.printer
    if printer.entity then return end

    local model = joaat(printer.model)
    if not pcall(lib.requestModel, model, 5000) then return end
    if printers[printer.id] ~= printer or printer.entity or point.currentDistance and point.currentDistance > spawnDistance then
        SetModelAsNoLongerNeeded(model)
        return
    end

    local coords = printer.coords
    local entity = CreateObject(model, coords.x, coords.y, coords.z, false, false, false)
    SetModelAsNoLongerNeeded(model)
    SetEntityHeading(entity, printer.heading)
    PlaceObjectOnGroundProperly(entity)
    FreezeEntityPosition(entity, true)

    printer.entity = entity
    exports.rhd_interact:addLocalEntity(entity, printer.options)
end

---@param point table
local function despawnObject(point)
    local printer = point.printer
    local entity = printer.entity
    if not entity then return end

    printer.entity = nil
    exports.rhd_interact:removeLocalEntity(entity)
    if DoesEntityExist(entity) then
        DeleteEntity(entity)
    end
end

---@param id number
local function removePrinter(id)
    local printer = printers[id]
    if not printer then return end

    printers[id] = nil

    if printer.kind == 'coords' then
        exports.rhd_interact:removeCoords(INTERACT_PREFIX .. id)
        return
    end

    local point = printer.point
    if point then
        despawnObject(point)
        point:remove()
    end
end

---@param data table
local function addPrinter(data)
    local id = data.id
    if printers[id] then removePrinter(id) end

    local raw = data.coords
    local printer = {
        id = id,
        kind = data.kind,
        model = data.model,
        coords = vec3(raw.x, raw.y, raw.z),
        heading = data.heading or 0.0,
        group = data.group,
        public = data.public == true,
    }
    printer.options = buildOptions(printer)
    printers[id] = printer

    if printer.kind == 'coords' then
        exports.rhd_interact:addCoords({
            id = INTERACT_PREFIX .. id,
            coords = printer.coords,
            options = printer.options,
        })
        return
    end

    printer.point = lib.points.new({
        coords = printer.coords,
        distance = spawnDistance,
        printer = printer,
        onEnter = spawnObject,
        onExit = despawnObject,
    })
end

local function clearAll()
    for id in pairs(printers) do
        removePrinter(id)
    end
end

---@param list table
local function syncAll(list)
    clearAll()
    loaded = true
    for i = 1, #list do
        addPrinter(list[i])
    end
end

local function loadAll()
    if loaded then return end
    local list = lib.callback.await('sm_printer:server:getAll', false)
    if list then syncAll(list) end
end

---@param distance number
---@return vector3 origin
---@return vector3 target
local function cameraRay(distance)
    local rot = GetFinalRenderedCamRot(2)
    local rx, rz = mathRad(rot.x), mathRad(rot.z)
    local cosX = mathAbs(mathCos(rx))
    local origin = GetFinalRenderedCamCoord()
    return origin, origin + vec3(-mathSin(rz) * cosX, mathCos(rz) * cosX, mathSin(rx)) * distance
end

---@param modelName string
---@return vector3?
---@return number?
local function placeObject(modelName)
    if placing then return end

    local model = joaat(modelName)
    if not pcall(lib.requestModel, model, 5000) then return end

    placing = true
    local ghost = CreateObject(model, 0.0, 0.0, 0.0, false, false, false)
    SetModelAsNoLongerNeeded(model)
    SetEntityAlpha(ghost, 150, false)
    SetEntityCollision(ghost, false, false)
    FreezeEntityPosition(ghost, true)

    infoUI.show({
        id = 'sm_printer_place',
        title = 'Pasang Printer',
        icon = 'fa-solid fa-print',
        description = '[kbd]E[/kbd] Pasang  [kbd]X[/kbd] Batal  [kbd]Scroll[/kbd] Putar',
    })

    local heading = 0.0
    local outlined = false
    local resultCoords, resultHeading
    local rayLength = placeDistance + 5.0

    while placing do
        DisableControlAction(0, 14, true)
        DisableControlAction(0, 15, true)
        DisableControlAction(0, 24, true)

        local origin, target = cameraRay(rayLength)
        local probe = StartExpensiveSynchronousShapeTestLosProbe(origin.x, origin.y, origin.z, target.x, target.y, target.z, 1, cache.ped, 4)
        local _, hit, coords = GetShapeTestResult(probe)

        if hit == 1 then
            SetEntityCoords(ghost, coords.x, coords.y, coords.z, false, false, false, false)
            SetEntityHeading(ghost, heading)
            PlaceObjectOnGroundProperly(ghost)

            local valid = #(GetEntityCoords(cache.ped) - coords) < placeDistance
            if valid == outlined then
                outlined = not valid
                SetEntityDrawOutline(ghost, outlined)
            end

            if valid and IsControlJustReleased(0, 38) then
                resultCoords = GetEntityCoords(ghost)
                resultHeading = heading
                placing = false
            end
        end

        if IsControlJustReleased(0, 73) then
            placing = false
        elseif IsDisabledControlJustReleased(0, 14) then
            heading = (heading + 5.0) % 360
        elseif IsDisabledControlJustReleased(0, 15) then
            heading = (heading - 5.0) % 360
        end

        Wait(0)
    end

    infoUI.remove('sm_printer_place')
    if DoesEntityExist(ghost) then
        DeleteEntity(ghost)
    end

    return resultCoords, resultHeading
end

---@return boolean
local function askPublic()
    return lib.alertDialog({
        header = 'Akses Publik?',
        content = 'Izinkan semua orang memakai printer ini untuk mencetak?',
        centered = true,
        cancel = true,
        labels = { cancel = 'Hanya Job', confirm = 'Publik' },
    }) == 'confirm'
end

---@param kind string
---@param model string
---@param coords vector3
---@param heading number
local function submitPrinter(kind, model, coords, heading)
    local created = lib.callback.await('sm_printer:server:create', false, {
        kind = kind,
        model = model,
        coords = coords,
        heading = heading,
        public = askPublic(),
    })

    if created then
        notify('Printer ditambahkan.', 'success')
    else
        notify('Gagal menambahkan printer.', 'error')
    end
end

local function chooseModelMenu()
    local options = {}

    for i = 1, #printerModels do
        local name = printerModels[i]
        options[i] = {
            title = name,
            image = MODEL_IMAGE:format(name),
            onSelect = function()
                local coords, heading = placeObject(name)
                if coords then submitPrinter('object', name, coords, heading) end
            end,
        }
    end

    lib.registerContext({
        id = 'sm_printer_models',
        title = 'Pilih Model Printer',
        menu = 'sm_printer_main',
        options = options,
    })
    lib.showContext('sm_printer_models')
end

local function addCoordsPrinter()
    local input = lib.inputDialog('Printer di Koordinat', {
        { type = 'input', label = 'Nama', required = true, default = 'Printer Station', max = 40 },
        { type = 'number', label = 'X', required = true },
        { type = 'number', label = 'Y', required = true },
        { type = 'number', label = 'Z', required = true },
    })
    if not input then return end

    submitPrinter('coords', input[1], vec3(input[2], input[3], input[4]), 0.0)
end

local function addPrinterHere()
    local coords = GetEntityCoords(cache.ped)
    local input = lib.inputDialog('Printer di Lokasi Ini', {
        { type = 'input', label = 'Nama', required = true, default = 'Printer Station', max = 40 },
        { type = 'checkbox', label = 'Atur koordinat manual', checked = false },
    })
    if not input then return end

    if input[2] then
        local adjusted = lib.inputDialog('Atur Koordinat', {
            { type = 'number', label = 'X', required = true, default = mathFloor(coords.x * 100) / 100 },
            { type = 'number', label = 'Y', required = true, default = mathFloor(coords.y * 100) / 100 },
            { type = 'number', label = 'Z', required = true, default = mathFloor(coords.z * 100) / 100 },
        })
        if adjusted then
            coords = vec3(adjusted[1], adjusted[2], adjusted[3])
        end
    end

    submitPrinter('coords', input[1], coords, 0.0)
end

local viewPrinters

---@param entry table
local function confirmDelete(entry)
    local answer = lib.alertDialog({
        header = 'Hapus Printer?',
        content = 'Printer dan isi lacinya akan dihapus permanen.',
        centered = true,
        cancel = true,
        labels = { cancel = 'Kembali', confirm = 'Hapus' },
    })
    if answer ~= 'confirm' then return end

    if not lib.callback.await('sm_printer:server:delete', false, entry.id) then
        return notify('Gagal menghapus printer.', 'error')
    end

    notify('Printer dihapus.', 'success')
    viewPrinters()
end

function viewPrinters()
    local list = lib.callback.await('sm_printer:server:listOwned', false)
    if not list or not list[1] then
        return notify('Belum ada printer untuk job ini.')
    end

    local options = {}
    for i = 1, #list do
        local entry = list[i]
        local isCoords = entry.kind == 'coords'
        options[i] = {
            title = (isCoords and '[Titik] ' or '') .. entry.model,
            image = not isCoords and MODEL_IMAGE:format(entry.model) or nil,
            icon = isCoords and 'location-dot' or nil,
            description = ('Kertas: %d  \nTinta: %d%%'):format(entry.paper or 0, entry.ink or 0),
            onSelect = function() confirmDelete(entry) end,
        }
    end

    lib.registerContext({
        id = 'sm_printer_list',
        title = 'Daftar Printer',
        menu = 'sm_printer_main',
        options = options,
    })
    lib.showContext('sm_printer_list')
end

local function openMenu()
    lib.registerContext({
        id = 'sm_printer_main',
        title = 'Kelola Printer',
        options = {
            { title = 'Printer Fisik Baru', icon = 'plus', description = 'Pasang objek printer', onSelect = chooseModelMenu },
            { title = 'Printer di Koordinat', icon = 'map-marker-alt', description = 'Titik printer tanpa objek di koordinat tertentu', onSelect = addCoordsPrinter },
            { title = 'Printer di Sini', icon = 'location-arrow', description = 'Titik printer tanpa objek di posisimu', onSelect = addPrinterHere },
            { title = 'Daftar Printer', icon = 'print', description = 'Lihat dan hapus printer job', onSelect = viewPrinters },
        },
    })
    lib.showContext('sm_printer_main')
end

local viewerOpen = false
local viewerMounted = false
local viewerReady = false
local pendingLink

local function sendDocument()
    local link = pendingLink
    pendingLink = nil
    interface.send({ action = 'show', data = { url = link } })
    interface.focus(true, true)
end

local function closeViewer()
    if not viewerOpen then return end

    viewerOpen = false
    pendingLink = nil
    interface.focus(false, false)

    SetTimeout(50, function()
        if viewerOpen or not viewerMounted then return end

        viewerMounted = false
        viewerReady = false
        interface.hide()
    end)
end

---@param link string
local function openDocument(link)
    if not hasFrame or viewerOpen then return end

    viewerOpen = true
    pendingLink = link

    if viewerReady then
        return sendDocument()
    end

    if not viewerMounted then
        viewerMounted = true
        interface.show()
    end
end

if hasFrame then
    interface.callback('ready', function(_, cb)
        viewerReady = true
        if viewerOpen and pendingLink then
            sendDocument()
        end
        cb('ok')
    end)

    interface.callback('closed', function(_, cb)
        cb('ok')
        closeViewer()
    end)
end

AddEventHandler('sm_printer:client:forceClose', function()
    if not viewerOpen then return end
    if viewerReady then
        interface.send({ action = 'close' })
    end
    closeViewer()
end)

exportWrapper('sm_printer', 'printerdocument', function(_, slot)
    local link = slot and slot.metadata and slot.metadata.imagelink
    if type(link) ~= 'string' or link == '' then return end

    openDocument(link)
end)

RegisterNetEvent('sm_printer:client:openMenu', function()
    if GetInvokingResource() then return end
    openMenu()
end)

RegisterNetEvent('sm_printer:client:sync', function(list)
    if GetInvokingResource() or not playerState.isLoggedIn then return end
    syncAll(list)
end)

RegisterNetEvent('sm_printer:client:add', function(data)
    if GetInvokingResource() or not loaded then return end
    addPrinter(data)
end)

RegisterNetEvent('sm_printer:client:remove', function(id)
    if GetInvokingResource() or not loaded then return end
    removePrinter(id)
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', loadAll)

CreateThread(function()
    if playerState.isLoggedIn then loadAll() end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end
    placing = false
    infoUI.remove('sm_printer_place')
    clearAll()
end)
