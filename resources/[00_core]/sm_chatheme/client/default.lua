RegisterNetEvent('chat:show', function()
    if not ConfigLoaded then return end

    SetNuiFocus(true, true)
    SendVueMessage('SHOW_CHAT', {})
end)

RegisterNetEvent("chat:addSuggestion")
AddEventHandler("chat:addSuggestion", function(command, help, params)
    SendVueMessage("ADD_SUGGESTION", {
        name = string.gsub(command, "/", ""),
        help = help,
        params = params,
    })
end)

RegisterNetEvent("chat:addSuggestions")
AddEventHandler("chat:addSuggestions", function(suggestions)
    for _, v in ipairs(suggestions) do
        SendVueMessage("ADD_SUGGESTION", {
            name = string.gsub(v.name, "/", ""),
            help = v.help,
            params = v.params,
        })
    end
end)

RegisterNetEvent('__cfx_internal:serverPrint')
AddEventHandler('__cfx_internal:serverPrint', function(msg)
    print(msg)
end)