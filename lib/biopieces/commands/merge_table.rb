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
  # == Merge records on a given key with tabular data from one or more files.
  #
  # +merge_table+ reads in one or more tabular files and merges any records in
  # the stream with identical values for a given key. The values for the given
  # key must be unique in the tabular files, but not necesarily in the stream.
  #
  # Consult *read_table* for details on how the tabular files are read.
  #
  # The stats for +merge_table+ includes the following values:
  #
  # *  rows_total     - total number of table rows.
  # *  rows_matched   - number of table rows with the given key.
  # *  rows_unmatched - number of table rows without the given key.
  # *  merged         - number of records that was merged.
  # *  non_merged     - number of records that was not merged.
  #
  # == Usage
  #    merge_table(<input: <glob>>, <key: <string>>[, columns: <list>
  #                [, keys: <list>[, skip: <uint>[, delimiter: <string>]]]])
  #
  # === Options
  # * input <glob>       - Input file or file glob expression.
  # * key <string>       - Key used to merge
  # * columns <list>     - List of columns to read in that order.
  # * keys <list>        - List of key identifiers to use for each column.
  # * skip <uint>        - Number of initial lines to skip (default=0).
  # * delimiter <string> - Delimter to use for separating columsn
  #                        (default="\s+").
  #
  # == Examples
  #
  # Consider the following two files:
  #
  # test1.tab:
  #     #ID ORGANISM
  #     1   parrot
  #     2   eel
  #     3   platypus
  #     4   beetle
  #
  # test2.tab:
  #
  #     #ID COUNT
  #     1   5423
  #     2   34
  #     3   2423
  #     4   234
  #
  # We can merge the data with +merge_table+ like this:
  #
  #    BP.new.
  #    read_table(input: "test1.tab").
  #    merge_table(input: "test2.tab", key: :ID).
  #    dump.
  #    run
  #
  #    {:ID=>1, :ORGANISM=>"parrot", :COUNT=>5423}
  #    {:ID=>2, :ORGANISM=>"eel", :COUNT=>34}
  #    {:ID=>3, :ORGANISM=>"platypus", :COUNT=>2423}
  #    {:ID=>4, :ORGANISM=>"beetle", :COUNT=>234}
  class MergeTable
    STATS = %i(records_in records_out rows_total rows_matched rows_unmatched
               merged non_merged)

    # Constructor for MergeTable.
    #
    # @param options [Hash]
    #   Options hash.
    #
    # @option options [String] :input
    #   Input glob expression.
    #
    # @option options [String, Symbol] :key
    #   Key used to merge.
    #
    # @option options [Array] :keys
    #   List of key identifiers to use for each column.
    #
    # @option options [Array] :columns
    #   List of columns to read in that order.
    #
    # @option options [Integer] :skip
    #   Number of initial lines to skip.
    #
    # @option options [String] :delimiter
    #   Delimter to use for separating columns.
    #
    # @return [MergeTable] Class instance.
    def initialize(options)
      @options = options

      check_options
      defaults

      @table   = {}
      @key     = @options[:key].to_sym
      @keys    = options[:keys] ? @options[:keys].map(&:to_sym) : nil

      status_init(STATS)
    end

    # Return command lambda for merge_table.
    #
    # @return [Proc] Command lambda.
    def lmb
      lambda do |input, output, status|
        parse_input_tables

        input.each do |record|
          @status[:records_in] += 1

          if record[@key] && @table[record[@key]]
            @merged += 1
            record = record.merge(@table[record[@key]])
          else
            @non_merged += 1
          end

          output << record
          @status[:records_out] += 1
        end

        @rows_total = @rows_matched + @rows_unmatched
      end
    end

    private

    # Check options.
    def check_options
      options_allowed(@options, :input, :key, :keys, :columns, :skip,
                      :delimiter)
      options_required(@options, :input, :key)
      options_files_exist(@options, :input)
      options_list_unique(@options, :keys, :columns)
      options_assert(@options, ':skip >= 0')
    end

    # Set default options.
    def defaults
      @options[:skip] ||= 0
    end

    # Parse input table files and add each row to a table hash.
    def parse_input_tables
      options_glob(@options[:input]).each do |file|
        BioPieces::CSV.open(file) do |ios|
          ios.skip(@options[:skip])

          ios.each_hash(delimiter: @options[:delimiter],
                        select: @options[:columns]) do |record|
            trim_record(record) if @keys

            add_row(record)
          end
        end
      end
    end

    # Trim given record removing unwanted key/values.
    #
    # @param record [Hash] BioPieces record.
    def trim_record(record)
      record.first(@keys.size).each_with_index do |(k, v), i|
        record.delete(k)
        record[@keys[i]] = v
      end
    end

    # Add a given record to the table hash.
    #
    # @param record [Hash] BioPieces record.
    #
    # @raise [RuntimeError] if duplicate values are found.
    def add_row(record)
      if record[@key]
        check_duplicate(record)

        @rows_matched += 1

        @table[record[@key]] = record
      else
        @rows_unmatched += 1
      end
    end

    # Check if a given record is already added to the table and raise if so.
    #
    # @param record [Hash] BioPieces record.
    #
    # @raise [RuntimeError] if duplicate values are found.
    def check_duplicate(record)
      return unless @table[record[@key]]
      fail "Duplicate values found for key: #{@key} value: #{record[@key]}"
    end
  end
end
