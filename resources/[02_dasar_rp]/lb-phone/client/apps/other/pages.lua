RegisterNUICallback("YellowPages", function(data, cb)
    local action = data.action
    debugprint("Pages:" .. (action or ""))
    if action == "getPosts" then
        TriggerCallback("yellowPages:getPosts", cb, data)
    elseif action == "sendPost" then
        TriggerCallback("yellowPages:createPost", cb, data.data)
    elseif action == "deletePost" then
        TriggerCallback("yellowPages:deletePost", cb, data.id)
    end
end)

RegisterNetEvent("phone:yellowPages:newPost", function(data)
    TriggerEvent("lb-phone:pages:newPost", data)
    SendNUIAction("yellowPages:newPost", data)
end)
