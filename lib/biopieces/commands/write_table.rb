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
    # == Write tabular output from the stream.
    # 
    # Description
    # 
    # +write_table+ writes tabular output from the stream.
    # 
    # == Usage
    #    write_table([keys: <string> | skip: <string>][, output: <file>[, force:
    #                <bool>[, header: <bool>[, pretty: <bool>[, commify: <bool>
    #                [, delimiter: <string>[, first: <uint> | last: <uint>
    #                [, gzip: <bool>, [bzip2: <bool>]]]]]]]]]
    #
    # === Options
    # * keys <string>      - Comma separated list of keys to print in that order.
    # * skip <string>      - Comma separated list of keys to skip printing.
    # * output <file>      - Output file.
    # * force <bool>       - Force overwrite existing output file.
    # * header <bool>      - Output header.
    # * pretty <bool>      - Pretty print table.
    # * commify <bool>     - Commify numbers when pretty printing.
    # * delimiter <string> - Specify delimiter (default="\t").
    # * first <uint>       - Only output +first+ number of rows.
    # * last <uint>        - Only output +last+ number of rows.
    # * gzip <bool>        - Write gzipped output file.
    # * bzip2 <bool>       - Write bzipped output file.
    # 
    # == Examples
    # 
    # Consider the following records in the stream:
    # 
    #    {ORGANISM: Human
    #     COUNT: 23524
    #     SEQ: ATACGTCAG},
    #    {ORGANISM: Dog
    #     COUNT: 2442
    #     SEQ: AGCATGAC},
    #    {ORGANISM: Mouse
    #     COUNT: 234
    #     SEQ: GACTG},
    #    {ORGANISM: Cat
    #     COUNT: 2342
    #     SEQ: AAATGCA}
    # 
    # To write all records from the stream as a table, do:
    # 
    #    write_table()
    # 
    #    Human  23524 ATACGTCAG
    #    Dog  2442  AGCATGAC
    #    Mouse  234 GACTG
    #    Cat  2342  AAATGCA
    # 
    # If you supply the +header+ option, then the first row in the table will be a
    # 'header' line prefixed with a '#':
    # 
    #    write_table(header: true)
    # 
    #    #ORGANISM  COUNT SEQ
    #    Human  23524 ATACGTCAG
    #    Dog  2442  AGCATGAC
    #    Mouse  234 GACTG
    #    Cat  2342  AAATGCA
    # 
    # You can also change the delimiter from the default (tab) to e.g. ',':
    # 
    #    write_table(delimiter: ',')
    # 
    #    Human,23524,ATACGTCAG
    #    Dog,2442,AGCATGAC
    #    Mouse,234,GACTG
    #    Cat,2342,AAATGCA
    # 
    # If you want the values output in a specific order you have to supply a comma
    # separated list using the +keys+ option that will print only those keys in that
    # order:
    # 
    #    write_table(keys: [:SEQ, :COUNT])
    # 
    #    ATACGTCAG  23524
    #    AGCATGAC 2442
    #    GACTG  234
    #    AAATGCA  2342
    # 
    # Keys in the format V0, V1, V2 ... Vn, is automagically sorted numerically.
    # 
    # Alternatively, if you have some keys that you don't want in the tabular output,
    # use the +skip+ option. So to print all keys except SEQ and SEQ_TYPE do:
    # 
    #    write_table(skip: [:SEQ])
    # 
    #    Human  23524
    #    Dog  2442
    #    Mouse  234
    #    Cat  2342
    # 
    # And if you want a pretty printed table use the +pretty+ option and throw
    # in the +commify+ option if you want commified numbers:
    # 
    #    write_tab(pretty: true, header: true, commify: true)
    # 
    #    +----------+--------+-----------+
    #    | ORGANISM | COUNT  | SEQ       |
    #    +----------+--------+-----------+
    #    | Human    | 23,524 | ATACGTCAG |
    #    | Dog      |  2,442 | AGCATGAC  |
    #    | Mouse    |    234 | GACTG     |
    #    | Cat      |  2,342 | AAATGCA   |
    #    +----------+--------+-----------+
    #
    # To write a table to a file 'test.tab':
    # 
    #    write_table(output: "test.tab")
    #
    # To write a table to a file 'test.tab' with only the first 3 rows:
    # 
    #    write_table(output: "test.tab", first: 3)
    #
    # To write a table to a file 'test.tab' with only the last 3 rows:
    # 
    #    write_table(output: "test.tab", last: 3)
    # 
    # To overwrite output file if this exists use the +force+ option:
    #
    #    write_table(output: "test.tab", force: true)
    #
    # To write gzipped output to a file 'test.tab.gz'.
    # 
    #    write_table(output: "test.tab.gz", gzip: true)
    #
    # To write bzipped output to a file 'test.tab.bz2'.
    # 
    #    write_table(output: "test.tab.bz2", bzip2: true)
    def write_table(options = {})
      require 'terminal-table'

      options_orig = options.dup
      options_load_rc(options, __method__)
      options_allowed(options, :keys, :skip, :output, :force, :header, :pretty,
                               :commify, :delimiter, :first, :last, :gzip, :bzip2)
      options_unique(options, :keys, :skip)
      options_unique(options, :first, :last)
      options_unique(options, :gzip, :bzip2)
      options_allowed_values(options, force: [nil, true, false])
      options_allowed_values(options, header: [nil, true, false])
      options_tie(options, commify: :pretty)
      options_conflict(options, delimiter: :pretty)
      options_allowed_values(options, pretty: [nil, true, false])
      options_allowed_values(options, commify: [nil, true, false])
      options_allowed_values(options, gzip: [nil, true, false])
      options_allowed_values(options, bzip2: [nil, true, false])
      options_tie(options, gzip: :output, bzip2: :output)
      options_files_exists_force(options, :output)

      options[:delimiter] ||= "\t"

      lmb = lambda do |input, output, status|
        first     = 0  if options[:first]
        last      = [] if options[:last]
        headings  = nil
        header    = true if options[:header]
        rows      = []
        skip_keys = options[:skip].each_with_object({}) { |i, h| h[i.to_sym] = true } if options[:skip]

        if options[:gzip]
          compress = :gzip
        elsif options[:bzip2]
          compress = :bzip2
        else
          compress = nil
        end

        tab_out = options[:output] ? Filesys.open(options[:output], 'w', compress: compress) : $stdout

        status_track(status) do
          input.each do |record|
            status[:records_in] += 1

            unless headings
              if options[:keys]
                headings = options[:keys].map { |k| k.to_sym }
              elsif record.keys.first =~ /^V\d+$/
                headings = record.keys.sort { |a, b| a.to_s[1 .. a.to_s.size].to_i <=> b.to_s[1 .. a.to_s.size].to_i }
              else
                headings = record.keys
              end

              headings.reject! {|r| skip_keys[r] } if options[:skip]
            end

            row = record.values_at(*headings)

            if options[:pretty]
              rows << row
            else
              if header
                tab_out.puts "#" + headings.join(options[:delimiter]) unless headings.compact.empty?
                header = false
              end

              unless row.compact.empty?
                if options[:first]
                  if first < options[:first]
                    tab_out.puts row.join(options[:delimiter])
                    first += 1
                  end
                elsif options[:last]
                  last << row
                  last.shift if last.size > options[:last]
                else
                  tab_out.puts row.join(options[:delimiter])
                end
              end
            end

            if output
              output << record
              status[:records_out] += 1
            end
          end

          if options[:last]
            last.each { |row| tab_out.puts(row.join(options[:delimiter])) }
          end

          if options[:pretty]
            table = Terminal::Table.new

            unless rows.empty?
              table.headings = headings if options[:header]

              first_row = rows.first.dup

              if options[:commify]
                rows.each do |row|
                  row.each_with_index do |cell, i|
                    if cell.is_a? Integer
                      row[i] = cell.to_i.commify
                    elsif cell.is_a? Float
                      row[i] = cell.to_f.commify
                    end
                  end
                end
              end

              if options[:first]
                table.rows = rows.first(options[:first])
              elsif options[:last]
                table.rows = rows.last(options[:last])
              else
                table.rows = rows
              end

              first_row.each_with_index do |cell, i|
                begin Float(cell)
                  table.align_column(i, :right)
                rescue
                end
              end
            end

            tab_out.puts table
          end
        end

        tab_out.close unless tab_out === $stdout
      end

      @commands << BioPieces::Pipeline::Command.new(__method__, options, options_orig, lmb)

      self
    end
  end
end

