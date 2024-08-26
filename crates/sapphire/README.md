# sapphire
A lightweight module loader or a batteries included framework

# API

## Types

### SignalNode<T...>
```luau
PRIVATE type SignalNode<T...> = {
    Next: SignalNode<T...>?,
    Callback: (T...) -> (),
}
```

### Signal<T...>
[red-blox/signal](https://github.com/red-blox/Util/blob/main/libs/Signal/Signal.luau) signal type.
```luau
type Signal<T...> = {
    Root: SignalNode<T...>?,

    Connect: (self: Signal<T...>, Callback: (T...) -> ()) -> () -> (),
    Wait: (self: Signal<T...>) -> T...,
    Once: (self: Signal<T...>, Callback: (T...) -> ()) -> (),
    Fire: (self: Signal<T...>, T...) -> (),
    DisconnectAll: (self: Signal<T...>) -> (),
}
```

### singleton
Registerable singleton.
```luau
type singleton = {
    --- The name of the ModuleScript which holds the singleton. Overwritten by sapphire.
    identifier: string?,
    --- Any singleton without priority will automatically have its priority set to 1, where 1 is the lowest priority.
    priority: number?,

    --- Initializes the singleton.
    --- Called prior to all singletons being started and their lifecycles ran.
    --- `.start()` should be preferred unless you need `.init()`'s unique behaviour.
    init: (() -> ())?,
    --- Starts the singleton.
    --- Called after all singletons are initialized, but before other lifecycles are ran.
    --- This is called in another thread and can yield.
    start: (() -> ())?,

    [string]: any,
}
```

### extension
Extensions are in their simplest form singletons that are instantly ran.
```luau
type extension = {
    --- What to identify the extension by.
    identifier: string,

    --- Starts the extension. This is called prior to any methods being registered.
    extension: (sapphire: sapphire) -> (),

    --- Registers the given methods within sapphire.
    methods: { [string]: (singleton: singleton) -> () },

    [string]: any,
}
```

### sapphire
```luau
type sapphire = {
    signals = {
        on_extension_registerd: Signal<extension>,
        on_singleton_registered: Signal<singleton>,
        on_singleton_initialized: Signal<singleton>,
        on_singleton_started: Signal<singleton>,
    },

    _singletons: { [string]: singleton },
    _extensions: { [string]: extension },
    _extra_methods: { [string]: (singleton: singleton) -> () },

    use: (self: sapphire, extension: extension) -> sapphire,
    register_singleton: (self: sapphire, mod: ModuleScript) -> sapphire,
    register_singletons: (self: sapphire, container: Folder) -> sapphire,
    start: (self: sapphire) -> (),
}
```

## Registered methods

### .init()
> [!TIP]
> `.init()` and `.start()` are optional, singletons can exist without them.
Called before singletons are started.
Yielding here yields everything else.
```luau
() -> ()
```

### .start()
> [!TIP]
> `.init()` and `.start()` are optional, singletons can exist without them.
Spawned with `task.spawn` after all singletons are initialized.
```luau
() -> ()
```

## Note
> [!NOTE]
> Sapphire returns a function which is used to construct it.
> ```luau
> () -> sapphire
> ```
> All of the following exports and function definitions are of what's returned by the constructor.

## Exports

### .signals
List of signals ran during certain stages.
```luau
{
    -- Runs after an extension is registered.
    on_extension_registered: Signal<extension>,
    --- Runs after a singleton is registered.
    on_singleton_registered: Signal<singleton>,
    --- Runs after a singleton is initialized.
    on_singleton_initialized: Signal<singleton>,
    --- Runs after a singleton is started.
    on_singleton_started: Signal<singleton>,
}
```

### ._singletons
Readonly map of identifiers to registered singletons.
> [!WARNING]
> Use `:register_singleton()` or `:register_singletons()` instead of editing directly.

### ._extensions
Readonly map of identifiers to registered extensions.
> [!WARNING]
> Use `:use()` instead of editing directly.

### .extra_methods
Readonly array of registered extended methods.
> [!WARNING]
> Use an extension instead of editing directly.

## Functions

### :use()
Uses an extension.
```luau
(
    self: sapphire,
    extension: extension
) -> sapphire
```

### :register_singleton()
Registers a singleton.
```luau
(
    self: sapphire,
    mod: ModuleScript
) -> sapphire
```

### :register_singletons()
Registers multiple singletons parented to a container - wrapper around `:register_singleton()`.
```luau
(
    self: sapphire,
    container: Folder
) -> sapphire
```

### :start()
Starts all singletons.
```luau
(
    self: sapphire
) -> ()
```
