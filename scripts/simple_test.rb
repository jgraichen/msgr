require 'msgr'

Msgr.logger.level = Logger::Severity::INFO

class TestConsumer < Msgr::Consumer
  def index
    log(:info) { payload }
  end

  def another_action
    log(:info) { payload }
  end

  def log_name
    "<TestConsumer##{action}>"
  end
end

@client = Msgr::Client.new user: 'guest', password: 'guest', size: 1

@client.routes.configure do
  route 'abc.#', to: 'test#index'
  route 'cde.#', to: 'test#index'
  route '#', to: 'test#another_action'
end

@client.start

100.times do |i|
  @client.publish 'abc.XXX', "Message #{i} #{rand}"
end

begin
  sleep
rescue Interrupt
ensure
  @client.stop timeout: 10
end
