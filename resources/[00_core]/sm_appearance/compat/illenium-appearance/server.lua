local outfits = require "server.outfits"
local shopConfig = require "config.shops"
local blacklist = require "server.blacklist"
local peds = require "server.peds"
local validate = require "server.validate"

---@type table<number, table>
local uniforms = {}

---@param shopType string
---@return number?
local function costOf(shopType)
    local cost = shopConfig.costs[shopType]

    return cost and cost > 0 and cost or nil
end

lib.callback.register("illenium-appearance:server:getAppearance", function(source, model)
    return exports[cache.resource]:getAppearance(source, model)
end)

lib.callback.register("illenium-appearance:server:GetPlayerAces", function(source)
    local names = {}

    blacklist.aceNames(names)
    peds.aceNames(names)

    local allowed = {}

    for ace in pairs(names) do
        if IsPlayerAceAllowed(source, ace) then
            allowed[#allowed + 1] = ace
        end
    end

    return allowed
end)

lib.callback.register("illenium-appearance:server:hasMoney", function(source, shopType)
    local cost = costOf(shopType)

    if not cost then return true, 0 end

    return Framework.HasMoney(source, shopConfig.account, cost), cost
end)

lib.callback.register("illenium-appearance:server:payForTattoo", function(source, tattoo)
    local cost = type(tattoo) == "table" and tonumber(tattoo.cost) or nil

    cost = cost or costOf("tattoo")

    if not cost then return true end

    return Framework.RemoveMoney(source, shopConfig.account, cost) == true
end)

lib.callback.register("illenium-appearance:server:getOutfits", function(source)
    return outfits.get(source)
end)

lib.callback.register("illenium-appearance:server:generateOutfitCode", function(source, outfitID)
    return outfits.generateCode(source, outfitID)
end)

lib.callback.register("illenium-appearance:server:importOutfitCode", function(source, outfitName, outfitCode)
    return outfits.import(source, outfitName, outfitCode)
end)

lib.callback.register("illenium-appearance:server:getUniform", function(source)
    return uniforms[source]
end)

RegisterNetEvent("illenium-appearance:server:saveAppearance", function(appearance)
    exports[cache.resource]:saveAppearance(source, appearance)
end)

RegisterNetEvent("illenium-appearance:server:chargeCustomer", function(shopType)
    local cost = costOf(shopType)

    if not cost then return end

    Framework.RemoveMoney(source, shopConfig.account, cost)
end)

RegisterNetEvent("illenium-appearance:server:saveOutfit", function(name, model, components, props)
    outfits.save(source, name, model, components, props)
end)

RegisterNetEvent("illenium-appearance:server:updateOutfit", function(id, model, components, props)
    outfits.update(source, id, model, components, props)
end)

RegisterNetEvent("illenium-appearance:server:deleteOutfit", function(id)
    outfits.remove(source, id)
end)

RegisterNetEvent("illenium-appearance:server:syncUniform", function(uniform)
    if uniform ~= nil and not validate.slots(uniform.components, "component_id") then return end

    uniforms[source] = uniform
end)

RegisterNetEvent("illenium-appearance:server:resetOutfitCache", function()
    uniforms[source] = nil
end)

AddEventHandler("playerDropped", function()
    uniforms[source] = nil
end)

---@type table<string, boolean>
local warned = {}

---@param name string
local function unsupported(name)
    if warned[name] then return end

    warned[name] = true

    print(("^3[rhd_appearance]^7 '%s' is part of illenium job management, which is not implemented.")
        :format(name))
end

lib.callback.register("illenium-appearance:server:getManagementOutfits", function()
    unsupported("getManagementOutfits")

    return {}
end)

lib.callback.register("illenium-appearance:server:esx:getGradesForJob", function()
    unsupported("esx:getGradesForJob")

    return {}
end)

RegisterNetEvent("illenium-appearance:server:saveManagementOutfit", function()
    unsupported("saveManagementOutfit")
end)

RegisterNetEvent("illenium-appearance:server:deleteManagementOutfit", function()
    unsupported("deleteManagementOutfit")
end)

RegisterNetEvent("illenium-appearance:server:ChangeRoutingBucket", function()
    SetPlayerRoutingBucket(source, source)
end)

RegisterNetEvent("illenium-appearance:server:ResetRoutingBucket", function()
    SetPlayerRoutingBucket(source, 0)
end)

lib.addCommand("joboutfits", { help = locale("outfits.title") }, function(source)
    TriggerClientEvent("illenium-apearance:client:outfitsCommand", source, true)
end)

lib.addCommand("gangoutfits", { help = locale("outfits.title") }, function(source)
    TriggerClientEvent("illenium-apearance:client:outfitsCommand", source, true)
end)
