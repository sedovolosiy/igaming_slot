# frozen_string_literal: true
require_relative 'slot'
require_relative 'visual_printer'

GAME = SlotGame.new
BET  = 1.0

# Single spin with output
screen = GAME.spin

# puts "\n=== Single spin ==="
# Visualization with highlighting of winning paths
win_paths = GAME.winning_paths(screen)
VisualPrinter.call(GAME.screen_rows(screen), win_paths)

simple_win = GAME.calculate_win(screen, BET)
puts "Simple win: #{simple_win.round(2)}\n\n"

# RTP simulation for 1,000,000 rounds
# rounds      = 1_000_000
# total_bet   = rounds * BET
# total_win   = 0.0

# rounds.times do
#   s = GAME.spin
#   total_win += GAME.calculate_win(s, BET)
# end

# rtp = (total_win / total_bet) * 100
# puts "Simulated RTP over #{rounds} rounds: #{rtp.round(2)}%"
