class TestController < ApplicationController

  def index
    @data = { abc: 'abc' }

    Msgr.publish @data, to: 'local.test.index'

    render nothing: true
  end
end
