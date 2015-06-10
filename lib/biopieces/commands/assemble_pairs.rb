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
  # == Assemble ordered overlapping pair-end sequences in the stream.
  #
  # +assemble_pairs+ assembles overlapping pair-end sequences into single
  # sequences that are output to the stream - the orginal sequences are no
  # output. Assembly works by progressively considering all overlaps between the
  # maximum considered overlap using the +overlap_max+ option (default is the
  # length of the shortest sequence) until the minimum required overlap supplied
  # with the +overlap_min+ option (default 1). For each overlap a percentage of
  # mismatches can be allowed using the +mismatch_percent+ option (default 20%).
  #
  # Mismatches in the overlapping regions are resolved so that the residues with
  # the highest quality score is used in the assembled sequence. The quality
  # scores are averaged in the overlapping region. The sequence of the
  # overlapping region is output in upper case and the remaining in lower case.
  #
  # Futhermore, sequences must be in interleaved order in the stream - use
  # +read_fastq+ with +input+ and +input2+ options for that.
  #
  # The additional keys are added to records with assembled sequences:
  #
  # * OVERLAP_LEN   - the length of the located overlap.
  # * HAMMING_DIST  - the number of mismatches in the assembly.
  #
  # Using the +merge_unassembled+ option will merge any unassembled sequences
  # taking into account reverse complementation of read2 if the
  # +reverse_complement+ option is true. Note that you probably want to set
  # +overlap_min+ to 1 before using +merge_unassembled+ to improve chances of
  # making an assembly before falling back to a simple merge.
  #
  # == Usage
  #
  #    assemble_pairs([mismatch_percent: <uint>[, overlap_min: <uint>
  #                   [, overlap_max: <uint>[, reverse_complement: <bool>
  #                   [, merge_unassembled: <bool>]]]]])
  #
  # === Options
  #
  # * mismatch_percent: <uint>   - Maximum allowed overlap mismatches in
  #                                percent (default=20).
  # * overlap_min: <uint>        - Minimum overlap required (default=1).
  # * overlap_max: <uint>        - Maximum overlap considered
  #                                (default=<length of shortest sequences>).
  # * reverse_complement: <bool> - Reverse-complement read2 before assembly
  #                                (default=false).
  # * merge_unassembled: <bool>  - Merge unassembled pairs (default=false).
  #
  # == Examples
  #
  # If you have two pair-end sequence files with the Illumina data then you
  # can assemble these using assemble_pairs like this:
  #
  #    BP.new.
  #    read_fastq(input: "file1.fq", input2: "file2.fq).
  #    assemble_pairs(reverse_complement: true).
  #    run
  # rubocop:disable ClassLength
  class AssemblePairs
    require 'biopieces/helpers/options_helper'
    require 'biopieces/helpers/status_helper'
    extend OptionsHelper
    include OptionsHelper
    include StatusHelper

    # Check the options and return a lambda for the command.
    #
    # @param [Hash] options Options hash.
    #
    # @option options [Integer] :mismatch_percent
    #   Maximum allowed overlap mismatches in percent.
    #
    # @option options [Integer] :overlap_min
    #   Minimum length of overlap.
    #
    # @option options [Integer] :overlap_max
    #   Maximum length of overlap.
    #
    # @option options [Boolean] :reverse_complement
    #   Reverse-complment read2.
    #
    # @option options [Boolean] :merge_unassembled
    #   Merge read pairs that couldn't be assembled.
    #
    # @option options [Boolean] :allow_unassembled
    #   Output reads that couldn't be assembled.
    #
    # @return [Proc] Returns the command lambda.
    def self.lmb(options)
      options_allowed(options, :mismatch_percent, :overlap_min, :overlap_max,
                      :reverse_complement, :merge_unassembled,
                      :allow_unassembled)
      options_allowed_values(options, reverse_complement: [true, false, nil])
      options_allowed_values(options, merge_unassembled: [true, false, nil])
      options_allowed_values(options, allow_unassembled: [true, false, nil])
      options_conflict(options, allow_unassembled: :merge_unassembled)
      options_assert(options, ':mismatch_percent >= 0')
      options_assert(options, ':mismatch_percent <= 100')
      options_assert(options, ':overlap_min > 0')

      options[:mismatch_percent] ||= 20
      options[:overlap_min]      ||= 1

      new(options).lmb
    end

    # Constructor for the AssemblePairs class.
    #
    # @param [Hash] options Options hash.
    #
    # @option options [Integer] :mismatch_percent
    #   Maximum allowed overlap mismatches in percent.
    #
    # @option options [Integer] :overlap_min
    #   Minimum length of overlap.
    #
    # @option options [Integer] :overlap_max
    #   Maximum length of overlap.
    #
    # @option options [Boolean] :reverse_complement
    #   Reverse-complment read2.
    #
    # @option options [Boolean] :merge_unassembled
    #   Merge read pairs that couldn't be assembled.
    #
    # @option options [Boolean] :allow_unassembled
    #   Output reads that couldn't be assembled.
    #
    # @return [ReadFasta] Returns an instance of the class.
    def initialize(options)
      @options       = options
      status_init(:overlap_sum, :hamming_sum, :records_in, :records_out,
                  :sequences_in, :sequences_out, :residues_in, :residues_out,
                  :assembled, :unassembled)
    end

    # Return a lambda for the read_fasta command.
    #
    # @return [Proc] Returns the read_fasta command lambda.
    def lmb
      lambda do |input, output, status|
        input.each_slice(2) do |record1, record2|
          @records_in += 2

          if record2 && record1[:SEQ] && record2[:SEQ]
            assemble_pairs(record1, record2, output)
          else
            output_record(record1, output)
            output_record(record2, output) if record2
          end
        end

        status_assign(status, :records_in, :records_out, :sequences_in,
                              :sequences_out, :residues_in, :residues_out,
                              :assembled)
        calc_status(status)
      end
    end

    private

    # Output a record to the stream if a stram is provided.
    #
    # @param record [Hash] BioPieces record to output.
    # @param output [Enumerator::Yielder, nil] Output stream or nil.
    def output_record(record, output)
      return unless output
      output << record
      @records_out += 1
    end

    # Assemble records with sequences and output to the stream
    #
    # @param record1 [Hash]                Biopieces record1.
    # @param record2 [Hash]                Biopieces record2.
    # @param output  [Enumerator::Yielder] Output stream.
    def assemble_pairs(record1, record2, output)
      entry1, entry2 = records2entries(record1, record2)

      if overlap_possible?(entry1, entry2, @options[:overlap_min]) &&
         assembled = assemble_entries(entry1, entry2)
        output_assembled(assembled, output)
      elsif @options[:merge_unassembled]
        output_merged(entry1, entry2, output)
      elsif @options[:allow_unassembled]
        output_entries(entry1, entry2, output)
      else
        @unassembled += 1
      end
    end

    # Given a pair of records convert these into sequence entries and
    # reverse-complment if need be.
    #
    # @param record1 [Hash] Record1.
    # @param record2 [Hash] Record2.
    #
    # @return [Array] Returns a tuple of sequence entries.
    def records2entries(record1, record2)
      entry1 = BioPieces::Seq.new_bp(record1)
      entry2 = BioPieces::Seq.new_bp(record2)
      entry1.type = :dna
      entry2.type = :dna
      entry2.reverse!.complement! if @options[:reverse_complement]

      @sequences_in += 2
      @residues_in  += entry1.length + entry2.length

      [entry1, entry2]
    end

    # Determines if an overlap between two given entries is possible considering
    # the minimum overlap length.
    #
    # @param entry1      [BioPieces::Seq] Sequence entry1.
    # @param entry2      [BioPieces::Seq] Sequence entry2.
    # @param overlap_min [Integer]        Minimum overlap.
    #
    # @return [Boolean] True if overlap possible otherwise false.
    def overlap_possible?(entry1, entry2, overlap_min)
      entry1.length >= overlap_min && entry2.length >= overlap_min
    end

    # Assemble a pair of given entries if possible and return an assembled
    # entry, or nil the entries could not be assembled.
    #
    # @param entry1 [BioPieces::Seq] Sequence entry1.
    # @param entry2 [BioPieces::Seq] Sequence entry2.
    #
    # @return [BioPieces::Seq, nil] Returns Seq entry or nil.
    def assemble_entries(entry1, entry2)
      BioPieces::Assemble.pair(
        entry1,
        entry2,
        mismatches_max: @options[:mismatch_percent],
        overlap_min:    @options[:overlap_min],
        overlap_max:    @options[:overlap_max]
      )
    end

    # Output assembled pairs to the output stream.
    #
    # @param assembled [BioPieces::Seq] Assembled sequence entry.
    # @param output [Enumerator::Yielder] Output stream.
    def output_assembled(assembled, output)
      output << assembled2record(assembled)

      @assembled     += 1
      @records_out   += 1
      @sequences_out += 1
      @residues_out  += assembled.length
    end

    # Convert a sequence entry to a BioPiece record with hamming distance and
    # overlap length from the entry's seq_name.
    #
    # @param assembled [BioPieces::Seq] Merged sequence entry.
    #
    # @return [Hash] BioPieces record.
    def assembled2record(assembled)
      new_record = assembled.to_bp

      if assembled.seq_name =~ /overlap=(\d+):hamming=(\d+)$/
        overlap = Regexp.last_match(1).to_i
        hamming = Regexp.last_match(2).to_i
        @overlap_sum += overlap
        @hamming_sum += hamming
        new_record[:OVERLAP_LEN]  = overlap
        new_record[:HAMMING_DIST] = hamming
      end

      new_record
    end

    # Merge and output entries to the stream.
    #
    # @param entry1 [BioPieces::Seq] Entry1.
    # @param entry2 [BioPieces::Seq] Entry2.
    # @param output [Enumerator::Yielder] Output stream.
    def output_merged(entry1, entry2, output)
      entry1 << entry2

      output << entry2record(entry1)

      @unassembled   += 1
      @sequences_out += 1
      @residues_out  += entry1.length
      @records_out   += 1
    end

    # Output unassembled entries to the stream.
    #
    # @param entry1 [BioPieces::Seq] Entry1.
    # @param entry2 [BioPieces::Seq] Entry2.
    # @param output [Enumerator::Yielder] Output stream.
    def output_entries(entry1, entry2, output)
      output << entry2record(entry1)
      output << entry2record(entry2)

      @unassembled   += 2
      @sequences_out += 2
      @residues_out  += entry1.length + entry2.length
      @records_out   += 2
    end

    # Converts a sequence entry to a BioPeice record.
    #
    # @param entry [BioPieces::Seq] Sequence entry.
    #
    # @return [Hash] Biopieces record.
    def entry2record(entry)
      record = entry.to_bp
      record[:OVERLAP_LEN]  = 0
      record[:HAMMING_DIST] = entry.length
      record
    end

    # Calculate additional status values.
    #
    # @param status [Hash] Status hash.
    def calc_status(status)
      assembled_percent = (100 * 2 * @assembled.to_f / @sequences_in).round(2)
      status[:assembled_percent] = assembled_percent
      status[:overlap_mean]      = (@overlap_sum.to_f / @records_out).round(2)
      status[:hamming_dist_mean] = (@hamming_sum.to_f / @records_out).round(2)
    end
  end
end
