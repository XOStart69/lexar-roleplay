--[[
    sm_htcontract :: server
    Kontrak dua sisi. Server pegang record, role, timeout, konsumsi & pengembalian item.
]]

local config = localmodule 'config'

local ITEM = config.item
local SIGNED = config.signedItem
local JOB = config.requiredJob
local GRADE = config.requiredGrade or 0
local RADIUS = config.nearbyRadius or 10.0
local TIMEOUT = config.contractTimeout or 120

local contracts = {}
local byInitiator = {}
local counter = 0

local function fullName(player)
    local info = player.PlayerData.charinfo
    return ('%s %s'):format(info.firstname or '', info.lastname or ''):gsub('^%s+', '')
end

local function notify(src, message, kind)
    TriggerClientEvent('ox_lib:notify', src, { description = message, type = kind or 'error' })
end

local function authorized(src)
    local player = qb_ecore:GetPlayer(src)
    if not player then return false end
    if player.PlayerData.job.name ~= JOB then return false end
    if (player.PlayerData.job.grade.level or 0) < GRADE then return false end
    return true
end

local function dist(a, b)
    local pa, pb = GetPlayerPed(a), GetPlayerPed(b)
    if pa == 0 or pb == 0 then return 9999.0 end
    return #(GetEntityCoords(pa) - GetEntityCoords(pb))
end

local function finish(id, refund)
    local contract = contracts[id]
    if not contract or contract.done then return end

    contract.done = true
    contracts[id] = nil

    if byInitiator[contract.initiator] == id then
        byInitiator[contract.initiator] = nil
    end

    if refund then
        ox_inventory:AddItem(contract.initiator, ITEM, 1)
    end

    TriggerClientEvent('sm_htcontract:client:cancelled', contract.initiator)
    TriggerClientEvent('sm_htcontract:client:cancelled', contract.target)
end

lib.callback.register('sm_htcontract:nearby', function(src)
    local ped = GetPlayerPed(src)
    if ped == 0 then return {} end

    local coords = GetEntityCoords(ped)
    local out = {}

    for _, raw in ipairs(GetPlayers()) do
        local other = tonumber(raw)
        if other and other ~= src then
            local oped = GetPlayerPed(other)
            if oped ~= 0 then
                local gap = #(coords - GetEntityCoords(oped))
                if gap <= RADIUS then
                    local player = qb_ecore:GetPlayer(other)
                    if player then
                        out[#out + 1] = {
                            serverId = other,
                            name = fullName(player),
                            job = player.PlayerData.job.label,
                            distance = gap,
                        }
                    end
                end
            end
        end
    end

    table.sort(out, function(a, b) return a.distance < b.distance end)

    return out
end)

RegisterNetEvent('sm_htcontract:server:send', function(targetServerId)
    local src = source
    local target = tonumber(targetServerId)
    if not target or target == src then return end

    local player = qb_ecore:GetPlayer(src)
    local other = qb_ecore:GetPlayer(target)
    if not player or not other then return end

    if not authorized(src) then return notify(src, 'Jabatan tidak memenuhi syarat.') end
    if byInitiator[src] then return notify(src, 'Masih ada kontrak berjalan.') end
    if (ox_inventory:GetItemCount(src, ITEM) or 0) < 1 then return notify(src, 'Tidak ada blangko kontrak.') end
    if dist(src, target) > RADIUS then return notify(src, 'Target terlalu jauh.') end

    if not ox_inventory:RemoveItem(src, ITEM, 1) then
        return notify(src, 'Gagal mengambil blangko.')
    end

    counter = counter + 1
    local id = ('HT-%d-%d'):format(os.time(), counter)

    local payload = {
        contractId = id,
        initiator = src,
        initiatorName = fullName(player),
        initiatorJob = player.PlayerData.job.label,
        target = target,
        targetName = fullName(other),
        targetJob = other.PlayerData.job.label,
    }

    contracts[id] = {
        contractId = id,
        initiator = src,
        initiatorName = payload.initiatorName,
        initiatorJob = payload.initiatorJob,
        target = target,
        targetName = payload.targetName,
        targetJob = payload.targetJob,
        signed = {},
        done = false,
    }

    byInitiator[src] = id

    TriggerClientEvent('sm_htcontract:client:open', src, payload, 'initiator')
    TriggerClientEvent('sm_htcontract:client:open', target, payload, 'target')

    CreateThread(function()
        Wait(TIMEOUT * 1000)
        if contracts[id] then finish(id, true) end
    end)
end)

RegisterNetEvent('sm_htcontract:server:sign', function(contractId)
    local src = source
    local contract = contracts[contractId]
    if not contract or contract.done then return end
    if contract.signed[src] then return end

    local role
    if src == contract.initiator then role = 'initiator'
    elseif src == contract.target then role = 'target'
    else return end

    if role == 'initiator' and not authorized(src) then
        return notify(src, 'Jabatan tidak memenuhi syarat.')
    end

    contract.signed[src] = true

    local partner = (role == 'initiator') and contract.target or contract.initiator
    TriggerClientEvent('sm_htcontract:client:partnerSigned', partner, role)

    if contract.signed[contract.initiator] and contract.signed[contract.target] then
        contract.done = true
        contracts[contractId] = nil
        byInitiator[contract.initiator] = nil

        local meta = {
            contract = {
                contractId = contract.contractId,
                initiator = contract.initiator,
                initiatorName = contract.initiatorName,
                initiatorJob = contract.initiatorJob,
                target = contract.target,
                targetName = contract.targetName,
                targetJob = contract.targetJob,
            },
            contractId = contract.contractId,
            initiatorJob = contract.initiatorJob,
            targetJob = contract.targetJob,
            targetName = contract.targetName,
            initiatorName = contract.initiatorName,
        }

        ox_inventory:AddItem(contract.target, SIGNED, 1, meta)
        ox_inventory:AddItem(contract.initiator, SIGNED, 1, meta)

        TriggerClientEvent('sm_htcontract:client:complete', contract.initiator)
        TriggerClientEvent('sm_htcontract:client:complete', contract.target)
    end
end)

RegisterNetEvent('sm_htcontract:server:cancel', function(contractId)
    local src = source
    local contract = contracts[contractId]
    if not contract or contract.done then return end
    if src ~= contract.initiator and src ~= contract.target then return end

    finish(contractId, true)
end)

AddEventHandler('playerDropped', function()
    local src = source
    local id = byInitiator[src]

    if id then
        local contract = contracts[id]
        if contract and not contract.done then
            contract.done = true
            contracts[id] = nil
            byInitiator[src] = nil
            TriggerClientEvent('sm_htcontract:client:cancelled', contract.target)
        end
        return
    end

    for key, contract in pairs(contracts) do
        if contract.target == src and not contract.done then
            contract.target = 0
            TriggerClientEvent('sm_htcontract:client:cancelled', contract.initiator)
            return
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    contracts = {}
    byInitiator = {}
end)

print('^2[sm_htcontract] server siap^7')