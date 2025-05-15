# frozen_string_literal: true
require 'sinatra'
require_relative 'slot'
require_relative 'visual_printer'
require 'digest'

enable :sessions

helpers do
  def game
    @game ||= SlotGame.new
  end
  def player_data
    session[:player_data] ||= {}
  end
end

before do
  unless request.path_info == '/set_player'
    unless session[:player_name] && player_data[:salt] && player_data[:client_seed]
      redirect to('/set_player'), 303
    end
  end
end

get '/set_player' do
  @error = session.delete(:player_error)
  erb :set_player
end

post '/set_player' do
  name = params[:player_name].to_s.strip
  salt = params[:salt].to_s.strip
  used_salts = (session[:used_salts] ||= [])
  if used_salts.include?(salt)
    session[:player_error] = 'This salt is already used. Please choose another.'
    redirect to('/set_player'), 303
  end
  client_seed = Digest::SHA256.hexdigest("#{name}:#{salt}")
  session[:player_name] = name
  player_data[:salt] = salt
  player_data[:client_seed] = client_seed
  player_data[:nonce] = 0
  used_salts << salt
  redirect to('/'), 303
end

get '/' do
  session[:balance] ||= 0.0
  session[:bet] ||= 1.0
  @balance = session[:balance]
  @bet = session[:bet]
  @message = session.delete(:message)
  @win = session.delete(:win)
  @screen = session.delete(:screen)
  @screen_rows = session.delete(:screen_rows)
  @win_paths = session.delete(:win_paths)
  @require_deposit = @balance <= 0.0
  erb :index
end

post '/set_bet' do
  bet = params[:bet].to_f
  if bet > 0 && bet <= session[:balance]
    session[:bet] = bet
  else
    session[:message] = 'Bet must be positive and not greater than balance!'
  end
  redirect to('/'), 303
end

post '/deposit' do
  amount = params[:amount].to_f
  if amount > 0
    session[:balance] += amount
  else
    session[:message] = 'Deposit amount must be positive!'
  end
  redirect to('/'), 303
end

post '/spin' do
  bet = session[:bet]
  balance = session[:balance]
  if balance <= 0.0
    session[:message] = 'Please deposit funds before playing!'
    redirect to('/'), 303
  end
  if bet > balance
    session[:message] = 'Not enough funds for the bet!'
    redirect to('/'), 303
  end
  pdata = player_data
  # nonce будет использоваться для текущего спина
  screen = game.provably_fair_spin(pdata[:client_seed], pdata[:nonce])
  win_paths = game.winning_paths(screen)
  win = game.calculate_win(screen, bet)
  session[:balance] = balance - bet + win
  session[:win] = win
  session[:screen] = screen
  session[:screen_rows] = game.screen_rows(screen)
  
  # Преобразуем пути в формат для отображения
  winning_cells = []
  win_paths.each do |path|
    path[:coords].each do |row, col|
      winning_cells << [row, col, path[:symbol], path[:payout]]
    end
  end
  session[:winning_cells] = winning_cells
  # Сохраняем историю только после успешного спина
  pdata[:history] ||= []
  pdata[:history] << {
    nonce: pdata[:nonce],
    screen: screen,
    server_seed: game.server_seed
  }
  pdata[:nonce] += 1
  redirect to('/'), 303
end

post '/verify' do
  idx = params[:spin_index].to_i
  pdata = player_data
  history = pdata[:history] || []
  if idx < 0 || idx >= history.size
    session[:message] = 'No data for this spin.'
  else
    record = history[-1 - idx]
    # Создаем временный экземпляр игры с тем же server_seed
    temp_game = SlotGame.new('config.json', record[:server_seed])
    # Проверяем честность используя сохраненные server_seed, client_seed и nonce
    regenerated = temp_game.provably_fair_spin(pdata[:client_seed], record[:nonce])
    valid = (regenerated == record[:screen])
    if valid
      session[:message] = '<div class="valid">Spin ' + record[:nonce].to_s + ' is VALID (provably fair)</div>'
    else
      session[:message] = '<div class="error">Spin ' + record[:nonce].to_s + ' is INVALID!</div>'
    end
  end
  redirect to('/'), 303
end
