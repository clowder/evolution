require "rubygems"
require "ruby-debug"

class HomoErgaster
  attr_accessor :last_move, :board, :moves_to_make
  
  def initialize
    @board         = Board.new
    @moves_to_make = []
  end

  def name
    "Homo Ergaster"
  end

  def new_game
    [
      [1, 0, 5, :across],
      [1, 1, 4, :across],
      [1, 2, 3, :across],
      [1, 3, 3, :across],
      [1, 4, 2, :across]
    ]
  end

  def take_turn(state, ships_remaining)
    board.push_state(state)
    count = 0
    
    if board.last_move_was_hit? 
      self.moves_to_make = self.moves_to_make + board.valid_moves_around_last_move
    end
    
    begin      
      if self.moves_to_make.count > 0
        move = self.moves_to_make.pop
      else
        move = [rand(10), rand(10)]
      end
    end until state[move[1]][move[0]] == :unknown
    
    board.push_move(move)
    move
  end
  
  class Board
    attr_reader :states, :moves
    
    def initialize
      @states = []
      @moves = []
    end
    
    def push_state(state)
      @states << state
    end
    
    def push_move(move)
      @moves << move
    end
    
    def valid_moves_around_last_move
      move  = moves.last
      moves = []
      
      moves << [move[0], move[1]+1] if move[1]+1 < 10 
      moves << [move[0], move[1]-1] if move[1]-1 >= 0
    
      moves << [move[0]+1, move[1]] if move[0]+1 < 10 
      moves << [move[0]-1, move[1]] if move[0]-1 >= 0
      
      moves
    end
    
    def last_move_was_hit?
      state = states.last
      move  = moves.last
      
      if move.nil?
        false
      else
        state[move[1]][move[0]] == :hit
      end
    end
  end
end

