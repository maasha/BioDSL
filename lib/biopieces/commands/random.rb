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
  # == Pick number of random records from the stream.
  #
  # +random+ can be used to pick a random number of records from the stream.
  # Note that the order of records is preserved.
  #
  # Using the `pair: true` option allows random picking of interleaved
  # paired-end sequence records.
  #
  # == Usage
  #
  #    random(<number: <uint>[, pairs: <bool>])
  #
  # === Options
  #
  # * number: <uint>  - Number of records to pick.
  # * pairs: <bool>   - Preserve interleaved pair order.
  #
  # == Examples
  #
  # To pick some random records from the stream do:
  #
  #    BP.new.
  #    read_fasta(input: "in.fna").
  #    random(number: 10_000).
  #    write_fasta(output: "out.fna").
  #    run
  class Random
    require 'biopieces/helpers/options_helper'

    extend OptionsHelper
    include OptionsHelper

    def self.lmb(options)
      options_load_rc(options, __method__)
      options_allowed(options, :number, :pairs)
      options_required(options, :number)
      options_allowed_values(options, pairs: [nil, true, false])
      options_assert(options, ':number > 0')

      new(options).lmb
    end

    def initialize(options)
      @options     = options
      @records_in  = 0
      @records_out = 0
      @wanted      = nil
    end

    def lmb
      lambda do |input, output, status|
        TmpDir.create('random') do |file, _|
          process_input(input, file)
          decide_wanted
          process_output(output, file)
        end

        assign_status(status)
      end
    end

    private

    # Serialize records from input
    #
    # @param input [Enumerator] Input stream.
    # @param file [String] Path to temporary file.
    def process_input(input, file)
      File.open(file, 'wb') do |ios|
        BioPieces::Serializer.new(ios) do |s|
          input.each do |record|
            @records_in += 1

            s << record
          end
        end
      end
    end

    # Compile a random set of numbers.
    def decide_wanted
      if @options[:pairs]
        decide_wanted_pairs
      else
        @wanted = (0...@records_in).to_a.shuffle[0...@options[:number]].to_set
      end
    end

    # Compile a random set of number pairs.
    def decide_wanted_pairs
      @wanted = Set.new
      num     = @options[:number] / 2

      (0...@records_in).to_a.shuffle.select(&:even?)[0...num].each do |i|
        @wanted.merge([i, i + 1])
      end
    end

    # Read records from temporary file and emit wanted records to the output
    # stream.
    #
    # @param output [Enumerator::Yielder] Output stream.
    # @param file [String] Path to termorary file with records.
    def process_output(output, file)
      File.open(file, 'rb') do |ios|
        BioPieces::Serializer.new(ios) do |s|
          s.each_with_index do |record, i|
            if @wanted.include? i
              output << record
              @records_out += 1
            end
          end
        end
      end
    end

    # Assign values to status hash.
    #
    # @param status [Hash] Status hash.
    def assign_status(status)
      status[:records_in]  = @records_in
      status[:records_out] = @records_out
    end
  end
end
