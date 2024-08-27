--!strict
type signal_node<T...> = {
    Next: signal_node<T...>?,
    Callback: (T...) -> (),
}

--- redblox signal type
export type signal<T...> = {
    Root: signal_node<T...>?,

    Connect: (self: signal<T...>, Callback: (T...) -> ()) -> () -> (),
    Wait: (self: signal<T...>) -> T...,
    Once: (self: signal<T...>, Callback: (T...) -> ()) -> () -> (),
    Fire: (self: signal<T...>, T...) -> (),
    DisconnectAll: (self: signal<T...>) -> (),
}

export type log_type = "info" | "debug" | "warn" | "error" | "fatal"

export type log = {
    --- Timestamps representing when the log took place
    timestamp: {
        --- CPU time at the time of log
        clock: number,
        --- Seconds passed since the start of the UNIX epoch at the time of log
        unix: number,
    },
    --- Type of the log
    type: log_type,
    --- Message passed to the log
    msg: string,
    --- Full traceback of all function calls leading to this log
    trace: string,
}

export type sink = (log) -> ()

export type logger_interface = {
    __index: logger_interface,

    --- Creates a new logger.
    --- @param debug boolean? -- Should debug messages be logged? Defaults to false
    --- @return logger
    new: (debug: boolean?) -> logger,
    --- Writes a message to the logger.
    --- Prefer to use the logging methods instead of this.
    --- @param log_type log_type
    --- @param msg string
    --- @param trace string -- Full traceback of all function calls leading to this
    --- @return log
    write: (self: logger, log_type: log_type, msg: string, trace: string) -> log,
    --- Writes an `info` to the logger.
    --- @param self logger
    --- @param msg string
    --- @return log
    info: (self: logger, msg: string) -> log,
    --- Writes a `debug` to the logger, IF logger is in debug mode.
    --- @param self logger
    --- @param msg string
    --- @return log?
    debug: (self: logger, msg: string) -> log?,
    --- Writes a `warn` to the logger.
    --- @param self logger
    --- @param msg string
    --- @return log
    warn: (self: logger, msg: string) -> log,
    --- Writes an `error` to the logger, continues execution.
    --- @param self logger
    --- @param msg string
    --- @return log
    error: (self: logger, msg: string) -> log,
    --- Kills the current thread after writing a `fatal` to the logger.
    --- @param self logger
    --- @param msg string
    fatal: (self: logger, msg: string) -> (),

    --- Connects the given sink to the loggers `msg_out` signal.
    --- Returns a disconnect function.
    --- @param self logger
    --- @param sink sink
    --- @return () -> () -- Disconnect connection
    connect_sink: (self: logger, sink: sink) -> () -> (),
}

export type logger = typeof(setmetatable(
    {} :: {
        --- @readonly
        --- Log debug messages?
        _debug: boolean,
        --- @readonly
        --- On log signal, connect with `:connect_sink()`
        msg_out: signal<log>,
        --- @readonly
        --- Logbook of all logs that happened
        logbook: { log },
    },
    {} :: logger_interface
))

return "types"
