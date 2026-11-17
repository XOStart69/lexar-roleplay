local hasFrame = interface.init(false)

local Wait = Wait
local GetGameTimer = GetGameTimer
local CreateThread = CreateThread
local joaat = joaat
local IsModelInCdimage = IsModelInCdimage
local RequestModel = RequestModel
local HasModelLoaded = HasModelLoaded
local SetModelAsNoLongerNeeded = SetModelAsNoLongerNeeded
local RequestStreamedTextureDict = RequestStreamedTextureDict
local HasStreamedTextureDictLoaded = HasStreamedTextureDictLoaded
local SetStreamedTextureDictAsNoLongerNeeded = SetStreamedTextureDictAsNoLongerNeeded
local DoesAnimDictExist = DoesAnimDictExist
local RequestAnimDict = RequestAnimDict
local HasAnimDictLoaded = HasAnimDictLoaded
local RemoveAnimDict = RemoveAnimDict
local SetPedPreloadVariationData = SetPedPreloadVariationData
local HasPedPreloadVariationDataFinished = HasPedPreloadVariationDataFinished
local ReleasePedPreloadVariationData = ReleasePedPreloadVariationData
local SetPedPreloadPropData = SetPedPreloadPropData
local HasPedPreloadPropDataFinished = HasPedPreloadPropDataFinished
local ReleasePedPreloadPropData = ReleasePedPreloadPropData
local GetNumberOfPedDrawableVariations = GetNumberOfPedDrawableVariations
local GetNumberOfPedPropDrawableVariations = GetNumberOfPedPropDrawableVariations
local GetNumberOfPedTextureVariations = GetNumberOfPedTextureVariations
local GetNumberOfPedPropTextureVariations = GetNumberOfPedPropTextureVariations
local GetResourceState = GetResourceState
local GetResourceKvpString = GetResourceKvpString
local GetResourceKvpInt = GetResourceKvpInt
local SetResourceKvp = SetResourceKvp
local SetResourceKvpInt = SetResourceKvpInt
local DeleteResourceKvp = DeleteResourceKvp
local DoesEntityExist = DoesEntityExist
local DeleteEntity = DeleteEntity
local tsort, tconcat = table.sort, table.concat
local ssub = string.sub
local mmax, mmin = math.max, math.min
local tonumber, pairs, type = tonumber, pairs, type
local jdecode = json.decode

local ASSET_TIMEOUT = 15000
local VERIFY_GRACE = 100
local BATCH_FAST = 32
local BATCH_SLOW = 4
local SCAN_GRACE = 1500
local SCAN_BATCH = 8
local SAVE_INTERVAL = 1000
local SEND_INTERVAL = 100
local LIST_TIMEOUT = 60000
local HIDE_DELAY = 150
local CLOTHING = 'clothing'
local ALL_SCOPE = '*'
local COMPONENT_SLOTS = 12
local PROP_ANCHORS = 13
local ASSET_KINDS = { 'model', 'txd', 'anim' }
local PED_KINDS = { 'component', 'prop' }
local KVP_OK = 'smcache:ok:'
local KVP_LIST = 'smcache:list:'
local LIST_CHUNK = 60000
local KVP = {
    version = 'smcache:version',
    scope = 'smcache:scope',
    index = 'smcache:index',
    name = 'smcache:name',
    done = 'smcache:done',
}

local assets
local storedChecked = false
local loadingList = false
local listWaiter

local mounted, ready = false, false
local focused = false
local panelOpen = false
local running, cancelled = false, false
local scanning, scanCancelled = false, false
local activePhase = 'verifying'
local current
local runState = {}
local progress = {}
local lastSend = 0

---@param text string
---@param kind? string
local function notify(text, kind)
    lib.notify({ title = 'Cache', description = text, type = kind or 'inform' })
end

---@param action string
---@param data? any
local function send(action, data)
    if ready then
        interface.send({ action = action, data = data })
    end
end

local function mount()
    if mounted then return end
    mounted = true
    ready = false
    interface.show()
end

local function unmountLater()
    SetTimeout(HIDE_DELAY, function()
        if panelOpen or running or scanning or not mounted then return end
        mounted = false
        ready = false
        interface.hide()
    end)
end

---@param state boolean
local function setFocus(state)
    focused = state
    interface.focus(state, state)
    send('focus', state)
end

---@param t table
---@return string[]
local function sortedKeys(t)
    local keys = {}
    for k in pairs(t) do keys[#keys + 1] = k end
    tsort(keys, function(a, b) return tostring(a) < tostring(b) end)
    return keys
end

---@param ver string
---@param raw string
---@return boolean
local function parseAssets(ver, raw)
    local ok, data = pcall(jdecode, raw)
    if not ok or type(data) ~= 'table' or type(data.r) ~= 'table' then return false end

    local resources, byName = {}, {}
    for i = 1, #data.r do
        local r = data.r[i]
        local entry = {
            name = r.n,
            hash = r.h,
            model = r.m or {},
            txd = r.t or {},
            anim = r.a or {},
            ped = r.p or {},
        }
        entry.count = #entry.model + #entry.txd + #entry.anim + #entry.ped
        resources[i] = entry
        byName[r.n] = entry
    end

    local clothing = {}
    for model, slots in pairs(data.c or {}) do
        local component, prop = {}, {}
        for slot, count in pairs(slots.c or {}) do component[tonumber(slot)] = count end
        for slot, count in pairs(slots.p or {}) do prop[tonumber(slot)] = count end
        clothing[model] = { component = component, prop = prop }
    end

    assets = {
        version = ver,
        resources = resources,
        byName = byName,
        clothing = next(clothing) and clothing or nil,
        clothingHash = data.ch or ver,
    }
    return true
end

---@param ver string
---@param raw string
local function storeList(ver, raw)
    local old = GetResourceKvpInt(KVP_LIST .. 'n')
    local parts = 0
    for i = 1, #raw, LIST_CHUNK do
        parts = parts + 1
        SetResourceKvp(KVP_LIST .. parts, ssub(raw, i, i + LIST_CHUNK - 1))
    end
    for i = parts + 1, old do DeleteResourceKvp(KVP_LIST .. i) end
    SetResourceKvpInt(KVP_LIST .. 'n', parts)
    SetResourceKvp(KVP_LIST .. 'v', ver)
end

local function loadStoredList()
    storedChecked = true
    local ver = GetResourceKvpString(KVP_LIST .. 'v')
    local parts = GetResourceKvpInt(KVP_LIST .. 'n')
    if not ver or parts < 1 then return end
    local chunks = {}
    for i = 1, parts do
        local chunk = GetResourceKvpString(KVP_LIST .. i)
        if not chunk then return end
        chunks[i] = chunk
    end
    parseAssets(ver, tconcat(chunks))
end

RegisterNetEvent('sm_cache:list', function(ver, raw, cooldown)
    if source == '' then return end
    if ver and raw then
        if parseAssets(ver, raw) then storeList(ver, raw) end
    elseif not ver then
        if cooldown then
            notify('Tunggu sebentar sebelum meminta daftar lagi', 'error')
        else
            notify('Daftar cache sedang disiapkan server, coba lagi nanti', 'error')
        end
    end
    local waiter = listWaiter
    listWaiter = nil
    if waiter then waiter:resolve(assets ~= nil) end
end)

RegisterNetEvent('sm_cache:queued', function(position)
    if source == '' then return end
    notify(('Daftar cache sedang antre (posisi %d), tunggu sebentar'):format(tonumber(position) or 0))
end)

---@return boolean
local function ensureList()
    if loadingList then return false end
    loadingList = true
    if not storedChecked then loadStoredList() end
    listWaiter = promise.new()
    local waiter = listWaiter
    SetTimeout(LIST_TIMEOUT, function()
        if listWaiter == waiter then
            listWaiter = nil
            waiter:resolve('timeout')
        end
    end)
    TriggerTokenEvent('sm_cache:request', assets and assets.version or false)
    local result = Citizen.Await(waiter)
    loadingList = false
    if assets then return true end
    if result == 'timeout' then
        notify('Daftar cache belum sampai (server sibuk), coba lagi sebentar lagi', 'error')
    end
    return false
end

---@param scope string
---@param index number
---@param name string
---@param done number
local function saveProgress(scope, index, name, done)
    SetResourceKvp(KVP.version, assets.version)
    SetResourceKvp(KVP.scope, scope)
    SetResourceKvpInt(KVP.index, index)
    SetResourceKvp(KVP.name, name)
    SetResourceKvpInt(KVP.done, done)
end

local function clearProgress()
    for _, key in pairs(KVP) do DeleteResourceKvp(key) end
end

---@return number, number
local function loadResume(scope, steps)
    if GetResourceKvpString(KVP.version) ~= assets.version or GetResourceKvpString(KVP.scope) ~= scope then
        return 1, 0
    end
    local index = GetResourceKvpInt(KVP.index)
    local name = GetResourceKvpString(KVP.name)
    local done = mmax(0, GetResourceKvpInt(KVP.done))
    if steps[index] and steps[index].label == name then return index, done end
    for i = 1, #steps do
        if steps[i].label == name then return i, done end
    end
    return 1, 0
end

---@param name string
---@param hash string
local function markCached(name, hash)
    SetResourceKvp(KVP_OK .. name, hash)
end

---@param name string
---@param hash string
---@return boolean
local function isMarkedCached(name, hash)
    return GetResourceKvpString(KVP_OK .. name) == hash
end

---@param flush? boolean
local function sendProgress(flush)
    local now = GetGameTimer()
    if not flush and now - lastSend < SEND_INTERVAL then return end
    lastSend = now
    send('progress', progress)
end

---@param phase string
local function setPhase(phase)
    if activePhase == phase then return end
    activePhase = phase
    progress.phase = phase
    sendProgress(true)
end

---@return boolean
local function requestAndWait(requestFn, checkFn, timeout)
    setPhase('verifying')
    requestFn()
    if checkFn() then return true end

    local startedAt = GetGameTimer()
    local deadline = startedAt + timeout
    while not checkFn() do
        local now = GetGameTimer()
        if cancelled or now > deadline then return false end
        if activePhase ~= 'downloading' and now - startedAt >= VERIFY_GRACE then
            setPhase('downloading')
        end
        Wait(0)
    end
    return true
end

local batchKinds = {
    model = {
        start = function(item)
            local hash = item.hash
            if not hash then
                hash = joaat(item.name)
                item.hash = hash
            end
            if not IsModelInCdimage(hash) then return false end
            RequestModel(hash)
            return true
        end,
        loaded = function(item) return HasModelLoaded(item.hash) end,
        release = function(item) SetModelAsNoLongerNeeded(item.hash) end,
    },
    txd = {
        start = function(item)
            RequestStreamedTextureDict(item.name, false)
            return true
        end,
        loaded = function(item) return HasStreamedTextureDictLoaded(item.name) end,
        release = function(item) SetStreamedTextureDictAsNoLongerNeeded(item.name) end,
    },
    anim = {
        start = function(item)
            if not DoesAnimDictExist(item.name) then return false end
            RequestAnimDict(item.name)
            return true
        end,
        loaded = function(item) return HasAnimDictLoaded(item.name) end,
        release = function(item) RemoveAnimDict(item.name) end,
    },
}

local pendingBatch = {}

---@param items table[]
---@param from number
---@param limit number
---@return number last, number failed, boolean fast
local function loadBatch(items, from, limit)
    local last, n = from - 1, 0
    for i = from, #items do
        local item = items[i]
        if n >= limit or not batchKinds[item.type] then break end
        last = i
        if batchKinds[item.type].start(item) then
            n = n + 1
            pendingBatch[n] = item
        end
    end
    for j = #pendingBatch, n + 1, -1 do pendingBatch[j] = nil end

    setPhase('verifying')
    local startedAt = GetGameTimer()
    local lastFinish = startedAt
    local failed = 0
    local left = n
    while left > 0 do
        left = 0
        local finished = false
        for j = 1, n do
            local item = pendingBatch[j]
            if item then
                local kind = batchKinds[item.type]
                if kind.loaded(item) then
                    kind.release(item)
                    pendingBatch[j] = false
                    finished = true
                else
                    left = left + 1
                end
            end
        end
        if left == 0 then break end

        local now = GetGameTimer()
        if finished then lastFinish = now end
        if cancelled or now - lastFinish > ASSET_TIMEOUT then
            for j = 1, n do
                local item = pendingBatch[j]
                if item then
                    batchKinds[item.type].release(item)
                    failed = failed + 1
                end
            end
            break
        end
        if activePhase ~= 'downloading' and now - startedAt >= VERIFY_GRACE then
            setPhase('downloading')
        end
        Wait(0)
    end
    return last, failed, GetGameTimer() - startedAt < VERIFY_GRACE
end

local loaders = {
    component = function(item)
        local ped = item.ped
        local ok = requestAndWait(function() SetPedPreloadVariationData(ped, item.slot, item.drawable, item.texture) end, function() return HasPedPreloadVariationDataFinished(ped) end, ASSET_TIMEOUT)
        ReleasePedPreloadVariationData(ped)
        return ok
    end,
    prop = function(item)
        local ped = item.ped
        local ok = requestAndWait(function() SetPedPreloadPropData(ped, item.slot, item.drawable, item.texture) end, function() return HasPedPreloadPropDataFinished(ped) end, ASSET_TIMEOUT)
        ReleasePedPreloadPropData(ped)
        return ok
    end,
}

---@param entities number[]
local function deleteEntities(entities)
    for i = 1, #entities do
        if DoesEntityExist(entities[i]) then DeleteEntity(entities[i]) end
    end
end

---@param model string
---@param abortFn fun(): boolean
---@return number?
local function createPreloadPed(model, abortFn)
    local hash = joaat(model)
    if not IsModelInCdimage(hash) then return end
    RequestModel(hash)
    local deadline = GetGameTimer() + ASSET_TIMEOUT
    while not HasModelLoaded(hash) do
        if abortFn() or GetGameTimer() > deadline then return end
        Wait(0)
    end

    local coords = GetEntityCoords(cache.ped)
    local ped = CreatePed(4, hash, coords.x, coords.y, coords.z - 50.0, 0.0, false, false)
    SetModelAsNoLongerNeeded(hash)
    if not DoesEntityExist(ped) then return end

    FreezeEntityPosition(ped, true)
    SetEntityCollision(ped, false, false)
    SetEntityVisible(ped, false, false)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    return ped
end

---@return number
local function drawableCount(ped, kind, slot)
    if kind == 'component' then return GetNumberOfPedDrawableVariations(ped, slot) end
    return GetNumberOfPedPropDrawableVariations(ped, slot)
end

local function addVariations(items, ped, kind, slot, first, last)
    local textureCount = kind == 'component' and GetNumberOfPedTextureVariations or GetNumberOfPedPropTextureVariations
    for drawable = mmax(0, first), last do
        for texture = 0, textureCount(ped, slot, drawable) - 1 do
            items[#items + 1] = { type = kind, ped = ped, slot = slot, drawable = drawable, texture = texture }
        end
    end
end

local function isCancelled()
    return cancelled
end

local function addClothingItems(items, entities, clothing)
    local models = sortedKeys(clothing)
    for i = 1, #models do
        local slots = clothing[models[i]]
        local ped = createPreloadPed(models[i], isCancelled)
        if ped then
            entities[#entities + 1] = ped
            for k = 1, #PED_KINDS do
                local kind = PED_KINDS[k]
                local list = slots[kind]
                local ids = sortedKeys(list)
                for s = 1, #ids do
                    local slot = ids[s]
                    local total = drawableCount(ped, kind, slot)
                    addVariations(items, ped, kind, slot, total - list[slot], total - 1)
                end
            end
        end
    end
end

local function addCustomPedItems(items, entities, models)
    for i = 1, #models do
        local ped = createPreloadPed(models[i], isCancelled)
        if ped then
            entities[#entities + 1] = ped
            for slot = 0, COMPONENT_SLOTS - 1 do
                addVariations(items, ped, 'component', slot, 0, drawableCount(ped, 'component', slot) - 1)
            end
            for slot = 0, PROP_ANCHORS - 1 do
                addVariations(items, ped, 'prop', slot, 0, drawableCount(ped, 'prop', slot) - 1)
            end
        end
    end
end

---@return table[]
local function expandStep(step, entities)
    local items = {}
    local entry = step.entry
    if entry then
        for k = 1, #ASSET_KINDS do
            local kind = ASSET_KINDS[k]
            local list = entry[kind]
            for i = 1, #list do
                items[#items + 1] = { type = kind, name = list[i] }
            end
        end
        if #entry.ped > 0 then addCustomPedItems(items, entities, entry.ped) end
    elseif step.clothing then
        addClothingItems(items, entities, step.clothing)
    end
    return items
end

---@param filter? string|table<string, boolean>
---@return table[]
local function buildSteps(filter)
    local steps = {}
    local onlyName = type(filter) == 'string' and filter or nil
    local filterSet = type(filter) == 'table' and filter or nil

    local function allowed(name)
        if onlyName then return onlyName == name end
        if filterSet then return filterSet[name] == true end
        return true
    end

    local resources = assets.resources
    for i = 1, #resources do
        local entry = resources[i]
        if allowed(entry.name) and GetResourceState(entry.name) == 'started' then
            steps[#steps + 1] = { label = entry.name, hash = entry.hash, entry = entry, count = entry.count }
        end
    end

    if assets.clothing and allowed(CLOTHING) then
        local total = 0
        for _, slots in pairs(assets.clothing) do
            for k = 1, #PED_KINDS do
                for _, count in pairs(slots[PED_KINDS[k]]) do total = total + count end
            end
        end
        steps[#steps + 1] = { label = CLOTHING, hash = assets.clothingHash, clothing = assets.clothing, count = total }
    end
    return steps
end

---@param filter? string|table<string, boolean>
---@return string
local function scopeOf(filter)
    if filter == nil then return ALL_SCOPE end
    if type(filter) == 'string' then return filter end
    return 'sel:' .. tconcat(sortedKeys(filter), ',')
end

---@return table[]
local function panelList()
    local steps = buildSteps(nil)
    local list = {}
    for i = 1, #steps do
        local step = steps[i]
        list[i] = {
            name = step.label,
            models = step.count,
            status = isMarkedCached(step.label, step.hash) and 'cached' or 'unknown',
            clothing = step.clothing ~= nil,
        }
    end
    return list
end

local function sendPanel()
    send('panel', {
        open = panelOpen,
        version = assets and assets.version,
        resources = panelOpen and panelList() or nil,
        scanning = scanning,
    })
end

local function sendRun()
    runState.running = running
    send('run', runState)
    if running then sendProgress(true) end
end

local function probe(requestFn, checkFn, releaseFn)
    requestFn()
    if checkFn() then
        releaseFn()
        return true
    end
    local deadline = GetGameTimer() + SCAN_GRACE
    while not checkFn() do
        if scanCancelled or GetGameTimer() > deadline then
            releaseFn()
            return false
        end
        Wait(0)
    end
    releaseFn()
    return true
end

---@return boolean
local function probeItem(kind, _, ped, slot, drawable)
    if kind == 'component' then
        return probe(function() SetPedPreloadVariationData(ped, slot, drawable, 0) end, function() return HasPedPreloadVariationDataFinished(ped) end, function() ReleasePedPreloadVariationData(ped) end)
    elseif kind == 'prop' then
        return probe(function() SetPedPreloadPropData(ped, slot, drawable, 0) end, function() return HasPedPreloadPropDataFinished(ped) end, function() ReleasePedPreloadPropData(ped) end)
    end
    return true
end

local function scanAborted()
    return scanCancelled or not panelOpen
end

local scanPool = {}
local scanLoaded = {}

---@param kind string
---@param list string[]
---@return string
local function scanList(kind, list)
    local spec = batchKinds[kind]
    local total = #list
    local i = 1
    while i <= total do
        if scanAborted() then return 'cancelled' end
        local last = mmin(total, i + SCAN_BATCH - 1)
        local n = 0
        for j = i, last do
            local item = scanPool[n + 1]
            if not item then
                item = {}
                scanPool[n + 1] = item
            end
            item.name = list[j]
            item.hash = nil
            if spec.start(item) then
                n = n + 1
                scanLoaded[n] = false
            end
        end

        local deadline = GetGameTimer() + SCAN_GRACE
        local left
        while true do
            left = 0
            for j = 1, n do
                if not scanLoaded[j] then
                    if spec.loaded(scanPool[j]) then
                        scanLoaded[j] = true
                    else
                        left = left + 1
                    end
                end
            end
            if left == 0 or scanAborted() or GetGameTimer() > deadline then break end
            Wait(0)
        end
        for j = 1, n do spec.release(scanPool[j]) end

        if scanAborted() then return 'cancelled' end
        if left > 0 then return 'needed' end
        i = last + 1
        Wait(0)
    end
    return 'cached'
end

---@return string
local function scanEntry(entry)
    for k = 1, #ASSET_KINDS do
        local kind = ASSET_KINDS[k]
        local status = scanList(kind, entry[kind])
        if status ~= 'cached' then return status end
    end
    return scanList('model', entry.ped)
end

---@return string
local function scanClothing(clothing)
    local entities = {}
    local models = sortedKeys(clothing)
    for i = 1, #models do
        if scanAborted() then
            deleteEntities(entities)
            return 'cancelled'
        end
        local ped = createPreloadPed(models[i], scanAborted)
        if not ped then
            deleteEntities(entities)
            return scanAborted() and 'cancelled' or 'needed'
        end
        entities[#entities + 1] = ped

        local slots = clothing[models[i]]
        for k = 1, #PED_KINDS do
            local kind = PED_KINDS[k]
            local list = slots[kind]
            local ids = sortedKeys(list)
            for s = 1, #ids do
                if scanAborted() then
                    deleteEntities(entities)
                    return 'cancelled'
                end
                local slot = ids[s]
                local first = mmax(0, drawableCount(ped, kind, slot) - list[slot])
                if not probeItem(kind, nil, ped, slot, first) then
                    deleteEntities(entities)
                    return 'needed'
                end
            end
        end
    end
    deleteEntities(entities)
    return 'cached'
end

local function runScan()
    local steps = buildSteps(nil)
    if #steps == 0 then
        scanning = false
        sendPanel()
        unmountLater()
        return notify('Tidak ada aset untuk di-scan', 'error')
    end

    scanCancelled = false
    for i = 1, #steps do
        if scanAborted() then break end
        local step = steps[i]
        if isMarkedCached(step.label, step.hash) then
            send('scan', { name = step.label, status = 'cached' })
        else
            send('scan', { name = step.label, status = 'scanning' })
            local status = step.entry and scanEntry(step.entry) or scanClothing(step.clothing)
            if status == 'cancelled' then break end
            if status == 'cached' then markCached(step.label, step.hash) end
            send('scan', { name = step.label, status = status })
        end
    end

    scanning = false
    scanCancelled = false
    sendPanel()
    unmountLater()
end

local function closePanel()
    if not panelOpen then return end
    if scanning then scanCancelled = true end
    panelOpen = false
    sendPanel()
    if running then
        setFocus(focused)
    else
        setFocus(false)
        unmountLater()
    end
end

local function openPanel()
    if panelOpen then return end
    if not ensureList() then return end
    if running then
        mount()
        return setFocus(true)
    end
    panelOpen = true
    mount()
    if ready then
        sendPanel()
        setFocus(true)
    end
end

---@param filter? string|table<string, boolean>
local function run(filter)
    local steps = buildSteps(filter)
    if #steps == 0 then
        running = false
        unmountLater()
        return notify(type(filter) == 'string' and ('Tidak ada aset untuk %s'):format(filter) or 'Tidak ada aset untuk diunduh', 'error')
    end

    local scope = scopeOf(filter)
    local startIndex, resumeDone = loadResume(scope, steps)
    if startIndex > 1 or resumeDone > 0 then
        notify(('Melanjutkan dari %s (%d/%d), aset %d'):format(steps[startIndex].label, startIndex, #steps, resumeDone))
    end

    local overallTotal, overallDone = 0, 0
    for i = startIndex + 1, #steps do overallTotal = overallTotal + steps[i].count end

    cancelled = false
    activePhase = 'verifying'
    runState.totalResources = #steps
    runState.cancelled = false
    progress.totalResources = #steps
    progress.phase = activePhase
    sendRun()

    local lastSave = 0
    local failedTotal = 0
    for index = startIndex, #steps do
        if cancelled then break end
        local step = steps[index]
        local entities = {}
        local items = expandStep(step, entities)
        local total = #items
        local skip = index == startIndex and mmin(resumeDone, total) or 0
        overallTotal = overallTotal + (total - skip) - (index == startIndex and 0 or step.count)
        current = { scope = scope, index = index, label = step.label, done = skip }
        local failed = 0

        progress.resource = step.label
        progress.index = index
        progress.total = total
        progress.done = skip
        progress.overallDone = overallDone
        progress.overallTotal = overallTotal
        sendProgress(true)

        local batchSize = BATCH_FAST
        local i = skip + 1
        while i <= total do
            if cancelled then break end
            local item = items[i]
            local last
            if batchKinds[item.type] then
                local bad, fast
                last, bad, fast = loadBatch(items, i, batchSize)
                if cancelled then break end
                failed = failed + bad
                batchSize = fast and BATCH_FAST or BATCH_SLOW
            else
                local ok = loaders[item.type](item)
                if cancelled then break end
                if not ok then failed = failed + 1 end
                last = i
            end
            overallDone = overallDone + (last - i + 1)
            current.done = last
            progress.done = last
            progress.overallDone = overallDone
            sendProgress(last == total)
            local now = GetGameTimer()
            if now - lastSave >= SAVE_INTERVAL then
                saveProgress(scope, index, step.label, last)
                lastSave = now
            end
            i = last + 1
            Wait(0)
        end

        deleteEntities(entities)

        if not cancelled then
            if failed == 0 then
                markCached(step.label, step.hash)
            else
                failedTotal = failedTotal + failed
                DeleteResourceKvp(KVP_OK .. step.label)
            end
            local nextStep = steps[index + 1]
            if nextStep then saveProgress(scope, index + 1, nextStep.label, 0) end
        end
    end

    if cancelled then
        if current then saveProgress(current.scope, current.index, current.label, current.done) end
    else
        clearProgress()
    end
    current = nil

    running = false
    runState.cancelled = cancelled
    sendRun()
    if cancelled then
        notify('Download cache dibatalkan, progress disimpan', 'error')
    elseif failedTotal > 0 then
        notify(('Selesai, tapi %d aset timeout (koneksi lambat). Buka /aturpikiran lalu Scan dan download yang PERLU UNDUH'):format(failedTotal), 'error')
    else
        notify('Download cache selesai', 'success')
    end
    if not panelOpen then
        setFocus(false)
        unmountLater()
    end
end

---@param filter? string|table<string, boolean>
local function startRun(filter)
    if running then return end
    running = true
    mount()
    setFocus(true)
    CreateThread(function() run(filter) end)
end

if hasFrame then
    interface.callback('ready', function(_, cb)
        ready = true
        cb({})
        if panelOpen then sendPanel() end
        if running then sendRun() end
        setFocus(panelOpen or (running and focused))
    end)

    interface.callback('unfocus', function(_, cb)
        cb({})
        if panelOpen then
            closePanel()
            if running then setFocus(false) end
        else
            setFocus(false)
        end
    end)

    interface.callback('cancel', function(_, cb)
        cb({})
        if running then cancelled = true end
    end)

    interface.callback('close', function(_, cb)
        cb({})
        closePanel()
    end)

    interface.callback('scan', function(_, cb)
        cb({})
        if not panelOpen or running or scanning then return end
        scanning = true
        sendPanel()
        CreateThread(runScan)
    end)

    interface.callback('stopScan', function(_, cb)
        cb({})
        if scanning then scanCancelled = true end
    end)

    interface.callback('download', function(data, cb)
        cb({})
        if not panelOpen or running then return end
        if scanning then return notify('Tunggu scan selesai dulu', 'error') end

        local selected = type(data) == 'table' and data.resources
        if type(selected) ~= 'table' then return end

        local filter, any = {}, false
        for i = 1, #selected do
            local name = selected[i]
            if type(name) == 'string' and (name == CLOTHING or assets.byName[name]) then
                filter[name] = true
                any = true
            end
        end
        if not any then return notify('Pilih minimal satu resource', 'error') end

        panelOpen = false
        sendPanel()
        startRun(filter)
    end)
end

RegisterCommand('mikir', function(_, args)
    if not hasFrame then return end
    if running then
        mount()
        return setFocus(true)
    end
    if scanning then return notify('Scan cache masih berjalan', 'error') end
    CreateThread(function()
        if not ensureList() or running then return end
        local name = args[1]
        if name and name ~= CLOTHING and not assets.byName[name] then
            return notify(('Resource %s tidak punya aset stream'):format(name), 'error')
        end
        if panelOpen then
            panelOpen = false
            sendPanel()
        end
        startRun(name)
    end)
end, false)

RegisterCommand('aturpikiran', function()
    if not hasFrame then return end
    CreateThread(openPanel)
end, false)

RegisterCommand('berhentimikir', function()
    if running then cancelled = true end
end, false)

TriggerEvent('chat:addSuggestion', '/mikir', 'Download cache aset server tanpa harus keliling (ESC sembunyikan kursor)', {
    { name = 'resource', help = 'opsional: nama resource atau "clothing"' },
})
TriggerEvent('chat:addSuggestion', '/aturpikiran', 'Panel scan & pilih resource untuk download cache')
TriggerEvent('chat:addSuggestion', '/berhentimikir', 'Batalkan download cache')

AddEventHandler('sm_cache:client:forceClose', function()
    if scanning then scanCancelled = true end
    panelOpen = false
    focused = false
    sendPanel()
    send('focus', false)
    unmountLater()
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= cache.resource then return end
    if running then
        cancelled = true
        if current then saveProgress(current.scope, current.index, current.label, current.done) end
    end
end)
