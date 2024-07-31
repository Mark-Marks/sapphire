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

declare interface WorldDeclaration {
    readonly identifier: "sapphire-ecr";
    readonly methods: Map<string, (singleton: singleton) => void>;

    registry: Registry;
    readonly stepped_systems: system[];
    readonly heartbeat_systems: system[];
    readonly render_stepped_systems: system[];

    extension(): void;
    create_spawner<T>(...components: T[]): spawner<T>;
    spawn_entity(): Entity;
    spawn_entity_with_handle(): Handle;
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
