$:.unshift(File.expand_path("../lib", __FILE__))
require "battleship/game"
require "battleship/console_renderer"

Dir[File.expand_path("../players/*.rb", __FILE__)].each do |path|
  load path
end

@number_of_rounds = ARGV[2].to_i.zero? ? 20 : ARGV[2].to_i
@winners     = {}
@move_counts = {}
@render      = ARGV[3] == 'all' ? :all :
                 ARGV[3] == 'final' ? :final : false
@renderer    = Battleship::ConsoleRenderer.new if !!@render
@players     = ARGV[0,2].map{ |s| Module.const_get(s).new }

@number_of_rounds.times do |i|
  @players.reverse!  
  game = Battleship::Game.new(10, [2, 3, 3, 4, 5], *@players)

  until game.winner
    @renderer.render(game) if :all == @render
    game.tick
  end

  @renderer.render(game) if :final == @render

  puts "\e[H\e[2J" + "#{i + 1}"

  @winners[game.winner.name] ||= 0
  @winners[game.winner.name] += 1
  @move_counts[game.winner.name] ||= []
  @move_counts[game.winner.name] << game.move_count
end

puts "\nResults after #{ @number_of_rounds } runs: #{@winners.inspect}"
@move_counts.each do |key, value|
  puts "Average number of moves for #{ key }: #{value.inject(&:+) / value.count}"
end