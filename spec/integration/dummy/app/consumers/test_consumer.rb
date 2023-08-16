# frozen_string_literal: true

class TestConsumer < ApplicationConsumer
  class << self
    attr_accessor :queue
  end

  def index
    data = {fuubar: 'abc'}

    publish data, to: 'local.test.another_action'
  end

  def another_action
    self.class.queue ||= []
    self.class.queue << payload
  end
end
