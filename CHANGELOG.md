# 0.3.0 2015-08-19

## Added

- Support for steps that return [kleisli](https://github.com/txus/kleisli) monads (solnic)
- Support for setting default step options via flow DSL (solnic)
- Support for subscribing many listeners to a single step (solnic)
- Support for subscribing one listener to all steps (solnic)

## Changed

- Now step objects are wrapped using `Step` decorator that uses `dry-pipeline` gem (solnic)
- Only `Transflow::StepError` errors can cause transaction failure (solnic)

[Compare v0.2.0...v0.3.0](https://github.com/solnic/transflow/compare/v0.2.0...v0.3.0)

# 0.2.0 2015-08-18

## Added

- Support for currying a publisher step (solnic)

[Compare v0.1.0...v0.2.0](https://github.com/solnic/transflow/compare/v0.1.0...v0.2.0)

# 0.1.0 2015-08-17

## Added

- `Transaction#call` will raise if options include an unknown step name (solnic)
- `Transflow` support shorter syntax for steps: `steps :one, :two, :three` (solnic)
- `step(name)` defaults to `step(name, with: name)` (solnic)

## Fixed

- `Transaction#to_s` displays steps in the order of execution (solnic)

## Internal

- Organize source code into separate files (solnic)
- Document public interface with YARD (solnic)
- Add unit specs for `Transaction` (solnic)

[Compare v0.0.2...v0.1.0](https://github.com/solnic/transflow/compare/v0.0.2...v0.1.0)

# 0.0.2 2015-08-16

## Added

- Ability to pass aditional arguments to specific operations prior calling the
  whole transaction (solnic)

[Compare v0.0.2...v0.0.2](https://github.com/solnic/transflow/compare/v0.0.1...v0.0.2)

# 0.0.2 2015-08-16

## Added

- Ability to publish events from operations via `publish: true` option (solnic)
- Ability to subscribe to events via `Transflow::Transaction#subscribe` interface (solnic)

[Compare v0.0.1...v0.0.2](https://github.com/solnic/transflow/compare/v0.0.1...v0.0.2)

# 0.0.1 2015-08-16

First public release \o/
