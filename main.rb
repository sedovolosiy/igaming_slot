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

# Храним данные игроков: salt, client_seed, nonce
PLAYER_DATA = {}

# Получить уникальную соль и client_seed для игрока
player_name = prompt("Введите ваше имя: ")
loop do
  salt = prompt("Введите уникальную соль (любая строка): ")
  if PLAYER_DATA.values.any? { |data| data[:salt] == salt }
    puts "Эта соль уже использована другим игроком. Введите другую."
    next
  end
  client_seed = Digest::SHA256.hexdigest("#{player_name}:#{salt}")
  PLAYER_DATA[player_name] = { salt: salt, client_seed: client_seed, nonce: 0, history: [] }
  break
end

balance = 0.0
puts "Ваш баланс: #{balance.round(2)}"
loop do
  input = prompt("Введите сумму пополнения: ")
  add = input.to_f
  if add > 0
    balance += add
    puts "Баланс пополнен. Текущий баланс: #{balance.round(2)}"
    break
  else
    puts "Сумма пополнения должна быть положительной!"
  end
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
  puts "1. Крутить (provably fair)"
  puts "2. Изменить ставку"
  puts "3. Пополнить баланс"
  puts "4. Выйти"
  puts "5. Проверить честность спина"
  choice = prompt("Выберите действие: ")

  case choice
  when '1'
    if bet > balance
      puts "Недостаточно средств для ставки!"
      next
    end
    pdata = PLAYER_DATA[player_name]
    screen = GAME.provably_fair_spin(pdata[:client_seed], pdata[:nonce])
    PLAYER_DATA[player_name][:nonce] += 1
    # Сохраняем историю только если был совершен спин
    if pdata[:nonce] > 0
      pdata[:history] << {nonce: pdata[:nonce] - 1, screen: screen}
    end
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
  when '5'
    pdata = PLAYER_DATA[player_name]
    print "Введите номер спина для проверки (0 - последний, 1 - предыдущий и т.д.): "
    idx = gets.strip.to_i
    if pdata[:history] && idx < pdata[:history].size
      record = pdata[:history][-1 - idx]
      valid = GAME.verify_spin(GAME.server_seed, pdata[:client_seed], record[:nonce], record[:screen])
      puts valid ? "Spin #{record[:nonce]} is VALID (provably fair)" : "Spin #{record[:nonce]} is INVALID!"
    else
      puts "Нет данных для проверки."
    end
  else
    puts "Некорректный выбор!"
  end
end
