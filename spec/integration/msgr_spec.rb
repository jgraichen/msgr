require 'spec_helper'

describe TestController do
  before do
    Msgr.logger = nil;
    Msgr.logger.level = Logger::Severity::DEBUG if Msgr.logger
  end

  it 'should send messages on :index' do
    get '/'
  end
end
