return {
    notifyRadius = 50.0,
    renderDistance = 30.0,
    duration = 30000,
    maxCards = 4,
    reasons = {
        { keyword = 'exiting', label = 'Exited', type = 'exit', detail = true },
        { keyword = 'quit', label = 'Quit Game', type = 'exit', detail = true },
        { keyword = 'left', label = 'Left Server', type = 'exit', detail = true },
        { keyword = 'timed', label = 'Timed Out', type = 'timeout' },
        { keyword = 'crash', label = 'Crashed', type = 'crash' },
        { keyword = 'disconnect', label = 'Disconnected', type = 'exit' },
        { keyword = 'reconnecting', label = 'Reconnecting', type = 'exit' },
        { keyword = 'killed', label = 'Kicked by Server', type = 'exit' },
        { keyword = 'shutting down', label = 'Server Restart', type = 'exit', skip = true },
    },
}
