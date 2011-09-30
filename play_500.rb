$:.unshift(File.expand_path("../lib", __FILE__))
require "battleship/game"
require "battleship/console_renderer"

Dir[File.expand_path("../players/*.rb", __FILE__)].each do |path|
  load path
end

@winners     = {}
@move_counts = {}
@render      = ARGV[2] == 'all' ? :all :
                 ARGV[2] == 'final' ? :final : false
@renderer    = Battleship::ConsoleRenderer.new if !!@render
@players     = ARGV[0,2].map{ |s| Module.const_get(s).new }

500.times do |i|
  game = Battleship::Game.new(10, [2, 3, 3, 4, 5], *@players)

  until game.winner
    @renderer.render(game) if :all == @render

    begin
      game.tick
    rescue SystemStackError
      puts "BOOM -- There's a bug"
      Battleship::ConsoleRenderer.new.render(game)
      debugger; p 'init'
    end
  end

  @renderer.render(game) if :final == @render

  puts "\e[H\e[2J" + "#{i + 1}"

  @winners[game.winner.name] ||= 0
  @winners[game.winner.name] += 1
  @move_counts[game.winner.name] ||= []
  @move_counts[game.winner.name] << game.move_count
end

puts "\nResults after 100 runs: #{@winners.inspect}"
@move_counts.each do |key, value|
  puts "Average number of moves for #{ key }: #{value.inject(&:+) / value.count}"
end