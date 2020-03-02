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
  let(:config) { {} }
  let(:args) { [config] }
  let(:dispatcher) { Msgr::Dispatcher.new(*args) }
  subject { dispatcher }

  describe 'dispatch' do
    it 'should ack messages automatically if auto_ack is enabled' do
      route_db = double('Route', consumer: 'MsgrAutoAckConsumer', action: :index)
      msg_db = double('Message', route: route_db, acked?: false)
      expect(msg_db).to receive(:ack)
      expect(msg_db).not_to receive(:nack)

      dispatcher.dispatch(msg_db)
    end

    it 'should not ack messages if auto_ack is disabled' do
      route_db = double('Route', consumer: 'MsgrManualAckConsumer', action: :index)
      msg_db = double('Message', route: route_db, acked?: false)
      expect(msg_db).not_to receive(:ack)
      expect(msg_db).not_to receive(:nack)

      dispatcher.dispatch(msg_db)
    end
  end
end
