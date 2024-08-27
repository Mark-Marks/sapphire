--!strict
-- latest JECS types that fix some issues
-- this will eat shit and die when the next JECS release is cut
export type i53 = number
export type i24 = number

export type Ty = { i53 }
export type ArchetypeId = number

export type Column = { any }

export type ArchetypeEdge = {
    add: Archetype,
    remove: Archetype,
}

export type Archetype = {
    id: number,
    edges: { [i53]: ArchetypeEdge },
    types: Ty,
    type: string | number,
    entities: { number },
    columns: { Column },
    records: { ArchetypeRecord },
}
export type Record = {
    archetype: Archetype,
    row: number,
    dense: i24,
    componentRecord: ArchetypeMap,
}

export type EntityIndex = { dense: { [i24]: i53 }, sparse: { [i53]: Record } }

export type ArchetypeRecord = {
    count: number,
    column: number,
}

export type ArchetypeMap = {
    cache: { ArchetypeRecord },
    flags: number,
    first: ArchetypeMap,
    second: ArchetypeMap,
    parent: ArchetypeMap,
    size: number,
}

export type ComponentIndex = { [i24]: ArchetypeMap }

export type Archetypes = { [ArchetypeId]: Archetype }

export type ArchetypeDiff = {
    added: Ty,
    removed: Ty,
}

export type CompatibleArchetype = { archetype: Archetype, indices: { number } }

export type Pair = number

export type Item<T...> = (self: Query<T...>) -> (Entity, T...)

export type Entity<T = nil> = number & { __T: T }

export type Iter<T...> = (query: Query<T...>) -> () -> (Entity, T...)

export type Query<T...> = typeof(setmetatable({}, {
    __iter = (nil :: any) :: Iter<T...>,
})) & {
    iter: Iter<T...>,
    next: Item<T...>,
    with: (self: Query<T...>, ...i53) -> Query<T...>,
    without: (self: Query<T...>, ...i53) -> Query<T...>,
    replace: (self: Query<T...>, <U...>(T...) -> U...) -> (),
    archetypes: () -> { Archetype },
}

export type World = {
    archetypeIndex: { [string]: Archetype },
    archetypes: Archetypes,
    componentIndex: ComponentIndex,
    entityIndex: EntityIndex,
    ROOT_ARCHETYPE: Archetype,

    nextComponentId: number,
    nextEntityId: number,
    nextArchetypeId: number,
} & {
    --- Creates a new entity
    entity: (self: World) -> Entity,
    --- Creates a new entity located in the first 256 ids.
    --- These should be used for static components for fast access.
    component: <T>(self: World) -> Entity<T>,
    --- Gets the target of an relationship. For example, when a user calls
    --- `world:target(id, ChildOf(parent))`, you will obtain the parent entity.
    target: (self: World, id: Entity, relation: Entity) -> Entity?,
    --- Deletes an entity and all it's related components and relationships.
    delete: (self: World, id: Entity) -> (),

    --- Adds a component to the entity with no value
    add: <T>(self: World, id: Entity, component: Entity<T>) -> (),
    --- Assigns a value to a component on the given entity
    set: <T>(self: World, id: Entity, component: Entity<T>, data: T) -> (),

    -- Clears an entity from the world
    clear: (self: World, id: Entity) -> (),
    --- Removes a component from the given entity
    remove: (self: World, id: Entity, component: Entity) -> (),
    --- Retrieves the value of up to 4 components. These values may be nil.
    get: (<A>(self: World, id: any, Entity<A>) -> A)
        & (<A, B>(self: World, id: Entity, Entity<A>, Entity<B>) -> (A, B))
        & (<A, B, C>(self: World, id: Entity, Entity<A>, Entity<B>, Entity<C>) -> (A, B, C))
        & <A, B, C, D>(self: World, id: Entity, Entity<A>, Entity<B>, Entity<C>, Entity<D>) -> (A, B, C, D),

    has: (self: World, ...Entity) -> boolean,

    parent: (self: World, entity: Entity) -> Entity,

    --- Searches the world for entities that match a given query
    query: (<A>(self: World, Entity<A>) -> Query<A>)
        & (<A, B>(self: World, Entity<A>, Entity<B>) -> Query<A, B>)
        & (<A, B, C>(self: World, Entity<A>, Entity<B>, Entity<C>) -> Query<A, B, C>)
        & (<A, B, C, D>(self: World, Entity<A>, Entity<B>, Entity<C>, Entity<D>) -> Query<A, B, C, D>)
        & (<A, B, C, D, E>(
            self: World,
            Entity<A>,
            Entity<B>,
            Entity<C>,
            Entity<D>,
            Entity<E>
        ) -> Query<A, B, C, D, E>)
        & (<A, B, C, D, E, F>(
            self: World,
            Entity<A>,
            Entity<B>,
            Entity<C>,
            Entity<D>,
            Entity<E>,
            Entity<F>
        ) -> Query<A, B, C, D, E, F>)
        & (<A, B, C, D, E, F, G>(
            self: World,
            Entity<A>,
            Entity<B>,
            Entity<C>,
            Entity<D>,
            Entity<E>,
            Entity<F>,
            Entity<G>
        ) -> Query<A, B, C, D, E, F, G>)
        & (<A, B, C, D, E, F, G, H>(
            self: World,
            Entity<A>,
            Entity<B>,
            Entity<C>,
            Entity<D>,
            Entity<E>,
            Entity<F>,
            Entity<G>,
            Entity<H>,
            ...Entity<any>
        ) -> Query<A, B, C, D, E, F, G, H>),
}

return "types"
