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
  # == Read tabular data from one or more files.
  #
  # Tabular input can be read with +read_table+ which will read in chosen rows
  # and chosen columns (separated by a given delimiter) from a table in ASCII
  # text format.
  #
  # If no +keys+ option is given and there is a comment line beginning with #
  # the fields here will be used as keys. Subsequence lines beginning with #
  # will be ignored.
  #
  # If a comment line is present beginning with a # the options +select+ and
  # +reject+ can be used to chose what columns to read.
  #
  # == Usage
  #    read_table(input: <glob>[, first: <uint>|last: <uint>][, select: <list>
  #               |, reject: <list>[, keys: <list>][, skip: <uint>
  #               [, delimiter: <string>]]])
  #
  # === Options
  # * input <glob>       - Input file or file glob expression.
  # * first <uint>       - Only read in the _first_ number of entries.
  # * last <uint>        - Only read in the _last_ number of entries.
  # * select <list>      - List of column indexes or header keys to read.
  # * reject <list>      - List of column indexes or header keys to skip.
  # * keys <list>        - List of key identifiers to use for each column.
  # * skip <uint>        - Number of initial lines to skip (default=0).
  # * delimiter <string> - Delimter to use for separating columsn
  #                        (default="\s+").
  #
  # == Examples
  #
  # To read all entries from a file:
  #
  #    read_table(input: "test.tab")
  #
  # To read all entries from a gzipped file:
  #
  #    read_table(input: "test.tab.gz")
  #
  # To read in only 10 records from a file:
  #
  #    read_table(input: "test.tab", first: 10)
  #
  # To read in the last 10 records from a file:
  #
  #    read_table(input: "test.tab", last: 10)
  #
  # To read all entries from multiple files:
  #
  #    read_table(input: "test1.tab,test2.tab")
  #
  # To read entries from multiple files using a glob expression:
  #
  #    read_table(input: "*.tab")
  #
  # Consider the following table from the file from the file test.tab:
  #
  #    #Organism   Sequence    Count
  #    Human      ATACGTCAG   23524
  #    Dog        AGCATGAC    2442
  #    Mouse      GACTG       234
  #    Cat        AAATGCA     2342
  #
  # Reading the entire table will result in 4 records, one for each row,
  # where the keys Organism, Sequence and Count are taken from the comment
  # line prefixe with #:
  #
  #    BP.new.read_tab(input: "test.tab").dump.run
  #
  #    {:Organism=>"Human", :Sequence=>"ATACGTCAG", :Count=>23524}
  #    {:Organism=>"Dog", :Sequence=>"AGCATGAC", :Count=>2442}
  #    {:Organism=>"Mouse", :Sequence=>"GACTG", :Count=>234}
  #    {:Organism=>"Cat", :Sequence=>"AAATGCA", :Count=>2342}
  #
  # However, if the first line is skipped using the +skip+ option the keys
  # will default to V0, V1, V2 ... Vn:
  #
  #    BP.new.read_table(input: "test.tab", skip: 1).dump.run
  #
  #    {:V0=>"Human", :V1=>"ATACGTCAG", :V2=>23524}
  #    {:V0=>"Dog", :V1=>"AGCATGAC", :V2=>2442}
  #    {:V0=>"Mouse", :V1=>"GACTG", :V2=>234}
  #    {:V0=>"Cat", :V1=>"AAATGCA", :V2=>2342}
  #
  # To explicitly name the columns (or the keys) use the +keys+ option:
  #
  #    BP.new.
  #    read_table(input: "test.tab", skip: 1, keys: [:ORGANISM, :SEQ, :COUNT]).
  #    dump.
  #    run
  #
  #    {:ORGANISM=>"Human", :SEQ=>"ATACGTCAG", :COUNT=>23524}
  #    {:ORGANISM=>"Dog", :SEQ=>"AGCATGAC", :COUNT=>2442}
  #    {:ORGANISM=>"Mouse", :SEQ=>"GACTG", :COUNT=>234}
  #    {:ORGANISM=>"Cat", :SEQ=>"AAATGCA", :COUNT=>2342}
  #
  # It is possible to select a subset of columns to read by using the
  # +select+ option which takes a comma separated list of columns numbers
  # (first column is designated 0) or header keys as (requires header)
  # argument. So to read in only the sequence and the count so that the
  # count comes before the sequence do:
  #
  #    BP.new.read_table(input: "test.tab", skip: 1, select: [2, 1]).dump.run
  #
  #    {:V0=>23524, :V1=>"ATACGTCAG"}
  #    {:V0=>2442, :V1=>"AGCATGAC"}
  #    {:V0=>234, :V1=>"GACTG"}
  #    {:V0=>2342, :V1=>"AAATGCA"}
  #
  # Alternatively, if a header line was present in the file:
  #
  #     #Organism  Sequence   Count
  #
  # Then the header keys can be used:
  #
  #    BP.new.
  #    read_table(input: "test.tab", skip: 1, select: [:Count, :Sequence]).
  #    dump.
  #    run
  #
  #    {:Count=>23524, :Sequence=>"ATACGTCAG"}
  #    {:Count=>2442, :Sequence=>"AGCATGAC"}
  #    {:Count=>234, :Sequence=>"GACTG"}
  #    {:Count=>2342, :Sequence=>"AAATGCA"}
  #
  # Likewise, it is possible to reject specified columns from being read
  # using the +reject+ option:
  #
  #    BP.new.read_table(input: "test.tab", skip: 1, reject: [2, 1]).dump.run
  #
  #    {:V0=>"Human"}
  #    {:V0=>"Dog"}
  #    {:V0=>"Mouse"}
  #    {:V0=>"Cat"}
  #
  # And again, the header keys can be used if a header is present:
  #
  #    BP.new.
  #    read_table(input: "test.tab", skip: 1, reject: [:Count, :Sequence]).
  #    dump.
  #    run
  #
  #    {:Organism=>"Human"}
  #    {:Organism=>"Dog"}
  #    {:Organism=>"Mouse"}
  #    {:Organism=>"Cat"}
  #
  # rubocop: disable ClassLength
  class ReadTable
    require 'biopieces/helpers/options_helper'
    require 'biopieces/helpers/status_helper'

    include OptionsHelper
    include StatusHelper

    STATS = %i(records_in records_out)

    # Constructor for ReadTable.
    #
    # @param options [Hash] Options hash.
    # @option options [String]  :input
    # @option options [Integer] :first
    # @option options [Integer] :last
    # @option options [Array]   :keys
    # @option options [Integer] :skip
    # @option options [String]  :delimiter
    # @option options [Boolean] :select
    # @option options [Boolean] :reject
    #
    # @return [ReadTable] Class instance.
    def initialize(options)
      @options = options
      @keys    = options[:keys] ? options[:keys].map(&:to_sym) : nil
      @skip    = options[:skip] || 0
      @buffer  = []

      check_options
      status_init(STATS)
    end

    # Return command lambda for ReadTable
    #
    # @return [Proc] Command lambda.
    def lmb
      lambda do |input, output, status|
        process_input(input, output)

        case
        when @options[:first] then read_first(output)
        when @options[:last]  then read_last(output)
        else read_all(output)
        end

        status_assign(status, STATS)
      end
    end

    private

    # Check options.
    def check_options
      options_allowed(@options, :input, :first, :last, :keys, :skip, :delimiter,
                      :select, :reject)
      options_required(@options, :input)
      options_files_exist(@options, :input)
      options_unique(@options, :first, :last)
      options_unique(@options, :select, :reject)
      options_list_unique(@options, :keys, :select, :reject)
      options_assert(@options, ':first >= 0')
      options_assert(@options, ':last >= 0')
      options_assert(@options, ':skip >= 0')
    end

    # Return a hash with options for CVS#each_hash.
    #
    # @return [Hash] Read table options.
    def read_options
      {delimiter: @options[:delimiter],
       select:    @options[:select],
       reject:    @options[:reject]}
    end

    # Read :first entries from input files and emit to output stream.
    #
    # @param output [Enumerator::Yeilder] Output stream.
    def read_first(output)
      options_glob(@options[:input]).each do |file|
        BioPieces::CSV.open(file) do |ios|
          ios.skip(@skip)

          ios.each_hash(read_options) do |record|
            output << record
            @records_out += 1
            return if @records_out >= @options[:first]
          end
        end
      end
    end

    # Read :last entries from input files and emit to output stream.
    #
    # @param output [Enumerator::Yeilder] Output stream.
    def read_last(output)
      options_glob(@options[:input]).each do |file|
        BioPieces::CSV.open(file) do |ios|
          ios.skip(@skip)

          ios.each_hash(read_options) do |record|
            @buffer << record
            @buffer.shift if @buffer.size > @options[:last]
          end
        end
      end

      output_buffer(output)
    end

    # Read all entries from input files and emit to output stream.
    #
    # @param output [Enumerator::Yeilder] Output stream.
    def read_all(output)
      options_glob(@options[:input]).each do |file|
        BioPieces::CSV.open(file) do |ios|
          ios.skip(@skip)

          ios.each_hash(read_options) do |record|
            replace_keys(record) if @keys
            output << record
            @records_out += 1
          end
        end
      end
    end

    # Replace the keys of a given record.
    #
    # @param record [Hash] BioPieces record.
    def replace_keys(record)
      record.first(@keys.size).each_with_index do |(k, v), i|
        record[@keys[i]] = v
        record.delete k
      end
    end

    # Output all record in the buffer to the output stream.
    #
    # @param output [Enumerator::Yielder] Output stream.
    def output_buffer(output)
      @buffer.each do |record|
        output << record
        @records_out += 1
      end
    end

    # Emit all records from the input stream to the output stream.
    #
    # @param input [Enumerator] Input stream.
    # @param output [Enumerator::Yielder] Output stream.
    def process_input(input, output)
      return unless output
      input.each do |record|
        output << record
        @records_in  += 1
        @records_out += 1
      end
    end
  end
end
