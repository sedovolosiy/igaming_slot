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

# === Simple CLI for Slot Game ===

def prompt(msg)
  print msg
  gets.strip
end

balance = nil
loop do
  input = prompt("Введите начальный баланс: ")
  balance = input.to_f
  break if balance > 0
  puts "Баланс должен быть положительным числом!"
end

bet = nil
loop do
  input = prompt("Введите размер ставки: ")
  bet = input.to_f
  if bet > 0 && bet <= balance
    break
  else
    puts "Ставка должна быть положительной и не больше баланса!"
  end
end

loop do
  puts "\nВаш баланс: #{balance.round(2)} | Ваша ставка: #{bet.round(2)}"
  puts "1. Крутить"
  puts "2. Изменить ставку"
  puts "3. Пополнить баланс"
  puts "4. Выйти"
  choice = prompt("Выберите действие: ")

  case choice
  when '1'
    if bet > balance
      puts "Недостаточно средств для ставки!"
      next
    end
    screen = GAME.spin
    win_paths = GAME.winning_paths(screen)
    VisualPrinter.call(GAME.screen_rows(screen), win_paths)
    win = GAME.calculate_win(screen, bet)
    balance -= bet
    balance += win
    puts "Вы выиграли: #{win.round(2)}"
    puts "Ваш новый баланс: #{balance.round(2)}"
    if balance < bet
      puts "Недостаточно средств для следующей ставки. Пополните баланс или измените ставку."
    end
  when '2'
    input = prompt("Введите новый размер ставки: ")
    new_bet = input.to_f
    if new_bet > 0 && new_bet <= balance
      bet = new_bet
    else
      puts "Ставка должна быть положительной и не больше баланса!"
    end
  when '3'
    input = prompt("Введите сумму пополнения: ")
    add = input.to_f
    if add > 0
      balance += add
      puts "Баланс пополнен. Текущий баланс: #{balance.round(2)}"
    else
      puts "Сумма пополнения должна быть положительной!"
    end
  when '4'
    puts "Спасибо за игру! Ваш финальный баланс: #{balance.round(2)}"
    break
  else
    puts "Некорректный выбор!"
  end
end
