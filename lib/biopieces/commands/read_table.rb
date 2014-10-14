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
    # == Read tabular data from one or more files.
    #
    # Tabular input can be read with read_tab which will read in chosen rows
    # and chosen columns (separated by a given delimiter) from a table in ASCII text
    # format.
    #
    # If no +keys+ option is given and there is a comment line beginning with #
    # the fields here will be used as keys.
    #
    # == Usage
    #    read_table(input: <glob>[, first: <uint>|last: <uint>][, columns: <list>
    #               [, keys: <list>][, skip: <uint>[, delimiter: <string>]]])
    #
    # === Options
    # * input <glob>       - Input file or file glob expression.
    # * first <uint>       - Only read in the _first_ number of entries.
    # * last <uint>        - Only read in the _last_ number of entries.
    # * columns <list>     - List of columns to read in that order.
    # * keys <list>        - List of key identifiers to use for each column.
    # * skip <uint>        - Number of initial lines to skip (default=0).
    # * delimiter <string> - Delimter to use for separating columsn (default="\s+").
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
    def read_table(options = {})
      options_orig = options.dup
      options_allowed(options, :input, :first, :last, :keys, :columns, :skip, :delimiter)
      options_required(options, :input)
      options_glob(options, :input)
      options_files_exist(options, :input)
      options_unique(options, :first, :last)
      options_list_unique(options, :keys, :columns)
      options_assert(options, ":first >= 0")
      options_assert(options, ":last >= 0")
      options_assert(options, ":skip >= 0")

      options[:skip] ||= 0

      lmb = lambda do |input, output, status|
        status_track(status) do
          if input
            input.each do |record|
              output << record
              status[:records_in]  += 1
              status[:records_out] += 1
            end
          end

          keys   = options[:keys].map { |key| key.to_sym } if options[:keys]
          count  = 0
          buffer = []

          catch :break do
            options[:input].each do |file|
              BioPieces::Filesys.open(file) do |ios|
                options[:skip].times { ios.get_entry }
                
                ios.each do |line|
                  line.chomp!
                  next if line.empty?

                  if line[0] == '#' 
                    unless keys
                      fields = line[1 .. -1].split(options[:delimiter])
                      raise "Duplicate headers found" if fields.uniq.size != fields.size
                      keys = fields.map { |key| key.to_sym }
                      keys = keys.values_at(*options[:columns]) if options[:columns]
                    end

                    next
                  end

                  fields = line.split(options[:delimiter])
                  fields = fields.values_at(*options[:columns]) if options[:columns]

                  raise ArgumentError, "Number of columns and keys don't match: #{fields.size} != #{keys.size}" if keys and fields.size != keys.size

                  record = {}

                  if keys
                    fields.each_with_index { |field, i| record[keys[i]] = field }
                  else
                    fields.each_with_index { |field, i| record["V#{i}".to_sym] = field }
                  end

                  if options[:last]
                    buffer << record
                    buffer.shift if buffer.size > options[:last]
                  else
                    output << record
                    status[:records_out] += 1

                    count += 1

                    throw :break if options[:first] and count == options[:first]
                  end
                end
              end
            end

            if options[:last]
              buffer.each do |record|
                output << record
                status[:records_out]  += 1
              end
            end
          end
        end
      end

      @commands << BioPieces::Pipeline::Command.new(__method__, options, options_orig, lmb)

      self
    end
  end
end

