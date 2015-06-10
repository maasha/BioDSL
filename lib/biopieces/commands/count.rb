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

# Namespace for BioPieces.
module BioPieces
  # == Count the number of records in the stream.
  #
  # +count+ counts the number of records in the stream and outputs the
  # count as a record who's count is _not_ included. Using the +output+
  # option will output the count in a file as a table with header.
  #
  # == Usage
  #
  #    count([output: <file>[, force: <bool]])
  #
  # === Options
  #
  # * output: <file> - Output file.
  # * force: <bool>  - Force overwrite existing output file.
  #
  # == Examples
  #
  # To count the number of records in the file `test.fq`:
  #
  #    BP.new.read_fastq(input: "test.fq").count(output: "count.txt").dump.run
  #
  #    {:SEQ_NAME=>"ILLUMINA-52179E_0004:2:1:1040:5263#TTAGGC/1",
  #     :SEQ=>"TTCGGCATCGGCGGCGACGTTGGCGGCGGGGCCGGGCGGGTCGANNNCAT",
  #     :SEQ_LEN=>50,
  #     :SCORES=>"GGFBGGEADFAFFDDD,-5AC5?>C:)7?#####################"}
  #    {:SEQ_NAME=>"ILLUMINA-52179E_0004:2:1:1041:14486#TTAGGC/1",
  #     :SEQ=>"CATGGCGTATGCCAGACGGCCAGAACGATGGCCGCCGGGCTTCANNNAAG",
  #     :SEQ_LEN=>50,
  #     :SCORES=>"FFFFDBD?EEEEEEEFGGFAGAGEFDF=BFGFFGGDDDD=ABAA######"}
  #    {:SEQ_NAME=>"ILLUMINA-52179E_0004:2:1:1043:19446#TTAGGC/1",
  #     :SEQ=>"CGGTACTGATCGAGTGTCAGGCTGTTGATCGCCGCGGGCGGGGGTNNGAC",
  #     :SEQ_LEN=>50,
  #     :SCORES=>"ECAEBEEEEEFFFFFEFFFFDDEEEGGGGGDEBEECBDAE@#########"}
  #    {:RECORD_TYPE=>"count", :COUNT=>3}
  #
  # And the count is also saved in the file `count.txt`:
  #    #RECORD_TYPE COUNT
  #    count  3
  class Count
    require 'biopieces/helpers/options_helper'
    require 'biopieces/helpers/status_helper'

    extend OptionsHelper
    include OptionsHelper
    include StatusHelper

    STATS = %i(records_in records_out)

    # Check options and return command lambda for count.
    #
    # @param options [Hash] Options hash.
    # @option options [String] :output Path to output file.
    # @option options [Boolean] :force Force overwrite of output file.
    #
    # @return [Proc] Command lambda.
    def self.lmb(options)
      options_allowed(options, :output, :force)
      options_allowed_values(options, force: [true, false, nil])
      options_files_exist_force(options, :output)

      new(options).lmb
    end

    # Constructor for the count command.
    #
    # @param options [Hash] Options hash.
    # @option options [String] :output Path to output file.
    # @option options [Boolean] :force Force overwrite of output file.
    #
    # @return [Count] Instance of class Count.
    def initialize(options)
      @options     = options

      status_init(STATS)
    end

    # Return the command lambda for count.
    #
    # @return [Proc] Command lambda.
    def lmb
      lambda do |input, output, status|
        process_input(input, output)

        new_record = {
          RECORD_TYPE: 'count',
          COUNT: @records_in
        }

        output << new_record
        @records_out += 1

        write_output if @options[:output]

        status_assign(status, STATS)
      end
    end

    private

    # Process the input stream and emit all recors to the output stream.
    #
    # @param input [Enumerator] Input stream
    # @param output [Enumerator::Yielder] Output stream
    def process_input(input, output)
      input.each do |record|
        @records_in += 1

        output << record
        @records_out += 1
      end
    end

    # Write output table to file.
    def write_output
      Filesys.open(@options[:output], 'w') do |ios|
        ios.puts "#RECORD_TYPE\tCOUNT"
        ios.puts "count\t#{@records_in}"
      end
    end
  end
end
