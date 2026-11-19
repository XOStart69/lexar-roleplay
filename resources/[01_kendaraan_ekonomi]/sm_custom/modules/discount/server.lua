local data = lib.load('data.pricing')

---@class DiscountServer
local discount = {}

---@param code any
---@return table
function discount.check(code)
    if type(code) ~= 'string' then return { ok = false, reason = 'Kode kosong' } end

    local codes = data.codes or {}
    local entry = codes[code:upper()]

    if not entry then return { ok = false, reason = 'Kode tidak berlaku' } end

    if entry.expires and entry.expires < os.time() then
        return { ok = false, reason = 'Kode kedaluwarsa' }
    end

    return { ok = true, percent = entry.percent or 0, label = entry.label or code }
end

return discount
