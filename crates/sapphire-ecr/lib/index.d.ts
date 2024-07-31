import type { Handle, Entity } from "@rbxts/ecr";
import type { singleton } from "@rbxts/sapphire";

declare type loop_type = "Stepped" | "Heartbeat" | "RenderStepped";
declare interface system {
    /** Fires every `RunService.Stepped` */
    runner(delta_time: number): void;
    /** 1 = lowest priority */
    priority?: number;
    /** Defaults to "Stepped" */
    loop_type?: loop_type;
}

declare interface spawner<T> {
    /**
     * Creates an entity with the given components.
     * @param components T[]
     * @return ecr.entity
     */
    spawn(...components: T[]): ecr.entity;
    /**
     * Creates an entity with the given components and returns a handle to it.
     * @param components T[]
     * @return @ecr.Handle
     */
    spawn_with_handle(...components: T[]): ecr.Handle;
}

declare interface World {
    readonly identifier: "sapphire-ecr";
    readonly methods: Map<string, (singleton: singleton) => void>;

    registry: ecr.registry;
    readonly stepped_systems: system[];
    readonly heartbeat_systems: system[];
    readonly render_stepped_systems: system[];

    extension(): void;
    create_spawner<T>(...components: T[]): spawner<T>;
    spawn_entity(): ecr.entity;
    spawn_entity_with_handle(): ecr.Handle;
}
