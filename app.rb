# frozen_string_literal: true

require 'sinatra'
require 'rack/session/cookie'
require 'set' # Make sure Set is required

# Global store for used salts (simplification for this example)
# In a real app, use a database for this to ensure persistence and thread-safety if using multi-threaded servers.
$used_salts = Set.new

# Session secret should be a long, random string and kept private.
# For development, you can generate one using: ruby -rsecurerandom -e "puts SecureRandom.hex(64)"
# Store this in an environment variable in production (e.g., ENV['SESSION_SECRET'])
SESSION_SECRET_KEY = ENV['SESSION_SECRET'] || 'super_secret_development_key_make_sure_to_change_this_for_production'

# Explicitly use Rack::Session::Cookie middleware
use Rack::Session::Cookie, secret: SESSION_SECRET_KEY, key: 'rack.session.slotgame'

set :port, ENV.fetch('PORT') { 4567 }
set :bind, '0.0.0.0'

require_relative 'slot'
require_relative 'visual_printer' # Assuming this is used by views or helpers not shown fully
require 'digest'

MAX_HISTORY_LENGTH = 20 # Maximum number of history items to keep in session

helpers do
  def game
    @game ||= SlotGame.new
  end

  def player_data
    session[:player_data] ||= { history: [], nonce: 0 } # Ensure history and nonce are initialized
  end
end

before do
  # Allow access to /set_player and any public assets (if any)
  return if ['/set_player'].include?(request.path_info) || request.path_info.start_with?('/public/')

  unless session[:player_name] && player_data[:salt] && player_data[:client_seed]
    redirect to('/set_player'), 303
  end
end

get '/set_player' do
  @error = session.delete(:player_error)
  erb :set_player
end

post '/set_player' do
  name = params[:player_name].to_s.strip
  salt = params[:salt].to_s.strip

  if name.empty? || salt.empty?
    session[:player_error] = 'Player name and salt cannot be empty.'
    redirect to('/set_player'), 303
    return
  end

  # Check against global $used_salts
  if $used_salts.include?(salt)
    session[:player_error] = 'This salt is already used. Please choose another.'
    redirect to('/set_player'), 303
    return
  end

  client_seed = Digest::SHA256.hexdigest("#{name}:#{salt}")
  session[:player_name] = name
  
  # Initialize player_data structure correctly
  data = { 
    salt: salt, 
    client_seed: client_seed, 
    nonce: 0, 
    history: [] 
  }
  session[:player_data] = data
  
  $used_salts.add(salt) # Add to global set
  # session.delete(:used_salts) # Clean up old session-based salts if any existed, not strictly necessary now

  # Reset balance and bet for the new player
  session[:balance] = 0.0  # Or any default starting balance you prefer
  session[:bet] = 1.0    # Default bet

  redirect to('/'), 303
end

get '/' do
  session[:balance] ||= 0.0
  session[:bet] ||= 1.0 # Default bet

  @balance = session[:balance]
  @bet = session[:bet]
  @player_name = session[:player_name]
  
  p_data = player_data
  @client_seed_hash = p_data[:client_seed] # This is the hash for the *current* setup, not verified
  @current_nonce = p_data[:nonce]
  @server_seed_hash = game.server_seed_hash # Hash of the *next* server seed

  @message = session.delete(:message)
  
  @last_win_amount = session.delete(:last_win_amount)
  @last_screen_rows = session.delete(:last_screen_rows_for_display)
  @last_winning_cells = session.delete(:last_winning_cells_for_display)

  @verified_screen_rows = session.delete(:verified_screen_rows_for_display)
  @verified_winning_cells = session.delete(:verified_winning_cells_for_display)
  @verified_win_amount = session.delete(:verified_win_amount) 
  @verified_nonce = session.delete(:verified_nonce)
  @verified_server_seed = session.delete(:verified_server_seed) # Revealed seed
  @verified_client_seed_hash = session.delete(:verified_client_seed_hash) # Hash of client seed used for verified spin
  @verified_server_seed_hash = session.delete(:verified_server_seed_hash) # Hash of revealed server seed

  @history = p_data[:history] || [] 
  @can_verify_last_spin = session.key?(:last_spin_to_verify) 

  @require_deposit = @balance <= 0.0 && @last_win_amount.nil? 
  erb :index
end

post '/set_bet' do
  bet_amount = params[:bet].to_f
  if bet_amount > 0 && bet_amount <= session[:balance]
    session[:bet] = bet_amount
    session[:message] = "Bet updated to #{bet_amount.round(2)}"
  else
    session[:message] = 'Bet must be positive and not greater than balance!'
  end
  redirect to('/'), 303
end

post '/deposit' do
  amount = params[:amount].to_f # Corrected to use params[:amount]
  if amount > 0
    session[:balance] = (session[:balance] || 0.0) + amount
    session[:message] = "Deposited #{amount.round(2)}. Your new balance is #{session[:balance].round(2)}."
  else
    session[:message] = 'Deposit amount must be positive!'
  end
  redirect to('/'), 303
end

post '/spin' do
  bet = session[:bet].to_f
  balance = session[:balance].to_f
  p_data = player_data # Access through helper to ensure initialization

  if balance <= 0.0 && bet > 0 
     session[:message] = "Your balance is zero. Please deposit funds to play."
     redirect to('/'), 303
     return
  end

  if bet <= 0
    session[:message] = "Bet must be a positive amount."
    redirect to('/'), 303
    return
  end
  
  if bet > balance
    session[:message] = "Not enough balance for this bet. Your balance is #{balance.round(2)}."
    redirect to('/'), 303
    return
  end

  current_server_seed = game.server_seed # Get the server seed for this spin
  
  # Store details for immediate verification *before* nonce is incremented
  session[:last_spin_to_verify] = {
    server_seed: current_server_seed,
    client_seed: p_data[:client_seed], # Store the clientSeed used for this spin
    nonce: p_data[:nonce] # Nonce used for this spin
  }

  # Use the provably_fair_spin method
  screen = game.provably_fair_spin(current_server_seed, p_data[:client_seed], p_data[:nonce])
  win_paths = game.winning_paths(screen) 
  win = game.calculate_win(screen, bet)

  session[:balance] = balance - bet + win
  
  session[:last_win_amount] = win
  session[:last_screen_rows_for_display] = game.screen_rows(screen)
  
  winning_cells = []
  (win_paths || []).each do |path_info| 
    (path_info[:coords] || []).each do |coord| 
      winning_cells << {row: coord[0], col: coord[1]}
    end
  end
  session[:last_winning_cells_for_display] = winning_cells
  session[:message] = win > 0 ? "Congratulations! You won #{win.round(2)}!" : "No win this time. Try again!"

  # History still stores minimal info, not directly used by the new "verify last spin" button
  current_history = p_data[:history] || []
  current_history << {
    nonce: p_data[:nonce], 
    server_seed: current_server_seed,
  }
  
  if current_history.length > MAX_HISTORY_LENGTH
    current_history.shift(current_history.length - MAX_HISTORY_LENGTH)
  end
  p_data[:history] = current_history
  
  p_data[:nonce] += 1
  session[:player_data] = p_data 

  redirect to('/'), 303
end

post '/verify_last_spin' do
  spin_details = session[:last_spin_to_verify]

  if spin_details && spin_details[:client_seed] 
    verified_screen = game.provably_fair_spin(
      spin_details[:server_seed],
      spin_details[:client_seed], 
      spin_details[:nonce]
    )
    
    session[:verified_nonce] = spin_details[:nonce]
    session[:verified_server_seed] = spin_details[:server_seed] # Revealed seed
    session[:verified_client_seed_hash] = spin_details[:client_seed] # This is already a hash
    session[:verified_server_seed_hash] = Digest::SHA256.hexdigest(spin_details[:server_seed]) # Hash of the revealed server seed
    
    session[:message] = "Verification for Nonce: #{spin_details[:nonce]}"
    session[:verified_screen_rows_for_display] = game.screen_rows(verified_screen)
    
    verified_win_paths = game.winning_paths(verified_screen)
    verified_winning_cells = []
    (verified_win_paths || []).each do |path_info|
        (path_info[:coords] || []).each do |coord|
            verified_winning_cells << {row: coord[0], col: coord[1]}
        end
    end
    session[:verified_winning_cells_for_display] = verified_winning_cells
  else
    session[:message] = "No previous spin details found to verify, or client seed missing in details."
  end
  redirect to('/'), 303
end

# Example of how to serve static files if you have them (e.g., CSS, JS)
# configure do
#   set :public_folder, File.join(File.dirname(__FILE__), 'public')
# end
