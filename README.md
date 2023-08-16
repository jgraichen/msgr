# Msgr: _Rails-like Messaging Framework_

[![Gem](https://img.shields.io/gem/v/msgr?logo=rubygems)](https://rubygems.org/gems/msgr)
[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/jgraichen/msgr/test.yml?branch=main&logo=github)](https://github.com/jgraichen/msgr/actions/workflows/test.yml)
[![RubyDoc Documentation](http://img.shields.io/badge/rubydoc-here-blue.svg)](http://rubydoc.info/github/jgraichen/msgr/master/frames)

You know it and you like it. Using Rails you can just declare your routes and
create a controller. That's all you need to process requests.

With _Msgr_ you can do the same for asynchronous AMQP messaging. Just define
your routes, create your consumer and watch your app processing messages.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'msgr'
```

And then execute:

```console
bundle
```

Or install it yourself as:

```console
gem install msgr
```

## Usage

After adding 'msgr' to your Gemfile create a `config/rabbitmq.yml` like this:

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

Run client daemon with `bundle exec msgr`.

## Advanced configuration

### Manual message acknowledgments

Per default messages are automatically acknowledged, if no (n)ack is sent explicitly by the consumer. This can be disabled by setting the `auto_ack` attribute to `false`.

```ruby
class TestConsumer < Msgr::Consumer
  self.auto_ack = false

  def index
    data = { fuubar: 'abc' }

    publish data, to: 'local.test.another_action'
  end
end
```

### Prefetch count

Per default each message queue has a prefetch count of 1. This value can be changed when specifying the messaging routes:

```ruby
route 'local.test.index', to: 'test#index', prefetch: 42
```

## Testing

### Recommended configuration

```yaml
test:
  <<: *common
  pool_class: Msgr::TestPool
  raise_exceptions: true
```

The `Msgr::TestPool` pool implementation executes all consumers synchronously.
By enabling the `raise_exceptions` configuration flag, we can ensure that exceptions raised in a consumer will not be swallowed by dispatcher (which it usually does in order to retry consuming the message).

### RSpec example

In your `spec_helper.rb`:

```ruby
config.after(:each) do
  # Flush the consumer queue
  Msgr.client.stop delete: true
  Msgr::TestPool.reset
end
```

In a test:

```ruby
before { Msgr.client.start }

it 'executes the consumer' do
  # Publish an event on our queue
  Msgr.publish 'payload', to: 'msgr.queue.my_queue'

  # Let the TestPool handle exactly one event
  Msgr::TestPool.run count: 1

  # And finally, assert that something happened
  expect(actual).to eq expected
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
