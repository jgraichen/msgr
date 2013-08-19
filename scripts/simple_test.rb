require 'msgr'

Msgr.logger.level = Logger::Severity::DEBUG

@client = Msgr::Client.new user: 'msgr', password: 'msgr'

@client.routes.configure do
  route 'abc.#', to: 'test#index'
  route 'cde.#', to: 'test#index'
  route '#', to: 'test#another_action'
end

@client.start

10.times do |i|
  @client.publish 'abc.XXX', "Message #{i} #{rand}"
end

sleep 5

@client.routes.configure do
  route 'abc.#', to: 'test#index'
end

@client.reload

10.times do |i|
  @client.publish 'abc.XXX', "Message #{i} #{rand}"
end

begin
  sleep
rescue Interrupt
  @client.stop
end

#class Dispatcher
#  include Msgr::Logging
#
#  def call(message)
#    log(:info) { message }
#    sleep 5 * rand
#    log(:info) { 'Done' }
#  end
#end
#
#pool = Msgr::Pool.new Dispatcher, size: 10
#pool.start
#
#100.times do |i|
#  pool.dispatch(:call, "Message ##{i}")
#end
#
#sleep 5
#
#pool.stop
#pool.terminate
#
#Msgr.logger.info('[ROOT]') { 'Pool terminated.' }

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
