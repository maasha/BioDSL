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
# This software is part of Biopieces (www.biopieces.org).                        #
#                                                                                #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

module BioPieces
  module Commands
    MAX_TEST = 1_000

    # == Read FASTQ entries from one or more files.
    #
    # +read_fastq+ read in sequence entries from FASTQ files. Each sequence
    # entry consists of a sequence name prefixed by a '>' followed by the sequence
    # name on a line of its own, followed by one or my lines of sequence until the
    # next entry or the end of the file. The resulting Biopiece record consists of
    # the following record type:
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
    #    BP.new.read_fastq(input: "file1.fq", input2: "file2.fq", reverse_complement: true).dump.run
    def read_fastq(options = {})
      options_orig = options.dup
      options_load_rc(options, __method__)
      options[:encoding] ||= :auto
      options_allowed(options, :encoding, :input, :input2, :first, :last, :reverse_complement)
      options_allowed_values(options, encoding: [:auto, :base_33, :base_64])
      options_allowed_values(options, reverse_complement: [nil, true, false])
      options_tie(options, reverse_complement: :input2)
      options_required(options, :input)
      options_glob(options, :input, :input2)
      options_files_exist(options, :input, :input2)
      options_unique(options, :first, :last)
      options_assert(options, ":first >= 0")
      options_assert(options, ":last >= 0")

      encoding = options[:encoding].to_sym

      lmb = lambda do |input, output, status|
        status_track(status) do
          if input
            input.each do |record|
              output << record
              status[:records_in]  += 1
              status[:records_out] += 1
            end
          end

          status[:sequences_in] = 0
          status[:residues_in]  = 0

          count  = 0
          buffer = []
          type   = nil

          catch :break do
            if options[:input] and options[:input2]
              if options[:input].size != options[:input2].size
                raise BioPieces::OptionError, "input and input2 file count don't match: #{options[:input].size} != #{options[:input2].size}" 
              end

              (0 ... options[:input].size).each do |i|
                file1 = options[:input][i]
                file2 = options[:input2][i]

                io1 = Fastq.open(file1, 'r')
                io2 = Fastq.open(file2, 'r')

                while entry1 = io1.next_entry and entry2 = io2.next_entry
                  if encoding == :auto
                    if entry1.qual_base33? or entry2.qual_base33?
                      encoding = :base_33
                    elsif entry1.qual_base64? or entry2.qual_base64?
                      encoding = :base_64
                    else
                      raise BioPieces::SeqError, "Could not auto-detect quality score encoding"
                    end
                  end

                  if options[:reverse_complement]
                    type = entry2.type_guess unless type
                    entry2.type = type
                    entry2.reverse!.complement!
                  end

                  entry1.qual_convert!(encoding, :base_33)
                  entry2.qual_convert!(encoding, :base_33)
                  entry1.qual_coerce!(:base_33)
                  entry2.qual_coerce!(:base_33)

                  if count < MAX_TEST
                    raise BioPieces::SeqError, "Quality score outside valid range" unless entry1.qual_valid?(:base_33)
                    raise BioPieces::SeqError, "Quality score outside valid range" unless entry2.qual_valid?(:base_33)
                  end

                  if options[:first]
                    throw :break if options[:first] == count

                    output << entry1.to_bp
                    output << entry2.to_bp

                    status[:records_out]  += 2
                    status[:sequences_in] += 2
                    status[:residues_in]  += entry1.length + entry2.length

                    count += 2
                  elsif options[:last]
                      buffer << entry1
                      buffer.shift if buffer.size > options[:last]
                      buffer << entry2
                      buffer.shift if buffer.size > options[:last]
                  else
                    output << entry1.to_bp
                    output << entry2.to_bp

                    status[:records_out]  += 2
                    status[:sequences_in] += 2
                    status[:residues_in]  += entry1.length + entry2.length
                  end
                end

                io1.close
                io2.close
              end
            else
              options[:input].each do |file|
                BioPieces::Fastq.open(file) do |ios|
                  ios.each do |entry|
                    if encoding == :auto
                      if entry.qual_base33?
                        encoding = :base_33
                      elsif entry.qual_base64?
                        encoding = :base_64
                      else
                        raise BioPieces::SeqError, "Could not auto-detect quality score encoding"
                      end
                    end

                    entry.qual_convert!(encoding, :base_33)
                    entry.qual_coerce!(:base_33)

                    if count < MAX_TEST
                      raise BioPieces::SeqError, "Quality score outside valid range" unless entry.qual_valid?(:base_33)
                    end

                    if options[:first]
                      throw :break if options[:first] == count

                      output << entry.to_bp

                      status[:records_out]  += 1
                      status[:sequences_in] += 1
                      status[:residues_in] += entry.length

                      count += 1
                    elsif options[:last]
                      buffer << entry
                      buffer.shift if buffer.size > options[:last]
                    else
                      output << entry.to_bp

                      status[:records_out]  += 1
                      status[:sequences_in] += 1
                      status[:residues_in] += entry.length
                    end
                  end
                end
              end
            end

            if options[:last]
              buffer.each do |entry|
                output << entry.to_bp

                status[:records_out] += 1
                status[:residues_in] += entry.length
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

