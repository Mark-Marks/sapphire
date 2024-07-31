--!strict
local fast_spawn = require(script.Parent.spawn)
local signal = require(script.Parent.signal)

type SignalNode<T...> = {
    Next: SignalNode<T...>?,
    Callback: (T...) -> (),
}

export type Signal<T...> = {
    Root: SignalNode<T...>?,

    Connect: (self: Signal<T...>, Callback: (T...) -> ()) -> () -> (),
    Wait: (self: Signal<T...>) -> T...,
    Once: (self: Signal<T...>, Callback: (T...) -> ()) -> () -> (),
    Fire: (self: Signal<T...>, T...) -> (),
    DisconnectAll: (self: Signal<T...>) -> (),
}

--- @interface
--- Registerable singleton.
export type singleton = {
    -- The name of the ModuleScript which holds the singleton. Overwritten by sapphire.
    identifier: string?,
    --- Any singleton without priority will automatically have it's priority set to 1.
    priority: number?,

    --- Initializes the singleton.\
    --- Called prior to all singletons being started and their lifecycles ran.\
    --- `.start()` should be preferred unless you need `.init()`'s unique behaviour.\
    --- ⚠️ Do not yield! This is called on the main thread.
    init: (() -> ())?,
    --- Starts the singleton.\
    --- Called after all singletons are initialized, but before other lifecycles are ran.\
    --- This is called in another thread and can yield.
    start: (() -> ())?,

    [string]: any,
}

--- @interface
--- Sapphire extension.\
--- Extensions are in their simplest form singletons that are instantly ran.
export type extension = {
    --- What to identify the extension by.
    identifier: string,

    --- Starts the extension. This is called prior to any methods being registered.
    --- @param sapphire sapphire
    extension: (sapphire: sapphire) -> (),

    --- Registers the given methods within sapphire.
    methods: { [string]: (singleton: singleton) -> () }?,

    [string]: any,
}

--- @class
export type sapphire = {
    --- List of signals ran during certain stages.
    signals: {
        --- Runs after an extension is registered.
        on_extension_registered: Signal<extension>,
        --- Runs after a singleton is registered.
        on_singleton_registered: Signal<singleton>,
        --- Runs after a singleton is initialized.
        on_singleton_initialized: Signal<singleton>,
        --- Runs after a singleton is started.
        on_singleton_started: Signal<singleton>,
    },

    --- @private
    --- Map of identifiers to registered singletons.\
    --- ⚠️ Use `:register_singleton()` or `:register_singletons()` instead of editing directly.
    _singletons: { [string]: singleton },
    --- @private
    --- Map of identifiers to registered extensions.\
    --- ⚠️ Use `:use()` instead of editing directly.
    _extensions: { [string]: extension },
    --- @private
    --- Array of registered extended methods.\
    --- ⚠️ Use an extension instead of editing directly.
    _extra_methods: { [string]: (singleton: singleton) -> () },

    --- Uses an extension.
    --- @param self sapphire
    --- @param extension extension
    --- @return sapphire
    use: (self: sapphire, extension: extension) -> sapphire,

    --- Registers a singleton.
    --- @param self sapphire
    --- @param mod ModuleScript
    --- @return sapphire
    register_singleton: (self: sapphire, mod: ModuleScript) -> sapphire,

    --- Registers multiple singletons parented to a container.
    --- @param self sapphire
    --- @param container Folder
    --- @return sapphire
    register_singletons: (self: sapphire, container: Folder) -> sapphire,

    --- Starts all singletons.
    --- @param self sapphire
    start: (self: sapphire) -> (),
}

local function constructor(): sapphire
    local sapphire = {} :: sapphire
    sapphire.signals = {
        on_extension_registered = signal(),
        on_singleton_started = signal(),
        on_singleton_registered = signal(),
        on_singleton_initialized = signal(),
    }
    sapphire._singletons = {}
    sapphire._extensions = {}
    sapphire._extra_methods = {}

    function sapphire:use(extension: extension): sapphire
        if self._extensions[extension.identifier] then
            return self -- Doesn't throw, an extension can register an extension
        end

        task.spawn(extension.extension, self, config :: any)

        for method, registrant in self._extra_methods do
            if not extension[method] then
                continue
            end
            fast_spawn(registrant, extension)
        end

        if extension.methods then
            for method, registrant in extension.methods do
                if self._extra_methods[method] then
                    error(
                        `[sapphire] Extension {extension.identifier} registers method {method} that is already registered!`
                    )
                end

                self._extra_methods[method] = registrant
            end
        end

        self._extensions[extension.identifier] = extension
        self.signals.on_extension_registered:Fire(extension)

        return self
    end

    function sapphire:register_singleton(mod: ModuleScript): sapphire
        if self._singletons[mod.Name] then
            return self -- Doesn't throw, the same singleton could be registered using `:register_singletons` and `:register_singleton`
        end
        local singleton: singleton = require(mod) :: any
        singleton.identifier = mod.Name

        if singleton.init then
            assert(typeof(singleton.init) == "function", `Singleton {mod.Name}'s '.init()' is not of type 'function'.`)
        end
        if singleton.start then
            assert(
                typeof(singleton.start) == "function",
                `Singleton {mod.Name}'s '.start()' is not of type 'function'.`
            )
        end
        if singleton.priority then
            assert(
                typeof(singleton.priority) == "number",
                `Singleton {mod.Name}'s '.priority' is not of type 'number'.`
            )
        else
            singleton.priority = 1
        end

        self._singletons[mod.Name] = singleton
        self.signals.on_singleton_registered:Fire(singleton)

        return self
    end

    function sapphire:register_singletons(container: Folder): sapphire
        for _, child in container:GetChildren() do
            if not child:IsA("ModuleScript") then
                continue
            end

            self:register_singleton(child)
        end

        return self
    end

    function sapphire:start()
        local array_of_singletons = {}
        for _, singleton in self._singletons do
            table.insert(array_of_singletons, singleton)
        end
        table.sort(array_of_singletons, function(a, b)
            return a.priority > b.priority
        end)

        for _, singleton in array_of_singletons do
            if not singleton.init then
                continue
            end

            singleton.init()
            self.signals.on_singleton_initialized:Fire(singleton)
        end

        for _, singleton in array_of_singletons do
            if singleton.start then
                task.spawn(singleton.start)
            end

            for method, registrant in self._extra_methods do
                if not singleton[method] then
                    continue
                end

                fast_spawn(registrant, singleton)
            end

            self.signals.on_singleton_started:Fire(singleton)
        end

        print(`[sapphire] Loaded {#array_of_singletons} singletons.`)
    end

    return sapphire
end

return constructor
