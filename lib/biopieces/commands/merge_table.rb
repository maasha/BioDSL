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
# This software is part of the Biopieces framework (www.biopieces.org).          #
#                                                                                #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

module BioPieces
  module Commands
    # == Merge records on a given key with tabular data from one or more files.
    #
    # +merge_table+ reads in one or more tabular files and merges any records
    # in the stream with identical values for a given key. The values for the
    # given key must be unique in the tabular files, but not necesarily in the
    # stream.
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
    # * delimiter <string> - Delimter to use for separating columsn (default="\s+").
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
    #    BP.new.read_table(input: "test1.tab").merge_table(input: "test2.tab", key: :ID).dump.run
    #
    #    {:ID=>1, :ORGANISM=>"parrot", :COUNT=>5423}
    #    {:ID=>2, :ORGANISM=>"eel", :COUNT=>34}
    #    {:ID=>3, :ORGANISM=>"platypus", :COUNT=>2423}
    #    {:ID=>4, :ORGANISM=>"beetle", :COUNT=>234}
    def merge_table(options = {})
      options_orig = options.dup
      options_load_rc(options, __method__)
      options_allowed(options, :input, :key, :keys, :columns, :skip, :delimiter)
      options_required(options, :input, :key)
      options_glob(options, :input)
      options_files_exist(options, :input)
      options_list_unique(options, :keys, :columns)
      options_assert(options, ":skip >= 0")

      options[:skip] ||= 0

      lmb = lambda do |input, output, status|
        status_track(status) do
          status[:rows_total]     = 0
          status[:rows_matched]   = 0
          status[:rows_unmatched] = 0
          status[:merged]         = 0
          status[:non_merged]     = 0

          table = {}
          key   = options[:key].to_sym
          keys  = options[:keys].map { |key| key.to_sym } if options[:keys]

          options[:input].each do |file|
            BioPieces::CSV.open(file) do |ios|
              ios.skip(options[:skip])

              header = keys || ios.header(delimiter: options[:delimiter], columns: options[:columns]) 
              
              ios.each_hash(delimiter: options[:delimiter], header: header, columns: options[:columns]) do |record|
                status[:rows_total] += 1

                if record[key]
                  status[:rows_matched] += 1
                  if table[record[key]]
                    raise "Duplicate values fund for key: #{key} value: #{record[key]}"
                  else
                    table[record[key]] = record
                  end
                else
                  status[:rows_unmatched] += 1
                end
              end
            end
          end

          input.each do |record|
            status[:records_in]  += 1

            if record[key] and table[record[key]]
              status[:merged] += 1
              record = record.merge(table[record[key]])
            else
              status[:non_merged] += 1
            end

            output << record
            status[:records_out] += 1
          end
        end
      end

      @commands << BioPieces::Pipeline::Command.new(__method__, options, options_orig, lmb)

      self
    end
  end
end

