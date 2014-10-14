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
    # == Write tabular output from the stream.
    # 
    # Description
    # 
    # +write_table+ writes sequence from the data stream in FASTA format.
    # 
    # == Usage
    #    write_table([keys: <string> | skip: <string>][, output: <file>[, force:
    #                <bool>[, header: <bool>[, pretty: <bool>[, commify: <bool>
    #                [, delimiter: <string>[, gzip: <bool>, [bzip2: <bool>]]]]]]]]
    #               
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
    # * gzip <bool>        - Write gzipped output file.
    # * bzip2 <bool>       - Write bzipped output file.
    # 
    # == Examples
    # 
    # To write FASTA entries to STDOUT.
    # 
    #    write_table
    #
    # To write FASTA entries wrapped in lines of length of 80 to STDOUT.
    # 
    #    write_table(wrap: 80)
    # 
    # To write FASTA entries to a file 'test.fna'.
    # 
    #    write_table(output: "test.fna")
    # 
    # To overwrite output file if this exists use the force option:
    #
    #    write_table(output: "test.fna", force: true)
    #
    # To write gzipped FASTA entries to file 'test.fna.gz'.
    # 
    #    write_table(output: "test.fna.gz", gzip: true)
    #
    # To write bzipped FASTA entries to file 'test.fna.bz2'.
    # 
    #    write_table(output: "test.fna.bz2", bzip2: true)
    def write_table(options = {})
      require 'terminal-table'

      options_orig = options.dup
      options_allowed(options, :keys, :skip, :output, :force, :header, :pretty,
                               :commify, :delimiter, :gzip, :bzip2)
      options_unique(options, :keys, :skip)
      options_unique(options, :gzip, :bzip2)
      options_allowed_values(options, force: [nil, true, false])
      options_allowed_values(options, header: [nil, true, false])
      options_allowed_values(options, pretty: [nil, true, false])
      options_allowed_values(options, commify: [nil, true, false])
      options_allowed_values(options, gzip: [nil, true, false])
      options_allowed_values(options, bzip2: [nil, true, false])
      options_tie(options, gzip: :output, bzip2: :output)
      options_files_exists_force(options, :output)

      options[:delimiter] ||= "\t"

      lmb = lambda do |input, output, status|
        headings  = nil
        header    = true if options[:header]
        rows      = []
        skip_keys = options[:skip].each_with_object({}) { |i, h| h[i.to_sym] = true } if options[:skip]
        compress  = options[:compress] ? options[:compress].to_sym : nil
        tab_out   = options[:output] ? Filesys.open(options[:output], 'w', compress: compress) : STDOUT

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
                tab_out.puts "#" + headings.join(options[:delimiter]) unless headings.empty?
                header = false
              end

              tab_out.puts row.join(options[:delimiter]) unless row.empty?
            end

            if output
              output << record
              status[:records_out] += 1
            end
          end

          if options[:pretty]
            table = Terminal::Table.new
            table.headings = headings if options[:header]

            first_row = rows.first.dup

            if options[:commify]
              rows.each do |row|
                row.each_with_index do |cell, i|
                  begin Integer(cell)
                    row[i] = cell.to_i.commify
                  rescue
                    begin Float(cell)
                      row[i] = cell.to_f.commify
                    rescue
                    end
                  end
                end
              end
            end

            table.rows = rows

            first_row.each_with_index do |cell, i|
              begin Float(cell)
                table.align_column(i, :right)
              rescue
              end
            end

            tab_out.puts table
          end
        end

        tab_out.close unless tab_out === STDOUT
      end

      @commands << BioPieces::Pipeline::Command.new(__method__, options, options_orig, lmb)

      self
    end
  end
end

