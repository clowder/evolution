require "rubygems"
require "ruby-debug"

class HomoGeorgicus
  attr_reader :board

  def name
    "Homo Georgicus"
  end

  def new_game
    @board = Board.new
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
  end#Placement

  class Move
    attr_reader :x, :y, :edges

    def self.find(x, y)
      self.new(x, y)
    end

    def self.new(x,y)
      @identity_map        ||= {}
      new_key                = "#{x}#{y}"
      @identity_map[new_key] = super(x,y) unless @identity_map.has_key?(new_key)
      @identity_map[new_key]
    end

    def self.clear_identity_map!
      @identity_map = nil
    end

    def self.board=(board)
      @board = board
    end

    def self.board
      @board
    end

    def initialize(x,y)
      @x = x
      @y = y
    end

    def to_s
      inspect
    end

    def inspect
      "#<HomoGeorgicus::Move:#{self.object_id} coords=[#{x},#{y}] base_probability=#{base_probability} accumulated_probability=#{accumulated_probability}>"
    end

    def ==(other)
      x == other.x && y == other.y
    end

    def to_a
      [x,y]
    end

    def value
      self.class.board.value_at(x, y)
    end

    def sunk!
      @sunk = true
    end

    def sunk?
      @sunk ||= false
    end

    def floating?
      !sunk?
    end

    def start_sinking!(ship_lengths=[])
      ship_lengths.sort.each { |length|
        following_y = select(:type => [:hit?, :floating?], :axis => :horizontal)
        following_x = select(:type => [:hit?, :floating?], :axis => :vertical)

        following_x << self
        following_y << self

        if following_x.count >= length
          if following_x.count == length
            following_x.map(&:sunk!)
          else
            up   = do_select([:hit?, :floating?], :vertical, :up)
            down = do_select([:hit?, :floating?], :vertical, :down)

            if up.empty?
              down[0, length].map(&:sunk!)
            elsif down.empty?
              up[0, length].map(&:sunk!)
            end
          end
        elsif following_y.count >= length
          if following_y.count == length
            following_y.map(&:sunk!)
          else
            left  = do_select([:hit?, :floating?], :horizontal, :left)
            right = do_select([:hit?, :floating?], :horizontal, :right)

            if left.empty?
              right[0, length].map(&:sunk!)
            elsif right.empty?
              left[0, length].map(&:sunk!)
            end
          end
        else
          puts "Sinking edge case"
        end
      }
    end

    def select(opts={})
      type       = opts[:type] || []
      type       = type.is_a?(Array) ? type : [type]
      axis       = opts[:axis]
      direction  = opts[:direction] || :both
      selected   = []

      if :both == direction
        directions = axis == :horizontal ? [:left, :right] : [:up, :down]
        selected << directions.collect { |d| do_select(type, axis, d) }
      else
        selected << do_select(type, axis, direction)
      end

      selected.flatten.compact
    end

    def do_select(type, axis, direction)
      selected = []
      coords   = if axis == :vertical
                   direction == :up ? [x, y-1] : [x, y+1]
                 else
                   direction == :left ? [x-1, y] : [x+1, y]
                 end

      unless coords[0] < 0 || coords[0] > 9 || coords[1] < 0 || coords[1] > 9
        move = Move.find(*coords)
        if type.all? { |t| move.send(t) } || type.empty?
          selected = [move] | move.do_select(type, axis, direction)
        end
      end

      selected
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

    def made?
      !unknown?
    end

    def probability
      return 0 if sunk?

      base_probability + accumulated_probability
    end

    def accumulated_probability
      return 0 if self.class.board.state.nil? || neighbours.all?(&:unknown?)

      left = acc_left
      left = (left / 1.5) if select(:type => [:unknown?], :axis => :horizontal, :direction => :left).length < self.class.board.smallest_remaining_boat_length

      right = acc_right
      right = (right / 1.5) if select(:type => [:unknown?], :axis => :horizontal, :direction => :right).length < self.class.board.smallest_remaining_boat_length

      up = acc_up
      up = (up / 1.5) if select(:type => [:unknown?], :axis => :vertical, :direction => :up).length < self.class.board.smallest_remaining_boat_length

      down = acc_down
      down = (down / 1.5) if select(:type => [:unknown?], :axis => :vertical, :direction => :down).length < self.class.board.smallest_remaining_boat_length

      left + right + up + down
    end

    def acc_left
      return 0 if 0 == x

      left = Move.find(x-1, y)
      (left.hit? && left.floating?) ? (5 + left.acc_left) : 0
    end

    def acc_right
      return 0 if 9 == x

      right = Move.find(x+1, y)
      (right.hit? && right.floating?) ? (5 + right.acc_right) : 0
    end

    def acc_up
      return 0 if 0 == y

      up = Move.find(x, y-1)
      (up.hit? && up.floating?) ? (5 + up.acc_up) : 0
    end

    def acc_down
      return 0 if 9 == y

      down = Move.find(x, y+1)
      (down.hit? && down.floating?) ? (5 + down.acc_down) : 0
    end

    def base_probability
      left  = select(:type => :unknown?, :axis => :horizontal, :direction => :left).length
      right = select(:type => :unknown?, :axis => :horizontal, :direction => :right).length
      up    = select(:type => :unknown?, :axis => :vertical,   :direction => :up).length
      down  = select(:type => :unknown?, :axis => :vertical,   :direction => :down).length

      highly_productive = [left, right, up, down].collect { |direction|
                            direction >= self.class.board.smallest_remaining_boat_length ? true : nil
                          }.compact.count

      kind_productive   = [[left, right], [up, down]].collect { |directions|
                            directions.inject(&:+) >= self.class.board.smallest_remaining_boat_length ? true : nil
                          }.compact.count

      base_probability = (x.even? == y.even?) ? 2 : 1
      base_probability = (base_probability * (1 + (highly_productive / 5.0))) + (base_probability * (1 + (kind_productive / 10.0)))

      base_probability
    end

    def neighbours
      calculate_y_neighbours + calculate_x_neighbours
    end

    private
    def calculate_y_neighbours
      moves = []
      moves << Move.find(x, y+1) if y+1 < 10
      moves << Move.find(x, y-1) if y-1 >= 0
      moves
    end

    def calculate_x_neighbours
      moves = []
      moves << Move.find(x+1, y) if x+1 < 10
      moves << Move.find(x-1, y) if x-1 >= 0
      moves
    end
  end#Move

  class Board
    attr_reader :state, :ships_remaining, :moves, :edges, :moves_made

    def initialize
      @state           = nil
      @ships_remaining = []
      @moves           = []
      @edges           = []
      @moves_made      = []

      Move.board = self
      Move.clear_identity_map!

      0.upto(9) { |x| 0.upto(9) { |y| moves << Move.new(x,y) } }
    end

    def push_state(state, ships_remaining)
      @state = state
      @ships_remaining << ships_remaining

      last_move.start_sinking!(sunk) if sunk_ship?
    end

    def value_at(x, y)
      state.nil? ? nil : state[y][x]
    end

    def next_move
      moves_made << get_move
      last_move.to_a
    end

    def last_move
      moves_made.last
    end

    def sunk_ship?
      !sunk.empty?
    end

    def sunk
      sunk = []
      if ships_remaining.count > 2
        sunk = ships_remaining[-2] - ships_remaining[-1]
        # [3,3] - [3] == [] .. in battle ships [3,3] - [3] == [3]
        sunk << 3 if (ships_remaining[-2].count - ships_remaining[-1].count) != sunk.count
      end

      sunk
    end

    def average_remaining_boat_length
      ships_remaining[-1].inject(&:+) / ships_remaining[-1].length
    end

    def smallest_remaining_boat_length
      ships_remaining[-1].min
    end

    private
    def get_move
      possible_moves = moves.find_all(&:unknown?)
      possible_moves = possible_moves.sort { |a,b| a.probability <=> b.probability }

      possible_moves.last
    end
  end
end