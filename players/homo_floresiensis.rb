require "rubygems"
require "ruby-debug"

class HomoFloresiensis
  attr_accessor :last_move, :board, :moves_to_make

  def initialize
    @board = Board.new
  end

  def name
    "Homo Floresiensis"
  end

  def new_game
    [2, 3, 3, 4, 5].inject([]) { |placed, length| placed.push(Placement.create_for_length_and_context(length, placed)) }
  end

  def take_turn(state, ships_remaining)
    board.push_state(state)
    board.next_move
  end

  class Placement
    attr_reader :length, :context, :direction

    def self.create_for_length_and_context(length, context)
      new(length, context).value
    end

    def initialize(length, context)
      @length = length
      @context = context
    end

    def direction
      @direction ||= [:across, :down].sample
    end

    def value
      @value ||= (generate_coords + [length, direction])
    end

    private

    def generate_coords
      try = [rand(10-length), rand(10)]
      try.reverse! if direction == :down

      is_succcessful_attempt(try) ? try : generate_coords
    end

    def is_succcessful_attempt(try)
      context.all? { |placement|
        (expand(*try) & self.class.expand(*placement)).empty?
      }
    end

    def expand(x, y)
      self.class.expand(x, y, length, direction)
    end

    def self.expand(x, y, length, direction)
      xy         = "#{x}#{y}".to_i
      multiplier = direction == :down ? 1 : 10
      coords     = (0...length).map{ |i| xy + i * multiplier }
    end

  end

  class Board
    attr_reader :states, :moves_made, :avaliable_moves

    def initialize
      @states = []
      @moves_made = []
      @avaliable_moves = []
    end

    def state
      states.last
    end

    def last_move
      moves_made.last
    end

    def push_state(state)
      @states << state
      @avaliable_moves += valid_moves_around_last_move if last_move_was_hit?
    end

    def next_move
      move = get_move
      moves_made << move

      move
    end

    private

    def get_move
      move = if avaliable_moves.empty?
               [rand(10), rand(10)]
             else
               avaliable_moves.pop
             end

      is_succcessful_attempt(move) ? move : get_move
    end

    def is_succcessful_attempt(try)
      state[try[1]][try[0]] == :unknown
    end

    def valid_moves_around_last_move
      moves = []

      moves << [last_move[0], last_move[1]+1] if last_move[1]+1 < 10
      moves << [last_move[0], last_move[1]-1] if last_move[1]-1 >= 0

      moves << [last_move[0]+1, last_move[1]] if last_move[0]+1 < 10
      moves << [last_move[0]-1, last_move[1]] if last_move[0]-1 >= 0

      moves
    end

    def last_move_was_hit?
      !moves_made.empty? && state[last_move[1]][last_move[0]] == :hit
    end
  end
end

