# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #
#                                                                                #
# Copyright (C) 2007-2015 Martin Asser Hansen (mail@maasha.dk).                  #
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
  class SerializerError < StandardError; end

  # Class for serializing and de-serializing data using Marshal. 
  class Serializer
    include Enumerable

    # Constructor for serializer.
    def initialize(io, &block)
      @io = io
      raise SerializerError, "No block given" unless block
      block.call(self)
    end

    # Method to write serialized data using Marshal to a given IO.
    # Usage:
    # File.open("foo.dat", 'wb') do |io|
    #   BioPieces::Serializer.new(io) do |s|
    #     s << {"foo": 0}
    #     s << {"bar": 1}
    #   end
    # end
    def <<(obj)
      data = Marshal.dump(obj)
      @io.write([data.size].pack("N"))
      @io.write(data)
    end

    alias :write :<< 

    # Iterator for reading and de-serialized data from a given IO.
    # Usage:
    # File.open("foo.dat", 'rb') do |io|
    #   BioPieces::Serializer.new(io) do |s|
    #     s.each do |record|
    #       puts record
    #     end
    #   end
    # end
    def each
      until @io.eof? 
        yield next_entry
      end
    end

    def next_entry
      size = @io.read(4)
      raise EOFError unless size
      data = @io.read(size.unpack("N").first)
      Marshal.load(data)
    end
  end
end
