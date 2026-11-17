local dev = {
    entities = {},
    selected_bone_id = nil,
    is_busy = false,
    bone_selector_active = false,
    bone_selector_position = nil,
    bone_selector_promise = nil,
    bone_category = nil
}

local entities = {}

local ped_bones = localmodule 'data.ped_bone'

local POSITION_STEP = 0.01
local ROTATION_STEP = 0.5
local STEP_INCREMENT = 0.01
local ROTATION_INCREMENT = 0.1
local MARKER_SIZE = 0.15

local CONTROLS = {
    COPY = 38,      -- E
    FINISH = 194,      -- Backspace
    UP = 172,          -- Arrow Up
    DOWN = 173,        -- Arrow Down
    LEFT = 174,        -- Arrow Left
    RIGHT = 175,       -- Arrow Right
    SHIFT = 21,        -- Left Shift
    SCROLL_UP = 15,    -- Mouse Scroll Up
    SCROLL_DOWN = 14,  -- Mouse Scroll Down
    NUMPAD_PLUS = 314, -- Numpad +
    NUMPAD_MINUS = 315, -- Numpad -
    Delete = 178
}

local CONTROL_INSTRUCTIONS = [[
X       : ← →
Y       : Mouse Scroll ↑↓
Z       : ↑↓
RX      : Shift + ←→
RY      : Shift + Scroll ↑↓
RZ      : Shift + ↑↓
Step    : %s (Numpad + or -)
Finish  : Backspace
Copy    : E
]]

local TABLE_TEMPLATE = [[
{
    boneId = %s,
    pos = vec(%.2f, %.2f, %.2f),
    rot = vec(%.2f, %.2f, %.2f),
}
]]

---@param results table
---@return string|nil
local function formatAttachmentData(results)
    if not results then
        return 'No data'
    end

    local bone, hash, coords, rotation in results

    if not coords or not rotation or not hash then
        return 'No data'
    end

    return TABLE_TEMPLATE:format(
        bone,
        coords.x, coords.y, coords.z,
        rotation.x, rotation.y, rotation.z
    )
end

---@param controls table
local function disableAllControls(controls)
    for _, control_id in pairs(controls) do
        DisableControlAction(0, control_id, true)
    end
end

local function createCacheEntity(data, isObject)
    local entity

    local hash, bone, coords, rotation in data
    
    if isObject then
        entity = CreateObject(hash, 0, 0, 0, false, false, false)
    else
        entity = CreateWeaponObject(hash, 50, 0, 0, 0, true, 1.0, 0)
    end

    AttachEntityToEntity(
        entity, cache.ped, bone,
        coords.x, coords.y, coords.z,
        rotation.x, rotation.y, rotation.z,
        true, true, false, true, 2, true
    )

    entities[#entities+1] = entity
end

local function deleteCacheEntity()
    local count = #entities

    if not entities[count] then
        lib.print.info('Tidak ada cache')
        return
    end

    pcall(DeleteEntity, entities[count])
    table.remove(entities, count)
end

---@param step number
---@param increment number
---@param min_value? number
---@param max_value? number
---@return number
local function adjustStep(step, increment, min_value, max_value)
    local new_step = step + increment

    if min_value and new_step < min_value then
        return min_value
    end

    if max_value and new_step > max_value then
        return max_value
    end

    return new_step
end

---@param hash string
---@param boneIndex? number
---@return string|unknown
function dev:getAttachmentData(hash, boneIndex, isObject)
    local bone_id = boneIndex or self.selected_bone_id
    local ped_coords = GetEntityCoords(cache.ped)

    local entity
    
    if isObject then
        entity = CreateObject(hash, ped_coords.x, ped_coords.y, ped_coords.z, false, false, false)
    else
        entity = CreateWeaponObject(hash, 50, ped_coords.x, ped_coords.y, ped_coords.z, true, 1.0, 0)
    end

    print(entity)
    self.entities[#self.entities + 1] = entity
    local position = {x = 0.0, y = 0.0, z = 0.0}
    local rotation = {x = 0.0, y = 0.0, z = 0.2}
    local position_step = POSITION_STEP
    local rotation_step = ROTATION_STEP

    self.is_busy = true

    lib.showTextUI(CONTROL_INSTRUCTIONS:format(position_step), { position = 'right-center' })

    CreateThread(function()
        while self.is_busy do
            disableAllControls(CONTROLS)

            local is_shift_pressed = IsDisabledControlPressed(0, CONTROLS.SHIFT)

            if IsDisabledControlJustPressed(0, CONTROLS.NUMPAD_PLUS) then
                position_step = adjustStep(position_step, STEP_INCREMENT, 0.001, 1.0)
                rotation_step = adjustStep(rotation_step, ROTATION_INCREMENT, 0.1, 10.0)
                lib.showTextUI(CONTROL_INSTRUCTIONS:format(position_step), { position = 'right-center' })
            elseif IsDisabledControlJustPressed(0, CONTROLS.NUMPAD_MINUS) then
                position_step = adjustStep(position_step, -STEP_INCREMENT, 0.001, 1.0)
                rotation_step = adjustStep(rotation_step, -ROTATION_INCREMENT, 0.1, 10.0)
                lib.showTextUI(CONTROL_INSTRUCTIONS:format(position_step), { position = 'right-center' })
            end

            if not is_shift_pressed then
                if IsDisabledControlPressed(0, CONTROLS.LEFT) then 
                    position.x = position.x - position_step 
                end
                if IsDisabledControlPressed(0, CONTROLS.RIGHT) then 
                    position.x = position.x + position_step 
                end
                if IsDisabledControlPressed(0, CONTROLS.UP) then 
                    position.z = position.z + position_step 
                end
                if IsDisabledControlPressed(0, CONTROLS.DOWN) then 
                    position.z = position.z - position_step 
                end
                if IsDisabledControlPressed(0, CONTROLS.SCROLL_UP) then 
                    position.y = position.y + position_step 
                end
                if IsDisabledControlPressed(0, CONTROLS.SCROLL_DOWN) then 
                    position.y = position.y - position_step 
                end
            else
                if IsDisabledControlPressed(0, CONTROLS.LEFT) then 
                    rotation.x = rotation.x + rotation_step 
                end
                if IsDisabledControlPressed(0, CONTROLS.RIGHT) then 
                    rotation.x = rotation.x - rotation_step 
                end
                if IsDisabledControlPressed(0, CONTROLS.UP) then 
                    rotation.z = rotation.z + rotation_step 
                end
                if IsDisabledControlPressed(0, CONTROLS.DOWN) then 
                    rotation.z = rotation.z - rotation_step 
                end
                if IsDisabledControlPressed(0, CONTROLS.SCROLL_UP) then 
                    rotation.y = rotation.y + rotation_step 
                end
                if IsDisabledControlPressed(0, CONTROLS.SCROLL_DOWN) then 
                    rotation.y = rotation.y - rotation_step 
                end
            end

            if IsDisabledControlJustPressed(0, CONTROLS.Delete) then
                deleteCacheEntity()
            end

            if DoesEntityExist(entity) and bone_id and bone_id ~= -1 then
                AttachEntityToEntity(
                    entity, cache.ped, bone_id,
                    position.x, position.y, position.z,
                    rotation.x, rotation.y, rotation.z,
                    true, true, false, true, 2, true
                )
            end

            if IsDisabledControlJustPressed(0, CONTROLS.COPY) then
                local attachment_data = {
                    bone = bone_id,
                    hash = hash,
                    coords = position,
                    rotation = rotation
                }

                local formatted_result = formatAttachmentData(attachment_data)

                lib.setClipboard(formatted_result)
                lib.notify({
                    description = 'Attachment code copied to clipboard!',
                    type = 'success'
                })

                local alert = lib.alertDialog({
                    header = 'Mau dibuat preview?',
                    content = 'jika iya, maka system akan membuat prop preview untuk penyesuaian berikutnya.',
                    centered = true,
                    cancel = true,
                    labels = {
                        confirm = 'Ya',
                        cancel = 'Tidak'
                    }
                })

                if alert == 'confirm' then
                    createCacheEntity(attachment_data, isObject)
                end
            end

            if IsDisabledControlJustPressed(0, CONTROLS.FINISH) then
                self.is_busy = false
                DeleteEntity(entity)
                lib.hideTextUI()
                break
            end

            Wait(0)
        end
    end)
end

---@return boolean
function dev:openBoneCategoryMenu()
    local menu_options = {}

    for category_name in pairs(ped_bones) do
        table.insert(menu_options, {
            label = category_name,
            args = { category = category_name }
        })
    end

    lib.registerMenu({
        id = 'bone_category_menu',
        title = 'Pilih Kategori Tulang',
        position = 'top-right',
        onClose = function()
            self.bone_selector_active = false
            if self.bone_selector_promise then
                self.bone_selector_promise:resolve(false)
            end
        end,
        options = menu_options
    }, function(selected, _, args)
        self.bone_category = args.category
        self:openBoneListMenu()
    end)

    self.bone_selector_active = true
    self.bone_selector_promise = promise.new()

    CreateThread(function()
        while self.bone_selector_active do
            if self.bone_selector_position and type(self.bone_selector_position) == "vector3" then
                DrawMarker(
                    28,
                    self.bone_selector_position.x,
                    self.bone_selector_position.y,
                    self.bone_selector_position.z,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    MARKER_SIZE, MARKER_SIZE, MARKER_SIZE,
                    255, 42, 24, 100,
                    false, false, 0, true, false, false, false
                )
            end
            Wait(1)
        end
    end)

    lib.showMenu('bone_category_menu')

    return Citizen.Await(self.bone_selector_promise)
end

function dev:openBoneListMenu()
    local menu_options = {}
    local bones_in_category = ped_bones[self.bone_category]

    for i = 1, #bones_in_category do
        local bone_name = bones_in_category[i]

        table.insert(menu_options, {
            label = bone_name,
            args = { bone = bone_name }
        })
    end

    lib.registerMenu({
        id = 'bone_list_menu',
        title = string.format('Tulang di %s', self.bone_category),
        position = 'top-right',
        onClose = function()
            self.bone_selector_position = nil
            lib.showMenu('bone_category_menu')
        end,
        onSelected = function(selected, secondary, args)
            local selected_bone = args.bone
            local bone_index = GetEntityBoneIndexByName(cache.ped, selected_bone)

            if bone_index ~= -1 then
                local bone_coords = GetWorldPositionOfEntityBone(cache.ped, bone_index)
                self.selected_bone_id = bone_index
                self.bone_selector_position = bone_coords
            end
        end,
        options = menu_options
    }, function(selected, _, args)
        self.bone_selector_active = false
        if self.bone_selector_promise then
            self.bone_selector_promise:resolve(true)
        end
    end)

    lib.showMenu('bone_list_menu')
end

RegisterNetEvent('dev:openWeaponAttacher', function()
    local input = lib.inputDialog('Weapon Attacher', {
        { type = 'input', label = 'Weapon Name (e.g weapon_pistol)', required = true },
        { type = 'number', label = 'Bone Index (Optional)' },
    })

    if not input or not input[1] then
        return lib.notify({ description = 'Input weapon harus diisi', type = 'error' })
    end

    local _, hash = pcall(function()
        return lib.requestWeaponAsset(input[1], 1500)
    end)

    if not (hash and hash ~= 0) then
        return lib.notify({ description = 'Model weapon tidak tersedia', type = 'error' })
    end

    local bone_index = input[2] and GetPedBoneIndex(cache.ped, input[2])

    if not bone_index or bone_index == -1 then
        if not dev:openBoneCategoryMenu() then return end
    end

    dev:getAttachmentData(hash, bone_index)
end)

RegisterNetEvent('dev:openObjectAttacher', function()
    local input = lib.inputDialog('Object Attacher', {
        { type = 'input', label = 'Model', required = true },
        { type = 'number', label = 'Bone Index (Optional)' },
    })

    if not input or not input[1] then
        return lib.notify({ description = 'Input model harus diisi', type = 'error' })
    end

    local _, hash = pcall(function()
        return lib.requestModel(input[1], 1500)
    end)

    if not (hash and hash ~= 0) then
        return lib.notify({ description = 'Model tidak tersedia', type = 'error' })
    end

    local bone_index = input[2] and GetPedBoneIndex(cache.ped, input[2])

    if not bone_index or bone_index == -1 then
        if not dev:openBoneCategoryMenu() then return end
    end

    dev:getAttachmentData(hash, bone_index, true)
end)

AddEventHandler('onResourceStop', function(resource_name)
    if resource_name == GetCurrentResourceName() then
        for i = 1, #dev.entities do
            local entity = dev.entities[i]
            pcall(DeleteEntity, entity)
        end
        dev.entities = {}
    end
end)