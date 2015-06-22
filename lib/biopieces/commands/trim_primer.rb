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
  # == Trim sequence ends in the stream matching a specified primer.
  #
  # +trim_primer+ can trim full or partial primer sequence from sequence ends.
  # This is done by matching the primer at the end specified by the +direction+
  # option:
  #
  # Forward clip:
  #     sequence       ATCGACTGCATCACGACG
  #     primer    CATGAATCGA
  #     result              CTGCATCACGACG
  #
  # Reverse clip:
  #     sequence  ATCGACTGCATCACGACG
  #     primer                  GACGATAGCA
  #     result    ATCGACTGCATCAC
  #
  # The primer sequence can be reverse complemented using the
  # +reverse_complement+ option. Also, a minimum overlap for trimming can be
  # specified using the +overlap_min+ option (default=1).
  #
  # Non-perfect matching can be allowed by setting the allowed
  # +mismatch_percent+, +insertion_percent+ and +deletion_percent+.
  #
  # The following keys are added to clipped records:
  #
  # * TRIM_PRIMER_DIR - Direction of clip.
  # * TRIM_PRIMER_POS - Sequence position of clip (0 based).
  # * TRIM_PRIMER_LEN - Length of clip match.
  # * TRIM_PRIMER_PAT - Clip match pattern.
  # == Usage
  #
  #    trim_primer(<primer: <string>>, <direction: <:forward|:reverse>
  #                [, reverse_complement: <bool>[, overlap_min: <uint>
  #                [, mismatch_percent: <uint>
  #                [, insertion_percent: <uint>
  #                [, deletion_percent: <uint>]]]]])
  #
  # === Options
  #
  # * primer: <string>               - Primer sequence to search for.
  # * direction: <:forward|:reverse> - Clip direction.
  # * reverse_complement: <bool>     - Reverse complement primer (default=false)
  # * overlap_min: <uint>            - Minimum primer length used (default=1)
  # * mismatch_percent: <unit>       - Allowed percent mismatches (default=0)
  # * insertion_percent: <unit>      - Allowed percent insertions (default=0)
  # * deletion_percent: <unit>       - Allowed percent mismatches (default=0)
  #
  # == Examples
  #
  # Consider the following FASTA entry in the file test.fna:
  #
  #     >test
  #     ACTGACTGATGACTACGACTACGACTACTACTACGT
  #
  # The forward end can be trimmed like this:
  #
  #     BP.new.
  #     read_fasta(input: "test.fna").
  #     trim_primer(primer: "ATAGAACTGAC", direction: :forward).
  #     dump.
  #     run
  #
  #     {:SEQ_NAME=>"test",
  #      :SEQ=>"TGATGACTACGACTACGACTACTACTACGT",
  #      :SEQ_LEN=>30,
  #      :TRIM_PRIMER_DIR=>"FORWARD",
  #      :TRIM_PRIMER_POS=>0,
  #      :TRIM_PRIMER_LEN=>6,
  #      :TRIM_PRIMER_PAT=>"ACTGAC"}
  #
  # And trimming a reverse primer:
  #
  #     BP.new.
  #     read_fasta(input: "test.fna").
  #     trim_primer(primer: "ACTACGTGCGGAT", direction: :reverse).
  #     dump.
  #     run
  #
  #     {:SEQ_NAME=>"test",
  #      :SEQ=>"ACTGACTGATGACTACGACTACGACTACT",
  #      :SEQ_LEN=>29,
  #      :TRIM_PRIMER_DIR=>"REVERSE",
  #      :TRIM_PRIMER_POS=>29,
  #      :TRIM_PRIMER_LEN=>7,
  #      :TRIM_PRIMER_PAT=>"ACTACGT"}
  #
  # rubocop: disable ClassLength
  class TrimPrimer
    STATS = %i(records_in records_out sequences_in sequences_out pattern_hits
               pattern_misses residues_in residues_out)

    # Constructor for TrimPrimer.
    #
    # @param options [Hash] Options hash.
    # @option options [String]   :primer
    # @option options [Symbol]   :direction
    # @option options [Boolean]  :overlap_min
    # @option options [Boolean]  :reverse_complement
    # @option options [Integer]  :mismatch_percent
    # @option options [Ingetger] :insertion_percent
    # @option options [Integer]  :deletion_percent
    #
    # @return [TrimPrimer] Class instance.
    def initialize(options)
      @options = options
      @options[:overlap_min]       ||= 1
      @options[:mismatch_percent]  ||= 0
      @options[:insertion_percent] ||= 0
      @options[:deletion_percent]  ||= 0
      @pattern = pattern
      @hit     = false

      check_options
      status_init(STATS)
    end

    # Return command lambda for trim_primer.
    #
    # @return [Proc] Command lambda.
    def lmb
      lambda do |input, output, status|
        status_init(status, STATS)

        input.each do |record|
          @status[:records_in] += 1

          if record[:SEQ] && record[:SEQ].length > 0
            @status[:sequences_in] += 1

            case @options[:direction]
            when :forward then trim_forward(record)
            when :reverse then trim_reverse(record)
            end
          end

          output << record

          @status[:records_out] += 1
        end
      end
    end

    private

    # Check options.
    def check_options
      options_allowed(@options, :primer, :direction, :overlap_min,
                      :reverse_complement, :mismatch_percent,
                      :insertion_percent, :deletion_percent)
      options_required(@options, :primer, :direction)
      options_allowed_values(@options, direction: [:forward, :reverse])
      options_allowed_values(@options, reverse_complement: [true, false])
      options_assert(@options, ':overlap_min        >  0')
      options_assert(@options, ':mismatch_percent  >= 0')
      options_assert(@options, ':insertion_percent >= 0')
      options_assert(@options, ':deletion_percent  >= 0')
    end

    # Determine the pattern from the sequence and reverse complement if need be.
    def pattern
      if @options[:reverse_complement]
        Seq.new(seq: @options[:primer], type: :dna).reverse.complement.seq
      else
        @options[:primer]
      end
    end

    # Trim record with sequence in the forward direction.
    #
    # @param record [Hash] BioPieces record
    def trim_forward(record)
      entry = BioPieces::Seq.new_bp(record)

      @status[:residues_in]  += entry.length

      while @pattern.length >= @options[:overlap_min]
        if (match = match_forward(entry))
          merge_forward(record, entry, match)
          @hit = true
          break
        end

        @pattern = @pattern[1...@pattern.length]
      end

      @hit ? @pattern_hits += 1 : @pattern_misses += 1
    end

    # Search a given entry and return match data.
    #
    # @param entry [BioPieces::Seq] Sequence entry.
    #
    # @return [BioPieces::Seq::Match,nil] Match result.
    def match_forward(entry)
      match_opt         = match_options(@pattern.length)
      match_opt[:start] = 0
      match_opt[:stop]  = 0

      entry.patmatch(@pattern, match_opt)
    end

    # Use given match data to extract subsequence from given entry and merge to
    # the given record.
    #
    # @param record [Hash] BioPieces record
    # @param entry [BioPieces::Seq] Sequence entry.
    # @param match [BioPieces::Seq::Match] Match data.
    def merge_forward(record, entry, match)
      entry = entry[match.pos + match.length..-1]

      record.merge!(entry.to_bp)
      record[:TRIM_PRIMER_DIR] = 'FORWARD'
      record[:TRIM_PRIMER_POS] = match.pos
      record[:TRIM_PRIMER_LEN] = match.length
      record[:TRIM_PRIMER_PAT] = match.match
    end

    # Trim record with sequence in the reverse direction.
    #
    # @param record [Hash] BioPieces record
    def trim_reverse(record)
      entry = BioPieces::Seq.new_bp(record)

      @status[:residues_in]  += entry.length

      while @pattern.length >= @options[:overlap_min]
        if (match = match_reverse(entry))
          merge_reverse(record, entry, match)
          @hit = true
          break
        end

        @pattern = @pattern[0...@pattern.length - 1]
      end

      @hit ? @pattern_hits += 1 : @pattern_misses += 1
    end

    # Search a given entry and return match data.
    #
    # @param entry [BioPieces::Seq] Sequence entry.
    #
    # @return [BioPieces::Seq::Match,nil] Match result.
    def match_reverse(entry)
      match_opt = match_options(@pattern.length)

      start = entry.length - @pattern.length
      start = 0 if start < 0

      match_opt[:start] = start

      entry.patmatch(@pattern, match_opt)
    end

    # Use given match data to extract subsequence from given entry and merge to
    # the given record.
    #
    # @param record [Hash] BioPieces record
    # @param entry [BioPieces::Seq] Sequence entry.
    # @param match [BioPieces::Seq::Match] Match data.
    def merge_reverse(record, entry, match)
      entry = entry[0...match.pos]

      record.merge!(entry.to_bp)
      record[:TRIM_PRIMER_DIR] = 'REVERSE'
      record[:TRIM_PRIMER_POS] = match.pos
      record[:TRIM_PRIMER_LEN] = match.length
      record[:TRIM_PRIMER_PAT] = match.match
    end

    # Calculate from the given pattern lenght the absolue mismatches, insertions
    # and deletions allowed and return a hash with these values.
    #
    # @param length [Integer] Pattern length.
    #
    # @return [Hash] Match options hash.
    def match_options(length)
      mis = (length * @options[:mismatch_percent]  * 0.01).round
      ins = (length * @options[:insertion_percent] * 0.01).round
      del = (length * @options[:deletion_percent]  * 0.01).round

      {max_mismatches: mis,
       max_insertions: ins,
       max_deletions:  del}
    end
  end
end
