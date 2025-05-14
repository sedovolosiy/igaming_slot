# frozen_string_literal: true

class ScreenPrinter
  def self.call(screen)
    screen.transpose.each do | row |
        row_string = row.map {|el| print_symbol(el)}.join(' | ')
        puts "| #{row_string} |"
    end
  end

  def self.print_symbol(s)
    case s
    when "BANANA"
        "BANANA"
    when "APPLE"
        "***APPLE**"
    when "PLUM"
        "***PLUM***"
    when "STAR"
        "***STAR***"
    when "WILD"
        "***WILD***"
    when "BAR"
        "****BAR***"
    when "7"
        "*****7****"
    end
  end
end
