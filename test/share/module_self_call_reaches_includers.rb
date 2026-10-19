# A module's method an include copies into its includers runs with self an
# includer, so a receiverless call there reaches the includer's method of
# the name (syswrite here, as in openssl's Buffering#do_write). The share
# walk takes the module's own method as well, where that call reached
# nothing, and the buffer it was handed, changed in place, joined what the
# walk does not follow. A String that met what the walk does not follow as
# well was then a shared String: the Method's answers here, which
# `map(&c)` keeps, were refused (#9258).
module Buffered
  def initialize
    @wbuffer = String.new
  end

  def write(s)
    @wbuffer << s
    until @wbuffer.empty?
      n = syswrite(@wbuffer)
      @wbuffer.slice!(0, n)
    end
    self
  end
end

class Pipe
  include Buffered

  def initialize(io)
    super()
    @io = io
  end

  def syswrite(data) = @io.write(data)
end

class Ledger
  include Buffered
  attr_reader :log

  def initialize
    super
    @log = String.new
  end

  def syswrite(data)
    @log << data.upcase
    data.bytesize
  end
end

r, w = IO.pipe
Pipe.new(w).write("Seongsu ").write("Station")
w.close
p r.read

ledger = Ledger.new.write("Kondae ").write("Guui")
p ledger.log

c = "Achasan".method(:center)
p [11, 13].map(&c)

# A self call whose name Kernel defines too (puts here) reaches the
# includers' methods as well when each of them defines it, and wherever the
# walk asks whether a call reaches a user method, it answers so for this
# call too. Taken there for Kernel#puts, which only prints, the Array handed
# in the module's own method, which those `puts` keep, would be a typed
# String container holding a shared String, and the program refused.
module Logbook
  def note(place)
    puts([place])
    place
  end
end

class Shelf
  include Logbook
  attr_reader :rows

  def initialize
    @rows = []
  end

  def puts(row) = @rows << row
end

class Wall
  include Logbook
  attr_reader :rows

  def initialize
    @rows = []
  end

  def puts(row) = @rows << row
end

shelf = Shelf.new
s = shelf.note(String.new("Jayang"))
s << "-dong"
p shelf.rows
wall = Wall.new
t = wall.note(String.new("Children's Grand Park"))
t << " Station"
p wall.rows
