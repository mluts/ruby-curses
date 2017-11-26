gem 'curses'
require 'curses'

def clamp(min, n, max)
  if n <= min
    min
  elsif n >= max
    max
  else
    n
  end
end

class Screen
  include Curses

  def initialize
    @termcaps = {}
  end

  def create
    init_screen
    nonl
    cbreak
    noecho

    at_exit { destroy }
  end

  def destroy
    close_screen
  end
end

class Point
  def initialize(window)
    @window = window
    @x = 0
    @y = 0
  end

  def mv(dx, dy)
    @x = clamp(0, @x + dx, @window.maxx)
    @y = clamp(0, @y + dy, @window.maxy)
  end

  def render
    @window.put_str('#', @x, @y)
  end
end

class Mapping
  def initialize(window)
    @window = window
    @table = {}
    yield self if block_given?
  end

  def read_key
    key = @window.get_char
    print key.inspect
    @table[key]&.call(key)
    key
  end

  def on(key, &block)
    @table[key] = block
  end
end

class Window < Curses::Window
  def initialize(*)
    super
    keypad(true)
  end

  def render
    clear
    yield
    refresh
  end

  def put_str(str, x, y)
    setpos(y, x)
    addstr(str)
    setpos(y, x)
  end
end

screen = Screen.new
screen.create

win = Window.new(0, 0, 0, 0)

point = Point.new(win)
mapping = Mapping.new(win) do |m|
  m.on 'q' do
    exit 0
  end

  m.on Curses::Key::UP do
    point.mv(0, -1)
  end

  m.on Curses::Key::DOWN do
    point.mv(0, 1)
  end

  m.on Curses::Key::LEFT do
    point.mv(-1, 0)
  end

  m.on Curses::Key::RIGHT do
    point.mv(1, 0)
  end
end

loop do
  mapping.read_key
  win.render do
    point.render
  end
end
