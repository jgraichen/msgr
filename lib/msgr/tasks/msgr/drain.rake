# frozen_string_literal: true

namespace :msgr do
  desc 'Drain all known queues'
  task drain: :environment do
    client = Msgr.client

    client.connect
    client.drain
  end
end
