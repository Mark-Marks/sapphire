declare interface SignalNode<T> {
    Next?: SignalNode<T>;
    Callback: (this: SignalNode<T>, Value: T) => void;
}

declare interface Signal<T> {
    Root?: SignalNode<T>;

    Connect(this: Signal<T>, Callback: (Value: T) => void): () => void;
    Wait(this: Signal<T>): T;
    Once(this: Signal<T>, Callback: (Value: T) => void): () => void;
    Fire(this: Signal<T>, Value: T): void;
    DisconnectAll(this: Signal<T>): void;
}

/**
 * Registerable singleton.
 */
export interface singleton {
    /**
     * The name of the ModuleScript which holds the singleton. Overwritten by sapphire.
     */
    identifier?: string;
    /**
     * Any singleton without priority will automatically have it's priority set to 1.
     */
    priority?: number;

    /**
     * Initializes the singleton.
     * Called prior to all singletons being started and their lifecycles ran.
     * `.start()` should be preferred unless you need `.init()`'s unique behaviour.
     * ⚠️ Do not yield! This is called on the main thread.
     */
    init?(): void;
    /**
     * Starts the singletno.
     * Called after all singletons are initialized, but before other lifecycles are ran.
     * This is called in another thread and can yield.
     */
    start?(): void;

    [key: string]: any;
}

/**
 * Sapphire extension.
 * Extensions are in their simplest form singletons that are instantly ran.
 */
export interface extension {
    /**
     * What to identify the extension by.
     */
    identifier: string;

    /**
     * Starts the extension. This is called prior to any methods being registered.
     * @param sapphire SapphireObject
     */
    extension(sapphire: SapphireObject): void;

    /**
     * Registers the given methods within sapphire.
     */
    methods?: Map<string, (singleton: singleton) => void>;

    [key: string]: any;
}

declare interface SapphireObject {
    /**
     * List of signals ran during certain stages.
     */
    signals: {
        /**
         * Runs after an extension is registered.
         */
        on_extension_registered: Signal<extension>;
        /**
         * Runs after a singleton is registered.
         */
        on_singleton_registered: Signal<singleton>;
        /**
         * Runs after a singleton is initialized.
         */
        on_singleton_initialized: Signal<singleton>;
        /**
         * Runs after a singleton is started.
         */
        on_singleton_started: Signal<singleton>;
    };

    /**
     * @private
     * Map of identifiers to registered singletons.
     * ⚠️ Use `.register_singleton()` or `.register_singletons()` instead of editing directly.
     */
    _singletons: Map<string, singleton>;
    /**
     * @private
     * Map of identifiers to registered extensions.
     * ⚠️ Use `.use()` instead of editing directly.
     */
    _extensions: Map<string, extension>;
    /**
     * @private
     * Map of identifiers to extended methods.
     * ⚠️ Use an extension instead of editing directly.
     */
    _extra_methods: Map<string, (singleton_method: () => void) => void>;

    /**
     * Uses an extension.
     * @param this SapphireObject
     * @param extension extension
     * @returns SapphireObject
     */
    use(this: SapphireObject, extension: extension): SapphireObject;

    /**
     * Registers a singleton.
     * @param this SapphireObject
     * @param mod ModuleScript
     * @returns SapphireObject
     */
    register_singleton(this: SapphireObject, mod: ModuleScript): SapphireObject;

    /**
     * Registers multiple singletons parented to a container.
     * @param this SapphireObject
     * @param container Folder
     * @returns SapphireObject
     */
    register_singletons(
        this: SapphireObject,
        container: Folder,
    ): SapphireObject;

    /**
     * Starts all singletons.
     * @param this SapphireObject
     */
    start(this: SapphireObject): void;
}

declare function sapphire(): SapphireObject;

export namespace sapphire {
    export { SapphireObject as sapphire };
}
