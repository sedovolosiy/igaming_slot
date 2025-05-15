# frozen_string_literal: true
require 'sinatra'
require_relative 'slot'
require_relative 'visual_printer'

enable :sessions

helpers do
  def game
    @game ||= SlotGame.new
  end
end

get '/' do
  session[:balance] ||= 100.0
  session[:bet] ||= 1.0
  @balance = session[:balance]
  @bet = session[:bet]
  @message = session.delete(:message)
  @win = session.delete(:win)
  @screen = session.delete(:screen)
  @screen_rows = session.delete(:screen_rows)
  @win_paths = session.delete(:win_paths)
  erb :index
end

post '/set_bet' do
  bet = params[:bet].to_f
  if bet > 0 && bet <= session[:balance]
    session[:bet] = bet
  else
    session[:message] = 'Ставка должна быть положительной и не больше баланса!'
  end
  redirect to('/'), 303
end

post '/deposit' do
  amount = params[:amount].to_f
  if amount > 0
    session[:balance] += amount
  else
    session[:message] = 'Сумма пополнения должна быть положительной!'
  end
  redirect to('/'), 303
end

post '/spin' do
  bet = session[:bet]
  balance = session[:balance]
  if bet > balance
    session[:message] = 'Недостаточно средств для ставки!'
    redirect to('/'), 303
  end
  screen = game.spin
  win_paths = game.winning_paths(screen)
  win = game.calculate_win(screen, bet)
  session[:balance] = balance - bet + win
  session[:win] = win
  session[:screen] = screen
  session[:screen_rows] = game.screen_rows(screen)
  session[:win_paths] = win_paths
  redirect to('/'), 303
end
