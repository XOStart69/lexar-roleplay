local uiActions = SmPets.uiActions
local petTypes = SmPets.petTypes

local SetTimeout = SetTimeout
local sformat = string.format

---@param data table|false
---@return table|nil
local function decorate(data)
    if not data then return nil end
    for i = 1, #data.rows do
        local row = data.rows[i]
        local petType = petTypes[row.type]
        row.image = SmPets.imageFor(petType and petType.image or 'placeholder')
    end
    return data
end

RegisterNetEvent('sm_pets:client:openAdmin', function()
    local data = decorate(lib.callback.await('sm_pets:admin:list', false, '', 0))
    if not data then return SmPets.notify('Kamu tidak punya akses Pet Manager.', 'error') end
    SmPets.openUI('admin', data)
end)

uiActions.adminList = function(data)
    local result = decorate(lib.callback.await('sm_pets:admin:list', false, data.search or '', data.page or 0))
    if not result then return { ok = false } end
    result.ok = true
    return result
end

uiActions.adminDelete = function(data)
    local ok = lib.callback.await('sm_pets:admin:delete', false, data.id)
    SmPets.notify(ok and 'Pet dihapus.' or 'Gagal menghapus pet.', ok and 'success' or 'error')
    return { ok = ok == true }
end

uiActions.adminRestore = function(data)
    local ok = lib.callback.await('sm_pets:admin:restore', false, data.id)
    SmPets.notify(ok and 'Pet dipulihkan.' or 'Gagal memulihkan pet (mungkin sedang dikeluarkan).', ok and 'success' or 'error')
    return { ok = ok == true }
end

lib.callback.register('sm_pets:client:transferPrompt', function(data)
    if SmPets.ui.open then SmPets.closeUI() end
    local seconds = data.seconds or 30
    local closed = false
    SetTimeout(seconds * 1000, function()
        if not closed then lib.closeAlertDialog() end
    end)
    local fee = data.fee and data.fee > 0 and sformat('\n\nBiaya transfer: **$%d** (dibayar tunai).', data.fee) or ''
    local answer = lib.alertDialog({
        header = 'Terima Pet?',
        content = sformat('%s ingin memberikan **%s** (%s) kepadamu.%s', data.from, data.pet, data.type, fee),
        centered = true,
        cancel = true,
        labels = { confirm = 'Terima', cancel = 'Tolak' },
    })
    closed = true
    return answer == 'confirm'
end)
