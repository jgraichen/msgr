# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.7.0] - 2025-01-17

### Added

- Support for Ruby 3.4 and Rails 8.0

### Changed

- Require Ruby 3.2+ and Rails 7.1+

## [1.6.1] - 2024-10-04

### Fixed

- Changelog parsing failing in release workflow

## [1.6.0] - 2024-10-04

### Added

- Support for Ruby 3.3

## [1.5.0] - 2023-08-16

### Added

- Support for Ruby 3.1 and 3.2

### Changed

- Drop support for Ruby < 2.7

### Fixed

- `TestPool#run` passing down keyword arguments

## [1.4.0] - 2022-01-10

### Added

- Support for namespaced consumer classes in routes file (#48, #49)

### Removed

- Unused `Channel#reject` method

## [1.3.2] - 2021-09-21

### Fixed

- Rake task `msgr:drain` ran before all routes were initialized (#44)

## [1.3.1] - 2020-12-16

### Fixed

- Delay setting default options for correct relative routing file path

## [1.3.0] - 2020-12-16

### Added

- Support and testing for Rails 6.1
- Rake task for purging all known queues (#43)

### Changed

- High-risk feature to autostart client in-process has been removed without replacement
- Parsing config is more relaxed now but directly based on YAML boolean values

## [1.2.0] - 2019-06-27

### Added

- Test support of Rails 5.2

### Changed

- Serialize JSON using core JSON instead of `MultiJson`
- Remove application/text fallback for payload (#25)

## [1.1.0] - 2018-07-25

### Added

- New command line runner

## [1.0.0] - 2017-12-29

### Changed

- Configure prefetch per binding and disable auto ack in consumer for customized batch processing (#15)
- Replace usage of deprecated exception class (#12)

## [0.15.2] - 2017-09-04

### Fixed

- Fix regression in parsing `:uri` config with empty path

## [0.15.1] - 2017-07-31

### Fixed

- Fix errors with additional configuration keys for AMQP connection (#13)

## [0.15.0] - 2017-03-30

### Added

- Add new configuration option `:raise_exceptions` that can be used to enable
  exceptions being raised from consumers. Mostly useful for testing consumers.
  Defaults to `false`.
- Add option to release bindings before purging
- Add methods for purging queues

### Changed

- Rework `TestPool` timeout handling to not account processing time

## [0.14.1] - 2016-02-17

### Fixed

- Fix loading test pool source file

## [0.14.0] - 2016-02-17

### Added

- Add experimental test pool (`Msgr::TestPool`)

## [0.13.0] - 2015-08-24

### Changed

- Use `Rails.application.config_for` if available.

## [0.12.2] - 2015-01-14

### Changed

- Do not delete the exchange on stop delete:true - as the exchange is changed

## [0.12.1] - 2014-11-06

### Changed

- Loose dependency on bunny to allow `~> 1.4` for stone-age old RabbitMQ servers.

## [0.11.0-rc3] - 2014-04-11

### Added

- Add `checkcredentials` config option to disable initial connect to RabbitMQ
  server to check the credentials

### Changed

- Define pool_class by string to make it useable with rails

## [0.11.0-rc2] - 2014-03-29

### Added

- Add `#nack` for messages when an error is rescued by dispatcher

## [0.11.0-rc1] - 2014-03-29

### Added

- Add `pool_class` config to override pool classes used by dispatcher

## [0.4.1] - 2014-03-18

### Fixed

- Fix bug with empty routes on client start

## [0.4.0] - 2014-03-04

### Changed

- Improve `Railtie` and autostart code

## [0.3.0] - 2014-03-03

### Added

- Support for forking web servers like unicorn

## [0.2.1] - 2014-02-26

### Fixed

- Fix wrong Rails initializer code - was not use the config file

## [0.2.0] - 2014-02-21

### Changed

- Improve rails initializer code

[Unreleased]: https://github.com/jgraichen/msgr/compare/v1.7.0...HEAD
[1.7.0]: https://github.com/jgraichen/msgr/compare/v1.6.1...v1.7.0
[1.6.1]: https://github.com/jgraichen/msgr/compare/v1.6.0...v1.6.1
[1.6.0]: https://github.com/jgraichen/msgr/compare/v1.5.0...v1.6.0
[1.5.0]: https://github.com/jgraichen/msgr/compare/v1.4.0...v1.5.0
[1.4.0]: https://github.com/jgraichen/msgr/compare/v1.3.2...v1.4.0
[1.3.2]: https://github.com/jgraichen/msgr/compare/v1.3.1...v1.3.2
[1.3.1]: https://github.com/jgraichen/msgr/compare/v1.3.0...v1.3.1
[1.3.0]: https://github.com/jgraichen/msgr/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/jgraichen/msgr/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/jgraichen/msgr/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/jgraichen/msgr/compare/v0.15.2...v1.0.0
[0.15.2]: https://github.com/jgraichen/msgr/compare/v0.15.1...v0.15.2
[0.15.1]: https://github.com/jgraichen/msgr/compare/v0.15.0...v0.15.1
[0.15.0]: https://github.com/jgraichen/msgr/compare/v0.14.1...v0.15.0
[0.14.1]: https://github.com/jgraichen/msgr/compare/v0.14.0...v0.14.1
[0.14.0]: https://github.com/jgraichen/msgr/compare/v0.13.0...v0.14.0
[0.13.0]: https://github.com/jgraichen/msgr/compare/v0.12.3...v0.13.0
[0.12.2]: https://github.com/jgraichen/msgr/compare/v0.12.1...v0.12.2
[0.12.1]: https://github.com/jgraichen/msgr/compare/v0.12.0...v0.12.1
[0.11.0-rc3]: https://github.com/jgraichen/msgr/compare/v0.11.0.rc2...v0.11.0.rc3
[0.11.0-rc2]: https://github.com/jgraichen/msgr/compare/v0.11.0.rc1...v0.11.0.rc2
[0.11.0-rc1]: https://github.com/jgraichen/msgr/compare/v0.10.2...v0.11.0.rc1
[0.4.1]: https://github.com/jgraichen/msgr/compare/v0.4.0...v0.4.1
[0.4.0]: https://github.com/jgraichen/msgr/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/jgraichen/msgr/compare/v0.2.1...v0.3.0
[0.2.1]: https://github.com/jgraichen/msgr/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/jgraichen/msgr/compare/v0.1.1...v0.2.0
