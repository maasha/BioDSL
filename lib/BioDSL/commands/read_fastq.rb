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
# This software is part of BioDSL (www.BioDSL.org).                      #
#                                                                              #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

module BioDSL
  # == Read FASTQ entries from one or more files.
  #
  # +read_fastq+ read in sequence entries from FASTQ files. Each sequence entry
  # consists of a sequence name prefixed by a '>' followed by the sequence name
  # on a line of its own, followed by one or my lines of sequence until the next
  # entry or the end of the file. The resulting Biopiece record consists of the
  # following record type:
  #
  #     {:SEQ_NAME=>"test",
  #      :SEQ=>"AGCATCGACTAGCAGCATTT",
  #      :SEQ_LEN=>20}
  #
  # It is possible to read in pair-end data interleaved by using the +input2+
  # option. Thus a read is in turn from input and input2. If the
  # +reverse_complement+ option is used, then the input2 reads will be
  # reverse-complemented.
  #
  # Input files may be compressed with gzip og bzip2.
  #
  # For more about the FASTQ format:
  #
  # http://en.wikipedia.org/wiki/Fasta_format
  #
  # == Usage
  #    read_fastq(input: <glob>[, input2: <glob>[, first: <uint>|last: <uint>
  #               [, reverse_complement: <bool>]]])
  #
  # === Options
  # * input <glob>               - Input file or file glob expression.
  # * input2 <glob>              - Input file or file glob expression.
  # * first <uint>               - Only read in the _first_ number of entries.
  # * last <uint>                - Only read in the _last_ number of entries.
  # * reverse_complement: <bool> - Reverse-complements input2 reads.
  #
  # == Examples
  #
  # To read all FASTQ entries from a file:
  #
  #    BP.new.read_fastq(input: "test.fq").dump.run
  #
  # To read all FASTQ entries from a gzipped file:
  #
  #    BP.new.read_fastq(input: "test.fq.gz").dump.run
  #
  # To read in only 10 records from a FASTQ file:
  #
  #    BP.new.read_fastq(input: "test.fq", first: 10).dump.run
  #
  # To read in the last 10 records from a FASTQ file:
  #
  #    BP.new.read_fastq(input: "test.fq", last: 10).dump.run
  #
  # To read all FASTQ entries from multiple files:
  #
  #    BP.new.read_fastq(input: "test1.fq,test2.fq").dump.run
  #
  # To read FASTQ entries from multiple files using a glob expression:
  #
  #    BP.new.read_fastq(input: "*.fq").dump.run
  #
  # To read FASTQ entries from pair-end data:
  #
  #    BP.new.read_fastq(input: "file1.fq", input2: "file2.fq").dump.run
  #
  # To read FASTQ entries from pair-end data:
  #
  #    BP.new.read_fastq(input: "file1.fq", input2: "file2.fq").dump.run
  #
  # To read FASTQ entries from pair-end data and reverse-complement read2:
  #
  #    BP.new.
  #    read_fastq(input: "file1.fq", input2: "file2.fq",
  #               reverse_complement: true)
  #    .dump.run
  #
  # rubocop: disable ClassLength
  # rubocop: disable Metrics/AbcSize
  # rubocop: disable Metrics/CyclomaticComplexity
  # rubocop: disable Metrics/PerceivedComplexity
  class ReadFastq
    MAX_TEST = 1_000
    STATS = %i(records_in records_out sequences_in sequences_out residues_in
               residues_out)

    # Constructor for ReadFastq.
    #
    # @param options [Hash] Options hash.
    # @option options [Symbol,String] :encoding
    # @option options [String]        :input
    # @option options [String]        :input2
    # @option options [Integer]       :first
    # @option options [Integer]       :last
    # @option options [Boolean]       :reverse_complement
    #
    # @return [ReadFastq] Class instance.
    def initialize(options)
      @options  = options
      @encoding = options[:encoding] ? options[:encoding].to_sym : :auto
      @pair     = options[:input2]
      @buffer   = []
      @type     = nil

      check_options
    end

    # Return command lambda for ReadFastq.
    #
    # @return [Proc] Command lambda.
    def lmb
      lambda do |input, output, status|
        status_init(status, STATS)

        process_input(input, output)

        case
        when @options[:first] && @pair then read_first_pair(output)
        when @options[:first]          then read_first_single(output)
        when @options[:last]  && @pair then read_last_pair(output)
        when @options[:last]           then read_last_single(output)
        when @pair                     then read_all_pair(output)
        else
          read_all_single(output)
        end
      end
    end

    private

    # Check options.
    def check_options
      options_allowed(@options, :encoding, :input, :input2, :first, :last,
                      :reverse_complement)
      options_allowed_values(@options, encoding: [:auto, :base_33, :base_64])
      options_allowed_values(@options, reverse_complement: [nil, true, false])
      options_tie(@options, reverse_complement: :input2)
      options_required(@options, :input)
      options_files_exist(@options, :input, :input2)
      options_unique(@options, :first, :last)
      options_assert(@options, ':first >= 0')
      options_assert(@options, ':last >= 0')
    end

    # Emit all records from the input stream to the output stream.
    #
    # @param input [Enumerator] Input stream.
    # @param output [Enumerator::Yielder] Output stream.
    def process_input(input, output)
      return unless input

      input.each do |record|
        @status[:records_in]  += 1
        @status[:records_out] += 1

        if (seq = record[:SEQ])
          @status[:sequences_in] += 1
          @status[:residues_in]  += seq.length
        end

        output << record
      end
    end

    # Read :first FASTQ entries from single files.
    #
    # @param output [Enumerator::Yielder] Output stream.
    def read_first_single(output)
      fastq_files.each do |file|
        BioDSL::Fastq.open(file) do |ios|
          ios.each do |entry|
            check_entry(entry)
            output << entry.to_bp
            @status[:records_out]   += 1
            @status[:sequences_out] += 1
            @status[:residues_out]  += entry.length
            return if @status[:sequences_out] >= @options[:first]
          end
        end
      end
    end

    # Read :first FASTQ entries from paired files interleaved.
    #
    # @param output [Enumerator::Yielder] Output stream.
    #
    # rubocop: disable MethodLength
    def read_first_pair(output)
      fastq_files.each_slice(2) do |file1, file2|
        BioDSL::Fastq.open(file1) do |ios1|
          BioDSL::Fastq.open(file2) do |ios2|
            while (entry1 = ios1.next_entry) && (entry2 = ios2.next_entry)
              check_entry(entry1, entry2)
              reverse_complement(entry2) if @options[:reverse_complement]
              output << entry1.to_bp
              output << entry2.to_bp
              @status[:records_out]   += 2
              @status[:sequences_out] += 2
              @status[:residues_out]  += entry1.length + entry2.length
              return if @status[:sequences_out] >= @options[:first]
            end
          end
        end
      end
    end

    # Read :last FASTQ entries from single files.
    #
    # @param output [Enumerator::Yielder] Output stream.
    #
    # rubocop: enable MethodLength
    def read_last_single(output)
      fastq_files.each do |file|
        BioDSL::Fastq.open(file) do |ios|
          ios.each do |entry|
            check_entry(entry)
            @buffer << entry
            @buffer.shift if @buffer.size > @options[:last]
          end
        end
      end

      output_buffer(output)
    end

    # Read :last FASTQ entries from paired files interleaved.
    #
    # @param output [Enumerator::Yielder] Output stream.
    def read_last_pair(output)
      fastq_files.each_slice(2) do |file1, file2|
        BioDSL::Fastq.open(file1) do |ios1|
          BioDSL::Fastq.open(file2) do |ios2|
            while (entry1 = ios1.next_entry) && (entry2 = ios2.next_entry)
              check_entry(entry1, entry2)
              reverse_complement(entry2) if @options[:reverse_complement]
              @buffer << entry1
              @buffer << entry2
              @buffer.shift(@buffer.size - @options[:last])
            end
          end
        end
      end

      output_buffer(output)
    end

    # Read all FASTQ entries from single files.
    #
    # @param output [Enumerator::Yielder] Output stream.
    def read_all_single(output)
      fastq_files.each do |file|
        BioDSL::Fastq.open(file) do |ios|
          ios.each do |entry|
            check_entry(entry)
            output << entry.to_bp
            @status[:records_out]   += 1
            @status[:sequences_out] += 1
            @status[:residues_out]  += entry.length
          end
        end
      end
    end

    # Read all FASTQ entries from paired files interleaved.
    #
    # @param output [Enumerator::Yielder] Output stream.
    def read_all_pair(output)
      fastq_files.each_slice(2) do |file1, file2|
        BioDSL::Fastq.open(file1) do |ios1|
          BioDSL::Fastq.open(file2) do |ios2|
            while (entry1 = ios1.next_entry) && (entry2 = ios2.next_entry)
              check_entry(entry1, entry2)
              reverse_complement(entry2) if @options[:reverse_complement]
              output << entry1.to_bp
              output << entry2.to_bp
              @status[:records_out]   += 2
              @status[:sequences_out] += 2
              @status[:residues_out]  += entry1.length + entry2.length
            end
          end
        end
      end
    end

    # Return a list of input files or an interleaved list of input files if
    # :input2 is specified.
    #
    # @return [Array] List of FASTQ files.
    def fastq_files
      if @options[:input2]
        files1 = options_glob(@options[:input])
        files2 = options_glob(@options[:input2])

        check_input_files(files1, files2)

        files1.zip(files2).flatten
      else
        options_glob(@options[:input])
      end
    end

    # Do the following for the given entry:
    #
    # * determine encoding.
    # * reverse complement if indicated.
    # * convert encoding
    # * coerce encoding
    # * check score range
    #
    # @param entries [Array] Sequence entries.
    def check_entry(*entries)
      entries.each do |entry|
        determine_encoding(entry)

        entry.qual_convert!(@encoding, :base_33)
        entry.qual_coerce!(:base_33)

        check_score_range(entry)
      end
    end

    # Reverse complement sequence.
    #
    # @param entry [BioDSL::Seq] Sequence entry.
    def reverse_complement(entry)
      @type = entry.type_guess unless @type
      entry.type = @type
      entry.reverse!.complement!
    end

    # Check that files1 and files2 are equal.
    #
    # @param files1 [Array] List of files.
    # @param files2 [Array] List of files.
    #
    # @raise [BioDSL::OptionError] If not equal.
    def check_input_files(files1, files2)
      size1 = files1.size
      size2 = files2.size
      return if size1 == size2

      msg = "input and input2 file count don't match: #{size1} != #{size2}"
      fail BioDSL::OptionError, msg
    end

    # Check the score range for a given entry.
    #
    # @param entry [BioDSL::Seq] Sequence entry.
    #
    # @raise [BioDSL::SeqError] If quality score is outside range.
    def check_score_range(entry)
      return if @status[:sequences_out] >= MAX_TEST
      return if entry.qual_valid?(:base_33)
      fail BioDSL::SeqError, 'Quality score outside valid range'
    end

    # Determine the quality score encoding.
    #
    # @raise [BioDSL::SeqError] If encoding wasn't determined.
    def determine_encoding(entry)
      return unless @encoding == :auto

      @encoding = if entry.qual_base33?
                    :base_33
                  elsif entry.qual_base64?
                    :base_64
                  else
                    msg = 'Could not auto-detect quality score encoding'
                    fail BioDSL::SeqError, msg
                  end
    end

    # Emit all records in the buffer to the output stream.
    #
    # @param output [Enumerator::Yielder] Output stream.
    def output_buffer(output)
      return unless @options[:last]

      @buffer.each do |entry|
        output << entry.to_bp

        @status[:records_out]   += 1
        @status[:sequences_out] += 1
        @status[:residues_out]  += entry.length
      end
    end
  end
end
