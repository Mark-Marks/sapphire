--!strict
local logger = require(script.logger)
local sinks = require(script.sinks)
local types = require(script.types)

export type signal<T...> = types.signal<T...>
export type log_type = types.log_type
export type log = types.log
export type sink = types.sink
export type logger = types.logger

local SapphireLogging = {}
--- @readonly
SapphireLogging.identifier = "sapphire-logging"
--- @readonly
SapphireLogging.methods = {}

--- @readonly
SapphireLogging.cache = {} :: { [string]: logger }

--- @readonly
function SapphireLogging.extension()
    -- noop
end

--- Gets an existing cached logger or creates a new one.
--- @param identifier string
--- @param debug boolean? -- Only applied if the logger doesn't exist
--- @return logger
function SapphireLogging.get(identifier: string, debug: boolean?): logger
    local existing_logger = SapphireLogging.cache[identifier]
    if existing_logger then
        return existing_logger
    end

    local new_logger = logger.new(debug)
    SapphireLogging.cache[identifier] = new_logger
    return new_logger
end

--- A default, uncached logger
SapphireLogging.default = logger.new()

--- Default sinks, connectable with `logger:connect_sink(sink)`
SapphireLogging.sinks = sinks

return SapphireLogging
