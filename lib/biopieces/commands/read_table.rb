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
# This software is part of the Biopieces framework (www.biopieces.org).          #
#                                                                                #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

module BioPieces
  module Commands
    # == Read tabular data from one or more files.
    #
    # Tabular input can be read with +read_table+ which will read in chosen rows
    # and chosen columns (separated by a given delimiter) from a table in ASCII text
    # format.
    #
    # If no +keys+ option is given and there is a comment line beginning with #
    # the fields here will be used as keys. Subsequence lines beginning with # 
    # will be ignored.
    #
    # If a comment line is present beginning with a # the options +select+ and
    # +reject+ can be used to chose what columns to read.
    #
    # == Usage
    #    read_table(input: <glob>[, first: <uint>|last: <uint>][, columns: <list>
    #               [, keys: <list>][, skip: <uint>[, delimiter: <string>
    #               [, select: <list> | reject: <list>]]]])
    #
    # === Options
    # * input <glob>       - Input file or file glob expression.
    # * first <uint>       - Only read in the _first_ number of entries.
    # * last <uint>        - Only read in the _last_ number of entries.
    # * columns <list>     - List of columns to read in that order.
    # * keys <list>        - List of key identifiers to use for each column.
    # * skip <uint>        - Number of initial lines to skip (default=0).
    # * delimiter <string> - Delimter to use for separating columsn (default="\s+").
    # * select <list>      - List of header keys to read in that order (requires header).
    # * reject <list>      - Read all header keys exect the rejected (requires header).
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
    #    BP.new.read_table(input: "test.tab", skip: 1, keys: [:ORGANISM, :SEQ, :COUNT]).dump.run
    #
    #    {:ORGANISM=>"Human", :SEQ=>"ATACGTCAG", :COUNT=>23524}
    #    {:ORGANISM=>"Dog", :SEQ=>"AGCATGAC", :COUNT=>2442}
    #    {:ORGANISM=>"Mouse", :SEQ=>"GACTG", :COUNT=>234}
    #    {:ORGANISM=>"Cat", :SEQ=>"AAATGCA", :COUNT=>2342}
    # 
    # It is possible to select a subset of columns to read by using the
    # +columns+ option which takes a comma separated list of columns numbers
    # (first column is designated 0) as argument. So to read in only the
    # sequence and the count so that the count comes before the sequence do:
    # 
    #    BP.new.read_table(input: "test.tab", skip: 1, columns: [2, 1]).dump.run
    #
    #    {:V0=>23524, :V1=>"ATACGTCAG"}
    #    {:V0=>2442, :V1=>"AGCATGAC"}
    #    {:V0=>234, :V1=>"GACTG"}
    #    {:V0=>2342, :V1=>"AAATGCA"}
    # 
    # It is also possible to rename the columns with the +keys+ option:
    # 
    #    BP.new.read_table(input: "test.tab", skip: 1, columns: [2, 1], keys: [:COUNT, :SEQ]).dump.run
    #
    #    {:COUNT=>23524, :SEQ=>"ATACGTCAG"}
    #    {:COUNT=>2442, :SEQ=>"AGCATGAC"}
    #    {:COUNT=>234, :SEQ=>"GACTG"}
    #    {:COUNT=>2342, :SEQ=>"AAATGCA"}
    def read_table(options = {})
      options_orig = options.dup
      options_load_rc(options, __method__)
      options_allowed(options, :input, :first, :last, :keys, :columns, :skip, :delimiter, :select, :reject)
      options_required(options, :input)
      options_glob(options, :input)
      options_files_exist(options, :input)
      options_unique(options, :first, :last)
      options_unique(options, :select, :reject)
      options_list_unique(options, :keys, :columns, :select, :reject)
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

          keys    = options[:keys].map { |key| key.to_sym } if options[:keys]
          count   = 0
          buffer  = []

          catch :break do
            options[:input].each do |file|
              BioPieces::CSV.open(file) do |ios|
                ios.skip(options[:skip])

                header = keys || ios.header(delimiter: options[:delimiter], columns: options[:columns]) 
                
                ios.each_hash(delimiter: options[:delimiter],
                              header:    header,
                              columns:   options[:columns],
                              select:    options[:select],
                              reject:    options[:reject]) do |record|
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

