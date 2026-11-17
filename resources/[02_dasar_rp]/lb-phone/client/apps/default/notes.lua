RegisterNUICallback("Notes", function(data, cb)
    if not currentPhone then
        return
    end
    local action = data.action
    debugprint("Notes:" .. (action or ""))
    if data.data then
        data = data.data
    end
    if action == "create" then
        TriggerCallback("notes:createNote", cb, data.title, data.content)
    elseif action == "save" then
        TriggerCallback("notes:saveNote", cb, data.id, data.title, data.content)
    elseif action == "fetch" then
        TriggerCallback("notes:getNotes", cb)
    elseif action == "remove" then
        TriggerCallback("notes:removeNote", cb, data.id)
    end
end)
