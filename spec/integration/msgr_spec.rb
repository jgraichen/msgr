require 'spec_helper'

describe TestController do
  it 'should send messages on :index' do
    get '/'
  end
end
