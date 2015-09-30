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
  # Error class for all exceptions to do with FASTA.
  class FastaError < StandardError; end

  class Fasta
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

    def self.read(*args)
      entries = []

      Fasta.open(*args) do |ios|
        ios.each do |entry|
          entries << entry
        end
      end

      entries
    end

    attr_accessor :seq_name, :seq

    def initialize(io)
      @io        = io
      @seq_name  = nil
      @seq       = ""
      @got_first = nil
      @got_last  = nil
    end

    def each
      while entry = next_entry
        yield entry
      end
    end

    def puts(*args)
      @io.puts(*args)
    end

    # Method to get the next FASTA entry form an ios and return this
    # as a Seq object. If no entry is found or eof then nil is returned.
    def next_entry
      @io.each do |line|
        line.chomp!

        next if line.empty?

        if line[0] == '>'
          if not @got_first and not @seq.empty?
            raise FastaError, "Bad FASTA format -> content before Fasta header: #{@seq}" unless @seq.empty?
          end

          @got_first = true

          if @seq_name
            entry     = Seq.new(seq_name: @seq_name, seq: @seq)
            @seq_name = line[1 .. -1]
            @seq      = ""

            raise FastaError, "Bad FASTA format -> truncated Fasta header: no content after '>'" if @seq_name.empty?

            return entry
          else
            @seq_name = line[1 .. -1]

            raise FastaError, "Bad FASTA format -> truncated Fasta header: no content after '>'" if @seq_name.empty?
          end
        else
          @seq << line
        end
      end

      if @seq_name
        @got_last = true
        entry     = Seq.new(seq_name: @seq_name, seq: @seq)
        @seq_name = nil
        return entry
      end

      if not @got_last and not @seq.empty?
        raise FastaError, "Bad FASTA format -> content witout Fasta header: #{@seq}"
      end

      nil
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
