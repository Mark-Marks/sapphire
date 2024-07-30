# sapphire
A lightweight module loader or a batteries included framework

# Vision
- A simple, short module loader that can be extended into a fully fledged framework taking care of networking, logging, data, ECS system scheduling, etc.
- By default can be as simple as:
```luau
local sapphire = require("@packages/sapphire")
local singletons = ...

sapphire()
    .add_singletons(singletons)
    .start()
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
singleton.priority = 1234
```
- Doesn't use any custom module loaders, depends on `require()` to not sacrifice types:
```luau
local dependency = require("@singletons/dependency")
```
- Can be extended with `.use()`, which instantly runs a singleton that can add extra functionality:
```luau
type extension = {
    start: (sapphire) -> (), -- extensions' `.start()` lifecycle is additionally called with the framework itself
    lifecycles: { [string]: () -> () }, -- to add extra lifecycles to singletons
}
type use = (extension) -> builder
```
```luau
local sapphire_lifecycles = require("@packages/sapphire_lifecycles")
local sapphire_net = require("@packages/sapphire_net")

sapphire()
    .use(sapphire_lifecycles) -- Adds extra lifecycles
    .use(sapphire_net) -- Initializes the networking library
-- Extensions are ran instantly! `sapphire_net` can use a `.heartbeat()` lifecycle if `sapphire_lifecycles` adds it, but also `sapphire_lifecycles` can't use any features from `sapphire_net`
```
- If an extension needs complex functionality and doesn't need custom functionality or functionality that doesn't exist, it should use an existing libary. For example:
  - A `sapphire_lifecycles` extension wouldn't need any complex functionality and wouldn't use any library
  - A `sapphire_net` extension would be different from existing networking libraries and wouldn't use any networking library, but would use a library such as `Squash` to not re-implement serdes
  - A `sapphire_ecs` or `sapphire_data` extension wouldn't need any new functionality so it would use an existing library like `ECR` or `keyForm` (in order)

# Todo
- [ ] Set up project
- [ ] Make basic, extensible module loader
- [ ] Add pre-built extensions:
  - [ ] `sapphire_lifecycles` - extra lifecycles for `RunService` and `Players`
  - [ ] `sapphire_net` - optimized networking library that features defined (like `ByteNet`) events and undefined events, both with buffer serdes, albeit undefined events performing worse due to having to define types and lengths in the buffer
  - [ ] `sapphire_data` - batteries included wrapper for an existing data library like `keyForm`
  - [ ] `sapphire_ecr` - scheduler for ECR with niceties
  - [ ] `sapphire_jecs` - scheduler for JECS with niceties
- [ ] Testing
     
# Note
Partially inspired by [team-fireworks/ohmyprvd](https://github.com/team-fireworks/ohmyprvd)!
