# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #
#                                                                                #
# Copyright (C) 2007-2014 Martin Asser Hansen (mail@maasha.dk).                  #
#                                                                                #
# This program is free software; you can redistribute it and/or                  #
# modify it under the terms of the GNU General Public License                    #
# as published by the Free Software Foundation; either version 2                 #
# of the License, or (at your option) any later version.                         #
#                                                                                #
# This program is distributed in the hope that it will be useful,                #
# but WITHOUT ANY WARRANTY; without even the implied warranty of                 #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                  #
# GNU General Public License for more details.                                   #
#                                                                                #
# You should have received a copy of the GNU General Public License              #
# along with this program; if not, write to the Free Software                    #
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA. #
#                                                                                #
# http://www.gnu.org/copyleft/gpl.html                                           #
#                                                                                #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #
#                                                                                #
# This software is part of Biopieces (www.biopieces.org).                        #
#                                                                                #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

module BioPieces
  # Class for Inter Process Communication between forked processes using msgpack
  # to serialize and deserialize objects.
  class Stream
    include Enumerable

    # Create a pair of connected pipe endpoints. The connection uses msgpack
    # allowing objects to be written and read.
    #
    # Stream.pipe ->  [read_io, write_io]
    def self.pipe
      read, write = IO.pipe(Encoding::BINARY)

      [self.new(read), self.new(write)]
    end

    def initialize(io)
      @io = io
    end

    def close
      @io.close
    end

    def closed?
      @io.closed?
    end

    def each
      while ! @io.eof?
        yield read
      end
    end

    def read
      size = @io.read(4)
      raise EOFError unless size
      size = size.unpack("I").first
      msg  = @io.read(size)
      MessagePack.unpack(msg, symbolize_keys: true)
    end

    def write(obj)
      msg = MessagePack.pack(obj)
      @io.write([msg.size].pack("I"))
      @io.write(msg)
    end

    alias :<< :write
  end

  class Channel
    include Enumerable

    def self.pair
      queue = Queue.new

      [self.new(queue), self.new(queue)]
    end

    def initialize(queue)
      @queue = queue
    end

    def each
      while obj = read
        yield obj
      end
    end

    def read
      @queue.pop
    end

    def write(obj)
      @queue << obj
    end

    def terminate
      @queue << nil
    end

    alias :<< :write
  end
end
