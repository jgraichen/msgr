class TestConsumer < ApplicationConsumer

  def index
    data = { fuubar: 'abc' }

    publish data, to: 'local.test.another_action'
  end

  def another_action
    puts "#{payload.inspect}"
  end
end
