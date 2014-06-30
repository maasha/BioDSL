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
    # == Write sequences from stream in FASTA format.
    # 
    # Description
    # 
    # +write_fasta+ writes sequence from the data stream in FASTA format.
    # However, a FASTA entry will only be written if a SEQ key and a SEQ_NAME key
    # is present. An example FASTA entry:
    #
    #     >test1
    #     TATGACGCGCATCGACAGCAGCACGAGCATGCATCGACTG
    #     TGCACTGACTACGAGCATCACTATATCATCATCATAATCT
    #     TACGACATCTAGGGACTAC
    # 
    # For more about the FASTA format:
    # 
    # http://en.wikipedia.org/wiki/FASTA_format
    # 
    # == Usage
    #    write_fasta([wrap: <uin>[, output: <file>[, force: <bool>
    #                [, gzip: <bool> | bzip2: <bool>]]]])
    #
    # === Options
    # * output <file> - Output file.
    # * force <bool>  - Force overwrite existing output file.
    # * wrap <uint>   - Wrap sequence into lines of wrap length.
    # * gzip <bool>   - Write gzipped output file.
    # * bzip2 <bool>  - Write bzipped output file.
    # 
    # == Examples
    # 
    # To write FASTA entries to STDOUT.
    # 
    #    write_fasta
    #
    # To write FASTA entries wrapped in lines of length of 80 to STDOUT.
    # 
    #    write_fasta(wrap: 80)
    # 
    # To write FASTA entries to a file 'test.fna'.
    # 
    #    write_fasta(output: "test.fna")
    # 
    # To overwrite output file if this exists use the force option:
    #
    #    write_fasta(output: "test.fna", force: true)
    #
    # To write gzipped FASTA entries to file 'test.fna.gz'.
    # 
    #    write_fasta(output: "test.fna.gz", gzip: true)
    #
    # To write bzipped FASTA entries to file 'test.fna.bz2'.
    # 
    #    write_fasta(output: "test.fna.bz2", bzip2: true)
    def write_fasta(options = {})
      options_orig = options.dup
      @options     = options
      options_allowed :force, :output, :wrap, :gzip, :bzip2
      options_unique :gzip, :bzip2
      options_tie gzip: :output, bzip2: :output
      options_files_exists_force :output

      lmb = lambda do |input, output, run_options|
        status_track(input, output, run_options) do

          run_options[:status][:bases_out] = 0

          options[:output] ||= $stdout

          if options[:output] === $stdout
            input.each do |record|
              if record[:SEQ_NAME] and record[:SEQ]
                entry = BioPieces::Seq.new_bp(record)

                $stdout.puts entry.to_fasta(options[:wrap])
                run_options[:status][:bases_out] += entry.length
              end

              output.write record if output
            end
          else
            if options[:gzip]
              compress = :gzip
            elsif options[:bzip2]
              compress = :bzip2
            else
              compress = nil
            end

            Fasta.open(options[:output], 'w', compress: compress) do |ios|
              input.each do |record|
                if record[:SEQ_NAME] and record[:SEQ]
                  entry = BioPieces::Seq.new_bp(record)

                  ios.puts entry.to_fasta(options[:wrap])
                  run_options[:status][:bases_out] += entry.length
                end

                output.write record if output
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

