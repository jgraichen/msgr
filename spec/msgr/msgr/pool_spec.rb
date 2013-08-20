require 'spec_helper'

$shutdown_test_graceful_down = false

class Runner
  def test_method(*_) end

  def shutdown_test
    sleep 2
    $shutdown_test_graceful_down = true
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
      expect_any_instance_of(Runner).to receive(:test_method).within(10).seconds.with(5, 3.2, 'hello').once
      pool.dispatch :test_method, 5, 3.2, 'hello'
    end
  end

  describe '#shutdown' do
    let!(:pool) { Msgr::Pool.new Runner, size: 1 }
    before do
      pool.start
      $shutdown_test_graceful_down = false
    end

    it 'should do a graceful shutdown of all worker' do
      pool.dispatch :shutdown_test
      pool.shutdown
      expect($shutdown_test_graceful_down).to be_false
    end
  end
end
