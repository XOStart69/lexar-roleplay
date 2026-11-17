local placementPromise = nil

RegisterNUICallback("savePlacement", function(data, cb)
    if placementPromise then
        local centerPoint = GetCenterPoint(CurrentHome)
        local entityCoords = GetEntityCoords(lastSelected.entity)
        local entityRotation = GetEntityRotation(lastSelected.entity)
        local entityModel = GetEntityModel(lastSelected.entity)
        local placementData = {
            model = entityModel,
            offset = {
                x = round(entityCoords.x - centerPoint.x, 4),
                y = round(entityCoords.y - centerPoint.y, 4),
                z = round(entityCoords.z - centerPoint.z, 4),
            },
            rotation = {
                x = round(entityRotation.x, 2),
                y = round(entityRotation.y, 2),
                z = round(entityRotation.z, 2),
            },
        }

        for modelName, itemData in pairs(FurnitureModelList) do
            if GetHashKey(modelName) == entityModel then
                placementData.label = itemData.label
            end
        end

        placementPromise:resolve(placementData)
        placementPromise = nil
    end

    cb("ok")
end)

local function setBedroomState(bedroom)
    exports.bob74_ipl:SetIplPropState(121346, { "bedroom1", "bedroom2", "bedroom3" }, false, true)
    exports.bob74_ipl:SetIplPropState(121346, bedroom, true)
end