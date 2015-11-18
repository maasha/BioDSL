# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #
#                                                                              #
# Copyright (C) 2007-2015 Martin Asser Hansen (mail@maasha.dk).                #
#                                                                              #
# This program is free software; you can redistribute it and/or                #
# modify it under the terms of the GNU General Public License                  #
# as published by the Free Software Foundation; either version 2               #
# of the License, or (at your option) any later version.                       #
#                                                                              #
# This program is distributed in the hope that it will be useful,              #
# but WITHOUT ANY WARRANTY; without even the implied warranty of               #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                #
# GNU General Public License for more details.                                 #
#                                                                              #
# You should have received a copy of the GNU General Public License            #
# along with this program; if not, write to the Free Software                  #
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301,    #
#  USA.                                                                        #
#                                                                              #
# http://www.gnu.org/copyleft/gpl.html                                         #
#                                                                              #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #
#                                                                              #
# This software is part of BioDSL (http://maasha.github.io/BioDSL).            #
#                                                                              #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

# Namespace for BioDSL.
module BioDSL
  # Error class for Serializer.
  SerializerError = Class.new(StandardError)

  # Class for serializing and de-serializing data using Marshal.
  class Serializer
    include Enumerable

    # Constructor for serializer.
    #
    # @param io    [IO]   IO object.
    # @param block [Proc] Block context.
    #
    # @raise [SerializerError] if no block given.
    #
    # @return [Serializer] class instance.
    def initialize(io, &block)
      @io = io

      fail SerializerError, 'No block given' unless block

      block.call(self)
    end

    # Method to write serialized data using Marshal to a given IO.
    #
    # @param obj [Object] Object to serialize.
    #
    # @example
    #   File.open("foo.dat", 'wb') do |io|
    #     BioDSL::Serializer.new(io) do |s|
    #       s << {"foo": 0}
    #       s << {"bar": 1}
    #     end
    #   end
    def <<(obj)
      data = Marshal.dump(obj)
      @io.write([data.size].pack('N'))
      @io.write(data)
    end

    alias_method :writei, :<<

    # Iterator for reading and de-serialized data from a given IO.
    #
    # @example
    #   File.open("foo.dat", 'rb') do |io|
    #     BioDSL::Serializer.new(io) do |s|
    #       s.each do |record|
    #         puts record
    #       end
    #     end
    #   end
    #
    # @yield [Object]
    def each
      yield next_entry until @io.eof?
    end

    # Read next entry from serialized stream.
    #
    # @return [Object] Deserialized Object.
    def next_entry
      size = @io.read(4)
      fail EOFError unless size
      data = @io.read(size.unpack('N').first)
      Marshal.load(data)
    end
  end
end
