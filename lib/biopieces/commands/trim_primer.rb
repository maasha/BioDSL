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
    # == Trim sequence ends in the stream matching a specified primer.
    # 
    # +trim_primer+ can trim full or partial primer sequence from sequence
    # ends. This is done by matching the primer at the end specified by the
    # +direction+ option:
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
    # * reverse_complement: <bool>     - Reverse complement primer (default=false).
    # * overlap_min: <uint>            - Minimum primer length used (default=1).
    # * mismatch_percent: <unit>       - Allowed percent mismatches (default=0).
    # * insertion_percent: <unit>      - Allowed percent insertions (default=0).
    # * deletion_percent: <unit>       - Allowed percent mismatches (default=0).
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
    #     BP.new.read_fasta(input: "test.fna").trim_primer(primer: "ATAGAACTGAC", direction: :forward).dump.run
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
    #     BP.new.read_fasta(input: "test.fna").trim_primer(primer: "ACTACGTGCGGAT", direction: :reverse).dump.run
    #     {:SEQ_NAME=>"test",
    #      :SEQ=>"ACTGACTGATGACTACGACTACGACTACT",
    #      :SEQ_LEN=>29,
    #      :TRIM_PRIMER_DIR=>"REVERSE",
    #      :TRIM_PRIMER_POS=>29,
    #      :TRIM_PRIMER_LEN=>7,
    #      :TRIM_PRIMER_PAT=>"ACTACGT"}
    def trim_primer(options = {})
      options_allowed(options, :primer, :direction, :overlap_min, :reverse_complement,
                      :mismatch_percent, :insertion_percent, :deletion_percent)
      options_required(options, :primer, :direction)
      options_allowed_values(options, direction: [:forward, :reverse])
      options_allowed_values(options, reverse_complement: [true, false])
      options_assert(options, ":overlap_min        >  0")
      options_assert(options, ":mismatch_percent  >= 0")
      options_assert(options, ":insertion_percent >= 0")
      options_assert(options, ":deletion_percent  >= 0")

      options[:overlap_min]       ||= 1
      options[:mismatch_percent]  ||= 0
      options[:insertion_percent] ||= 0
      options[:deletion_percent]  ||= 0

      if options[:reverse_complement]
        primer = Seq.new(seq: options[:primer], type: :dna).reverse.complement.seq
      else
        primer = options[:primer]
      end

      lmb = lambda do |input, output, status|
        status_track(status) do
          status[:sequences_in]   = 0
          status[:sequences_out]  = 0
          status[:pattern_hits]   = 0
          status[:pattern_misses] = 0
          status[:residues_in]    = 0
          status[:residues_out]   = 0

          input.each do |record|
            if record[:SEQ] and record[:SEQ].length > 0
              miss  = true
              entry = BioPieces::Seq.new_bp(record)
              pat   = primer
              min   = options[:overlap_min]

              status[:sequences_in] += 1
              status[:residues_in]  += entry.length

              case options[:direction]
              when :reverse
                while pat.length >= min
                  mis = (pat.length * options[:mismatch_percent]  * 0.01).round
                  ins = (pat.length * options[:insertion_percent] * 0.01).round
                  del = (pat.length * options[:deletion_percent]  * 0.01).round

                  if match = entry.patmatch(pat, start: entry.length - pat.length, max_mismatches: mis, max_insertions: ins, max_deletions: del)
                    run_options[:status][:pattern_hits] += 1

                    entry = entry[0 ... match.pos]

                    record = record.merge(entry.to_bp)
                    record[:TRIM_PRIMER_DIR] = "REVERSE" 
                    record[:TRIM_PRIMER_POS] = match.pos
                    record[:TRIM_PRIMER_LEN] = match.length
                    record[:TRIM_PRIMER_PAT] = match.match

                    miss = false
                    break
                  end

                  pat = pat[0 ... pat.length - 1]
                end
              when :forward
                while pat.length >= min
                  mis = (pat.length * options[:mismatch_percent]  * 0.01).round
                  ins = (pat.length * options[:insertion_percent] * 0.01).round
                  del = (pat.length * options[:deletion_percent]  * 0.01).round

                  if match = entry.patmatch(pat, start: 0, stop: 0, max_mismatches: mis, max_insertions: ins, max_deletions: del)
                    run_options[:status][:pattern_hits] += 1

                    entry = entry[match.pos + match.length .. -1]

                    record = record.merge(entry.to_bp)
                    record[:TRIM_PRIMER_DIR] = "FORWARD" 
                    record[:TRIM_PRIMER_POS] = match.pos
                    record[:TRIM_PRIMER_LEN] = match.length
                    record[:TRIM_PRIMER_PAT] = match.match

                    miss = false
                    break
                  end

                  pat = pat[1 ... pat.length]
                end
              else
                raise RunTimeError, "This should never happen"
              end

              status[:sequences_out]  += 1
              status[:residues_out]   += entry.length
              status[:pattern_misses] += 1 if miss
            end

            output << record
          end
        end
      end

      @commands << BioPieces::Pipeline::Command.new(__method__, options, lmb)

      self
    end
  end
end

