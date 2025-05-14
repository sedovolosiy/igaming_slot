# frozen_string_literal: true

# ANSI color codes for highlighting
module ConsoleColors
  RESET = "\e[0m"
  RED = "\e[31m"
  GREEN = "\e[32m"
  YELLOW = "\e[33m"
  BLUE = "\e[34m"
  MAGENTA = "\e[35m"
  CYAN = "\e[36m"
  BOLD = "\e[1m"
end

class VisualPrinter
  include ConsoleColors

  # screen: 2D array [row][col]
  # win_paths: array of {symbol:, coords: [[row, col], ...]}
  def self.call(screen, win_paths)
    rows = screen.size
    cols = screen[0].size
    # For quick lookup: { [row, col] => {symbol, color} }
    highlight = {}
    color_map = [RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN]
    win_paths.each_with_index do |path, idx|
      color = color_map[idx % color_map.size]
      path[:coords].each { |rc| highlight[rc] = {symbol: path[:symbol], color: color} }
    end

    puts "\nSlot visualization (winning paths highlighted):"
    rows.times do |row|
      line = []
      cols.times do |col|
        cell = screen[row][col]
        if highlight[[row, col]]
          color = highlight[[row, col]][:color]
          line << "#{color}■#{cell}■#{RESET}"
        else
          line << cell
        end
      end
      puts line.join('   ')
    end
    puts
    win_paths.each_with_index do |path, idx|
      color = color_map[idx % color_map.size]
      coords_str = path[:coords].map { |r, c| "(#{r+1},#{c+1})" }.join(' → ')
      puts "#{color}Path #{idx+1}: #{path[:symbol]} #{coords_str} (length: #{path[:length]}, payout: #{path[:payout]})#{RESET}"
    end
  end
end
