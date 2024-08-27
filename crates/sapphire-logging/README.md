# sapphire-logging
A simple logging libary with a logbook for [Mark-Marks/sapphire](https://github.com/Mark-Marks/sapphire)

# Installation
1. Install it with wally
```toml
[dependencies]
sapphire_logging = "mark-marks/sapphire-logging@LATEST"
```
2. `wally install`
3. Extend sapphire with it
```luau
local sapphire_logging = require("@pkg/sapphire_logging")

sapphire
    :use(sapphire_logging)
```

# API

## Types

### signal<T...>
```luau
type signal<T...> = {
    Root: signal_node<T...>?,

    Connect: (self: signal<T...>, Callback: (T...) -> ()) -> () -> (),
    Wait: (self: signal<T...>) -> T...,
    Once: (self: signal<T...>, Callback: (T...) -> ()) -> () -> (),
    Fire: (self: signal<T...>, T...) -> (),
    DisconnectAll: (self: signal<T...>) -> (),
}
```

### log_type
```luau
type log_type = "info" | "debug" | "warn" | "error" | "fatal"
```

### log
```luau
type log = {
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
```

### sink
```luau
type sink = (log) -> ()
```

### logger
```luau
type logger = {
    _debug: boolean,
    msg_out: signal<log>,
    logbook: { log },

    new: (debug: boolean?) -> logger,
    write: (self: logger, log_type: log_type, msg: string, trace: string) -> log,
    debug: (self: logger, msg: string) -> log?,
    warn: (self: logger, msg: string) -> log,
    error: (self: logger, msg: string) -> log,
    fatal: (self: logger, msg: string) -> (),

    connect_sink: (self: logger, sink: sink) -> () -> (),
}
```

## Exports

### .identifier
Readonly, extension identifier required by sapphire.
```luau
type identifier = string
```

### .methods
Readonly
```luau
type methods = {}
```

### .cache
Readonly, cache for `sapphire_logging.get()`
```luau
type cache = { [string]: logger }
```

### .default
A default, uncached logger
```luau
type default = logger
```

### .sinks
Default sinks, connectable with `logger:connect_sink()`
```luau
type sinks = {
    --- Roblox logging sink.
    roblox: sink,
}
```

## Registered Methods

N/A

## Functions

### .extensions()
Readonly, required by sapphire for extension startup.
```luau
() -> ()
```

### .get()
Gets an existing cached logger or creates a new one.
```luau
(
    identifier: string,
    debug: boolean?, -- Only applied if the logger doesn't exist
) -> logger
```

## logger

### ._debug
Readonly - log debug messages?
```luau
type _debug = boolean
```

### .msg_out
Readonly - on log signal, connect with `:connect_sink()`
```luau
type msg_out = signal<log>
```

### .logbook
Readonly logbook of all logs that happened
```luau
type logbook = { log }
```

### .new()
Creates a new logger.
```luau
(
    debug: boolean? --  Should debug messages be logged? Defaults to false
) -> logger
```

### :write()
Writes a message to the logger.
Prefer to use the logging methods instead of this.
```luau
(
    self: logger,
    log_type: log_type,
    msg: string,
    trace: string -- Full traceback of all function calls leading to this
) -> log
```

### :info()
Writes an `info` to the logger.
```luau
(
    self: logger,
    msg: string
) -> log
```

### :debug()
Writes a `debug` to the logger, IF logger is in debug mode.
```luau
(
    self: logger,
    msg: string
) -> log?
```

### :warn()
Writes a `warn` to the logger.
```luau
(
    self: logger,
    msg: string
) -> log
```

### :error()
Writes an `error` to the logger, continues execution.
```luau
(
    self: logger,
    msg: string
) -> log
```

### :fatal()
Kills the current thread after writing a `fatal` to the logger.
```luau
(
    self: logger,
    msg: string
)
```

### :connect_sink()
Connects the given sink to the loggers `msg_out` signal.
Returns a disconnect function.
```luau
(
    self: logger,
    sink: sink
) -> () -> ()
```
