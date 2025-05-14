# frozen_string_literal: true
require 'rspec'
require_relative '../slot'

RSpec.describe SlotGame do
  let(:game) { SlotGame.new('config.json') }

  describe '#ways_and_length_for' do
    context 'when testing APPLE symbol' do
      it 'calculates ways and length for a horizontal line of APPLE' do
        # Horizontal line of APPLE
        screen = [
          ['APPLE', 'APPLE', 'APPLE'],
          ['PLUM', 'BAR', 'BANANA'],
          ['BANANA', 'WILD', 'PLUM']
        ]
        ways, length = game.ways_and_length_for(screen, 'APPLE')
        expect(ways).to eq(2) # Corrected: 1(col0) * (1 APPLE + 1 WILD)(col1) * 1(col2) = 2
        expect(length).to eq(3) # Path length = 3 columns
      end

      it 'calculates ways and length as in Example 1 from README' do
        # Example 1 from README: APPLE Symbol
        # | APPLE  | *      | APPLE  |
        # | APPLE  | *      | *      |
        # | *      | WILD   | *      |
        screen = [
          ['APPLE', 'STAR', 'APPLE'],   # * replaced with STAR (other symbol)
          ['APPLE', 'PLUM', 'BANANA'],  # * replaced with different symbols
          ['STAR', 'WILD', 'PLUM']      # * replaced with different symbols
        ]
        ways, length = game.ways_and_length_for(screen, 'APPLE')
        expect(ways).to eq(2) # 2 APPLE in the first column, 1 WILD in the second, 1 APPLE in the third, 2 x 1 x 1 = 2
        expect(length).to eq(3) # Path length = 3 columns
      end
    end

    context 'when testing BANANA symbol' do
      it 'calculates ways and length as in Example 2 from README' do
        # Example 2 from README: BANANA Symbol
        # | *      | BANANA | *      |
        # | *      | *      | BANANA |
        # | BANANA | WILD   | *      |
        screen = [
          ['PLUM', 'BANANA', 'PLUM'],    # * replaced with PLUM
          ['PLUM', 'PLUM', 'BANANA'],    # * replaced with PLUM
          ['BANANA', 'WILD', 'PLUM']     # * replaced with PLUM
        ]
        ways, length = game.ways_and_length_for(screen, 'BANANA')
        expect(ways).to eq(2) # 1 BANANA in the first column, 1 BANANA + 1 WILD in the second, 1 BANANA in the third, 1 x 2 x 1 = 2
        expect(length).to eq(3) # Path length = 3 columns
      end
    end
  end

  describe '#calculate_win' do
    it 'calculates win for a screen with APPLE horizontal line' do
      screen = [
        ['APPLE', 'APPLE', 'APPLE'],
        ['PLUM', 'BAR', 'BANANA'],
        ['BANANA', 'WILD', 'PLUM']
      ]
      win = game.calculate_win(screen, 1.0)
      # Wins: APPLE (2 ways * payout 2 = 4.0), BANANA (1 way * payout 1 = 1.0), PLUM (1 way * payout 3 = 3.0)
      # Total win = 4.0 + 1.0 + 3.0 = 8.0
      expect(win).to eq(8.0) 
    end

    it 'calculates win for a screen with BANANA and WILD combinations' do
      screen = [
        ['PLUM', 'BANANA', 'PLUM'],
        ['PLUM', 'PLUM', 'BANANA'],
        ['BANANA', 'WILD', 'PLUM']
      ]
      win = game.calculate_win(screen, 1.0)
      # BANANA: ways=2, len=3, payout=1. Win_B = 2.0
      # PLUM: ways=8, len=3, payout=3. Win_P = 24.0
      # Total = 2.0 + 24.0 = 26.0
      expect(win).to eq(26.0) # Corrected: Total win for the screen
    end
  end
end
