local function openEditor()
    if NetworkIsSessionActive() then
        NetworkSessionLeaveSinglePlayer()
    end

    ActivateRockstarEditor()
end

lib.registerContext({
    id = 'sm_rockstareditor',
    title = 'Rockstar Editor',
    options = {
        {
            title = 'Mulai Merekam',
            description = 'Mulai merekam video.',
            onSelect = function()
                if not IsRecording() then
                    StartRecording(1)
                end
            end
        },
        {
            title = 'Hentikan dan Hapus Rekaman',
            description = 'Hentikan rekaman dan hapus klip.',
            onSelect = function()
                if IsRecording() then
                    StopRecordingAndDiscardClip()
                end
            end
        },
        {
            title = 'Simpan Rekaman',
            description = 'Hentikan rekaman dan simpan klip.',
            onSelect = function()
                if IsRecording() then
                    StopRecordingAndSaveClip()
                end
            end
        },
        {
            title = 'Buka Rockstar Editor',
            description = 'Masuk ke Rockstar Editor.',
            onSelect = openEditor
        }
    }
})

RegisterCommand('record', function()
    lib.showContext('sm_rockstareditor')
end, false)

RegisterCommand('clip', function()
    StartRecording(0)
end, false)

RegisterCommand('saveclip', function()
    StopRecordingAndSaveClip()
    lib.notify({ description = 'Saved Recording!', type = 'success' })
end, false)

RegisterCommand('delclip', function()
    StopRecordingAndDiscardClip()
    lib.notify({ description = 'Deleted Recording!', type = 'error' })
end, false)

RegisterCommand('editor', function()
    openEditor()
end, false)
