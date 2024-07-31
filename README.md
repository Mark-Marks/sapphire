# sapphire
A lightweight module loader or a batteries included framework

# Installation
Add `sapphire` to your `wally.toml`:
```toml
sapphire = "mark-marks/sapphire@LATEST" # change LATEST to latest version
```

# Vision
- A simple, short module loader that can be extended into a fully fledged framework taking care of networking, logging, data, ECS system scheduling, etc.
- roblox-ts support
- By default can be as simple as:
```luau
local sapphire = require("@packages/sapphire")
local singletons = ...

sapphire()
    :add_singletons(singletons)
    :start()
```
- Singletons don't have to require sapphire itself for anything:
```luau
local singleton = {}

function singleton.start()
end

return singleton
```
- Singletons can have priority by specifying an optional `priority` property:
```luau
local singleton = {}
singleton.priority = 1234 -- 1 is the lowest priority
```
- Doesn't use any custom module loaders, depends on `require()` to not sacrifice types:
```luau
local dependency = require("@singletons/dependency")
```
- Can be extended with `.use()`, which instantly runs a singleton that can add extra functionality:
```luau
export type extension = {
    --- What to identify the extension by.
    identifier: string,

    --- Starts the extension. This is called prior to any methods being registered.
    --- @param sapphire sapphire
    extension: (sapphire: sapphire) -> (),

    --- Registers the given methods within sapphire.
    --- ```luau
    --- local function on_heartbeat(singleton_method: (delta_time: number) -> ())
    ---     heartbeat_signal:Connect(singleton_method)
    --- end
    --- ```
    methods: { [string]: (singleton_method: (any) -> ()) -> () }?,

    [string]: any,
}
```
```luau
local sapphire_lifecycles = require("@packages/sapphire-lifecycles")
local sapphire_net = require("@packages/sapphire-net")

sapphire()
    :use(sapphire_lifecycles) -- Adds extra lifecycles
    :use(sapphire_net) -- Initializes the networking library
-- Extensions are ran instantly! `sapphire_net` can use a `.heartbeat()` lifecycle if `sapphire_lifecycles` adds it, but also `sapphire_lifecycles` can't use any features from `sapphire_net`
```
- If an extension needs complex functionality and doesn't need custom functionality or functionality that doesn't exist, it should use an existing libary. For example:
  - A `sapphire-lifecycles` extension wouldn't need any complex functionality and wouldn't use any library
  - A `sapphire-net` extension would be different from existing networking libraries and wouldn't use any networking library, but would use a library such as `Squash` to not re-implement serdes
  - A `sapphire-ecs` or `sapphire-data` extension wouldn't need any new functionality so it would use an existing library like `ECR` or `keyForm` (in order)

# Todo
- [ ] Set up project
- [ ] Make basic, extensible module loader
- [ ] Add pre-built extensions:
  - [ ] `sapphire-lifecycles` - extra lifecycles for `RunService` and `Players`
  - [ ] `sapphire-logging` - a nice logging library with a log history
  - [ ] `sapphire-net` - optimized networking library that features defined (like `ByteNet`) events and undefined events, both with buffer serdes, albeit undefined events performing worse due to having to define types and lengths in the buffer
  - [ ] `sapphire-data` - batteries included wrapper for an existing data library like `keyForm`
  - [ ] `sapphire-ecr` - scheduler for ECR with niceties
  - [ ] `sapphire-jecs` - scheduler for JECS with niceties
- [ ] Testing

# Note
Partially inspired by [team-fireworks/ohmyprvd](https://github.com/team-fireworks/ohmyprvd)!
