$:.unshift(File.expand_path("../lib", __FILE__))
require "battleship/game"
require "battleship/console_renderer"

Dir[File.expand_path("../players/*.rb", __FILE__)].each do |path|
  load path
end

winners = {}
100.times do
  players = ARGV[0,2].map{ |s| Module.const_get(s).new }

  game = Battleship::Game.new(10, [2, 3, 3, 4, 5], *players)
  until game.winner
    game.tick
  end
  
  print '.'
  
  winners[game.winner.name] ||= 0
  winners[game.winner.name] += 1
end

puts "Results after 100 runs:", winners.inspect