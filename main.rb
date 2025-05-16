# frozen_string_literal: true
require_relative 'slot'
require_relative 'visual_printer'
require 'digest'

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

# === Simple CLI for Slot Game ===

def prompt(msg)
  print msg
  gets.strip
end

# Store player data: salt, client_seed, nonce
PLAYER_DATA = {}

# Get a unique salt and client_seed for the player
player_name = prompt("Enter your name: ")
loop do
  salt = prompt("Enter a unique salt (any string): ")
  if PLAYER_DATA.values.any? { |data| data[:salt] == salt }
    puts "This salt is already used by another player. Enter a different one."
    next
  end
  client_seed = Digest::SHA256.hexdigest("#{player_name}:#{salt}")
  PLAYER_DATA[player_name] = { salt: salt, client_seed: client_seed, nonce: 0, history: [] }
  break
end

balance = 0.0
puts "Your balance: #{balance.round(2)}"
loop do
  input = prompt("Enter the deposit amount: ")
  add = input.to_f
  if add > 0
    balance += add
    puts "Balance topped up. Current balance: #{balance.round(2)}"
    break
  else
    puts "The deposit amount must be positive!"
  end
end

bet = nil
loop do
  input = prompt("Enter the bet amount: ")
  bet = input.to_f
  if bet > 0 && bet <= balance
    break
  else
    puts "The bet must be positive and not exceed the balance!"
  end
end

loop do
  puts "\nYour balance: #{balance.round(2)} | Your bet: #{bet.round(2)}"
  puts "1. Spin (provably fair)"
  puts "2. Change bet"
  puts "3. Top up balance"
  puts "4. Exit"
  puts "5. Verify spin fairness"
  choice = prompt("Choose an action: ")

  case choice
  when '1'
    if bet > balance
      puts "Insufficient funds for the bet!"
      next
    end
    pdata = PLAYER_DATA[player_name]
    screen = GAME.provably_fair_spin(GAME.server_seed, pdata[:client_seed], pdata[:nonce])
    PLAYER_DATA[player_name][:nonce] += 1
    # Save history only if a spin was made
    if pdata[:nonce] > 0
      pdata[:history] << {nonce: pdata[:nonce] - 1, screen: screen}
    end
    win_paths = GAME.winning_paths(screen)
    VisualPrinter.call(GAME.screen_rows(screen), win_paths)
    win = GAME.calculate_win(screen, bet)
    balance -= bet
    balance += win
    puts "You won: #{win.round(2)}"
    puts "Your new balance: #{balance.round(2)}"
    if balance < bet
      puts "Insufficient funds for the next bet. Top up your balance or change the bet."
    end
  when '2'
    input = prompt("Enter the new bet amount: ")
    new_bet = input.to_f
    if new_bet > 0 && new_bet <= balance
      bet = new_bet
    else
      puts "The bet must be positive and not exceed the balance!"
    end
  when '3'
    input = prompt("Enter the deposit amount: ")
    add = input.to_f
    if add > 0
      balance += add
      puts "Balance topped up. Current balance: #{balance.round(2)}"
    else
      puts "The deposit amount must be positive!"
    end
  when '4'
    puts "Thank you for playing! Your final balance: #{balance.round(2)}"
    break
  when '5'
    pdata = PLAYER_DATA[player_name]
    print "Enter the spin number to verify (0 - last, 1 - previous, etc.): "
    idx = gets.strip.to_i
    if pdata[:history] && idx < pdata[:history].size
      record = pdata[:history][-1 - idx]
      valid = GAME.verify_spin(GAME.server_seed, pdata[:client_seed], record[:nonce], record[:screen])
      puts valid ? "Spin #{record[:nonce]} is VALID (provably fair)" : "Spin #{record[:nonce]} is INVALID!"
    else
      puts "No data available for verification."
    end
  else
    puts "Invalid choice!"
  end
end
