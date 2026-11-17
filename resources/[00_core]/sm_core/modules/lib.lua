---@source https://github.com/Qbox-project/qbx_core/blob/main/modules/lib.lua

local qbLib = {}

qbLib.table = {}
qbLib.string = {}
qbLib.math = {}
qbLib.array = {}


local isServer = lib.context == 'server'

if not isServer then
    qbLib.blip = require '@sm_core.modules.blip.client'
end

qbLib.armsWithoutGloves = lib.table.freeze({
    male = lib.table.freeze({
        [0] = true,
        [1] = true,
        [2] = true,
        [3] = true,
        [4] = true,
        [5] = true,
        [6] = true,
        [7] = true,
        [8] = true,
        [9] = true,
        [10] = true,
        [11] = true,
        [12] = true,
        [13] = true,
        [14] = true,
        [15] = true,
        [18] = true,
        [26] = true,
        [52] = true,
        [53] = true,
        [54] = true,
        [55] = true,
        [56] = true,
        [57] = true,
        [58] = true,
        [59] = true,
        [60] = true,
        [61] = true,
        [62] = true,
        [112] = true,
        [113] = true,
        [114] = true,
        [118] = true,
        [125] = true,
        [132] = true
    }),

    female = lib.table.freeze({
        [0] = true,
        [1] = true,
        [2] = true,
        [3] = true,
        [4] = true,
        [5] = true,
        [6] = true,
        [7] = true,
        [8] = true,
        [9] = true,
        [10] = true,
        [11] = true,
        [12] = true,
        [13] = true,
        [14] = true,
        [15] = true,
        [19] = true,
        [59] = true,
        [60] = true,
        [61] = true,
        [62] = true,
        [63] = true,
        [64] = true,
        [65] = true,
        [66] = true,
        [67] = true,
        [68] = true,
        [69] = true,
        [70] = true,
        [71] = true,
        [129] = true,
        [130] = true,
        [131] = true,
        [135] = true,
        [142] = true,
        [149] = true,
        [153] = true,
        [157] = true,
        [161] = true,
        [165] = true
    }),
})


qbLib.duffelbagIndexes = lib.table.freeze({
    male = lib.table.freeze({
        [40] = true,
        [41] = true,
        [44] = true,
        [45] = true,
        [81] = true,
        [82] = true,
        [85] = true,
        [86] = true,
        [130] = true,
        [131] = true,
        [132] = true
    }),
    female = lib.table.freeze({
        [40] = true,
        [41] = true,
        [44] = true,
        [45] = true,
        [81] = true,
        [82] = true,
        [85] = true,
        [86] = true,
        [131] = true,
        [132] = true,
        [133] = true
    })
})

---@param cb function Callback function to execute safely
---@param ... any Arguments to pass to callback
---@return any|nil result Returns callback result or nil on error
function qbLib.safecall(cb, ...)
    assert(type(cb) == 'function', 'safecall: callback must be a function')

    local success, result = pcall(cb, ...)

    if not success then
        local info = debug.getinfo(2, 'Sl')
        local source = info.source:match('^@?(.+)$') or info.source
        local line = info.currentline or 0

        lib.print.error(('safecall failed at %s:%d\n%s'):format(source, line, result))
        return nil
    end

    return result
end

---Returns the given string with its trailing whitespaces removed.
---@param str string
---@return string
function qbLib.string.trim(str)
    local trimmed = str:gsub('^%s*(.-)%s*$', '%1')
    return trimmed
end

---Returns true if the given string is nil, empty, or contains only whitespace.
---@param str string?
---@return boolean
function qbLib.string.isEmpty(str)
    return str == nil or str:match('^%s*$') ~= nil
end

---Returns the given string with its first character capitalized.
---@param str string
---@return string
function qbLib.string.capitalize(str)
    local capitalized = str:gsub('^%l', string.upper)
    return capitalized
end

---Returns the given string with its first character lowercased (camelCase start).
---@param str string
---@return string
function qbLib.string.uncapitalize(str)
    ---@diagnostic disable-next-line: redundant-return-value
    return str:gsub('^%u', string.lower)
end

---Rounds and returns the given number.
---@param num number
---@param decimalPlaces? integer
---@return number rounded integer if `decimalPlaces` isn't passed, number otherwise
function qbLib.math.round(num, decimalPlaces)
    if not decimalPlaces then return math.floor(num + 0.5) end
    local power = 10 ^ decimalPlaces
    return math.floor((num * power) + 0.5) / power
end

---@param t table<string, any>
---@param fn fun(val, key):any
function qbLib.table.find(t, fn)
    for k, v in pairs(t) do
        local f = fn and fn(v, k)

        if f then
            return v, k
        end
    end
end

---Returns a shallow copy of the given table (nested tables are not cloned).
---@param tbl table
---@return table
function qbLib.table.clone(tbl)
    local copy = {}
    for k, v in pairs(tbl) do
        copy[k] = v
    end
    return copy
end

---Returns a deep copy of the given table (all nested tables are recursively cloned).
---@param tbl table
---@return table
function qbLib.table.deepclone(tbl)
    local copy = {}
    for k, v in pairs(tbl) do
        if type(v) == 'table' then
            copy[k] = qbLib.table.deepclone(v)
        else
            copy[k] = v
        end
    end
    return copy
end

---Returns the number of items in a table. Useful for non-array tables.
---@param tbl table
---@return integer
function qbLib.table.size(tbl)
    local size = 0
    for _ in pairs(tbl) do
        size += 1
    end
    return size
end

---Maps and returns the values of the given table by the given subfield.
---@param tble table
---@param subfield any
---@return table<any, table[]>
function qbLib.table.mapBySubfield(tble, subfield)
    local map = {}

    for _, subTable in pairs(tble) do
        local subfieldValue = subTable[subfield]

        if subfieldValue then
            if not map[subfieldValue] then
                map[subfieldValue] = {}
            end

            map[subfieldValue][#map[subfieldValue] + 1] = subTable
        end
    end

    return map
end

---Returns the number plate of the given vehicle.
---@param vehicle integer
---@return string?
function qbLib.getVehiclePlate(vehicle)
    local plate = GetVehicleNumberPlateText(vehicle)
    if not plate then return end
    return qbLib.string.trim(plate)
end

---Generates and returns a random number plate with the given pattern.
---Note that the generated plate may or may not be already used by an existing vehicle.
---For more info about the pattern see [`lib.string.random`](https://coxdocs.dev/ox_lib/Modules/String/Shared#stringrandom) from ox_lib.
---@param pattern? string
---@return string
function qbLib.generateRandomPlate(pattern)
    pattern = pattern or '........'
    return lib.string.random(pattern):upper()
end

---Returns the cardinal direction that the given entity is staring towards, or nil if the entity doesn't exist.
---```
---                 North
---     45°           0°           315°
---       \    .- - - - - - -.    /
---          X                 X
---        .'   \           /   '.
---       |        \     /        |
--- West  |           X           |  East
---       |        /     \        |
---        '.   /           \   .'
---          X                 X
---       /    '- - - - - - -'    \
---     135°                      225°
---                 South
---```
---(art inspired by [`SET_PED_TURNING_THRESHOLDS`](https://github.com/citizenfx/fivem/blob/0b61c93a3308360ea70d443398eab17f47453e11/code/components/extra-natives-five/src/PedExtraNatives.cpp#L390-L400))
---@param entity integer
---@return 'North' | 'South' | 'East' | 'West'
function qbLib.getCardinalDirection(entity)
    -- heading is between 0 - 360 (excluding 360)
    local heading = GetEntityHeading(entity) % 360

    if heading < 45 or heading >= 315 then
        return 'North'
    end

    if heading >= 45 and heading < 135 then
        return 'West'
    end

    if heading >= 135 and heading < 225 then
        return 'South'
    end

    -- heading >= 225 and heading < 315
    return 'East'
end

---@param playerGroups PlayerJob
---@param job_table string|string[]|table<string, number|number[]>
---@param required_duty? boolean
---@return boolean
function qbLib.checkGroup(playerGroups, job_table, required_duty)
    if not playerGroups then return false end

    local jn = playerGroups.name
    local jt = playerGroups.type
    local jd = playerGroups.onduty
    local jg = playerGroups.grade.level

    if required_duty and not jd then
        return false
    end

    local tt = type(job_table)

    if tt == 'string' then
        return jn == job_table or jt == job_table
    end

    if tt == 'table' then
        if lib.array.isArray(job_table) then
            return lib.table.contains(job_table, jn) or lib.table.contains(job_table, jt)
        end

        local requirement = job_table[jn] or job_table[jt]
        if not requirement then return false end

        local rt = type(requirement)

        if rt == 'number' then
            return jg >= requirement
        end

        if rt == 'table' and lib.array.isArray(requirement) then
            return lib.table.contains(requirement, jg)
        end

        return false
    end

    return false
end

if isServer then
    ---@class LibSpawnVehicleParams
    ---@field model integer
    ---@field spawnSource integer | vector3 | vector4 ped id or coords
    ---@field warp? boolean | integer a ped id to warp inside the vehicle, or additionally a boolean if `spawnSource` is a ped
    ---@field props? table https://coxdocs.dev/ox_lib/Modules/VehicleProperties/Client#vehicle-properties
    ---@field bucket? integer routing bucket to move spawned entity to.

    ---Creates a vehicle on the server-side and returns its `netId`.
    ---
    ---The `CreateVehicleServerSetter` native uses only the server to create a vehicle instead of using the client as well.
    ---To get the vehicle on the client first check and wait for it to exist using the `NetworkDoesEntityExistWithNetworkId` native,
    ---then get the vehicle's id by using `NetToVeh`.
    --[[

    lib.waitFor(function()
        if NetworkDoesEntityExistWithNetworkId(netId) then
            return NetToVeh(netId)
        end
    end)
    ]]
    ---@param params LibSpawnVehicleParams
    ---@return integer netId
    ---@return number veh
    function qbLib.spawnVehicle(params)
        local model = params.model
        local source = params.spawnSource
        local sourceType = type(source)
        local warp = params.warp
        local ped = type(warp) == 'number' and warp or (sourceType == 'number' and warp and source or nil)
        local props = params.props
        local bucket = params.bucket or ped and GetEntityRoutingBucket(ped) or nil

        ---@type vector4
        local coords
        if sourceType == 'vector3' then
            coords = vec4(source.x, source.y, source.z, 0)
        elseif sourceType == 'vector4' then
            coords = source
        else
            local pedCoords = GetEntityCoords(source)
            coords = vec4(pedCoords.x, pedCoords.y, pedCoords.z, GetEntityHeading(source))
        end

        local vehData = exports.sm_core:GetVehiclesByHash(joaat(model))
        local vehicleType = vehData and vehData.type or nil

        if not vehicleType then
            warn(('No vehicle type found for model: %s temp vehicle was created and taken in type'):format(model))
            local tempVehicle = CreateVehicle(model, 0, 0, -200, 0, true, true)
            while not DoesEntityExist(tempVehicle) do Wait(0) end
            vehicleType = GetVehicleType(tempVehicle)
            DeleteEntity(tempVehicle)
        end

        local attempts = 0

        local veh, netId
        while attempts < 3 do
            veh = CreateVehicleServerSetter(model, vehicleType, coords.x, coords.y, coords.z, coords.w)

            if bucket and bucket > 0 then
                exports.sm_core:SetEntityBucket(veh, bucket)
            end

            while not DoesEntityExist(veh) do Wait(0) end
            while GetVehicleNumberPlateText(veh) == '' do Wait(0) end

            if ped then
                SetPedIntoVehicle(ped, veh, -1)
            end

            if not pcall(function()
                lib.waitFor(function()
                    local owner = NetworkGetEntityOwner(veh)
                    if ped then
                        --- the owner should be transferred to the driver
                        if owner == NetworkGetEntityOwner(ped) then return true end
                    else
                        if owner ~= -1 then return true end
                    end
                end, 'client never set as owner', 15000)
            end) then
                DeleteEntity(veh)
                error('Deleting vehicle which timed out finding an owner')
            end

            local state = Entity(veh).state
            local owner = NetworkGetEntityOwner(veh)
            state:set('initVehicle', true, true)
            netId = NetworkGetNetworkIdFromEntity(veh)
            if props and type(props) == 'table' and props.plate then
                TriggerClientEvent('sm_core:client:setVehicleProperties', owner, netId, props)
                local success = pcall(function()
                    local plateMatched = false
                    lib.waitFor(function()
                        if qbLib.string.trim(GetVehicleNumberPlateText(veh)) == qbLib.string.trim(props.plate) then
                            local currentOwner = NetworkGetEntityOwner(veh)
                            assert(currentOwner == owner, ('Owner changed during vehicle init. expected=%s, actual=%s'):format(owner, currentOwner))
                            --- check that the plate matches twice, 100ms apart as a bug has been observed in which server side matches but plate is not observed by clients to match
                            if plateMatched then
                                return true
                            end
                            plateMatched = true
                            Wait(100)
                        end
                    end, 'Failed to set vehicle properties within 5 second', 5000)
                end)
                if success then
                    break
                else
                    DeleteEntity(veh)
                    attempts += 1
                end
            else
                break
            end
        end

        if attempts == 3 then
            error('unable to successfully spawn vehicle after 3 attempts')
        end

        --- prevent server from deleting a vehicle without an owner
        SetEntityOrphanMode(veh, 2)
        return netId, veh
    end
else
    ---@class LibDrawTextParams
    ---@field text string
    ---@field scale? integer default: `0.35`
    ---@field font? integer default: `4`
    ---@field color? vector4 rgba, white by default
    ---@field enableDropShadow? boolean
    ---@field enableOutline? boolean

    ---@class LibDrawText2DParams : LibDrawTextParams
    ---@field coords vector2
    ---@field width? number default: `1.0`
    ---@field height? number default: `1.0`

    ---Draws text onto the screen in 2D space for a single frame.
    ---@param params LibDrawText2DParams
    function qbLib.drawText2d(params)
        local text = params.text
        local coords = params.coords
        local scale = params.scale or 0.35
        local font = params.font or 4
        local color = params.color or vec4(255, 255, 255, 255)
        local width = params.width or 1.0
        local height = params.height or 1.0
        local enableDropShadow = params.enableDropShadow or false
        local enableOutline = params.enableOutline or false

        SetTextScale(scale, scale)
        SetTextFont(font)
        SetTextColour(math.floor(color.r), math.floor(color.g), math.floor(color.b), math.floor(color.a))
        if enableDropShadow then
            SetTextDropShadow()
        end
        if enableOutline then
            SetTextOutline()
        end

        SetTextCentre(true)
        BeginTextCommandDisplayText('STRING')
        AddTextComponentSubstringPlayerName(text)
        EndTextCommandDisplayText(coords.x - width / 2, coords.y - height / 2 + 0.005)
    end

    ---@class LibDrawText3DParams : LibDrawTextParams
    ---@field coords vector3
    ---@field disableDrawRect? boolean
    ---@field scale? integer | vector2 default: `vec2(0.35,0.35)`

    ---Draws text onto the screen in 3D space for a single frame.
    ---@param params LibDrawText3DParams
    function qbLib.drawText3d(params) -- luacheck: ignore
        local isScaleparamANumber = type(params.scale) == "number"
        local text = params.text
        local coords = params.coords

        ---@diagnostic disable-next-line: param-type-mismatch
        local scale = (isScaleparamANumber and vec2(params.scale, params.scale))
        or params.scale
        or vec2(0.35, 0.35)

        local font = params.font or 4
        local color = params.color or vec4(255, 255, 255, 255)
        local enableDropShadow = params.enableDropShadow or false
        local enableOutline = params.enableOutline or false

        SetTextScale(scale.x, scale.y)
        SetTextFont(font)
        SetTextColour(math.floor(color.r), math.floor(color.g), math.floor(color.b), math.floor(color.a))
        if enableDropShadow then
            SetTextDropShadow()
        end
        if enableOutline then
            SetTextOutline()
        end
        SetTextCentre(true)
        BeginTextCommandDisplayText('STRING')
        AddTextComponentSubstringPlayerName(text)
        SetDrawOrigin(coords.x, coords.y, coords.z, 0)
        EndTextCommandDisplayText(0.0, 0.0)

        if not params.disableDrawRect then
            local factor = #text / 370
            DrawRect(0.0, 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 75)
        end
        ClearDrawOrigin()
    end

    ---Gets and returns an entity handle and network id from a state bag name
    ---([source](https://github.com/overextended/ox_core/blob/main/client/utils.lua)).
    ---Statebag handlers receive changes for every entity on the server, including
    ---entities outside this client's scope which will never exist locally. Those
    ---must return quietly instead of throwing, so the wait is short and guarded.
    ---@async
    ---@param bagName string
    ---@return integer? entity, integer? netId
    function qbLib.getEntityAndNetIdFromBagName(bagName)
        local netId = tonumber(bagName:gsub('entity:', ''), 10)
        if not netId then return end

        if NetworkDoesEntityExistWithNetworkId(netId) then
            return NetworkGetEntityFromNetworkId(netId), netId
        end

        local ok, entity = pcall(lib.waitFor, function()
            if NetworkDoesEntityExistWithNetworkId(netId) then
                return NetworkGetEntityFromNetworkId(netId)
            end
        end, nil, 1500)

        if not ok or not entity or entity == 0 then return end

        return entity, netId
    end

    ---Returns a state bag handler made for entities
    ---([source](https://github.com/overextended/ox_core/blob/main/client/utils.lua)).
    ---@param keyFilter string
    ---@param cb fun(entity: number, netId: number, value: any, bagName: string)
    ---@return number
    function qbLib.entityStateHandler(keyFilter, cb)
        return AddStateBagChangeHandler(keyFilter, '', function(bagName, _, value)
            local entity, netId = qbLib.getEntityAndNetIdFromBagName(bagName)
            if not entity or entity == 0 or not netId then return end

            cb(entity, netId, value, bagName)
        end)
    end

    ---Deletes the specified vehicle and returns whether it was successful.
    ---@param vehicle integer
    ---@return boolean deleted
    function qbLib.deleteVehicle(vehicle)
        SetEntityAsMissionEntity(vehicle, true, true)
        DeleteVehicle(vehicle)
        return not DoesEntityExist(vehicle)
    end

    ---Returns the model name of the given vehicle.
    ---@param vehicle integer
    ---@return string
    function qbLib.getVehicleDisplayName(vehicle)
        return GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)))
    end

    ---Returns the brand name of the given vehicle.
    ---@param vehicle integer
    ---@return string
    function qbLib.getVehicleMakeName(vehicle)
        return GetLabelText(GetMakeNameFromVehicleModel(GetEntityModel(vehicle)))
    end

    ---Returns the mod type name of the given vehicle.
    ---@param vehicle integer
    ---@param modType integer
    ---@param modIndex integer
    ---@return string
    function qbLib.getVehicleModName(vehicle, modType, modIndex)
        return GetLabelText(GetModTextLabel(vehicle, modType, modIndex))
    end

    ---Returns the livery name of the given vehicle.
    ---@param vehicle integer
    ---@param liveryIndex integer
    ---@return string
    function qbLib.getVehicleLiveryName(vehicle, liveryIndex)
        return GetLabelText(GetLiveryName(vehicle, liveryIndex))
    end

    ---Returns the street name and cross section name at the given coords.
    ---@param coords vector3
    ---@return { main: string, cross: string }
    function qbLib.getStreetName(coords)
        local street1, street2 = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
        return { main = GetStreetNameFromHashKey(street1), cross = GetStreetNameFromHashKey(street2) }
    end

    ---Returns the name of the zone at the given coords.
    ---@param coords vector3
    ---@return string
    function qbLib.getZoneName(coords)
        return GetLabelText(GetNameOfZone(coords.x, coords.y, coords.z))
    end

    ---Set an extra on the given vehicle.
    ---@param vehicle integer
    ---@param extra integer
    ---@param enable boolean
    function qbLib.setVehicleExtra(vehicle, extra, enable)
        if not DoesExtraExist(vehicle, extra) then return end
        SetVehicleExtra(vehicle, extra, not enable)
    end

    ---Enables all the extras of the given vehicle.
    ---@param vehicle integer
    function qbLib.resetVehicleExtras(vehicle)
        for i = 1, 20 do
            qbLib.setVehicleExtra(vehicle, i, true)
        end
    end

    ---Sets all the extras of the given vehicle.
    ---@param vehicle integer
    ---@param extras table<integer, boolean>
    function qbLib.setVehicleExtras(vehicle, extras)
        qbLib.resetVehicleExtras(vehicle)

        for id, enable in pairs(extras) do
            qbLib.setVehicleExtra(vehicle, id, enable)
        end
    end

    ---Returns if the local ped is wearing gloves.
    ---@return boolean
    function qbLib.isWearingGloves()
        local armIndex = GetPedDrawableVariation(cache.ped, 3)
        local model = GetEntityModel(cache.ped)
        local tble = qbLib.armsWithoutGloves[model == `mp_m_freemode_01` and 'male' or 'female']
        return not tble[armIndex]
    end

    --- Returns if the local ped is wearing a duffel bag.
    --- @return boolean
    function qbLib.isWearingDuffelbag()
        local torsoIndex = GetPedDrawableVariation(cache.ped, 5) -- Duffel bags are in component 5
        local model = GetEntityModel(cache.ped)
        local tble = qbLib.duffelbagIndexes[model == `mp_m_freemode_01` and 'male' or 'female']
        return tble[torsoIndex] == true
    end

    ---Attempts to load an audio bank and returns whether it was successful.
    ---Remember to use `ReleaseScriptAudioBank` since you can only load up to 10 banks.
    ---@param audioBank string
    ---@param timeout number?
    ---@return boolean
    function qbLib.loadAudioBank(audioBank, timeout)
        return lib.waitFor(function()
            if RequestScriptAudioBank(audioBank, false) then
                return true
            end
        end, ('timed out while requesting audio bank! (%s)'):format(audioBank), timeout or 500) or false
    end

    ---@class LibPlayAudioParams
    ---@field audioName string
    ---@field audioRef string
    ---@field returnSoundId? boolean
    ---@field audioSource? number | vector3 entity handle or vector3 coords
    ---@field range? number only used if `audioSource` is a vector3 coordinate

    ---@deprecated use mana_audio instead
    ---Plays a sound with the provided audio name and audio ref.
    ---If `returnSoundId` is false or not specified the soundId is released,
    ---otherwise the function returns the soundId without releasing it.
    ---@param params LibPlayAudioParams
    ---@return number? soundId
    function qbLib.playAudio(params)
        local audioName = params.audioName
        local audioRef = params.audioRef
        local returnSoundId = params.returnSoundId or false
        local source = params.audioSource
        local range = params.range or 5.0

        local soundId = GetSoundId()

        local sourceType = type(source)
        if sourceType == 'vector3' then
            local coords = source
            PlaySoundFromCoord(soundId, audioName, coords.x, coords.y, coords.z, audioRef, false, range, false)
        elseif sourceType == 'number' then
            PlaySoundFromEntity(soundId, audioName, source, audioRef, false, false)
        else
            PlaySoundFrontend(soundId, audioName, audioRef, true)
        end

        if returnSoundId then
            return soundId
        end

        ReleaseSoundId(soundId)
    end
end

_ENV.qbLib = qbLib