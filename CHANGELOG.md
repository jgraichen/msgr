# Changelog

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
