lib.callback.register('Housing:server:GetShellTime', function(source)
    return Config.TimeInShell or 18
end)

exports('GetShellTime', function()
    return Config.TimeInShell or 18
end)