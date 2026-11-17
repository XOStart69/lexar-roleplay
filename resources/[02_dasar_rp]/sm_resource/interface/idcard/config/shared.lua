local config = {}

---@alias IDCARD_ITEMNAME
---| 'ktp'
---| 'ktp_palsu'
---| 'kta_reporter'

---@type table<IDCARD_ITEMNAME, IDCARD_DATA>
config.template = {}

Citizen.CreateThreadNow(function()
    local filename = {'ktp', 'ktp_palsu', 'kta', 'kia', 'kkes', 'license', 'dlicense', 'casino_member', 'badge'}

    for i=1, #filename do
        local path = ('interface.idcard.template.%s'):format(filename[i])
        tbl.merge(config.template, require(path))
    end
end)

return config