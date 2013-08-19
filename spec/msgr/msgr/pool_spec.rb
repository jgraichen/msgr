require 'spec_helper'

class Runner
  def test_method(*args)
  end
end

describe Msgr::Pool do
  let(:pool) { Msgr::Pool.new Runner }

  describe '#initialize' do
    let(:opts) { {} }
    let(:pool) { Msgr::Pool.new Runner, opts }

    context 'pool size' do
      let(:opts) { {size: 4} }
      before { pool }

      it 'should define number of worker actors' do
        expect(pool.size).to eq 4
      end
    end
  end

  describe '#start' do
    let!(:pool) { Msgr::Pool.new Runner, size: 4 }

    it 'should start worker actors' do
      expect { pool.start }.to change { Celluloid::Actor.all.size }.by(4)
    end
  end

  describe '#size' do
    it 'should default to number of available cores' do
      expect(pool.size).to eq Celluloid.cores
    end
  end

  describe '#dispatch' do
    let!(:pool) { Msgr::Pool.new Runner, size: 4 }
    before { pool.start }

    it 'should dispatch message to runner' do
      expect_any_instance_of(Runner).to receive(:test_method).with(5, 3.2, 'hello').once
      pool.dispatch :test_method, 5, 3.2, 'hello'
      sleep 1 # TODO: Asynchronous time-boxed assertion
    end
  end
end
