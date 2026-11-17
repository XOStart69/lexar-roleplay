---@class PackagingContext
---@field recipes table<string, CraftingRecipe>
---@field packagesByBox table<string, CraftingRecipe>
---@field menuItems table<string, table<string, string>>
---@field notify fun(source: integer, message: string, kind?: string)
---@field itemLabel fun(name: string): string
---@field getCustom fun(jobName: string, recipe: CraftingRecipe): { label: string?, image: string? }?
---@field transact fun(source: integer, removals: TransactionRemoval[], additions: TransactionAddition[], context: TransactionContext): boolean

---@class PackageEntry
---@field name string
---@field count integer
---@field label? string
---@field imageurl? string

local ostime = os.time
local mathMin = math.min
local tointeger = math.tointeger
local sformat = string.format
local tconcat = table.concat
local tsort = table.sort
local type = type
local pairs = pairs

local EMPTY = {}

---@param metadata table?
---@param now integer
---@return boolean
local function isFresh(metadata, now)
    local durability = metadata and metadata.durability
    if type(durability) ~= 'number' then return true end
    if durability > 100 then return durability > now end
    return durability > 0
end

---@param label string?
---@param imageurl string?
---@return string
local function variantKey(label, imageurl)
    return (label or '') .. '\0' .. (imageurl or '')
end

---@param ctx PackagingContext
return function(ctx)
    local Recipes = ctx.recipes
    local PackagesByBox = ctx.packagesByBox
    local MenuItems = ctx.menuItems
    local notify = ctx.notify
    local itemLabel = ctx.itemLabel
    local getCustom = ctx.getCustom
    local transact = ctx.transact

    ---@param source integer
    ---@param item string
    ---@param now integer
    ---@return table[] slots
    ---@return integer total
    local function freshSlots(source, item, now)
        local slots = ox_inventory:Search(source, 'slots', item) or EMPTY
        local fresh, total = {}, 0

        for _, slot in pairs(slots) do
            local metadata = slot.metadata or EMPTY

            if isFresh(metadata, now) then
                fresh[#fresh + 1] = {
                    slot = slot.slot,
                    count = slot.count,
                    label = metadata.label,
                    imageurl = metadata.imageurl,
                    variant = variantKey(metadata.label, metadata.imageurl),
                }
                total += slot.count
            end
        end

        return fresh, total
    end

    ---@param jobName string
    ---@param item string
    ---@return string
    local function activeVariant(jobName, item)
        local items = MenuItems[jobName]
        local key = items and items[item]
        local recipe = key and Recipes[key]
        local custom = recipe and getCustom(jobName, recipe)
        return variantKey(custom and custom.label, custom and custom.image)
    end

    ---@param entries PackageEntry[]
    ---@return string
    local function describe(entries)
        local parts = {}

        for i = 1, #entries do
            local entry = entries[i]
            parts[i] = sformat('%dx %s', entry.count, entry.label or itemLabel(entry.name))
        end

        return 'Isi: ' .. tconcat(parts, ', ')
    end

    ---@param entry PackageEntry
    ---@return table?
    local function entryMetadata(entry)
        if not entry.label and not entry.imageurl then return nil end
        return { label = entry.label, imageurl = entry.imageurl }
    end

    ---@param source integer
    ---@param recipe CraftingRecipe
    ---@param amount integer
    ---@return boolean
    local function hasMaterials(source, recipe, amount)
        local now = ostime()

        for item, count in pairs(recipe.materials) do
            local _, total = freshSlots(source, item, now)
            if total < count * amount then return false end
        end

        return true
    end

    ---@param source integer
    ---@param jobName string
    ---@param recipe CraftingRecipe
    ---@param amount integer
    ---@param custom { label: string?, image: string? }?
    local function pack(source, jobName, recipe, amount, custom)
        local now = ostime()
        local removals, materials = {}, {}

        for item, perBox in pairs(recipe.materials) do
            local slots, total = freshSlots(source, item, now)
            local need = perBox * amount

            if total < need then
                return notify(source, sformat('Butuh %dx %s yang belum basi, kamu punya %dx.', need, itemLabel(item), total))
            end

            local preferred = activeVariant(jobName, item)

            tsort(slots, function(a, b)
                local aPreferred, bPreferred = a.variant == preferred, b.variant == preferred
                if aPreferred ~= bPreferred then return aPreferred end
                return a.slot < b.slot
            end)

            local chunks, remaining = {}, need

            for i = 1, #slots do
                if remaining <= 0 then break end

                local slot = slots[i]
                local take = mathMin(remaining, slot.count)

                removals[#removals + 1] = { item = item, count = take, slot = slot.slot }
                chunks[#chunks + 1] = { label = slot.label, imageurl = slot.imageurl, left = take }
                remaining -= take
            end

            materials[#materials + 1] = { item = item, perBox = perBox, chunks = chunks, cursor = 1 }
        end

        tsort(materials, function(a, b) return a.item < b.item end)

        local groups, order = {}, {}

        for _ = 1, amount do
            local entries, signature = {}, {}

            for m = 1, #materials do
                local material = materials[m]
                local needed = material.perBox

                while needed > 0 do
                    local chunk = material.chunks[material.cursor]
                    local take = mathMin(needed, chunk.left)
                    local last = entries[#entries]

                    if last and last.name == material.item and last.label == chunk.label and last.imageurl == chunk.imageurl then
                        last.count += take
                    else
                        entries[#entries + 1] = { name = material.item, count = take, label = chunk.label, imageurl = chunk.imageurl }
                    end

                    chunk.left -= take
                    needed -= take

                    if chunk.left == 0 then material.cursor += 1 end
                end
            end

            for i = 1, #entries do
                local entry = entries[i]
                signature[i] = sformat('%s:%d:%s', entry.name, entry.count, variantKey(entry.label, entry.imageurl))
            end

            local key = tconcat(signature, '|')
            local group = groups[key]

            if group then
                group.count += 1
            else
                group = {
                    count = 1,
                    metadata = {
                        contents = entries,
                        description = describe(entries),
                        label = custom and custom.label or nil,
                        imageurl = custom and custom.image or nil,
                    },
                }
                groups[key] = group
                order[#order + 1] = group
            end
        end

        local box = recipe.output
        local additions = {}

        for i = 1, #order do
            additions[i] = { item = box, count = order[i].count, metadata = order[i].metadata }
        end

        local done = transact(source, removals, additions, {
            remove = sformat('crafting-material:%s', recipe.key),
            add = sformat('crafting-result:%s', recipe.key),
        })

        if not done then
            return notify(source, 'Inventory kamu penuh atau terlalu berat, packaging dibatalkan. Bahan tidak berkurang.')
        end

        notify(source, sformat('Berhasil membuat %dx %s.', amount, custom and custom.label or recipe.label or itemLabel(box)), 'success')
    end

    ---@param recipe CraftingRecipe
    ---@param contents any
    ---@return PackageEntry[]
    local function readContents(recipe, contents)
        local entries, used = {}, {}

        if type(contents) == 'table' then
            for i = 1, #contents do
                local entry = contents[i]
                local name = type(entry) == 'table' and entry.name
                local limit = name and recipe.materials[name]
                local count = limit and type(entry.count) == 'number' and tointeger(entry.count)

                if count and count > 0 and (used[name] or 0) + count <= limit then
                    used[name] = (used[name] or 0) + count
                    entries[#entries + 1] = {
                        name = name,
                        count = count,
                        label = type(entry.label) == 'string' and entry.label or nil,
                        imageurl = type(entry.imageurl) == 'string' and entry.imageurl or nil,
                    }
                end
            end
        end

        if #entries > 0 then return entries end

        for name, count in pairs(recipe.materials) do
            entries[#entries + 1] = { name = name, count = count }
        end

        return entries
    end

    ---@param source integer
    ---@param slotId integer
    local function open(source, slotId)
        local slot = ox_inventory:GetSlot(source, slotId)
        if not slot then return end

        local recipe = PackagesByBox[slot.name]
        if not recipe then return notify(source, 'Paket ini tidak valid.') end

        local metadata = slot.metadata or EMPTY

        if not isFresh(metadata, ostime()) then
            if ox_inventory:RemoveItem(source, slot.name, 1, nil, slotId) then
                notify(source, 'Paket sudah basi dan tidak bisa dibuka, makanannya rusak total.')
            end
            return
        end

        local entries = readContents(recipe, metadata.contents)

        local additions = {}

        for i = 1, #entries do
            local entry = entries[i]
            additions[i] = { item = entry.name, count = entry.count, metadata = entryMetadata(entry) }
        end

        local context = sformat('package-open:%s', recipe.key)
        local done = transact(source, { { item = slot.name, count = 1, slot = slotId } }, additions, { remove = context, add = context })

        if not done then
            return notify(source, 'Inventory kamu penuh atau terlalu berat, paket tidak bisa dibuka.')
        end

        notify(source, 'Paket dibuka, isinya keluar dalam kondisi segar.', 'success')
    end

    return {
        isFresh = isFresh,
        hasMaterials = hasMaterials,
        pack = pack,
        open = open,
    }
end
