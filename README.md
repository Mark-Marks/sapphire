<div align="center">
<img
  align="center"
  src="./assets/sapphire_darkmode.png#gh-dark-mode-only"
  alt="sapphire"
  width="500px"/>
<img
  align="center"
  src="./assets/sapphire_lightmode.png#gh-light-mode-only"
  alt="sapphire"
  width="500px"/>

<br/>
<br/>

[![CI](https://img.shields.io/github/actions/workflow/status/mark-marks/sapphire/ci.yml?style=for-the-badge&label=CI)](https://github.com/mark-marks/sapphire/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue?style=for-the-badge)](https://github.com/Mark-Marks/sapphire/blob/main/LICENSE)
[![Wally](https://img.shields.io/github/v/tag/mark-marks/sapphire?&style=for-the-badge)](https://wally.run/package/mark-marks/sapphire)
</br>

</div>

# ARCHIVED

Sapphire has been archived due to being unmaintained and serving practically no purpose in my eyes.\
If you'd like an alternative, consider [Quill](https://github.com/featherfall-org/quill), which is similar to Sapphire, or [prvdmwrong](https://github.com/prvdmwrong/prvdmwrong). Happy coding!

# sapphire

A lightweight module loader or a batteries included framework

> [!CAUTION]
> Here be dragons! Sapphire and its extensions are barely tested and in alpha

> [!IMPORTANT]
> All crates are versioned differently. Whilst the core may be at `v0.1.0`, an extension could be at `v0.5.3`.\
> Because this is a change @ `v0.1.2`, `sapphire`, `sapphire-lifecycles`, `sapphire-logging` `saphire-net`, `sapphire-data` and `sapphire-ecr` start at `v0.1.2` whilst any other crates don't because they were released after this change.

## Todo
- [x] Set up project
- [x] Make basic, extensible module loader
- [x] Add pre-built extensions:
  - [x] `sapphire-lifecycles` - extra lifecycles for `RunService` and `Players`
  - [x] `sapphire-logging` - a nice logging library with a log history
  - [x] `sapphire-net` - optimized networking library that features defined (like `ByteNet`) events and undefined events, both with buffer serdes, albeit undefined events performing worse due to having to define types and lengths in the buffer
  - [x] `sapphire-data` - batteries included wrapper for an existing data library like `keyForm`
  - [x] `sapphire-ecr` - scheduler for ECR with niceties
  - [x] `sapphire-jecs` - scheduler for JECS with niceties

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

A documentation website doesn't exist yet, although an API reference can be viewed in extension READMEs.

Do note that some API references might not be fully up to date, although the author tries to maintain them.

### [sapphire](/crates/sapphire)

### [sapphire-lifecycles](/crates/sapphire-lifecycles)

### [sapphire-logging](/crates/sapphire-logging)

### [sapphire-net](/crates/sapphire-net)

### [sapphire_data](/crates/sapphire-data)

### [sapphire-ecr](/crates/sapphire-ecr)

### [sapphire-jecs](/crates/sapphire-jecs)
