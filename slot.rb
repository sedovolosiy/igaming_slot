# frozen_string_literal: true
require 'json'

class SlotGame
  attr_reader :reels, :paytable, :rows, :cols

  def initialize(config_path = 'config.json')
    config = JSON.parse(File.read(config_path))
    @reels     = config['reels']
    @paytable  = config['paytable']
    @cols      = reels.size
    @rows      = 3
  end

  # Returns a 2D array of rows×cols representing the screen symbols.
  def spin
    # Generate screen as an array of columns first
    columns = reels.map do |reel|
      idx = rand(reel.size)
      # Select three consecutive symbols (with wrapping)
      Array.new(rows) { |i| reel[(idx + i) % reel.size] }
    end
    
    # Convert to rows format for consistency with the rest of the code
    columns.transpose
  end

  # Calculates the payout for a single screen given the bet amount.
  # For each symbol, only the maximum length of ways is considered.
  def calculate_win(screen, bet_amount)
    total_win = 0.0
    
    paytable.each_key do |sym|
      ways, length = ways_and_length_for(screen, sym)
      # If there are no ways or the length is less than 2, skip
      next if ways.zero? || length < 2
      
      # Расчет выплаты только для максимальной длины пути для символа
      multiplier = paytable[sym][length - 1] || 0
      total_win += ways * multiplier * bet_amount
    end

    total_win
  end

  # For the given symbol, returns [ways, length]:
  # - ways: the number of ways for the maximum continuous length from the first column.
  # - length: the maximum continuous length of such a way (1..cols).
  # Logic: According to README.md, ways are calculated by multiplying the number of
  # matching symbols (or WILD) in each adjacent column, starting from the left.
  def ways_and_length_for(screen, sym)
    cols = screen[0].size
    symbol_counts_in_cols = []

    # Iterate through columns from left to right
    cols.times do |col_idx|
      # Count occurrences of the target symbol and WILDs in the current column
      # A screen is an array of rows. To get a column, we iterate through rows.
      matches_in_col = 0
      screen.each do |row|
        matches_in_col += 1 if row[col_idx] == sym || row[col_idx] == 'WILD'
      end

      # If no matching symbols (or WILDs) are found in the current column, the way is broken
      break if matches_in_col.zero?

      symbol_counts_in_cols << matches_in_col
    end

    # If no columns with matching symbols were found
    return [0, 0] if symbol_counts_in_cols.empty?

    # Calculate the number of ways and the length of the way
    ways = symbol_counts_in_cols.reduce(1, :*) # Start with 1 for multiplication
    length = symbol_counts_in_cols.size

    [ways, length]
  end

  # Returns an array of winning paths: [{symbol:, coords: [[row, col], ...]}]
  def winning_paths(screen)
    paths = []
    paytable.each_key do |sym|
      ways, length, all_paths = ways_and_length_with_coords(screen, sym)
      next if ways.zero? || length < 2
      payout = paytable[sym][length - 1] || 0
      next if payout <= 0
      all_paths.each do |coords|
        paths << {symbol: sym, coords: coords, length: length, payout: payout}
      end
    end
    paths
  end

  # Returns [ways, length, all_paths]:
  # - ways: number of ways
  # - length: length of the way
  # - all_paths: array of paths (each path is an array of coordinates [[row, col], ...])
  def ways_and_length_with_coords(screen, sym)
    rows = screen.size
    cols = screen[0].size
    # For each starting position in the first column
    start_positions = []
    rows.times do |row|
      start_positions << [row, 0] if screen[row][0] == sym || screen[row][0] == 'WILD'
    end
    all_paths = []
    max_length = 0
    # BFS for all possible paths
    queue = start_positions.map { |pos| [pos] }
    until queue.empty?
      path = queue.shift
      col = path.last[1]
      if col == cols - 1
        all_paths << path
        max_length = [max_length, path.size].max
        next
      end
      next_col = col + 1
      rows.times do |row|
        if screen[row][next_col] == sym || screen[row][next_col] == 'WILD'
          queue << (path + [[row, next_col]])
        end
      end
      # If no continuation is found, record the path
      if queue.none? { |p| p[0...col+1] == path }
        all_paths << path
        max_length = [max_length, path.size].max
      end
    end
    # Keep only the maximum length paths
    max_paths = all_paths.select { |p| p.size == max_length }
    [max_paths.size, max_length, max_paths]
  end
end
