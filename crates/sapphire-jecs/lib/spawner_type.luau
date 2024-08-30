--!strict
type entity<T = nil> = number & {
    __T: T,
}

type id<T = nil> = entity<T> | number

local handle = require(script.Parent.handle)
type handle = handle.handle

export type spawner<T...> = {
    --- Creates an entity with the given components.
    --- @param ... T...
    --- @return entity
    spawn: (T...) -> entity,
    --- Creates an entity with the given components and returns a handle to it.
    --- @param ... T...
    --- @return handle
    spawn_with_handle: (T...) -> handle,
}

-- Very beautiful type incoming!
-- Sadly this has to be done, components are of different types than their values (`entity<T>` vs `T`)
export type create_spawner =
    (<A>(id<A>) -> spawner<A>)
    & (<A, B>(id<A>, id<B>) -> spawner<A, B>)
    & (<A, B, C>(id<A>, id<B>, id<C>) -> spawner<A, B, C>)
    & (<A, B, C, D>(id<A>, id<B>, id<C>, id<D>) -> spawner<A, B, C, D>)
    & (<A, B, C, D, E>(id<A>, id<B>, id<C>, id<D>, id<E>) -> spawner<A, B, C, D, E>)
    & (<A, B, C, D, E, F>(id<A>, id<B>, id<C>, id<D>, id<E>, id<F>) -> spawner<A, B, C, D, E, F>)
    & (<A, B, C, D, E, F, G>(id<A>, id<B>, id<C>, id<D>, id<E>, id<F>, id<G>) -> spawner<A, B, C, D, E, F, G>)
    & (<A, B, C, D, E, F, G, H>(
        id<A>,
        id<B>,
        id<C>,
        id<D>,
        id<E>,
        id<F>,
        id<G>,
        id<H>
    ) -> spawner<A, B, C, D, E, F, G, H>)
    & (<A, B, C, D, E, F, G, H, I>(
        id<A>,
        id<B>,
        id<C>,
        id<D>,
        id<E>,
        id<F>,
        id<G>,
        id<H>,
        id<I>
    ) -> spawner<A, B, C, D, E, F, G, H, I>)
    & (<A, B, C, D, E, F, G, H, I, J>(
        id<A>,
        id<B>,
        id<C>,
        id<D>,
        id<E>,
        id<F>,
        id<G>,
        id<H>,
        id<I>,
        id<J>
    ) -> spawner<A, B, C, D, E, F, G, H, I, J>)
    & (<A, B, C, D, E, F, G, H, I, J, K>(
        id<A>,
        id<B>,
        id<C>,
        id<D>,
        id<E>,
        id<F>,
        id<G>,
        id<H>,
        id<I>,
        id<J>,
        id<K>
    ) -> spawner<A, B, C, D, E, F, G, H, I, J, K>)
    & (<A, B, C, D, E, F, G, H, I, J, K, L>(
        id<A>,
        id<B>,
        id<C>,
        id<D>,
        id<E>,
        id<F>,
        id<G>,
        id<H>,
        id<I>,
        id<J>,
        id<K>,
        id<L>
    ) -> spawner<A, B, C, D, E, F, G, H, I, J, K, L>)
    & (<A, B, C, D, E, F, G, H, I, J, K, L, M>(
        id<A>,
        id<B>,
        id<C>,
        id<D>,
        id<E>,
        id<F>,
        id<G>,
        id<H>,
        id<I>,
        id<J>,
        id<K>,
        id<L>,
        id<M>
    ) -> spawner<A, B, C, D, E, F, G, H, I, J, K, L, M>)
    & (<A, B, C, D, E, F, G, H, I, J, K, L, M, N>(
        id<A>,
        id<B>,
        id<C>,
        id<D>,
        id<E>,
        id<F>,
        id<G>,
        id<H>,
        id<I>,
        id<J>,
        id<K>,
        id<L>,
        id<M>,
        id<N>
    ) -> spawner<A, B, C, D, E, F, G, H, I, J, K, L, M, N>)
    & (<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O>(
        id<A>,
        id<B>,
        id<C>,
        id<D>,
        id<E>,
        id<F>,
        id<G>,
        id<H>,
        id<I>,
        id<J>,
        id<K>,
        id<L>,
        id<M>,
        id<N>,
        id<O>
    ) -> spawner<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O>)
    & (<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P>(
        id<A>,
        id<B>,
        id<C>,
        id<D>,
        id<E>,
        id<F>,
        id<G>,
        id<H>,
        id<I>,
        id<J>,
        id<K>,
        id<L>,
        id<M>,
        id<N>,
        id<O>,
        id<P>
    ) -> spawner<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P>)
    & (<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q>(
        id<A>,
        id<B>,
        id<C>,
        id<D>,
        id<E>,
        id<F>,
        id<G>,
        id<H>,
        id<I>,
        id<J>,
        id<K>,
        id<L>,
        id<M>,
        id<N>,
        id<O>,
        id<P>,
        id<Q>
    ) -> spawner<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q>)
    & (<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R>(
        id<A>,
        id<B>,
        id<C>,
        id<D>,
        id<E>,
        id<F>,
        id<G>,
        id<H>,
        id<I>,
        id<J>,
        id<K>,
        id<L>,
        id<M>,
        id<N>,
        id<O>,
        id<P>,
        id<Q>,
        id<R>
    ) -> spawner<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R>)
    & (<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S>(
        id<A>,
        id<B>,
        id<C>,
        id<D>,
        id<E>,
        id<F>,
        id<G>,
        id<H>,
        id<I>,
        id<J>,
        id<K>,
        id<L>,
        id<M>,
        id<N>,
        id<O>,
        id<P>,
        id<Q>,
        id<R>,
        id<S>
    ) -> spawner<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S>)
    & (<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T>(
        id<A>,
        id<B>,
        id<C>,
        id<D>,
        id<E>,
        id<F>,
        id<G>,
        id<H>,
        id<I>,
        id<J>,
        id<K>,
        id<L>,
        id<M>,
        id<N>,
        id<O>,
        id<P>,
        id<Q>,
        id<R>,
        id<S>,
        id<T>
    ) -> spawner<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T>)
    & (<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U>(
        id<A>,
        id<B>,
        id<C>,
        id<D>,
        id<E>,
        id<F>,
        id<G>,
        id<H>,
        id<I>,
        id<J>,
        id<K>,
        id<L>,
        id<M>,
        id<N>,
        id<O>,
        id<P>,
        id<Q>,
        id<R>,
        id<S>,
        id<T>,
        id<U>
    ) -> spawner<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U>)
    & (<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V>(
        id<A>,
        id<B>,
        id<C>,
        id<D>,
        id<E>,
        id<F>,
        id<G>,
        id<H>,
        id<I>,
        id<J>,
        id<K>,
        id<L>,
        id<M>,
        id<N>,
        id<O>,
        id<P>,
        id<Q>,
        id<R>,
        id<S>,
        id<T>,
        id<U>,
        id<V>
    ) -> spawner<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V>)
    & (<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W>(
        id<A>,
        id<B>,
        id<C>,
        id<D>,
        id<E>,
        id<F>,
        id<G>,
        id<H>,
        id<I>,
        id<J>,
        id<K>,
        id<L>,
        id<M>,
        id<N>,
        id<O>,
        id<P>,
        id<Q>,
        id<R>,
        id<S>,
        id<T>,
        id<U>,
        id<V>,
        id<W>
    ) -> spawner<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W>)
    & (<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X>(
        id<A>,
        id<B>,
        id<C>,
        id<D>,
        id<E>,
        id<F>,
        id<G>,
        id<H>,
        id<I>,
        id<J>,
        id<K>,
        id<L>,
        id<M>,
        id<N>,
        id<O>,
        id<P>,
        id<Q>,
        id<R>,
        id<S>,
        id<T>,
        id<U>,
        id<V>,
        id<W>,
        id<X>
    ) -> spawner<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X>)
    & (<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y>(
        id<A>,
        id<B>,
        id<C>,
        id<D>,
        id<E>,
        id<F>,
        id<G>,
        id<H>,
        id<I>,
        id<J>,
        id<K>,
        id<L>,
        id<M>,
        id<N>,
        id<O>,
        id<P>,
        id<Q>,
        id<R>,
        id<S>,
        id<T>,
        id<U>,
        id<V>,
        id<W>,
        id<X>,
        id<Y>
    ) -> spawner<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y>)
    & (<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z>(
        id<A>,
        id<B>,
        id<C>,
        id<D>,
        id<E>,
        id<F>,
        id<G>,
        id<H>,
        id<I>,
        id<J>,
        id<K>,
        id<L>,
        id<M>,
        id<N>,
        id<O>,
        id<P>,
        id<Q>,
        id<R>,
        id<S>,
        id<T>,
        id<U>,
        id<V>,
        id<W>,
        id<X>,
        id<Y>,
        id<Z>
    ) -> spawner<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z>)

return "spawner_type"
