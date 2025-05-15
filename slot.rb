# frozen_string_literal: true
require 'json'
require 'set'

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
    columns
  end

  # Returns the screen as rows for visualization (transpose)
  def screen_rows(screen)
    screen.transpose
  end

  # Parallel simple calculation of win using column counts
  def calculate_win(screen, bet_amount)
    total_win = 0.0
    # For each symbol, multiply column counts for every payout length
    paytable.each do |sym, payouts|
      # counts of (symbol or WILD) in each column
      counts = screen.map { |col| col.count(sym) + col.count('WILD') }
      payouts.each_with_index do |payout, idx|
        length = idx + 1
        # only lengths >=2, within column size, and positive payout
        next if length < 2 || length > counts.size || payout.to_i <= 0
        ways = counts.take(length).reduce(1, :*)
        total_win += ways * payout * bet_amount
      end
    end
    total_win
  end

  # Returns an array of paths (each path is an array of coordinates) for symbol sym and length
  # The path always starts from the first column and goes consecutively to the right
  def ways_paths_for_length(screen, sym, length)
    rows = screen.size
    cols = screen[0].size
    return [] if length > cols
    return [] unless length == 2 || length == 3 # only for 2 and 3 in a row
    start_positions = []
    rows.times do |row|
      start_positions << [[row, 0]] if screen[row][0] == sym || screen[row][0] == 'WILD'
    end
    paths = []
    queue = start_positions.dup
    until queue.empty?
      path = queue.shift
      col = path.last[1]
      if path.size == length
        paths << path
        next
      end
      next_col = col + 1
      next if next_col >= cols
      rows.times do |row|
        if screen[row][next_col] == sym || screen[row][next_col] == 'WILD'
          queue << (path + [[row, next_col]])
        end
      end
    end
    paths.map { |p| p.map(&:dup) }
  end

  # Returns the number of ways for symbol sym and length
  def ways_for_length(screen, sym, length)
    rows = screen.size
    cols = screen[0].size
    return 0 if length > cols
    # For each starting position in the first column
    start_positions = []
    rows.times do |row|
      start_positions << [row, 0] if screen[row][0] == sym || screen[row][0] == 'WILD'
    end
    count = 0
    queue = start_positions.map { |pos| [pos] }
    until queue.empty?
      path = queue.shift
      col = path.last[1]
      if path.size == length
        count += 1
        next
      end
      next_col = col + 1
      next if next_col >= cols
      rows.times do |row|
        if screen[row][next_col] == sym || screen[row][next_col] == 'WILD'
          queue << (path + [[row, next_col]])
        end
      end
    end
    count
  end

  # Returns an array of winning paths: [{symbol:, coords: [[row, col], ...]}]
  def winning_paths(screen)
    paths = []
    # Convert columns to row-major matrix
    matrix = screen.transpose
    paytable.each_key do |sym|
      ways, length, all_paths = ways_and_length_with_coords(matrix, sym)
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
