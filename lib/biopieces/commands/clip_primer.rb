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
  # == Clip sequences in the stream at a specified primer location.
  #
  # +clip_primer+ locates a specified +primer+ in sequences in the stream and
  # clips the sequence after the match if the +direction+ is forward or before
  # the match is the +direction+ is reverse. Using the +reverse_complement+
  # option the primer sequence will be reverse complemented prior to matching.
  # Using the +search_distance+ option will limit the primer search to the
  # beginning of the sequence if the +direction+ is forward and to the end if
  # the direction is +reverse+.
  #
  # Non-perfect matching can be allowed by setting the allowed
  # +mismatch_percent+, +insertion_percent+ and +deletion_percent+.
  #
  # The following keys are added to clipped records:
  #
  # * CLIP_PRIMER_DIR - Direction of clip.
  # * CLIP_PRIMER_POS - Sequence position of clip (0 based).
  # * CLIP_PRIMER_LEN - Length of clip match.
  # * CLIP_PRIMER_PAT - Clip match pattern.
  # == Usage
  #
  #    clip_primer(<primer: <string>>, <direction: <:forward|:reverse>
  #                [, reverse_complement: <bool>[, search_distance: <uint>
  #                [, mismatch_percent: <uint>
  #                [, insertion_percent: <uint>
  #                [, deletion_percent: <uint>]]]]])
  #
  # === Options
  #
  # * primer: <string>               - Primer sequence to search for.
  # * direction: <:forward|:reverse> - Clip direction.
  # * reverse_complement: <bool>     -
  #   Reverse complement primer (default=false).
  # * search_distance: <uint>        -
  #   Search distance from forward or reverse end.
  # * mismatch_percent: <unit>       - Allowed percent mismatches (default=0).
  # * insertion_percent: <unit>      - Allowed percent insertions (default=0).
  # * deletion_percent: <unit>       - Allowed percent mismatches (default=0).
  #
  # == Examples
  #
  # Consider the following FASTA entry in the file test.fq:
  #
  #    >test
  #    actgactgaTCGTATGCCGTCTTCTGCTTactacgt
  #
  # To clip this sequence in the forward direction with the primer
  # 'TGACTACGACTACGACTACT' do:
  #
  #    BP.new.
  #    read_fasta(input: "test.fna").
  #    clip_primer(primer: "TGACTACGACTACGACTACT", direction: :forward).
  #    dump.
  #    run
  #
  #    {:SEQ_NAME=>"test",
  #     :SEQ=>"actacgt",
  #     :SEQ_LEN=>7,
  #     :CLIP_PRIMER_DIR=>"FORWARD",
  #     :CLIP_PRIMER_POS=>9,
  #     :CLIP_PRIMER_LEN=>20,
  #     :CLIP_PRIMER_PAT=>"TGACTACGACTACGACTACT"}
  #
  # Or in the reverse direction:
  #
  #    BP.new.
  #    read_fasta(input: "test.fna").
  #    clip_primer(primer: "TGACTACGACTACGACTACT", direction: :reverse).
  #    dump.
  #    run
  #
  #    {:SEQ_NAME=>"test",
  #     :SEQ=>"actgactga",
  #     :SEQ_LEN=>9,
  #     :CLIP_PRIMER_DIR=>"REVERSE",
  #     :CLIP_PRIMER_POS=>9,
  #     :CLIP_PRIMER_LEN=>20,
  #     :CLIP_PRIMER_PAT=>"TGACTACGACTACGACTACT"}
  # rubocop:disable ClassLength
  class ClipPrimer
    require 'biopieces/helpers/options_helper'

    extend OptionsHelper
    include OptionsHelper

    # Check options and return command lambda.
    #
    # @param options [Hash] Options hash.
    # @option options [String] :primer Primer used for matching.
    # @option options [Symbol] :direction Direction for clipping.
    # @option options [Integer] :search_distance Search distance.
    # @option options [Boolean] :reverse_complment
    # @option options [Integer] :mismatch_percent
    # @option options [Integer] :insertion_percent
    # @option options [Integer] :deletion_percent
    #   Flag indicating that primer should be reverse complemented.
    #
    # @return [Proc] Command lambda.
    def self.lmb(options)
      options_allowed(options, :primer, :direction, :search_distance,
                      :reverse_complement, :mismatch_percent,
                      :insertion_percent, :deletion_percent)
      options_required(options, :primer, :direction)
      options_allowed_values(options, direction: [:forward, :reverse])
      options_allowed_values(options, reverse_complement: [true, false])
      options_assert(options, ':search_distance   >  0')
      options_assert(options, ':mismatch_percent  >= 0')
      options_assert(options, ':insertion_percent >= 0')
      options_assert(options, ':deletion_percent  >= 0')

      defaults(options)

      new(options).lmb
    end

    # Set default option values.
    #
    # @param options [Hash] Options hash.
    # @option options [Integer] :mismatch_percent
    # @option options [Integer] :insertion_percent
    # @option options [Integer] :deletion_percent
    def self.defaults(options)
      options[:mismatch_percent]  ||= 0
      options[:insertion_percent] ||= 0
      options[:deletion_percent]  ||= 0
    end

    # Constructor for ClipPrimer.
    #
    # @param options [Hash] Options hash.
    # @option options [String] :primer Primer used for matching.
    # @option options [Symbol] :direction Direction for clipping.
    # @option options [Integer] :search_distance Search distance.
    # @option options [Boolean] :reverse_complment
    #   Flag indicating that primer should be reverse complemented.
    #
    # @return [ClipPrimer] Returns ClipPrimer instance.
    def initialize(options)
      @options        = options
      @records_in     = 0
      @records_out    = 0
      @sequences_in   = 0
      @sequences_out  = 0
      @pattern_hits   = 0
      @pattern_misses = 0
      @residues_in    = 0
      @residues_out   = 0
      @primer         = primer
      @mis            = calc_mis
      @ins            = calc_ins
      @del            = calc_del
    end

    # Lambda for ClipPrimer command.
    #
    # @return [Proc] Lambda for command.
    def lmb
      lambda do |input, output, status|
        input.each do |record|
          @records_in += 1

          clip_primer(record) if record[:SEQ] && record[:SEQ].length > 0

          output << record
          @records_out += 1
        end

        assign_status(status)
      end
    end

    private

    # Calculate the mismatch percentage.
    #
    # @return [Float] Mismatch percentage.
    def calc_mis
      (@primer.length * @options[:mismatch_percent]  * 0.01).round
    end

    # Calculate the insertion percentage.
    #
    # @return [Float] Insertion percentage.
    def calc_ins
      (@primer.length * @options[:insertion_percent] * 0.01).round
    end

    # Calculate the deletion percentage.
    #
    # @return [Float] Deletion percentage.
    def calc_del
      (@primer.length * @options[:deletion_percent]  * 0.01).round
    end

    # Reset any previous clip_primer results from record.
    #
    # @param record [Hash] BioPiece record to reset.
    def reset(record)
      record.delete :CLIP_PRIMER_DIR
      record.delete :CLIP_PRIMER_POS
      record.delete :CLIP_PRIMER_LEN
      record.delete :CLIP_PRIMER_PAT
    end

    def clip_primer(record)
      reset(record)
      entry = BioPieces::Seq.new_bp(record)

      @sequences_in += 1
      @residues_in  += entry.length

      case @options[:direction]
      when :forward then clip_primer_forward(record, entry)
      when :reverse then clip_primer_reverse(record, entry)
      else
        fail RunTimeError, 'This should never happen'
      end

      @sequences_out += 1
      @residues_out  += entry.length
    end

    # Clip forward primer from entry and save clip information
    # in record.
    #
    # @param record [Hash] BioPiece record with sequence.
    # @param entry [BioPieces::Seq] Sequence entry.
    def clip_primer_forward(record, entry)
      if (match = entry.patmatch(@primer, start: 0, stop: stop(entry),
                                          max_mismatches: @mis,
                                          max_insertions: @ins,
                                          max_deletions:  @del))
        @pattern_hits += 1

        if match.pos + match.length <= entry.length
          entry = entry[match.pos + match.length..-1]

          merge_record_entry(record, entry, match, 'FORWARD')
        end
      else
        @pattern_misses += 1
      end
    end

    # Calculate the match stop position.
    #
    # @param entry [BioPieces::Seq] Sequence entry.
    #
    # @return [Integer] Match stop position.
    def stop(entry)
      stop = search_distance(entry) - @primer.length
      stop = 0 if stop < 0
      stop
    end

    # Clip reverse primer from entry and save clip information
    # in record.
    #
    # @param record [Hash] BioPiece record with sequence.
    # @param entry [BioPieces::Seq] Sequence entry.
    def clip_primer_reverse(record, entry)
      start = entry.length - search_distance(entry)

      if (match = entry.patmatch(@primer, start: start,
                                          stop: entry.length - 1,
                                          max_mismatches: @mis,
                                          max_insertions: @ins,
                                          max_deletions:  @del))
        @pattern_hits += 1

        entry = entry[0...match.pos]

        merge_record_entry(record, entry, match, 'REVERSE')
      else
        @pattern_misses += 1
      end
    end

    # Merge entry and match info to record.
    #
    # @param record [Hash] BioPieces record.
    # @param entry [BioPieces::Seq] Sequence entry.
    # @param match [BioPieces::Match] Match object.
    # @param type [String] Type.
    def merge_record_entry(record, entry, match, type)
      record.merge!(entry.to_bp)
      record[:CLIP_PRIMER_DIR] = type
      record[:CLIP_PRIMER_POS] = match.pos
      record[:CLIP_PRIMER_LEN] = match.length
      record[:CLIP_PRIMER_PAT] = match.match
    end

    # Return the primer sequence and reverse-complement according to options.
    #
    # @return [String] Primer sequence.
    def primer
      if @options[:reverse_complement]
        Seq.new(seq: @options[:primer], type: :dna).reverse.complement.seq
      else
        @options[:primer]
      end
    end

    # Determine the search distance from the search_distance in the options or
    # as the sequence length.
    #
    # @param entry [BioPieces::Seq] Sequence entry.
    #
    # @return [Integer] Search distance.
    def search_distance(entry)
      if @options[:search_distance] && @options[:search_distance] < entry.length
        @options[:search_distance]
      else
        entry.length
      end
    end

    # Assign status values to the status hash.
    #
    # @param status [Hash] Status hash
    def assign_status(status)
      status[:records_in]     = @records_in
      status[:records_out]    = @records_out
      status[:sequences_in]   = @sequences_in
      status[:sequences_out]  = @sequences_out
      status[:pattern_hits]   = @pattern_hits
      status[:pattern_misses] = @pattern_misses
      status[:residues_in]    = @residues_in
      status[:residues_out]   = @residues_out
    end
  end
end
