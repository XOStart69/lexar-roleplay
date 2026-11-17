local FRAME_ID = 'browser'
local resourceName = GetCurrentResourceName()

local MEDIA_HOST = 'satumedia.gate-smrp.site'

local ANIM_DICT = 'amb@code_human_in_bus_passenger_idles@female@tablet@idle_a'
local ANIM_NAME = 'idle_a'
local PROP_MODEL = `prop_cs_tablet`

local isOpen = false
local animActive = false
local tabletProp

local function stopTabletAnim()
    if not animActive then return end

    animActive = false

    local ped = PlayerPedId()

    if tabletProp then
        if DoesEntityExist(tabletProp) then
            DetachEntity(tabletProp, true, true)
            DeleteEntity(tabletProp)
        end

        tabletProp = nil
    end

    StopAnimTask(ped, ANIM_DICT, ANIM_NAME, 1.0)
    ClearPedTasks(ped)

    RemoveAnimDict(ANIM_DICT)
    SetModelAsNoLongerNeeded(PROP_MODEL)
end

local function playTabletAnim()
    stopTabletAnim()

    local ped = PlayerPedId()

    if not pcall(lib.requestAnimDict, ANIM_DICT, 5000) then return end
    if not pcall(lib.requestModel, PROP_MODEL, 5000) then return end

    local coords = GetEntityCoords(ped)
    tabletProp = CreateObject(PROP_MODEL, coords.x, coords.y, coords.z, true, true, false)

    SetEntityAsMissionEntity(tabletProp, true, true)
    AttachEntityToEntity(tabletProp, ped, GetPedBoneIndex(ped, 28422), -0.05, 0.0, 0.0, 0.0, -90.0, 0.0, true, true,
        false, true, 1, true)

    TaskPlayAnim(ped, ANIM_DICT, ANIM_NAME, 3.0, 3.0, -1, 49, 0, false, false, false)

    animActive = true
end

local nuiReady = false

local function sendFrameInit()
    SendNUIMessage({
        __frameInit = true,
        frameId = FRAME_ID,
        resourceName = resourceName,
    })
end

local function beginHandshake()
    CreateThread(function()
        local attempts = 0

        while not nuiReady and attempts < 60 do
            attempts += 1

            sendFrameInit()

            Wait(250)
        end
    end)
end

---@param state boolean
local function setFocus(state)
    isOpen = state

    SetNuiFocus(state, state)
end

---@param url string
---@param title? string
---@param anim? boolean play the tablet prop animation while the browser is open
---@return boolean
local function open(url, title, anim)
    if type(url) ~= 'string' or url:find('^https?://[^%s/]+') ~= 1 then return false end

    local message = {
        action = 'setBrowserUrl',
        data = { url = url, title = title },
    }

    setFocus(true)

    if nuiReady then
        SendNUIMessage(message)
    else
        CreateThread(function()
            local attempts = 0

            while isOpen and not nuiReady and attempts < 100 do
                attempts += 1

                sendFrameInit()

                Wait(50)
            end

            if isOpen then SendNUIMessage(message) end
        end)
    end

    if url:find(MEDIA_HOST, 1, true) then
        TriggerEvent('sm_media_notify:opened')
    end

    if anim then
        CreateThread(playTabletAnim)
    end

    return true
end

---@param force? boolean
local function close(force)
    if not isOpen and not force then return end

    SendNUIMessage({ action = 'closeBrowser', data = {} })
    setFocus(false)
    stopTabletAnim()
end

RegisterNUICallback(('%s:exit'):format(FRAME_ID), function(_, cb)
    close()
    cb({})
end)

RegisterNetEvent('sm_nui_browser:open', function(url, title, anim)
    if source == '' then return end

    open(url, title, anim)
end)

RegisterNetEvent('sm_nui_browser:close', function()
    if source == '' then return end

    close()
end)

exports('open', open)
exports('close', close)
exports('isOpen', function()
    return isOpen
end)

RegisterNUICallback(('%s:ready'):format(FRAME_ID), function(_, cb)
    nuiReady = true
    cb({})
end)

beginHandshake()

AddEventHandler('onResourceStop', function(resource)
    if resource ~= resourceName then return end

    if isOpen then setFocus(false) end

    stopTabletAnim()
end)
