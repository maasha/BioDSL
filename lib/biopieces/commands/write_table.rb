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
  # rubocop: disable ClassLength

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
  # separated list using the +keys+ option that will print only those keys in
  # that order:
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
  # Alternatively, if you have some keys that you don't want in the tabular
  # output, use the +skip+ option. So to print all keys except SEQ and SEQ_TYPE
  # do:
  #
  #    write_table(skip: [:SEQ])
  #
  #    Human  23524
  #    Dog  2442
  #    Mouse  234
  #    Cat  2342
  #
  # And if you want a pretty printed table use the +pretty+ option and throw in
  # the +commify+ option if you want commified numbers:
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
  class WriteTable
    require 'set'
    require 'terminal-table'

    STATS = %i(records_in records_out)

    # Constructor for WriteTable.
    #
    # @param options [Hash] Options hash.
    # @option options [Array]   :keys
    # @option options [Array]   :skip
    # @option options [String]  :output
    # @option options [Boolean] :force
    # @option options [Boolean] :header
    # @option options [Boolean] :pretty
    # @option options [Boolean] :commify
    # @option options [String]  :delimiter
    # @option options [Fixnum]  :first
    # @option options [Fixnum]  :last
    # @option options [Boolean] :gzip
    # @option options [Boolean] :bzip2
    #
    # @return [WriteTable] Class instance.
    def initialize(options)
      @options               = options
      check_options
      @options[:delimiter] ||= "\t"
      @compress              = choose_compression
      @headings              = nil
      @header                = @options[:header] ? true : false
      @last                  = []
      @rows                  = []

      status_init(STATS)
    end

    # Return command lambda for write_table.
    #
    # @return [Proc] Command lambda.
    def lmb
      lambda do |input, output, status|
        if @options[:output]
          Filesys.open(@options[:output], 'w', compress: @compress) do |tab_out|
            write_table(input, output, tab_out)
          end
        else
          write_table(input, output, $stdout)
        end

        status_assign(status, STATS)
      end
    end

    private

    # Check options.
    def check_options
      options_allowed(@options, :keys, :skip, :output, :force, :header, :pretty,
                      :commify, :delimiter, :first, :last, :gzip, :bzip2)
      options_unique(@options, :keys, :skip)
      options_unique(@options, :first, :last)
      options_unique(@options, :gzip, :bzip2)
      options_allowed_values(@options, force: [nil, true, false])
      options_allowed_values(@options, header: [nil, true, false])
      options_tie(@options, commify: :pretty)
      options_conflict(@options, delimiter: :pretty)
      options_allowed_values(@options, pretty: [nil, true, false],
                                       commify: [nil, true, false],
                                       gzip: [nil, true, false],
                                       bzip2: [nil, true, false])
      options_tie(@options, gzip: :output, bzip2: :output)
      options_files_exist_force(@options, :output)
    end

    # Choose compression to use which can either be gzip or bzip2 or no
    # compression.
    #
    # @return [Symbol,nil] Compression.
    def choose_compression
      if @options[:gzip]
        :gzip
      elsif @options[:bzip2]
        :bzip2
      end
    end

    # Write table from records read from the input stream and emit records
    # to the output stream and table rows to the tab_out IO.
    #
    # @param input   [Enumerator]          Input stream.
    # @param output  [Enumerator::Yielder] Output stream.
    # @param tab_out [IO,STDOUT]           Output to file or stdout.
    def write_table(input, output, tab_out)
      input.each_with_index do |record, i|
        @records_in += 1

        compile_headings(record) unless @headings

        row = record.values_at(*@headings)

        if @options[:pretty]
          @rows << row
        else
          output_row(tab_out, row, i)
        end

        if output
          output << record
          @records_out += 1
        end
      end

      @options[:pretty] ? output_pretty(tab_out) : output_last(tab_out)
    end

    # Compile a list of headings to be used with the output table.
    #
    # @param record [Hash] BioPieces record.
    def compile_headings(record)
      @headings = if @options[:keys]
                    @options[:keys].map(&:to_sym)
                  elsif record.keys.first =~ /^V\d+$/
                    sort_keys(record)
                  else
                    record.keys
                  end

      skip_headings if @options[:skip]
    end

    # Sort keys in the form V[0-9]+ on the numerical part in ascending order.
    def sort_keys(record)
      record.keys.sort do |a, b|
        a.to_s[1..a.to_s.size].to_i <=> b.to_s[1..a.to_s.size].to_i
      end
    end

    # Output row.
    #
    # @param tab_out [Enumerator::Yielder,STDOUT]
    # @param row     [Array]  Row to output
    # @param i       [Fixnum] Row number
    def output_row(tab_out, row, i)
      output_header(tab_out) if @header

      return if row.compact.empty?

      if @options[:first]
        process_first(tab_out, row, i)
      elsif @options[:last]
        process_last(row)
      else
        tab_out.puts row.join(@options[:delimiter])
      end
    end

    # Output header to the given IO if the +header+ flag is set.
    #
    # @param tab_out [IO,STDOUT] Table output IO.
    def output_header(tab_out)
      unless @headings.compact.empty?
        tab_out.puts '#' + @headings.join(@options[:delimiter])
      end

      @header = false
    end

    # Output row to IO if row is among the first number requested.
    #
    # @param tab_out [IO,STDOUT] Table output IO.
    # @param row     [Array] Row with table data.
    # @param i       [Integer] Row number.
    def process_first(tab_out, row, i)
      return unless i < @options[:first]
      tab_out.puts row.join(@options[:delimiter])
    end

    # Add row to last buffer and adjust the size of the buffer to the number of
    # rows requested.
    #
    # @param row [Array] Row with table data.
    def process_last(row)
      @last << row
      @last.shift if @last.size > @options[:last]
    end

    # Skip headings according to the specified options.
    def skip_headings
      skip = @options[:skip].each_with_object(Set.new) { |e, a| a << e.to_sym }
      @headings.reject! { |r| skip.include? r }
    end

    # Output data rows as pretty printed table.
    #
    # @param tab_out [IO,STDOUT] Table output IO.
    def output_pretty(tab_out)
      return unless @options[:pretty]

      table = Terminal::Table.new

      unless @rows.empty?
        table.headings = @headings if @options[:header]
        commify                    if @options[:commify]
        fill_table(table)
        align_columns(table)
      end

      tab_out.puts table
    end

    # Insert commas in large numbers for readability.
    def commify
      @rows.each do |row|
        row.each_with_index do |cell, i|
          if cell.is_a? Integer
            row[i] = cell.to_i.commify
          elsif cell.is_a? Float
            row[i] = cell.to_f.commify
          end
        end
      end
    end

    # Fill terminal table with data.
    #
    # @param table [Terminal::Table] Table to be pretty printed.
    def fill_table(table)
      table.rows = if @options[:first]
                     @rows.first(@options[:first])
                   elsif @options[:last]
                     @rows.last(@options[:last])
                   else
                     @rows
                   end
    end

    # Iterate over the first row in the given table to be pretty printed and
    # determine the alignment of each column.
    #
    # @param table [Terminal::Table] Table to be pretty printed.
    def align_columns(table)
      @rows.first.each_with_index do |cell, i|
        next unless cell.is_a?(Fixnum) ||
                    cell.is_a?(Float)  ||
                    cell.delete(',') =~ /^[0-9]+$/

        table.align_column(i, :right)
      end
    end

    # Output last table rows.
    #
    # @param tab_out [IO,STDOUT] Table output IO.
    def output_last(tab_out)
      @last.each { |row| tab_out.puts(row.join(@options[:delimiter])) }
    end
  end
end
