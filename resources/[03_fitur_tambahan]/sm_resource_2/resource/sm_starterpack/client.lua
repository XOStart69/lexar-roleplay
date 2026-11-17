local config = localmodule 'config'

local busy = false

---@param text string
---@param kind? string
local function notify(text, kind)
    lib.notify({ title = 'Starter Pack', description = text, type = kind or 'inform' })
end

---@param questions { question: string, description: string, options: string[] }[]
---@return string[]?
local function askQuestions(questions)
    local total = #questions
    local answers = {}

    for i = 1, total do
        local entry = questions[i]
        local options = {}

        for j = 1, #entry.options do
            local label = entry.options[j]
            options[j] = { label = label, value = label }
        end

        local input = lib.inputDialog(('Pertanyaan %d dari %d'):format(i, total), {
            {
                type = 'select',
                label = entry.question,
                description = entry.description,
                options = options,
                icon = 'circle-question',
                required = true,
            },
        })

        if not input then return end

        answers[i] = input[1]
    end

    return answers
end

local function claim()
    local session = lib.callback.await('sm_starterpack:server:start', false)
    if not session then return end

    if session.error then
        return notify(session.error, 'error')
    end

    local agreed = lib.alertDialog({
        header = 'Starter Pack',
        content = config.intro,
        centered = true,
        cancel = true,
    })

    if agreed ~= 'confirm' then return end

    local answers = askQuestions(session.questions)
    if not answers then
        return notify('Kuis dibatalkan.', 'error')
    end

    local finished = lib.progressCircle({
        duration = 2000,
        label = 'Menerima starter pack',
        position = 'bottom',
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = 'mp_common', clip = 'givetake1_a' },
    })

    if not finished then
        return notify('Penerimaan starter pack dibatalkan.', 'error')
    end

    local result = lib.callback.await('sm_starterpack:server:claim', false, answers)
    if not result then return end

    if result.error then
        return notify(result.error, 'error')
    end

    notify(result.message, 'success')
end

local function onSelect()
    if busy then return end

    busy = true

    CreateThread(function()
        claim()
        busy = false
    end)
end

CreateThread(function()
    exports[cache.resource]:addPed({
        model = config.ped.model,
        coords = config.locations,
        renderDistance = config.renderDistance,
        scenario = config.ped.scenario,
        interactOptions = {
            {
                label = 'Ambil Starter Pack',
                icon = 'gift',
                distance = config.interactDistance,
                onSelect = onSelect,
            },
        },
    })
end)
