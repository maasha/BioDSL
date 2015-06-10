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
# USA.                                                                         #
#                                                                              #
# http://www.gnu.org/copyleft/gpl.html                                         #
#                                                                              #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #
#                                                                              #
# This software is part of the Biopieces framework (www.biopieces.org).        #
#                                                                              #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

module BioPieces
  # == Read FASTA entries from one or more files.
  #
  # +read_fasta+ read in sequence entries from FASTA files. Each sequence
  # entry consists of a sequence name prefixed by a '>' followed by the sequence
  # name on a line of its own, followed by one or my lines of sequence until the
  # next entry or the end of the file. The resulting Biopiece record consists of
  # the following record type:
  #
  #     {:SEQ_NAME=>"test",
  #      :SEQ=>"AGCATCGACTAGCAGCATTT",
  #      :SEQ_LEN=>20}
  #
  # Input files may be compressed with gzip og bzip2.
  #
  # For more about the FASTA format:
  #
  # http://en.wikipedia.org/wiki/Fasta_format
  #
  # == Usage
  #    read_fasta(input: <glob>[, first: <uint>|last: <uint>])
  #
  # === Options
  # * input <glob> - Input file or file glob expression.
  # * first <uint> - Only read in the _first_ number of entries.
  # * last <uint>  - Only read in the _last_ number of entries.
  #
  # == Examples
  #
  # To read all FASTA entries from a file:
  #
  #    read_fasta(input: "test.fna")
  #
  # To read all FASTA entries from a gzipped file:
  #
  #    read_fasta(input: "test.fna.gz")
  #
  # To read in only 10 records from a FASTA file:
  #
  #    read_fasta(input: "test.fna", first: 10)
  #
  # To read in the last 10 records from a FASTA file:
  #
  #    read_fasta(input: "test.fna", last: 10)
  #
  # To read all FASTA entries from multiple files:
  #
  #    read_fasta(input: "test1.fna,test2.fna")
  #
  # To read FASTA entries from multiple files using a glob expression:
  #
  #    read_fasta(input: "*.fna")
  class ReadFasta
    require 'biopieces/helpers/options_helper'
    require 'biopieces/helpers/status_helper'

    extend OptionsHelper
    include OptionsHelper
    include StatusHelper

    STATS = %i(records_in records_out sequences_in sequences_out residues_in
               residues_out)

    # Check the options and return a lambda for the command.
    #
    # @param [Hash] options Options hash.
    # @option options [String, Array] :input String or Array with glob
    #   expressions.
    # @option options [Integer] :first Dump first number of records.
    # @option options [Integer] :last  Dump last number of records.
    #
    # @return [Proc] Returns the command lambda.
    def self.lmb(options)
      options_allowed(options, :input, :first, :last)
      options_required(options, :input)
      options_files_exist(options, :input)
      options_unique(options, :first, :last)
      options_assert(options, ':first >= 0')
      options_assert(options, ':last >= 0')

      new(options).lmb
    end

    # Constructor for the ReadFasta class.
    #
    # @param [Hash] options Options hash.
    # @option options [String, Array] :input String or Array with glob
    #   expressions.
    # @option options [Integer] :first Dump first number of records.
    # @option options [Integer] :last  Dump last number of records.
    #
    # @return [ReadFasta] Returns an instance of the class.
    def initialize(options)
      @options = options
      @count   = 0
      @buffer  = []

      status_init(STATS)
    end

    # Return a lambda for the read_fasta command.
    #
    # @return [Proc] Returns the read_fasta command lambda.
    def lmb
      lambda do |input, output, status|
        read_input(input, output)

        options_glob(@options[:input]).each do |file|
          BioPieces::Fasta.open(file) do |ios|
            if @options[:first] && read_first(ios, output)
            elsif @options[:last] && read_last(ios)
            else
              read_all(ios, output)
            end
          end
        end

        write_buffer(output) if @options[:last]

        status_assign(status, STATS)
      end
    end

    private

    # Read and emit records from the input to the output stream.
    #
    # @param input  [Enumerable::Yielder] Input stream.
    # @param output [Enumerable::Yielder] Output stream.
    def read_input(input, output)
      return unless input

      input.each do |record|
        output << record
        @records_in  += 1
        @records_out += 1
      end
    end

    # Read in a specified number of entries from the input and emit to the
    # output.
    #
    # @param input [BioPieces::Fasta] FASTA file input stream.
    # @param output [Enumerable::Yielder] Output stream.
    def read_first(input, output)
      first = @options[:first]

      input.each do |entry|
        break if @count == first
        output << entry.to_bp

        @records_out  += 1
        @sequences_in += 1
        @residues_in  += entry.length

        @count += 1
      end
    end

    # Read in entries from input and cache the specified last number in a
    # buffer.
    #
    # @param input [BioPieces::Fasta] FASTA file input stream.
    def read_last(input)
      last = @options[:last]

      input.each do |entry|
        @buffer << entry
        @buffer.shift if @buffer.size > last
      end
    end

    # Read in all entries from input and emit to output.
    #
    # @param input [BioPieces::Fasta] FASTA file input stream.
    # @param output [Enumerable::Yielder] Output stream.
    def read_all(input, output)
      input.each do |entry|
        output << entry.to_bp

        @records_out  += 1
        @sequences_in += 1
        @residues_in  += entry.length
      end
    end

    # Emit all entries in buffer to output.
    #
    # @param output [Enumerable::Yielder] Output stream.
    def write_buffer(output)
      @buffer.each do |entry|
        output << entry.to_bp

        @records_out  += 1
        @sequences_in += 1
        @residues_in  += entry.length
      end
    end
  end
end
