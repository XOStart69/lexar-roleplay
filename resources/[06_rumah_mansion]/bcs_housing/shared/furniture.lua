FurnitureImages = {}

local thumbnails = lib.loadJson("thumbnails") or {}

for model, image in pairs(thumbnails) do
    local modelKey = tostring(model)
    if Config.Screenshot == "offline" then
        FurnitureImages[modelKey] = "images/furnitures/" .. image .. ".png"
    else
        FurnitureImages[modelKey] = image
    end
end