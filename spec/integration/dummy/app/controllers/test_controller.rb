class TestController < ApplicationController

  def index
    @data = { abc: 'abc' }

    Msgr.publish @data, to: 'local.test.index'
  end
end
