if not interface.init(false) then return end

local difficulty = localmodule 'config.default'

local minigame_status

local frameToken = 0
local frameShown = false

local function openFrame()
    frameToken += 1
    if frameShown then return true end

    frameShown = true
    return interface.show()
end

local function closeFrame()
    frameToken += 1
    local token = frameToken

    SetTimeout(400, function()
        if token == frameToken then
            frameShown = false
            interface.hide()
        end
    end)
end

---@param options TerminalHackMinigameParam|TerminalMinigameDifficulty
local function startMinigame(options)
    if minigame_status then
        lib.print.error('Terminal hack minigame masih berjalan, permintaan baru ditolak')
        return false
    end

    openFrame()
    interface.send({
        action = 'setConfig',
        data = difficulty
    })

    local sent = interface.send({
        action = 'startTerminal',
        data = {
            options = options,
            isdeveloper = false
        }
    })

    if not sent then
        lib.print.error('Terminal hack frame belum siap, minigame dibatalkan')
        interface.focus(false, false)
        closeFrame()
        return false
    end

    if not interface.focus(true, true) then
        lib.print.error('Gagal fokus ke terminal hack frame, minigame dibatalkan')
        interface.focus(false, false)
        closeFrame()
        return false
    end

    minigame_status = promise.new()
    return Citizen.Await(minigame_status)
end

interface.callback('minigame_result', function(data, cb)
    cb('ok')

    interface.focus(false, false)
    closeFrame()

    if not minigame_status then return end

    minigame_status:resolve(data?.success)
    minigame_status = nil
end)

_ENV.terminal_hack = {
    start = startMinigame,
}