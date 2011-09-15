require "rubygems"
require "ruby-debug"

class HomoErectus
  def name
    "Homo Erectus"
  end

  def new_game
    [
      [0, 0, 5, :across],
      [0, 1, 4, :across],
      [0, 2, 3, :across],
      [0, 3, 3, :across],
      [0, 4, 2, :across]
    ]
  end

  def take_turn(state, ships_remaining)    
    begin
      move = [rand(10), rand(10)]
    end until state[move[1]][move[0]] == :unknown
    
    move
  end  
end

