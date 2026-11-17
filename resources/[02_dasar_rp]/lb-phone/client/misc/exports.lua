exports("ToggleHomeIndicator", function(toggle)
    SendNUIAction("toggleShowHomeIndicator", toggle)
end)

exports("ToggleLandscape", function(toggle)
    SendNUIAction("toggleLandscape", toggle)
end)

exports("OpenApp", function(name, metadata)
    SendNUIAction("setApp", {
        name = name,
        metadata = metadata
    })
end)

exports("CloseApp", function(data)
    if not data then
        data = {}
    end

    debugprint("CloseApp: " .. (data.app or "nil") .. ", closeCompletely: " .. tostring(data.closeCompletely))

    SendNUIAction("closeApp", {
        app = data.app,
        closeCompletely = data.closeCompletely == true
    })
end)

local hiddenApps = {}

function GetHiddenApps()
    return hiddenApps
end

exports("SetAppHidden", function(app, hidden)
    hiddenApps[app] = hidden == true
    SendNUIAction("app:setHidden", {
        app = app,
        hidden = hidden == true
    })
end)

exports("SetAppInstalled", function(app, installed)
    SendNUIAction("app:setInstalled", {
        app = app,
        installed = installed == true
    })
end)
