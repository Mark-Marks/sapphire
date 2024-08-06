export interface event<T> {
    /**
     * Sends the data to the server. Client only - throws on the server.
     * @param data T
     */
    send(data: T): void;

    /**
     * Sends the data to the passed player. Server only - throws on the client.
     * @param player Player
     * @param data T
     */
    send_to(player: Player, data: T): void;
    /**
     * Sends the data to all players except the passed player. Server only - throws on the client.
     * @param except Player
     * @param data T
     */
    send_to_all_except(except: Player, data: T): void;
    /**
     * Sends the data to a list of players. Server only - throws on the client.
     * @param players Player[]
     * @param data T
     */
    send_to_list(players: Player[], data: T): void;
    /**
     * Sends the data to all players. Server only - throws on the client.
     * @param data T
     */
    send_to_all(data: T): void;

    /**
     * Received data is instantly fired through a signal, and is also stored in a queue.
     * This function returns an iterator for all packets of data stored in the queue.
     * Once a packet of data is iterated over, it's deleted from the queue.
     * ```ts
     * // `player` is only featured on the server
     * for (const [index, data, player] = event.poll()) {
     *     ...
     *     // the current index is now removed from the queue as it was iterated over; you can only poll in one place
     * }
     * ```
     * @returns () => (number index, T data, Player? player) // Iterator
     */
    poll(): () => LuaTuple<[number, T, Player?]>;
    /**
     * Connects the passed listener to the given event's signal.
     * @param listener (data: T, player?: Player) => void // Listener. The player argument is only passed on the server.
     * @returns () => void // Disconnect function
     */
    listen(listener: (data: T, player?: Player) => void): () => void;
}

export type reliability_type = "reliable" | "unreliable";

export interface packet_props<T> {
    value: T;
    reliability_type?: reliability_type;
}

/**
 * All usable data types, exported from squash. All types with a required number type have been modified for a float32 to be default.\
 * Note that a lot of the docs come from squash itself to have documentation for the types inside of your editor.
 */
declare interface data_types {
    /**
     * Represents a boolean.
     * @returns boolean
     */
    boolean(): boolean;
    /**
     * Unsigned integers are whole numbers that can be serialized using 1 to 8 bytes.\
     * **N = { 0, 1, 2, 3, 4, 5, . . . }**\
     * They may only be positive and can represent all possible permutations of their bits. These are the easiest to wrap our heads around and manipulate. They are often used to implement Fixed Point numbers by multiplying by some scale factor and shifting by some offset, then doing the reverse when deserializing.\
     * ```
     * | Bytes |                     Range                      | Min |     Max    |
     * | 1     | { 0, 1, 2, 3, ..., 253, 254, 255 }             | 0   | 255        |
     * | 2     | { 0, 1, 2, 3, ..., 65,534, 65,535 }            | 0   | 65,535     |
     * | 3     | { 0, 1, 2, 3, ..., 16,777,214, 16,777,215 }    | 0   | 16,777,215 |
     * | ...   | ...                                            | 0   | ...        |
     * | n     | { 0, 1, 2, 3, . . . , 2^(8n) - 2, 2^(8n) - 1 } | 0   | 2^(8n) - 1 |
     * ```
     * **WARNING:** Using 7 or 8 bytes puts uints outside the 52 bit range of representation, leading to inaccurate results.
     * ```ts
     * const cursor = Squash.cursor()
     * Squash.uint(1).ser(cursor, 243)
     * Squash.print(cursor)
     * // Pos: 1 / 8
     * // Buf: { 243 0 0 0 0 0 0 0 }
     * //            ^
     * print(Squash.uint(1).des(cursor))
     * // 243
     * ```
     * ```ts
     * const cursor = Squash.cursor(1)
     * Squash.uint(1).ser(cursor, -13)
     * Squash.print(cursor)
     * // Pos: 1 / 1
     * // Buf: { 243   }
     * //            ^
     * print(Squash.uint(1).des(cursor))
     * // 243
     * ```
     * ```ts
     * const cursor = Squash.cursor(4, 1)
     * Squash.uint(2).ser(cursor, 7365)
     * Squash.print(cursor)
     * // Pos: 3 / 4
     * // Buf: { 0 197 28 0 }
     * //                 ^
     * print(Squash.uint(2).des(cursor))
     * // 7365
     * ```
     * @param bytes number
     * @returns number
     */
    uint(bytes: number): number;
    /**
     * Signed Integers are Integers that can be serialized with 1 through 8 bytes:\
     * **Z = { ..., -2, -1, 0, 1, 2, 3, ... }**\
     * They use 2's Compliment to represent negative numbers. The first bit is called the sign bit and the rest of the bits are called the magnitude bits. The sign bit is 0 for positive numbers and 1 for negative numbers. This implies the range of signed integers is one power of two smaller than the range of unsigned integers with the same number of bits, because the sign bit is not included in the magnitude bits.
     * ```
     * | Bytes |                                 Range                                    |    Min        |       Max      |
     * | 1     | { -128, -127, . . . , 126, 127 }                                         | -128          | 127            |
     * | 2     | { -32,768, -32,767, . . . , 32,766, 32,767 }                             | -32,768       | 32,767         |
     * | 3     | { -8,388,608, -8,388,607, . . . , 8,388,606, 8,388,607 }                 | -8,388,608    | 8,388,607      |
     * | ...   | ...                                                                      | ...           | ...            |
     * | n     | { -2^(8n - 1), -2^(8n - 1) + 1, . . . , 2^(8n - 1) - 2, 2^(8n - 1) - 1 } | -2^(8n - 1)   | 2^(8n - 1) - 1 |
     * ```
     * **WARNING:** Using 7 or 8 bytes puts ints outside the 52 bit range of representation, leading to inaccurate results.
     * ```ts
     * const cursor = Squash.cursor()
     * Squash.int(1).ser(cursor, 127)
     * Squash.print(cursor)
     * // Pos: 1 / 8
     * // Buf: { 127 0 0 0 0 0 0 0 }
     * //            ^
     * print(Squash.int(1).des(cursor))
     * // 127
     * ```
     * ```ts
     * const cursor = Squash.cursor()
     * Squash.int(1).ser(cursor, -127)
     * Squash.print(cursor)
     * // Pos: 1 / 8
     * // Buf: { 129 0 0 0 0 0 0 0 }
     * //            ^
     * print(Squash.int(1).des(cursor))
     * // -127
     * ```
     * ```ts
     * const cursor = Squash.cursor()
     * Squash.int(1).ser(cursor, 128)
     * Squash.print(cursor)
     * // Pos: 1 / 8
     * // Buf: { 128 0 0 0 0 0 0 0 }
     * //            ^
     * print(Squash.int(1).des(cursor))
     * // -128
     * ```
     * ```ts
     * const cursor = Squash.cursor()
     * Squash.int(1).ser(cursor, -128)
     * Squash.print(cursor)
     * // Pos: 1 / 8
     * // Buf: { 128 0 0 0 0 0 0 0 }
     * //            ^
     * print(Squash.int(1).des(cursor))
     * // -128
     * ```
     * @param bytes number
     * @returns number
     */
    int(bytes: number): number;
    /**
     * Floating Point Numbers are Rational Numbers that can be represented with either 4 or 8 bytes:\
     * **Q = { ..., -2.0, ..., -1.0, ..., 0.0, ..., 1.0, ..., 2.0, ... }**\
     * With 4 bytes (called a `float`), the possible values that can be represented are a bit more complicated. The first bit is used to represent the sign of the number, the next 8 bits are used to represent the exponent, and the last 23 bits are used to represent the mantissa.\
     * The formula for calculating the value of a `float` from its sign, exponent, and mantissa can be found at [this wikipedia article](https://en.wikipedia.org/wiki/Single-precision_floating-point_format).\
     * With 8 bytes (called a `double`). The first bit is used to represent the sign of the number, the next 11 bits are used to represent the exponent, and the last 52 bits are used to represent the mantissa.\
     * The formula for calculating the value of a `double` from its sign, exponent, and mantissa can be found at [this wikipedia article](https://en.wikipedia.org/wiki/Double-precision_floating-point_format).
     * ```ts
     * const cursor = Squash.cursor()
     * Squash.number(4).ser(cursor, 174302.923957475339573)
     * Squash.print(cursor)
     * // Pos: 4 / 8
     * // Buf: { 187 55 42 72 0 0 0 0 }
     * //                     ^
     * print(Squash.number(4).des(cursor))
     * // 174302.921875
     * ```
     * ```ts
     * const cursor = Squash.cursor()
     * Squash.number(8).ser(cursor, -17534840302.923957475339573)
     * Squash.print(cursor)
     * // Pos: 8 / 8
     * // Buf: { 34 178 187 183 161 84 16 194   }
     * //                                     ^
     * print(Squash.number(8).des(cursor))
     * // -17534840302.923958
     * ```
     * @param bytes number? - Defaults to 4.
     * @returns number
     */
    number(bytes?: number): number;
    /**
     * Strings are a bit trickier conceptually since they have a variable size. However to serialize with Squash is actually easier than numbers! Every character is a byte, so it is useful to think of strings are arrays of bytes. After writing each character in sequence, we need a mechanism to count how many characters we've serialized else we'll never know when to stop reading when deserializing. Right after the string, the length is serialized as a Variable Length Quantity to use only necessary bytes.
     * ```ts
     * const cursor = Squash.cursor()
     * Squash.string().ser(cursor, "Hello, World!")
     * Squash.print(cursor)
     * // Pos: 14 / 18
     * // Buf: { 72 101 108 108 111 44 32 87 111 114 108 100 33 141 0 0 0 0 }
     * //                                                           ^
     * print(Squash.string().des(cursor))
     * // Hello, World!
     * ```
     * ```ts
     * const cursor = Squash.cursor()
     * Squash.string(13).ser(cursor, "Hello, World!")
     * Squash.print(cursor)
     * // Pos: 13 / 18
     * // Buf: { 72 101 108 108 111 44 32 87 111 114 108 100 33 0 0 0 0 0 }
     * //                                                       ^
     * print(Squash.string(13).des(cursor))
     * // Hello, World!
     * ```
     * @param length number? - Not giving a length makes squash serialize the length dynamically.
     * @returns string
     */
    string(length?: number): string;
    /**
     * Represents a buffer with an optional length of [length].
     * @param length number? - Not giving a length makes squash serialize the length dynamically.
     * @returns buffer
     */
    buffer(length?: number): buffer;
    /**
     * Sometimes we don't know how many bytes we need to represent a number, or we need to represent a number so large that 8 bytes isn't enough. This is where VLQs come in. They are a binary format to represent arbitrarily large numbers as a sequence of bytes. 7 bits encode the number, 1 bit encodes the end of the number. This means 127 serializes to 1 byte. 128 serializes to 2 bytes. It increments by powers of 128 instead of 256 like bytes do because of the missing bit.
     * ```ts
     * const cursor = Squash.cursor()
     * Squash.vlq().ser(cursor, 10)
     * Squash.print(cursor)
     * // Pos: 1 / 8
     * // Buf: { 138 0 0 0 0 0 0 0 }
     * //            ^
     * print(Squash.vlq().des(cursor))
     * // 10
     * ```
     * ```ts
     * const cursor = Squash.cursor()
     * Squash.vlq().ser(cursor, 130)
     * Squash.print(cursor)
     * // Pos: 2 / 8
     * // Buf: { 129 2 0 0 0 0 0 0 }
     * //              ^
     * print(Squash.vlq().des(cursor))
     * // 130
     * ```
     * ```ts
     * const cursor = Squash.cursor()
     * Squash.vlq().ser(cursor, 547359474)
     * Squash.print(cursor)
     * // Pos: 5 / 8
     * // Buf: { 130 5 0 21 114 0 0 0 }
     * //                       ^
     * print(Squash.vlq().des(cursor))
     * // 547359474
     * ```
     * @returns number
     */
    vlq(): number;
    /**
     * Represents an optional value of type T.
     * @param type T
     * @returns T?
     */
    opt<T>(type: T): T | undefined;
    /**
     * Arrays are a classic table type `{T}`. Like strings, which are also arrays (of bytes), after serializing every element in sequence we append a VLQ representing the count. An array can store an array or any other table type.
     * ```ts
     * const arr = Squash.array
     * const float = Squash.number(4)
     * const myarr = arr(float)
     *
     * const cursor = Squash.cursor()
     * myarr.ser(cursor, [1, 2, 3, 4, 5.5, 6.6, -7.7, -8.9, 10.01])
     * Squash.print(cursor)
     * // Pos: 37 / 40
     * // Buf: { 0 0 128 63 0 0 0 64 0 0 64 64 0 0 128 64 0 0 176 64 51 51 211 64 102 102 246 192 102 102 14 193 246 40 32 65 137 0 0 0 }
     * //                                                                                                                         ^
     * print(myarr.des(cursor))
     * // 1 2 3 4 5.5 6.599999904632568 -7.699999809265137 -8.899999618530273 10.01000022888184
     * ```
     * ```ts
     * const arr = Squash.array
     * const float = Squash.number(4)
     * const myarr = arr(float, 8)
     *
     * const cursor = Squash.cursor()
     * myarr.ser(cursor, [1, 2, 3, 4, 5.5, 6.6, -7.7, -8.9, 10.01])
     * Squash.print(cursor)
     * // Pos: 32 / 40
     * // Buf: { 0 0 128 63 0 0 0 64 0 0 64 64 0 0 128 64 0 0 176 64 51 51 211 64 102 102 246 192 102 102 14 193 0 0 0 0 0 0 0 0 }
     * //                                                                                                        ^
     * print(myarr.des(cursor))
     * // 1 2 3 4 5.5 6.599999904632568 -7.699999809265137 -8.899999618530273
     * ```
     * @param type T
     * @param length number? - Not giving a length makes squash serialize the length dynamically.
     * @returns T[]
     */
    array<T>(type: T, length?: number): T[];
    /**
     * Tuple types `(T...)` are like arrays but not wrapped in a table, and each element can be a different type. Tuples cannot be used in table types, and cannot be nested in other tuples.
     * ```ts
     * const mytuple = squash.tuple(
     *     squash.Vector3(squash.number(8)),
     *     squash.CFrame(squash.int(1)),
     *     squash.BrickColor(),
     *     squash.EnumItem(Enum.HumanoidStateType)
     * )
     *
     * const cursor = squash.cursor()
     * mytuple.ser(cursor, Vector3.new(123456789, 1, 0), CFrame.new(1, 2, 3), BrickColor.new(93), Enum.HumanoidStateType.Freefall)
     * squash.print(cursor)
     * // Pos: 40 / 40
     * // Buf: { 0 0 0 0 0 0 0 0 0 0 0 0 0 0 240 63 0 0 0 96 52 111 157 65 1 0 0 64 64 0 0 0 64 0 0 128 63 194 0 134   }
     * //                                                                                                            ^
     * print(mytuple.des(cursor))
     * // 123456792, 1, 0 1, 2, 3, 1, 0, 0, 0, 1, 0, 0, 0, 1 Medium stone grey Enum.HumanoidStateType.Freefall
     * ```
     * @param types T
     * @returns T
     */
    tuple<T extends []>(...types: T): T;
    /**
     * Records (Structs) `{ prop1: any, prop2: any, ... }` map enumerated string identifiers to different values, like a named tuple. Because all keys are string literals known ahead of time, none of them have to be serialized! A record can store a record or any other table type.\
     * When defining compound types the code can become verbose and difficult to read. If this is an issue, it is encouraged to store each SerDes in a variable with a shorter name.
     * ```ts
     * const playerserdes = Squash.record({
     *     position: squash.Vector2(squash.number(4)),
     *     health: squash.uint(1),
     *     name: squash.string(),
     *     poisoned: squash.boolean(),
     *     items: squash.array(squash.record({
     *         count: squash.vlq(),
     *         name: squash.string(),
     *     })),
     *     inns: squash.map(squash.string(), squash.boolean()),
     *     equipped: squash.opt(squash.string()),
     * })
     *
     * const cursor = Squash.cursor()
     * playerserdes.ser(cursor, {
     *     position: Vector2.new(287.3855, -13486.3),
     *     health: 9,
     *     name: "Cedrick",
     *     poisoned: true,
     *     items: {
     *         { name = 'Lantern', count = 2 },
     *         { name = 'Waterskin', count = 1 },
     *         { name = 'Map', count = 4 },
     *     },
     *     inns: {
     *         ['The Copper Cauldron']: true,
     *         Infirmary: true,
     *         ['His Recess']: true,
     *     },
     *     equipped: nil,
     * })
     * Squash.print(cursor)
     * // Pos: 90 / 90
     * // Buf: { 0 9 1 72 105 115 32 82 101 99 101 115 115 138 1 84 104 101 32 67 111 112 112 101 114 32 67 97 117 108 100 114 111 110 147 1 73 110 102 105 114 109 97 114 121 137 131 130 76 97 110 116 101 114 110 135 129 87 97 116 101 114 115 107 105 110 137 132 77 97 112 131 131 67 101 100 114 105 99 107 135 1 51 185 82 198 88 177 143 67   }
     * //                                                                                                                                                                                                                                                                                                                                            ^
     * print(playerserdes.des(cursor))
     * // {
     * //     ["health"] = 9,
     * //     ["inns"] =  ▼  {
     * //        ["His Recess"] = true,
     * //        ["Infirmary"] = true,
     * //        ["The Copper Cauldron"] = true
     * //     },
     * //     ["items"] =  ▼  {
     * //        [1] =  ▼  {
     * //           ["count"] = 2,
     * //           ["name"] = "Lantern"
     * //        },
     * //        [2] =  ▼  {
     * //           ["count"] = 1,
     * //           ["name"] = "Waterskin"
     * //        },
     * //        [3] =  ▼  {
     * //           ["count"] = 4,
     * //           ["name"] = "Map"
     * //        }
     * //     },
     * //     ["name"] = "Cedrick",
     * //     ["poisoned"] = true,
     * //     ["position"] = 287.385498, -13486.2998
     * //  }
     * ```
     * @param schema T
     * @returns T
     */
    record<T extends Record<string, any>>(schema: T): T;
    /**
     * Maps are a classic table type { [T]: U } that map T's to U's. A map can store a map or any other table type.
     * ```ts
     * const u = Squash.uint
     * const vec3 = Squash.Vector3
     * const vec2 = Squash.Vector2
     * const mymap = Squash.map(vec2(u(2)), vec3(u(3)))
     *
     * const cursor = Squash.cursor()
     * mymap.ser(cursor, {
     *     [Vector2.new(1, 2)]: Vector3.new(1, 2, 3),
     *     [Vector2.new(4, 29)]: Vector3.new(4, 29, 33),
     *     [Vector2.new(72, 483)]: Vector3.new(72, 483, 555),
     * })
     * Squash.print(cursor)
     * // Pos: 40 / 40
     * // Buf: { 43 2 0 227 1 0 72 0 0 227 1 72 0 33 0 0 29 0 0 4 0 0 29 0 4 0 3 0 0 2 0 0 1 0 0 2 0 1 0 131   }
     * //                                                                                                    ^
     * print(mymap.des(cursor))
     * // {
     * //    [Vector2(24346692898)]: 72, 483, 555,
     * //    [Vector2(243466928B0)]: 4, 29, 33,
     * //    [Vector2(243466928C8)]: 1, 2, 3
     * // }
     * ```
     * @param key_type K
     * @param value_type V
     * @returns Map<K, V>
     */
    map<K, V>(key_type: K, value_type: V): Map<K, V>;
    /**
     * Luau tables are extremely versatile data structures that can and do implement every other kind of data structure one can think of. They are too versatile to optimally serialize in the general case, which is why Squash has the previously listed Array, Map, and Record serializers.\
     * Only use this serializer if you cannot guarantee the shape of your table beforehand, as it offers less control and worse size reduction. This is the algorithm that Roblox uses when serializing tables because they can't guarantee the shape of the tables users pass. If you do not know the type of your table but you still need to serialize it, then the Squash.table serializer is a last resort.\
     * It has to store data for every value, the type of every value, every key, and the type of every key, which makes it significantly larger than the specialized functions. It also does not offer property-specific granularity, instead only letting you map types to serializers for both keys and values alike.
     * ```ts
     * const serdes = Squash.table {
     *     number: Squash.number(8),
     *     string: Squash.string(),
     *     boolean: Squash.boolean(),
     *     table: Squash.table {
     *         CFrame: Squash.CFrame(Squash.number(4)),
     *         Vector3: Squash.Vector3(Squash.int(2)),
     *         number: Squash.vlq(),
     *     },
     * }
     *
     * const cursor = Squash.cursor()
     * serdes.ser(cursor, {
     *     wow: -5.352345,
     *     [23846.4522]: true,
     *     [false]: 'Gaming!',
     *     ThisWontSerialize: DateTime.now(),
     *     [{
     *         CFrame.new(-24.2435, 2, 3), CFrame.new(), Vector3.new(354, -245, -23),
     *         [100]: Vector3.zAxis,
     *         [Vector3.zero]: 255,
     *     }] = {
     *         [1]: CFrame.identity,
     *         [2]: Vector3.zero,
     *         [3]: 256,
     *     },
     * })
     * Squash.print(cursor)
     * // Pos: 131 / 135
     * // Buf: { 71 97 109 105 110 103 33 135 1 0 2 240 162 175 32 205 104 21 192 0 119 111 119 131 1 1 2 208 68 216 240 156 73 215 64 0 1 0 0 0 0 0 0 0 0 0 0 0 0 1 129 0 0 0 0 0 0 0 2 130 0 130 0 0 131 0 131 3 1 0 0 64 64 0 0 0 64 176 242 193 193 1 129 0 1 0 0 0 0 0 0 0 0 0 0 0 0 1 130 0 233 255 11 255 98 1 2 131 0 129 127 0 0 0 0 0 0 0 2 1 0 0 0 0 0 2 228 0 133 3 132 0 0 0 0 }
     * //                                                                                                                                                                                                                                                                                                                                                                           ^
     * print(serdes.des(cursor))
     * // {
     * //     ["wow"] = -5.352345,
     * //     [23846.4522] = true,
     * //     [Table(24BE4A11A98)] =  ▼  {
     * //         [1] = 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1,
     * //         [2] = 0, 0, 0,
     * //         [3] = 256
     * //     },
     * //     [false] = "Gaming!"
     * // }
     * ```
     * @param schema Map<string, any>
     * @returns Map<any, any>
     */
    table(schema: Map<string, any>): Map<any, any>;
    /**
     * Represents an `Axes`.
     * @returns Axes
     */
    Axes(): Axes;
    /**
     * Represents a `BrickColor`.
     * @returns BrickColor
     */
    BrickColor(): BrickColor;
    /**
     * Represents an `EnumItem`.
     * @param _enum Enum
     * @returns EnumItem
     */
    EnumItem(_enum: Enum): EnumItem;
    /**
     * Represents a `CatalogSearchParams`.
     * @returns CatalogSearchParms
     */
    CatalogueSearchParams(): CatalogSearchParams;
    /**
     * Represents a `CFrame` with a number type or the default `float32`.
     * @param number_type number? - Defaults to a `float32`.
     * @returns CFrame
     */
    CFrame(number_type?: number): CFrame;
    /**
     * Represents a `Color3`.
     * @returns Color3
     */
    Color3(): Color3;
    /**
     * Represents a `ColorSequenceKeypoint`.
     * @returns ColorSequenceKeypoint
     */
    ColorSequenceKeypoint(): ColorSequenceKeypoint;
    /**
     * Represents a `ColorSequence`.
     * @returns ColorSequence
     */
    ColorSequence(): ColorSequence;
    /**
     * Represents a `DateTime`.
     * @returns DateTime
     */
    DateTime(): DateTime;
    /**
     * Returns a `Faces`.
     * @returns Faces
     */
    Faces(): Faces;
    /**
     * Returns a `FloatCurveKey`.
     * @returns FloatCurveKey
     */
    FloatCurveKey(): FloatCurveKey;
    /**
     * Returns a `Font`.
     * @returns Font
     */
    Font(): Font;
    /**
     * Represents a `NumberRange` with a number type or the default `float32`.
     * @param number_type number? - Defaults to a `float32`.
     * @returns NumberRange
     */
    NumberRange(number_type?: number): NumberRange;
    /**
     * Represents a `NumberSequenceKeypoint` with a number type or the default `float32`.
     * @param number_type number? - Defaults to a `float32`.
     * @returns NumberSequenceKeypoint
     */
    NumberSequenceKeypoint(number_type?: number): NumberSequenceKeypoint;
    /**
     * Represents a `NumberSequence` with a number type or the default `float32`.
     * @param number_type number? - Defaults to a `float32`.
     * @returns NumberSequence
     */
    NumberSequence(number_type?: number): NumberSequence;
    /**
     * Represents an `OverlapParams`.
     * @returns OverlapParams
     */
    OverlapParams(): OverlapParams;
    /**
     * Represents a `RaycastParams`.
     * @returns RaycastParams
     */
    RaycastParams(): RaycastParams;
    /**
     * Represents a `Vector3` with a number type or the default `float32`.
     * @param number_type number? - Defaults to a `float32`.
     * @returns Vector3
     */
    Vector3(number_type?: number): Vector3;
    /**
     * Represents a `PathWaypoint` with a number type or the default `float32`.
     * @param number_type number? - Defaults to a `float32`.
     * @returns PathWaypoint
     */
    PathWaypoint(number_type?: number): PathWaypoint;
    /**
     * Represents a `PhysicalProperties`.
     * @returns PhysicalProperties
     */
    PhysicalProperties(): PhysicalProperties;
    /**
     * Represents a `Ray` with a number type or the default `float32`.
     * @param number_type number? - Defaults to a `float32`.
     * @returns Ray
     */
    Ray(number_type?: number): Ray;
    /**
     * Represents a `RaycastResult` with a number type or the default `float32`.
     * @param number_type number? - Defaults to a `float32`.
     * @returns RaycastResult
     */
    RaycastResult(number_type?: number): RaycastResult;
    /**
     * Represents a `Vector2` with a number type or the default `float32`.
     * @param number_type number? - Defaults to a `float32`.
     * @returns Vector2
     */
    Vector2(number_type?: number): Vector2;
    /**
     * Represents a `Rect` with a number type or the default `float32`.
     * @param number_type number? - Defaults to a `float32`.
     * @returns Rect
     */
    Rect(number_type?: number): Rect;
    /**
     * Represents a `Region3` with a number type or the default `float32`.
     * @param number_type number? - Defaults to a `float32`.
     * @returns Region3
     */
    Region3(number_type?: number): Region3;
    /**
     * Represents a `Region3int16`.
     * @returns Region3int16
     */
    Region3int16(): Region3int16;
    /**
     * Represents a `RotationCurveKey` with a number type or the default `float32`.
     * @param number_type number? - Defaults to a `float32`.
     * @returns RotationCurveKey
     */
    RotationCurveKey(number_type?: number): RotationCurveKey;
    /**
     * Represents a `TweenInfo`.
     * @returns TweenInfo
     */
    TweenInfo(): TweenInfo;
    /**
     * Represents an `UDim` with a number type or the default `float32`.
     * @param number_type number? - Defaults to a `float32`.
     * @returns UDim
     */
    UDim(number_type?: number): UDim;
    /**
     * Represents an `UDim2` with a number type or the default `float32`.
     * @param number_type number? - Defaults to a `float32`.
     * @returns UDim2
     */
    UDim2(number_type?: number): UDim2;
    /**
     * Represents a `Vector2int16`.
     * @returns Vector2int16
     */
    Vector2int16(): Vector2int16;
    /**
     * Represents a `Vector3int16`.
     * @returns Vector3int16
     */
    Vector3int16(): Vector3int16;
    /**
     * # Using Base Conversion
     * There are many ways to compress serialized strings, a lossless approach is to treat the string itself as a number and convert the number into a higher base, or radix. This is called [base conversion](https://en.wikipedia.org/wiki/Radix). Strings come in many different *flavors* though, so we need to know how to serialize each *flavor*. Each string is composed of a sequence of certain characters. The set of those certain characters is called that string's smallest **Alphabet**. For example, the string **"Hello, World!"** has the alphabet **"!,HWdelorw"**. We can assign a number to each character in the alphabet like its position in the string. With our example:
     * ```ts
     * {
     *     [' '] = 1, ['!'] = 2, [','] = 3, ['H'] = 4, ['W'] = 5,
     *     ['d'] = 6, ['e'] = 7, ['l'] = 8, ['o'] = 9, ['r'] = 10,
     *     ['w'] = 11,
     * }
     * ```
     * This allows us to now calculate a numerical value for each string using [Positional Notation](https://en.wikipedia.org/wiki/Positional_notation). The alphabet above has a radix of 11, so we can convert the string into a number with base 11. We can then use the base conversion formula, modified to work with strings, to convert the number with a radix 11 alphabet into a number with a radix 256 alphabet such as extended ASCII or UTF-8. To prevent our numbers from being shortened due to leading 0's, we have to use an extra character in our alphabet in the 0's place that we never use, such as the \0 character, making our radix 12. Long story short, you can fit **log12(256) = 2.23** characters from the original string into a single character in the new string. This proccess is invertible and lossless, so we can convert the serialized string back into the original string when we are ready. To play with this concept for arbitrary alphabets, you can visit [Zamicol's Base Converter](https://convert.zamicol.com/) which supports these exact operations and comes with many pre-defined alphabets.
     * ```ts
     * const x = 'Hello, world!'
     * const alphabet = Squash.string.alphabet(x)
     * print(alphabet)
     * //  !,Hdelorw
     * const y = Squash.string.convert(x, alphabet, Squash.string.utf8)
     * print(y)
     * // >q#�
     * print(Squash.string.convert(y, Squash.string.utf8, alphabet))
     * // 'Hello, world!'
     * ```
     * ```ts
     * const y = Squash.string.convert('great sword', Squash.string.lower .. ' ', Squash.string.utf8)
     * print(y)
     * // �zvFV�
     * print(Squash.string.convert(y, Squash.string.utf8, Squash.string.lower .. ' '))
     * // 'great sword'
     * ```
     * ```ts
     * const y = Squash.string.convert('lowercase', Squash.string.lower, Squash.string.upper)
     * print(y)
     * // LOWERCASE
     * print(Squash.string.convert(y, Squash.string.upper, Squash.string.lower))
     * // lowercase
     * ```
     * ```ts
     * const y = Squash.string.convert('123', Squash.string.decimal, Squash.string.binary)
     * print(y)
     * // 1111011
     * print(Squash.string.convert(y, Squash.string.binary, Squash.string.octal))
     * // 173
     * print(Squash.string.convert(y, Squash.string.binary, Squash.string.decimal))
     * // 123
     * print(Squash.string.convert(y, Squash.string.binary, Squash.string.duodecimal))
     * // A3
     * print(Squash.string.convert(y, Squash.string.binary, Squash.string.hexadecimal))
     * // 7B
     * print(Squash.string.convert(y, Squash.string.binary, Squash.string.utf8))
     * // {
     * ```
     */
    base_conversion: {
        /**
         * Creates an alphabet for the given string.
         * @param x string
         * @returns string
         */
        alphabet(x: string): string;
        /**
         * Converts the given string [x] from the alphabet [input_alphabet] to the alphabet [output_alphabet].
         * @param x string
         * @param input_alphabet string
         * @param output_alphabet string
         * @returns string
         */
        convert(
            x: string,
            input_alphabet: string,
            output_alphabet: string,
        ): string;
        /** Alphabet for binary. `01` */
        binary: string;
        /** Alphabet for octal. `01234567` */
        octal: string;
        /** Alphabet for decimal. `0123456789` */
        decimal: string;
        /** Alphabet for duodecimal. `0123456789AB` */
        duodecimal: string;
        /** Alphabet for hexadecimal. `0123456789ABCDEF` */
        hexadecimal: string;
        /** Alphabet for UTF8 characters. */
        utf8: string;
        /** Alphabet for lower case letters. `abcdefghijklmnopqrstuvwxyz` */
        lower: string;
        /** Alphabet for upper case letters. `ABCDEFGHIJKLMNOPQRSTUVWXYZ` */
        upper: string;
        /** Alphabet for letters. `abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ` */
        letters: string;
        /** Alphabet for punctuation. ` .,?!:;\'"-_` */
        punctuation: string;
        /** Alphabet for English. `abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ .,?!:;\'"-_` */
        english: string;
        /** Alphabet for filepaths. `abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ:/` */
        filepath: string;
        /** Alphabet for datastores. `!#$%&\'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]^_`abcdefghijklmnopqrstuvwxyz{|}~` */
        datastore: string;
    };
}

/**
 * @private
 * Required by `sapphire:use()`
 */
export const identifier: "sapphire-net";
/**
 * @private
 * Required by `sapphire:use()`
 */
export function extension(): void;
/**
 * @private
 * Required by `sapphire:use()`
 */
export const methods: {};

/**
 * Creates a defined event. Do not use outside of namespaces.
 * ```ts
 * const t = net.data_types
 * export default net.define_namespace("namespace_name", () => {
 *     return {
 *         event_name: net.defined({
 *             // `value` can be any type, but it's a struct for demonstration purposes
 *             value: t.struct({
 *                 a: t.string(),
 *                 b: t.uint(2), // in bytes
 *             }),
 *             reliability_type: "reliable", // Optional, can be "reliable" or "unreliable"
 *         }),
 *         // etc.
 *     }
 * })
 * ```
 * @param props packet_props<T>
 * @returns event<T>
 */
export function defined<T>(props: packet_props<T>): event<T>;
/**
 * Creates an undefined event. Do not use in namespaces.\
 * Undefined events use dynamic serdes, which is a few times slower and more bandwidth intensive
 * than regular, statically defined serdes, due to it having to write all types, values and key names for tables.
 * ```ts
 * const reliable_event: net.event<{ a: string, b: number }> = net.undefined("event_name", "reliable")
 * // This is for demonstration; note that events can't have the same name, even if they're of different reliability types
 * const unreliable_event: net.event<{ a: string, b: number }> = net.undefined("event_name", "unreliable")
 * ```
 * @param name string
 * @param reliability_type "reliable" | "unreliable"
 * @returns event<T>
 */
export function undefined<T>(
    name: string,
    reliability_type: reliability_type,
): event<T>;

/**
 * Creates a namespace. Use in shared files to avoid defining the same thing multiple times.\
 * Houses events in itself - an event can have the same name if it's in another namespace.
 * ```ts
 * const t = net.data_types
 * export default net.define_namespace("namespace_name", () => {
 *     return {
 *         event_name: net.defined({
 *             // `value` can be any type, but it's a struct for demonstration purposes
 *             value: t.struct({
 *                 a: t.string(),
 *                 b: t.uint(2), // in bytes
 *             }),
 *             reliability_type: "reliable", // Optional, can be "reliable" or "unreliable"
 *         }),
 *         // etc.
 *     }
 * })
 * ```
 * @param name string
 * @param namespace () => T
 * @returns T
 */
export function define_namespace<T>(name: string, namespace: () => T): T;

/**
 * All usable data types, exported from squash. All types with a required number type have been modified for a float32 to be default.
 */
export const data_types: data_types;
/**
 * Features all data types + internal id to type and type to id lookup tables for dynamic serdes.
 */
export const _data_types: {
    /**
     * All usable data types, exported from squash. All types with a required number type have been modified for a float32 to be default.
     */
    types: data_types;
    /**
     *  Internal id to type lookup table for dynamic serdes.
     */
    id_to_type: Map<number, string>;
    /**
     * Internal type to id lookup table for dynamic serdes.
     */
    type_to_id: Map<string, number>;
};
