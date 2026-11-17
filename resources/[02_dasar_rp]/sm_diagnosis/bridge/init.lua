local config = require 'config.init'

return require(('bridge.%s.%s'):format(config.framework, lib.context))
