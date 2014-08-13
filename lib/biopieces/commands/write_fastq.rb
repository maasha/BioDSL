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
    # == Write sequences from stream in FASTQ format.
    # 
    # Description
    # 
    # +write_fastq+ writes sequence from the data stream in FASTQ format.
    # However, a FASTQ entry will only be written if a SEQ key and a SEQ_NAME key
    # is present. An example FASTQ entry:
    #
    #     >test1
    #     TATGACGCGCATCGACAGCAGCACGAGCATGCATCGACTG
    #     TGCACTGACTACGAGCATCACTATATCATCATCATAATCT
    #     TACGACATCTAGGGACTAC
    # 
    # For more about the FASTQ format:
    # 
    # http://en.wikipedia.org/wiki/FASTQ_format
    # 
    # == Usage
    #    write_fastq([encoding: <:base_33|:base_64>[, output: <file>
    #                [, force: <bool>[, gzip: <bool> | bzip2: <bool>]]])
    #
    # === Options
    # * encoding <base> - Encoding quality scores using :base_33 (default) or :base_64.
    # * output <file>   - Output file.
    # * force <bool>    - Force overwrite existing output file.
    # * gzip <bool>     - Write gzipped output file.
    # * bzip2 <bool>    - Write bzipped output file.
    # 
    # == Examples
    # 
    # To write FASTQ entries to STDOUT.
    # 
    #    write_fastq
    #
    # To write FASTQ entries to a file 'test.fq'.
    # 
    #    write_fastq(output: "test.fq")
    # 
    # To overwrite output file if this exists use the force option:
    #
    #    write_fastq(output: "test.fq", force: true)
    #
    # To write gzipped FASTQ entries to file 'test.fq.gz'.
    # 
    #    write_fastq(output: "test.fq.gz", gzip: true)
    #
    # To write bzipped FASTQ entries to file 'test.fq.bz2'.
    # 
    #    write_fastq(output: "test.fq.bz2", bzip2: true)
    def write_fastq(options = {})
      options_allowed(options, :encoding, :force, :output, :gzip, :bzip2)
      options_allowed_values(options, encoding: [:base_33, :base_64])
      options_unique(options, :gzip, :bzip2)
      options_tie(options, gzip: :output, bzip2: :output)
      options_files_exists_force(options, :output)

      encoding = options[:encoding] || :base_33

      lmb = lambda do |input, output, status|
        status_track(status) do
          options[:output] ||= $stdout

          status[:sequences_out] = 0
          status[:residues_out]  = 0

          if options[:output] === $stdout
            input.each do |record|
              status[:records_in] += 1

              if record[:SEQ_NAME] and record[:SEQ] and record[:SCORES]
                entry = BioPieces::Seq.new_bp(record)
                entry.qual_convert!(:base_33, encoding)

                $stdout.puts entry.to_fastq
                status[:sequences_out] += 1
                status[:residues_out]  += entry.length
              end

              if output
                output << record
                status[:records_out] += 1
              end
            end
          else
            if options[:gzip]
              compress = :gzip
            elsif options[:bzip2]
              compress = :bzip2
            else
              compress = nil
            end

            Fastq.open(options[:output], 'w', compress: compress) do |ios|
              input.each do |record|
                status[:records_in] += 1

                if record[:SEQ_NAME] and record[:SEQ] and record[:SCORES]
                  entry = BioPieces::Seq.new_bp(record)
                  entry.qual_convert!(:base_33, encoding)

                  ios.puts entry.to_fastq
                  status[:sequences_out] += 1
                  status[:residues_out]  += entry.length
                end

                if output
                  output << record
                  status[:records_out] += 1
                end
              end
            end
          end
        end
      end

      @commands << BioPieces::Pipeline::Command.new(__method__, options, lmb)

      self
    end
  end
end

