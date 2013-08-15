require 'msgr'

@client = Msgr::Client.new uri: 'amqp://msgr:msgr@localhost'

@client.routes.configure do
  route 'abc.#', to: 'test#index'
  route 'cde.#', to: 'test#index'
  route '#', to: 'test#another_action'
end

@client.start

Thread.new do
  loop do
    10.times { |x| @client.publish 'route.ing.key', "message #{x}" }
  end
end.run

begin
  sleep 5
  @client.stop
rescue Interrupt
  @client.stop
end

sleep 30

#require 'celluloid'
#
#class Worker
#  include Celluloid
#
#  def do_work
#    sleep 15
#  end
#end
#
#logger = Logger.new $stdout
#
#pool = Worker.pool
#
#logger.info 'Start work'
#
#4.times do |i|
#  pool.async.do_work
#end
#
#logger.info 'Wait'
#
#sleep 5
#
#logger.info 'Terminate'
#
#pool.terminate
#
#logger.info 'Done.'


#require 'bunny'
#
#bunny = Bunny.new 'amqp://msgr:msgr@localhost'
#bunny.start
#
#channel  = bunny.create_channel
#exchange = channel.topic 'msgr.topic'
#queue    = channel.queue 'msgr.test.single-queue'
#
#queue.bind(exchange, routing_key: 'a.b.#')
#queue.bind(exchange, routing_key: 'a.c.#')
#queue.subscribe do |delivery_info, metadata, payload|
#  puts "#{delivery_info.routing_key} #{payload}"
#end
#
#sleep 1
#
#10.times { |i| exchange.publish "Message ##{i}", routing_key: [ 'a.b.c', 'a.c.d', 'a.b', 'a' ].sample; sleep 0.2 }
#
#sleep 10
#
#channel.close
#bunny.close
