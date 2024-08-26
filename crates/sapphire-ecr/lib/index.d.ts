import type { Handle, Entity, Registry } from "@rbxts/ecr";
import type { singleton as sapphire_singleton } from "@rbxts/sapphire";

export type loop_type = "Stepped" | "Heartbeat" | "RenderStepped";
export interface system {
    /** Fires every `RunService.Stepped` */
    runner(delta_time: number): void;
    /** 1 = lowest priority */
    priority?: number;
    /** Defaults to "Stepped" */
    loop_type?: loop_type;
}

export type singleton = sapphire_singleton & {
    system(registry: Registry): (delta_time: number) => void;
    priority?: number;
    loop_type?: loop_type;
};

export interface spawner<T> {
    /**
     * Creates an entity with the given components.
     * @param components T[]
     * @returns ecr.entity
     */
    spawn(...components: T[]): Entity;
    /**
     * Creates an entity with the given components and returns a handle to it.
     * @param components T[]
     * @returns @ecr.Handle
     */
    spawn_with_handle(...components: T[]): Handle;
}

export type raw_data = Map<Entity, Map<number, any>>;

/**
 * A replicator keeps track of all entities with the passed components and their values -
 * whenever a component is changed (add, change, remove) and the replicator listens to it, it's also changed within the contained raw data.\
 * The developer can then calculate the difference on the server and send it to the client every time,
 * on which the difference is then applied to the registry.\
 * Albeit it's called a replicator, it doesn't replicate the data by itself.
 * It allows the developer to use any networking libary to replicate the changes.
 * ```ts
 * // server
 * const replicator = sapphire_ecr.create_replicator(component_a, component_b, ...)
 *
 * export function system() {
 *     return () => {
 *         const difference = replicator.calculate_difference() --> buffer
 *         // There might not be any difference
 *         if (!difference) return
 *         data_replication_event.send_to_all(difference)
 *     }
 * }
 * ```
 * ```ts
 * // client
 * const replicator = sapphire_ecr.create_replicator(component_a, component_b, ...)
 *
 * export function system() {
 *     return () => {
 *         for (const [_, difference] = data_replication_event.poll()) {
 *             replicator.apply_difference(difference)
 *         }
 *     }
 * }
 * ```
 */
export interface replicator {
    /**
     * Gets the full data representing the entire registry.
     * Useful for initial replication to every player.
     * ```ts
     * const replicator = sapphire_ecr.create_replicator(component_a, component_b, ...)
     *
     * Players.PlayerAdded.Connect((player) => {
     *     data_replication_event.send_to(player, replicator.get_full_data())
     * })
     * ```
     * @returns raw_data
     */
    get_full_data(): raw_data;
    /**
     * Calculates the difference between last sent data and currently stored data.
     * ```ts
     * // server
     * const replicator = sapphire_ecr.create_replicator(component_a, component_b, ...)
     *
     * export function system() {
     *     return () => {
     *         const difference = replicator.calculate_difference() --> buffer
     *         // There might not be any difference
     *         if (!difference) return
     *         data_replication_event.send_to_all(difference)
     *     }
     * }
     * ```
     * @returns raw_data?
     */
    calculate_difference(): raw_data | undefined;
    /**
     * Applies the difference to the current data.
     * ```ts
     * // client
     * const replicator = sapphire_ecr.create_replicator(component_a, component_b, ...)
     *
     * export function system() {
     *     return () => {
     *         for (const [_, difference] = data_replication_event.poll()) {
     *             replicator.apply_difference(difference)
     *         }
     *     }
     * }
     * ```
     * @param difference raw_data
     */
    apply_difference(difference: raw_data): void;
}

declare interface WorldDeclaration {
    readonly identifier: "sapphire-ecr";
    readonly methods: Map<string, (singleton: singleton) => void>;

    registry: Registry;
    readonly stepped_systems: system[];
    readonly heartbeat_systems: system[];
    readonly render_stepped_systems: system[];

    extension(): void;
    /**
     * Creates a spawner.
     * ```ts
     * const spawner = sapphire_ecr.create_spawner(components.part, components.velocity, components.part)
     * for (let i = 0; i < 1000; i++) {
     *     spawner.spawn(part_template.Clone(), Vector3.zero, Vector3.zero)
     * }
     * ```
     * @param components T[]
     * @returns spawner<T>
     */
    create_spawner<T>(...components: T[]): spawner<T>;
    /**
     * Creates an entity and returns its id.
     * @returns Entity
     */
    spawn_entity(): Entity;
    /**
     * Creates an entity and returns a handle to it.
     * @returns Handle
     */
    spawn_entity_with_handle(): Handle;
    /**
     * Creates a `replicator`.
     * A replicator keeps track of all entities with the passed components and their values -
     * whenever a component is changed (add, change, remove) and the replicator listens to it, it's also changed within the contained raw data.\
     * The developer can then calculate the difference on the server and send it to the client every time,
     * on which the difference is then applied to the registry.\
     * Albeit it's called a replicator, it doesn't replicate the data by itself.
     * It allows the developer to use any networking libary to replicate the changes.
     * ```ts
     * // server
     * const replicator = sapphire_ecr.create_replicator(component_a, component_b, ...)
     *
     * export function system() {
     *     return () => {
     *         const difference = replicator.calculate_difference() --> buffer
     *         // There might not be any difference
     *         if (!difference) return
     *         data_replication_event.send_to_all(difference)
     *     }
     * }
     * ```
     * ```ts
     * // client
     * const replicator = sapphire_ecr.create_replicator(component_a, component_b, ...)
     *
     * export function system() {
     *     return () => {
     *         for (const [_, difference] = data_replication_event.poll()) {
     *             replicator.apply_difference(difference)
     *         }
     *     }
     * }
     * ```
     * @returns replicator
     */
    create_replicator(): replicator;
}

/** @readonly */
export const identifier: "sapphire-ecr";
/** @readonly */
export const methods: Map<string, (singleton: singleton) => void>;

export const registry: Registry;
/** @readonly */
export const stepped_systems: system[];
/** @readonly */
export const heartbeat_systems: system[];
/** @readonly */
export const render_stepped_systems: system[];

/** Do not call. */
export function extension(): void;
/**
 * Creates a spawner.
 * ```ts
 * const spawner = sapphire_ecr.create_spawner(components.part, components.velocity, components.position)
 * for (let i = 0; i < 1000; i++) {
 *     spawner.spawn(part_template.Clone(), new Vector3(0, 0, 0), new Vector3(0, 0, 0))
 * }
 * ```
 * @generic T
 * @param components T[]
 * @returns spawner<T>
 */
export function create_spawner<T>(...components: T[]): spawner<T>;
/**
 * Creates an entity and returns it's id.
 * @returns Entity
 */
export function spawn_entity(): Entity;
/**
 * Creates an entity and returns a handle to it.
 * @returns Handle
 */
export function spawn_entity_with_handle(): Handle;
