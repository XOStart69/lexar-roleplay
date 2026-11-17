RegisterNUICallback("Marketplace", function(data, cb)
    local action = data.action
    debugprint("Marketplace:" .. (action or ""))
    if action == "getPosts" then
        local posts = AwaitCallback("marketplace:getPosts", data)
        for i = 1, #posts do
            posts[i].attachments = json.decode(posts[i].attachments)
        end
        cb(posts)
    elseif action == "sendPost" then
        TriggerCallback("marketplace:createPost", cb, data.data)
    elseif action == "deletePost" then
        TriggerCallback("marketplace:deletePost", cb, data.id)
    end
end)

RegisterNetEvent("phone:marketplace:newPost", function(data)
    TriggerEvent("lb-phone:marketplace:newPost", data)
    SendNUIAction("marketPlace:newPost", data)
end)
