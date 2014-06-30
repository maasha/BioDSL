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
    # == Read FASTA entries from one or more files.
    #
    # +read_fasta+ read in sequence entries from FASTA files. Each sequence
    # entry consists of a sequence name prefixed by a '>' followed by the sequence
    # name on a line of its own, followed by one or my lines of sequence until the
    # next entry or the end of the file. The resulting Biopiece record consists of
    # the following record type:
    #
    #     {:SEQ_NAME=>"test",
    #      :SEQ=>"AGCATCGACTAGCAGCATTT",
    #      :SEQ_LEN=>20}
    #
    # Input files may be compressed with gzip og bzip2.
    #
    # For more about the FASTA format:
    #
    # http://en.wikipedia.org/wiki/Fasta_format
    # 
    # == Usage
    #    read_fasta(input: <glob>[, first: <uint>|last: <uint>])
    #
    # === Options
    # * input <glob> - Input file or file glob expression.
    # * first <uint> - Only read in the _first_ number of entries.
    # * last <uint>  - Only read in the _last_ number of entries.
    #
    # == Examples
    #
    # To read all FASTA entries from a file:
    #
    #    read_fasta(input: "test.fna")
    #
    # To read all FASTA entries from a gzipped file:
    #
    #    read_fasta(input: "test.fna.gz")
    #
    # To read in only 10 records from a FASTA file:
    #
    #    read_fasta(input: "test.fna", first: 10)
    #
    # To read in the last 10 records from a FASTA file:
    #
    #    read_fasta(input: "test.fna", last: 10)
    #
    # To read all FASTA entries from multiple files:
    #
    #    read_fasta(input: "test1.fna,test2.fna")
    #
    # To read FASTA entries from multiple files using a glob expression:
    #
    #    read_fasta(input: "*.fna")
    def read_fasta(options = {})
      options_orig = options.dup
      @options     = options
      options_allowed :input, :first, :last
      options_required :input
      options_glob :input
      options_files_exist :input
      options_unique :first, :last
      options_assert ":first >= 0"
      options_assert ":last >= 0"

      lmb = lambda do |input, output, run_options|
        status_track(input, output, run_options) do
          input.each { |record| output.write record } if input

          run_options[:status][:bases_in] = 0

          count  = 0
          buffer = []

          catch :break do
            options[:input].each do |file|
              BioPieces::Fasta.open(file) do |ios|
                if options[:first]
                  ios.each do |entry|
                    throw :break if options[:first] == count

                    output.write entry.to_bp if output
                    run_options[:status][:bases_in] += entry.length

                    count += 1
                  end
                elsif options[:last]
                  ios.each do |entry|
                    buffer << entry
                    buffer.shift if buffer.size > options[:last]
                  end
                else
                  ios.each do |entry|
                    output.write entry.to_bp if output
                    run_options[:status][:bases_in] += entry.length
                  end
                end
              end
            end

            if options[:last]
              buffer.each do |entry|
                output.write entry.to_bp if output
                run_options[:status][:bases_in] += entry.length
              end
            end
          end
        end
      end

      add(__method__, options, options_orig, lmb)

      self
    end
  end
end

