# frozen_string_literal: true

require 'spec_helper'

class MsgrAutoAckConsumer < Msgr::Consumer
  self.auto_ack = true

  def index; end
end

class MsgrManualAckConsumer < Msgr::Consumer
  self.auto_ack = false

  def index; end
end

describe Msgr::Dispatcher do
  subject { dispatcher }

  let(:config) { {} }
  let(:args) { [config] }
  let(:dispatcher) { described_class.new(*args) }

  describe 'dispatch' do
    it 'acks messages automatically if auto_ack is enabled' do
      route_db = double('Route', consumer: 'MsgrAutoAckConsumer', action: :index)
      msg_db = double('Message', route: route_db, acked?: false)
      expect(msg_db).to receive(:ack)
      expect(msg_db).not_to receive(:nack)

      dispatcher.dispatch(msg_db)
    end

    it 'does not ack messages if auto_ack is disabled' do
      route_db = double('Route', consumer: 'MsgrManualAckConsumer', action: :index)
      msg_db = double('Message', route: route_db, acked?: false)
      expect(msg_db).not_to receive(:ack)
      expect(msg_db).not_to receive(:nack)

      dispatcher.dispatch(msg_db)
    end
  end
end
