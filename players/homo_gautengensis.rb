require "rubygems"
require "ruby-debug"

class HomoGautengensis
  attr_reader :board

  def initialize
    @board = Board.new
  end

  def name
    "Homo Gautengensis"
  end

  def new_game
    [2, 3, 3, 4, 5].inject([]) { |placed, length| placed.push(Placement.for_length_and_context(length, placed)) }
  end

  def take_turn(state, ships_remaining)
    board.push_state(state, ships_remaining)
    board.next_move
  end

  module Placement
    def self.for_length_and_context(length, context)
      direction = [:across, :down].sample
      generate_coords(length, direction, context) + [length, direction]
    end

    private

    def self.generate_coords(length, direction, context)
      try = [rand(10-length), rand(10)]
      try.reverse! if direction == :down

      succcessful_attempt?(try, length, direction, context) ? try : generate_coords(length, direction, context)
    end

    def self.succcessful_attempt?(try, length, direction, context)
      context.all? { |placement|
        (expand(*try, length, direction) & expand(*placement)).empty?
      }
    end

    def self.expand(x, y, length, direction)
      xy         = "#{x}#{y}".to_i
      multiplier = direction == :down ? 1 : 10
      coords     = (0...length).map{ |i| xy + i * multiplier }
    end

  end

  class Move
    attr_reader :x, :y

    def initialize(board, coords=nil)
      @board = board
      @x, @y = coords.nil? ? random_move : coords
    end

    def inspect
      "#<HomoGautengensis::Move:#{self.object_id} coords=[#{x},#{y}]>"
    end
    
    def ==(other)
      x == other.x && y == other.y
    end

    def to_a
      [x,y]
    end

    def value
      @board.value_at(x, y)
    end

    def valid?
      unmade? && unknown?
    end

    def unknown?
      value == :unknown
    end

    def hit?
      value == :hit
    end

    def miss?
      value == :miss
    end

    def unmade?
      !made?
    end

    def made?
      !!@made
    end

    def made!
      @made = true
    end

    def sunk_ship?
      @board.last_move_sunk_ship? && self.hit?
    end

    def better_guess_neighbours
      probable   = []
      improbable = []

      if !self.sunk_ship? && self.hit?
        if neighbours.any?(&:hit?)
          continue_on_x = false
          continue_on_y = false
          
          unknown_x = calculate_x_neighbours.find_all(&:unknown?)
          unknown_y = calculate_y_neighbours.find_all(&:unknown?)
          
          neighbours.each do |move|
            continue_on_y = true if (move.hit? && move.y == y) || unknown_y.empty?
            continue_on_x = true if (move.hit? && move.x == x) || unknown_x.empty?
          end

          if continue_on_y
            probable   += unknown_x
            improbable += unknown_y
          end 
          
          if continue_on_x
            probable   += unknown_y
            improbable += unknown_x
          end
        else
          probable = neighbours
        end
      end

      [probable.find_all(&:unknown?), improbable.find_all(&:unknown?)]
    end

    def neighbours
      @neighbours ||= calculate_neighbours
    end

    private
    def calculate_neighbours
      calculate_y_neighbours + calculate_x_neighbours
    end

    def calculate_y_neighbours
      moves = []
      moves << Move.new(@board, [x, y+1]) if y+1 < 10
      moves << Move.new(@board, [x, y-1]) if y-1 >= 0
      moves
    end

    def calculate_x_neighbours
      moves = []
      moves << Move.new(@board, [x+1, y]) if x+1 < 10
      moves << Move.new(@board, [x-1, y]) if x-1 >= 0
      moves
    end

    def random_move(complimentary=true)
      x = rand(10)
      y = complimentary ? complimentary_y(x) : rand(10)

      y.nil? ? random_move(false) : [x, y]
    end

    def complimentary_y(x, guess_limit=100)
      return nil if guess_limit.zero?
      y = rand(10)
      (x.odd? != y.odd?) ? y : complimentary_y(x, guess_limit-1)
    end
  end

  class Board
    attr_reader :states, :ships_remaining, :moves_made, :probable_moves, :improbable_moves

    def initialize
      @states = []
      @ships_remaining = []
      @moves_made = []
      @probable_moves = []
      @improbable_moves = []
    end

    def push_state(state, ships_remaining)
      last_move.made! unless last_move.nil?
      @states << state
      @ships_remaining << ships_remaining
      update_avaliable_moves
    end

    def current_state
      states.last
    end

    def value_at(x, y)
      current_state.nil? ? nil : current_state[y][x]
    end

    def next_move
      move = get_move
      moves_made << move

      move.to_a
    end

    def last_move_sunk_ship?
      if ships_remaining.count < 2
        false
      else
        ships_remaining[-1].count != ships_remaining[-2].count
      end
    end

    private
    def update_avaliable_moves
      return if last_move.nil? || last_move.miss?

      probable, improbable = last_move.better_guess_neighbours

      @probable_moves   += probable
      @improbable_moves += improbable      
      
      @improbable = [] if last_move_sunk_ship?
    end

    def last_move
      moves_made.empty? ? nil : moves_made.last
    end

    def get_move
      move = if !probable_moves.empty?
               probable_moves.shift
             elsif !improbable_moves.empty?
               improbable_moves.shift
             else
               Move.new(self)
             end

      move.valid? ? move : get_move
    end
  end
end

