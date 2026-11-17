interface.init()


local showingPhoto = false

local camera = require 'interface.rhd_photo_system.modules.camera'

local function showPreview(data)
    interface.send({
        action = 'openPhotoPreview',
        data = data
    })
    interface.focus(true, true)
end

local function takePhoto()
    local photo = camera()

    if not photo then
        return lib.notify({
            description = 'Gagal mengambil foto, coba lagi!',
            type = 'error'
        })
    end

    showPreview({
        id = photo.photoId,
        url = photo.url,
        description = '',
        editable = true
    })
end

lib.callback.register('rhd_photo_system:playPhotoAnim', function (imageUrl)
    local model = "prop_cs_polaroid"

    if showingPhoto then return end
    showingPhoto = true

    local origTxd = model
    local origTexName = "prop_temp_polaroid"
    local customTxd = "polaroid_runtime_txd"
    local customTex = "polaroid_runtime_tex"
    local coords = GetEntityCoords(cache.ped)

    if not pcall(function (...)
        return lib.requestModel(model)
    end) then return false end

    local duiObj = CreateDui(imageUrl, 1920, 1080)
    local duiHandle = GetDuiHandle(duiObj)

    local txd = CreateRuntimeTxd(customTxd)
    CreateRuntimeTextureFromDuiHandle(txd, customTex, duiHandle)
    AddReplaceTexture(origTxd, origTexName, customTxd, customTex)

    local timeout = 5
    local timeStart = GetGameTimer()

    repeat
        Wait(100)
    until IsDuiAvailable(duiObj) or (GetGameTimer() - timeStart) / 1000 > timeout

    local prop = CreateObject(model, coords.x, coords.y, coords.z + 0.2, true, true, true)

    AttachEntityToEntity(
        prop, cache.ped,
        GetPedBoneIndex(cache.ped, 28422),
        0.15, 0.055, -0.025,
        170.0, 0.0, -240.0,
        true, true, false, false, 1, true
    )

    local dict = "paper_1_rcm_alt1-9"
    pcall(lib.playAnim, cache.ped, dict, "player_one_dual-9", 3.0, 3.0, -1, 49, 0, 0, 0, 0)

    CreateThread(function ()
        while showingPhoto do
            if not IsEntityPlayingAnim(cache.ped, dict, "player_one_dual-9", 3) then
                ---@diagnostic disable-next-line: param-type-mismatch
                TaskPlayAnim(cache.ped, dict, "player_one_dual-9", 3.0, 3.0, -1, 49, 0, 0, 0, 0)
            end
            Wait(500)
        end

        StopAnimTask(cache.ped, dict, "player_one_dual-9", 1.0)
        DeleteEntity(prop)

        RemoveReplaceTexture(origTxd, origTexName)
        DestroyDui(duiObj)
    end)

    return true
end)

RegisterNetEvent('rhd_photo_system:useCamera', function ()
    if source == '' then return end

    takePhoto()
end)

RegisterNetEvent('rhd_photo_system:usePdCamera', function ()
    if source == '' then return end

    camera({ pd = true })
end)

RegisterNetEvent('rhd_photo_system:previewPhoto', function (data)
    if source == '' then return end

    local nuiData = {
        id = data.id,
        url = data.url,
        description = data.description,
    }

    showPreview(nuiData)
end)

RegisterNetEvent('rhd_photo_system:initAlbum', function (photos)
    if source == '' then return end

    interface.send({
        action = 'initAlbum',
        data = {
            photos = lib.array.map(photos, function (photo)
                return {
                    id = photo.photo_id,
                    url = photo.url,
                    description = photo.description
                }
            end)
        }
    })
end)

RegisterNetEvent('rhd_photo_system:openAlbum', function ()
    if source == '' then return end
    interface.send({
        action = 'openPhotoAlbum',
        data = {}
     })
     interface.focus(true, true)
end)

RegisterNetEvent('rhd_photo_system:addPhotoToAlbum', function (photo)
    if source == '' then return end

    interface.send({
        action = 'addPhotoAlbum',
        data = {
            photo = photo
        }
    })
end)

interface.callback('editDescription', function(data, cb)
    CreateThread(function()
        local editType = data.editType or 'inventory'
        local success = lib.callback.await('rhd_photo_system:updateDescription', 1500, editType, data)

        if success then
            interface.send({
                action = 'updatePhotoData',
                data = {
                     id = data.id,
                     description = data.description
                }
            })
        end

        cb({ success = success })
    end)
end)

interface.callback('resetFocus', function (body, cb)
    interface.focus(false, false)

    if showingPhoto then
        showingPhoto = false
    end

    cb({ success = true })
end)

interface.callback('removeFromAlbum', function (data, cb)
    CreateThread(function()
        cb({ success = lib.callback.await('rhd_photo_system:removePhotoFromAlbum', 1500, data, true) })
    end)
end)

interface.callback('deletePhoto', function (data, cb)
    CreateThread(function()
        cb({ success = lib.callback.await('rhd_photo_system:removePhotoFromAlbum', 1500, data) })
    end)
end)

interface.callback('sharePhoto', function (data, cb)
    CreateThread(function()
        cb({ success = lib.callback.await('rhd_photo_system:sharePhoto', 1500, data.photo) })
    end)
end)