# frozen_string_literal: true
require 'rspec'
require_relative '../slot'

RSpec.describe SlotGame do
  let(:game) { SlotGame.new('spec/test_config.json') }

  describe '#calculate_win' do
    it 'calculates win for a screen with only APPLE horizontal line return 0' do
      screen = [
        ['APPLE', 'APPLE', 'APPLE'],
        ['PLUM', 'BAR', 'BANANA'],
        ['BANANA', 'WILD', 'PLUM']
      ]
      win = game.calculate_win_simple(screen, 1.0)
      expect(win).to eq(0)
    end

    it 'calculates win for a screen with BANANA and WILD combinations' do
      screen = [
        ['PLUM', 'BANANA', 'PLUM'],
        ['PLUM', 'PLUM', 'BANANA'],
        ['BANANA', 'WILD', 'PLUM']
      ]
      win = game.calculate_win_simple(screen, 1.0)
      expect(win).to eq(26.0)
    end

    it 'calculates win for a screen with 7 symbol for both 2 and 3 in a row' do
      screen = [
        ["7", "7", "APPLE"],
        ["7", "WILD", "7"],
        ["7", "PLUM", "BANANA"]
      ]

      win = game.calculate_win_simple(screen, 1.0)

      expect(win).to eq(660.0)
    end
  end
end
