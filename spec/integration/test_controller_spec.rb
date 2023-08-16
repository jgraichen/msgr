# frozen_string_literal: true

require 'spec_helper'

describe TestController, type: :controller do
  before do
    Msgr.client.start
  end

  it 'sends messages on :index' do
    get :index

    Msgr::TestPool.run(count: 2)

    expect(TestConsumer.queue).to eq [{fuubar: 'abc'}]
  end
end
