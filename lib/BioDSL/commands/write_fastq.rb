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
# This software is part of the BioDSL framework (www.BioDSL.org).        #
#                                                                              #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

module BioDSL
  # == Write sequences from stream in FASTQ format.
  #
  # Description
  #
  # +write_fastq+ writes sequence from the data stream in FASTQ format. However,
  # a FASTQ entry will only be written if a SEQ key and a SEQ_NAME key is
  # present. An example FASTQ entry:
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
  # * encoding <base> - Encoding quality scores using :base_33 (default) or
  #                     :base_64.
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
  class WriteFastq
    STATS = %i(records_in records_out sequences_in sequences_out residues_in
               residues_out)

    # Constructor for WriteFastq.
    #
    # @param options [Hash] Options hash.
    # @option options [String,Symbol] :encoding
    # @option options [Boolean] :force
    # @option options [String] :output
    # @option options [Boolean] :gzip
    # @option options [Boolean] :bzip2
    #
    # @return [WriteFastq] Class instance.
    def initialize(options)
      @options            = options
      check_options
      @options[:output] ||= $stdout
      @compress           = choose_compression
      @encoding           = choose_encoding
    end

    # Return command lambda for write_fastq.
    #
    # @return [Proc] Command lambda.
    def lmb
      lambda do |input, output, status|
        status_init(status, STATS)

        if @options[:output] == $stdout
          process_input(input, output, $stdout)
        else
          Fastq.open(@options[:output], 'w', compress: @compress) do |ios|
            process_input(input, output, ios)
          end
        end
      end
    end

    private

    # Check options.
    def check_options
      options_allowed(@options, :encoding, :force, :output, :gzip, :bzip2)
      options_allowed_values(@options, encoding: [:base_33, :base_64, 'base_33',
                                                  'base_64'])
      options_unique(@options, :gzip, :bzip2)
      options_tie(@options, gzip: :output, bzip2: :output)
      options_files_exist_force(@options, :output)
    end

    # Process all records in the input stream and output FASTQ data to the given
    # ios, and finally emit all records to the output stream if specified.
    #
    # @param input  [Enumerable]                  Input stream.
    # @param output [Enumerable::Yielder]         Output stream.
    # @param ios    [BioDSL::Fastq::IO,STDOUT] Output IO.
    def process_input(input, output, ios)
      input.each do |record|
        @status[:records_in] += 1

        if record[:SEQ]
          @status[:sequences_in] += 1
          @status[:residues_in]  += record[:SEQ].length

          write_fastq(record, ios) if record[:SEQ_NAME] && record[:SCORES]
        end

        if output
          output << record
          @status[:records_out] += 1
        end
      end
    end

    # Given a BioPeices record convert this to a sequence entry and output in
    # FASTQ format to the speficied IO.
    #
    # @param record [Hash] BioDSL record.
    # @param ios    [BioDSL::Fastq::IO,STDOUT] Output IO.
    def write_fastq(record, ios)
      entry = BioDSL::Seq.new_bp(record)
      entry.qual_convert!(:base_33, @encoding)

      ios.puts entry.to_fastq
      @status[:sequences_out] += 1
      @status[:residues_out]  += entry.length
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

    # Chose the quality score encoding.
    #
    # @return [Symbol,nil] Encoding.
    def choose_encoding
      if @options[:encoding]
        @options[:encoding].to_sym
      else
        :base_33
      end
    end
  end
end
