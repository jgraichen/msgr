# frozen_string_literal: true

require 'spec_helper'

describe Msgr::Connection do
  describe '#rebind' do
    let(:conn) { double }
    let(:routes) { Msgr::Routes.new }
    let(:connection) { described_class.new conn, routes, dispatcher }

    pending 'some tests missing -> only lets written'
  end
end
