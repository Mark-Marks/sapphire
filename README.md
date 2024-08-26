<div align="center">
<img
  align="center"
  src="./assets/sapphire.png"
  alt="sapphire"
  width="500px"/>

<br/>

[![Continuous Integration](https://img.shields.io/github/actions/workflow/status/mark-marks/sapphire/ci.yml?style=flat-square&label=Continuous%20Integration)](https://github.com/mark-marks/sapphire/actions/workflows/ci.yml)
[![MIT License](https://img.shields.io/badge/license-MIT-blue?style=flat-square)](https://github.com/Mark-Marks/sapphire/blob/main/LICENSE)
[![Wally](https://img.shields.io/github/v/tag/mark-marks/sapphire?&style=flat-square)](https://wally.run/package/mark-marks/sapphire)
</br>


A lightweight module loader or a batteries included framework

> [!CAUTION]
> Here be dragons! Sapphire and its extensions are barely tested and in alpha

## Todo
- [x] Set up project
- [x] Make basic, extensible module loader
- [ ] Add pre-built extensions:
  - [x] `sapphire-lifecycles` - extra lifecycles for `RunService` and `Players`
  - [ ] `sapphire-logging` - a nice logging library with a log history
  - [x] `sapphire-net` - optimized networking library that features defined (like `ByteNet`) events and undefined events, both with buffer serdes, albeit undefined events performing worse due to having to define types and lengths in the buffer
  - [x] `sapphire-data` - batteries included wrapper for an existing data library like `keyForm`
  - [x] `sapphire-ecr` - scheduler for ECR with niceties
  - [ ] `sapphire-jecs` - scheduler for JECS with niceties

## Notes
- Partially inspired by [prvdmwrong/prvdmwrong](https://github.com/prvdmwrong/prvdmwrong)!
- Dependency injection doesn't exist because it can be implemented as an extension.
- Typescript support is half assed at best and non existent at worst, feel free to PR good types in and I'll accept them.
- Sapphire and all of its extensions are licensed under [the MIT license](https://opensource.org/license/mit).
- Sapphire and all of its extensions are strictly typed.
- Sapphire is built around decoupling singletons from itself - you don't have to require sapphire in singletons to do anything.
> [!IMPORTANT]
> [JohnnyMorganz/wally-package-types](https://github.com/JohnnyMorganz/wally-package-types) or a package manager which exports types **NEEDS** to be used to get good type support for extensions. All extensions with dependencies rely on them to have exported types.

## Styling guide
There is none, although sapphire tries its best to follow snake_case.

## Documentation

A documentation website doesn't exist yet, although some form of it can be viewed in extension READMEs:

### sapphire
[sapphire/README.md](/crates/sapphire/README.md)

### sapphire-lifecycles
[sapphire-lifecycles/README.md](/crates/sapphire-lifecycles/README.md)

### sapphire-logging
[sapphire-logging/README.md](/crates/sapphire-logging/README.md)

### sapphire-net
[sapphire-net/README.md](/crates/sapphire-net/README.md)

### sapphire-data
[sapphire-data/README.md](/crates/sapphire-data/README.md)

### sapphire-ecr
[sapphire-ecr/README.md](/crates/sapphire-ecr/README.md)

### sapphire-jecs
[sapphire-jecs/README.md](/crates/sapphire-jecs/README.md)
