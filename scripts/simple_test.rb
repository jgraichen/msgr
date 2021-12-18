# frozen_string_literal: true

$LOAD_PATH.unshift File.join File.dirname(__FILE__), '../lib'
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

class NullPool
  def initialize(*); end

  def post(*args)
    yield(*args)
  end
end

@client = Msgr::Client.new user: 'guest', password: 'guest',
  max: 4 # , pool_class: 'NullPool'

@client.routes.configure do
  route 'abc.#', to: 'test#index'
  route 'cde.#', to: 'test#index'
  route '#', to: 'test#another_action'
end

@client.start

100.times do |i|
  @client.publish "Message #{i} #{rand}", to: 'abc.XXX'
end

begin
  sleep
rescue Interrupt # rubocop:disable Lint/SuppressedException
ensure
  @client.stop timeout: 10, delete: true
end

warn "COUNTER: #{@counter}"
