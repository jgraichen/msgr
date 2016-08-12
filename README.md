# Msgr: *Rails-like Messaging Framework*

[![Gem Version](https://badge.fury.io/rb/msgr.png)](http://badge.fury.io/rb/msgr)
[![Build Status](https://travis-ci.org/jgraichen/msgr.png?branch=master)](https://travis-ci.org/jgraichen/msgr)
[![Coverage Status](https://coveralls.io/repos/jgraichen/msgr/badge.png?branch=master)](https://coveralls.io/r/jgraichen/msgr)
[![Code Climate](https://codeclimate.com/github/jgraichen/msgr.png)](https://codeclimate.com/github/jgraichen/msgr)
[![Dependency Status](https://gemnasium.com/jgraichen/msgr.png)](https://gemnasium.com/jgraichen/msgr)
[![RubyDoc Documentation](https://raw.github.com/jgraichen/shields/master/rubydoc.png)](http://rubydoc.info/github/jgraichen/msgr/master/frames)

You know it and you like it. Using Rails you can just declare your routes and
create a controller. That's all you need to process requests.

With *Msgr* you can do the same for asynchronous AMQP messaging. Just define
your routes, create your consumer and watch you app processing messages.

## Installation

Add this line to your application's Gemfile:

    gem 'msgr'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install msgr

## Usage

After adding 'msgr' to your gemfile create a `config/rabbitmq.yml` like this:

```yaml
common: &common
  uri: amqp://localhost/

test:
  <<: *common

development:
  <<: *common

production:
  <<: *common
```

Specify your messaging routes in `config/msgr.rb`:

```ruby
route 'local.test.index', to: 'test#index'
route 'local.test.another_action', to: 'test#another_action'
```

Create your consumer in `app/consumers`:

```ruby
class TestConsumer < Msgr::Consumer
  def index
    data = { fuubar: 'abc' }

    publish data, to: 'local.test.another_action'
  end

  def another_action
    puts "#{payload.inspect}"
  end
end
```

Use `Msgr.publish` in to publish a message:

```ruby
class TestController < ApplicationController
  def index
    @data = { abc: 'abc' }

    Msgr.publish @data, to: 'local.test.index'

    render nothing: true
  end
end
```

## Msgr and fork web server like unicorn

Per default msgr opens the rabbitmq connect when rails is loaded. If you use a multi-process web server that preloads the application (like unicorn) will lead to unexpected behavior. In this case adjust `config/rabbitmq.yml` and adjust `autostart = false`:


```yaml
common: &common
  uri: amqp://localhost/
  autostart: false
```

And call inside each worker `Msgr.start` - e.g. in an after-fork block


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
