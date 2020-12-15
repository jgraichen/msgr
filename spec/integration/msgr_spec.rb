# frozen_string_literal: true

require 'spec_helper'

describe TestController, type: :request do
  it 'sends messages on :index' do
    get '/'
  end
end
