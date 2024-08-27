--!strict
local signal = require(script.Parent.Parent.signal)

local types = require(script.Parent.types)
type log_type = types.log_type
type log = types.log

local function kill()
    local thread = coroutine.running()
    task.defer(coroutine.close, thread)
    return coroutine.yield()
end

local logger = {} :: types.logger_interface
logger.__index = logger

function logger.new(debug: boolean?)
    local self = {
        _debug = debug or false,
        logbook = {},
        msg_out = signal(),
    }

    return setmetatable(self, logger)
end

function logger:write(log_type: log_type, msg: string, trace: string): log
    local log = {
        timestamp = {
            clock = os.clock(),
            unix = os.time(),
        },
        type = log_type,
        msg = msg,
        trace = trace,
    }

    table.insert(self.logbook, log)
    self.msg_out:Fire(log)
    return log
end

function logger:info(msg: string): log
    local trace = debug.traceback(nil, 2)
    return self:write("info", msg, trace)
end

function logger:debug(msg: string): log?
    if not self._debug then
        return
    end

    local trace = debug.traceback(nil, 2)
    return self:write("debug", msg, trace)
end

function logger:warn(msg: string): log
    local trace = debug.traceback(nil, 2)
    return self:write("warn", msg, trace)
end

function logger:error(msg: string): log
    local trace = debug.traceback(nil, 2)
    return self:write("error", msg, trace)
end

function logger:fatal(msg: string)
    local trace = debug.traceback(nil, 2)
    self:write("fatal", msg, trace)
    kill()
end

function logger:connect_sink(sink: types.sink)
    return self.msg_out:Connect(sink)
end

return logger
