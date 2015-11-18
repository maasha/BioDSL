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
# This software is part of BioDSL (www.BioDSL.org).                              #
#                                                                                #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

module BioDSL
  # Error class for all exceptions to do with FASTQ.
  class FastqError < StandardError; end

  # Class for parsing FASTQ entries from an ios and return as Seq objects.
  class Fastq < BioDSL::Filesys
    def self.open(*args)
      ios = IO.open(*args)

      if block_given?
        begin
          yield self.new(ios)
        ensure
          ios.close
        end
      else
        return self.new(ios)
      end
    end

    def initialize(io)
      @io        = io
    end

    def each
      while entry = next_entry
        yield entry
      end
    end

    # Method to get the next FASTQ entry from an ios and return this
    # as a Seq object. If no entry is found or eof then nil is returned.
    def next_entry
      return nil if @io.eof?
      seq_name = @io.gets[1 .. -2]
      seq      = @io.gets.chomp
      @io.gets
      qual     = @io.gets.chomp

      Seq.new(seq_name: seq_name, seq: seq, qual: qual)
    end

    class IO < Filesys
      def each
        while not @io.eof?
          yield @io.gets
        end
      end
    end
  end
end
