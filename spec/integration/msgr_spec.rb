# frozen_string_literal: true

require 'spec_helper'

describe TestController, type: :request do
  it 'should send messages on :index' do
    get '/'
  end
end
