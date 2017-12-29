# Changelog

## 1.0

* Configure prefetch per binding and disable auto ack in consumer for customized batch processing (#15)
* Replace usage of deprecated exception class (#12)

## 0.15.2

* Fix regression in parsing `:uri` config with empty path

## 0.15.1

* Fix errors with additional configuration keys for AMQP connection (#13)

## 0.15.0

* Add new configuration option `:raise_exceptions` that can be used to enable
  exceptions being raised from consumers. Mostly useful for testing consumers.
  Defaults to `false`.
* Add option to release bindings before purging
* Rework TestPool timeout handling to not account processing time
* Add methods for purging queues

## 0.14.1

* Fix loading test pool source file

## 0.14.0

* Add experimental test pool (`Msgr::TestPool`)

## 0.13.0

* Use `Rails.application.config_for` if available.

## 0.12.2

* Do not delete the exchange on stop delete:true - as the exchange is changed

## 0.12.1

* Loose dependency on bunny to allow ~> 1.4 for stone-age old RabbitMQ servers.

## 0.11.rc3

* Define pool_class by string to make it useable with rails
* Add checkcredentials config option to disable initial connect to rabbitmq
  server to check the credentials

## 0.11.rc2

* Add nack for messages when an error is rescued by dispatcher

## 0.11.rc1

* Add pool_class config to override pool classes used by dispatcher

## 0.4 - 0.10

* Some lost history due to several crises

## 0.4.1

* Fix bug with empty routes on client start

## 0.4.0

* Improve railtie and autostart code

## 0.3.0

* Support for forking web servers like unicorn

## 0.2.1

* Fix wrong rails initializer code - was not use the config file

## 0.2.0

* Improve rails initializer code
