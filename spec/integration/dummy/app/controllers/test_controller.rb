# frozen_string_literal: true
class TestController < ApplicationController
  def index
    @data = {abc: 'abc'}

    Msgr.publish @data, to: 'local.test.index'

    head :ok
  end
end
