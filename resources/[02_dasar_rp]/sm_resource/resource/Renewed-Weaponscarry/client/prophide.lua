local Prophide = localmodule 'modules.prophide'

---@param enabled boolean
local function notify(enabled)
    lib.notify({
        title = 'Render Prop',
        description = enabled
            and 'Prop di punggung player lain disembunyikan. Cuma di layar kamu.'
            or 'Prop di punggung player lain dirender lagi seperti biasa.',
        type = enabled and 'info' or 'success'
    })
end

---@param enabled boolean
local function apply(enabled)
    Prophide.setEnabled(enabled)
    Prophide.refresh()
    notify(enabled)
end

RegisterCommand('prophide', function()
    apply(true)
end, false)

RegisterCommand('propshow', function()
    apply(false)
end, false)

TriggerEvent('chat:addSuggestion', '/prophide', 'Sembunyikan prop/senjata di punggung player lain biar FPS ga drop (cuma di layar kamu)')
TriggerEvent('chat:addSuggestion', '/propshow', 'Render ulang prop di punggung player lain')

CreateThread(function()
    Wait(1000)

    Prophide.refresh()

    if Prophide.isEnabled() then
        notify(true)
    end
end)

exports('IsPropHidden', Prophide.isEnabled)
