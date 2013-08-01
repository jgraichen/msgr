# Coverage
require 'coveralls'
Coveralls.wear! do
  add_filter 'spec'
end

#
require 'rspec/autorun'

# Support files
Dir[Rails.root.join(__FILE__, '../support/**/*.rb')].each { |f| require f }

RSpec.configure do |config|
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'

  config.expect_with :rspec do |c|
    # Only allow expect syntax
    c.syntax = :expect
  end
end
