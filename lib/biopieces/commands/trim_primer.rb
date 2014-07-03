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
    # == Clip sequences in the stream at a specified primer location.
    # 
    # +trim_primer+ locates a specified +primer+ in sequences in the stream and
    # clips the sequence after the match if the +direction+ is forward or 
    # before the match is the +direction+ is reverse. Using the 
    # +reverse_complement+ option the primer sequence will be reverse
    # complemented prior to matching. Using the +search_distance+ option will
    # limit the primer search to the beginning of the sequence if the
    # +direction+ is forward and to the end if the direction is +reverse+.
    #
    # Non-perfect matching can be allowed by setting the allowed
    # +mismatch_percent+, +insertion_percent+ and +deletion_percent+.
    #
    # The following keys are added to clipped records:
    #
    # * PRIMER_CLIP_DIRECTION - Direction of clip.
    # * PRIMER_CLIP_POS       - Sequence position of clip (0 based).
    # * PRIMER_CLIP_LEN       - Length of clip match.
    # * PRIMER_CLIP_PAT       - Clip match pattern.
    # == Usage
    # 
    #    trim_primer(<primer: <string>>, <direction: <:forward|:reverse>
    #                [, reverse_complement: <bool>[, length_min: <uint>
    #                [, mismatch_percent: <uint>
    #                [, insertion_percent: <uint>
    #                [, deletion_percent: <uint>]]]]]) 
    #
    # === Options
    #
    # * primer: <string>               - Primer sequence to search for.
    # * direction: <:forward|:reverse> - Clip direction.
    # * reverse_complement: <bool>     - Reverse complement primer (default=false).
    # * length_min: <uint>             - Minimum primer length used (default=1).
    # * mismatch_percent: <unit>       - Allowed percent mismatches (default=0).
    # * insertion_percent: <unit>      - Allowed percent insertions (default=0).
    # * deletion_percent: <unit>       - Allowed percent mismatches (default=0).
    # 
    # == Examples
    # 
    # Consider the following FASTA entry in the file test.fq:
    def trim_primer(options = {})
      options_orig = options.dup
      @options = options
      options_allowed :primer, :direction, :length_min, :reverse_complement,
                      :mismatch_percent, :insertion_percent, :deletion_percent
      options_required :primer, :direction
      options_allowed_values direction: [:forward, :reverse]
      options_allowed_values reverse_complement: [true, false]
      options_assert ":length_min        >  0"
      options_assert ":mismatch_percent  >= 0"
      options_assert ":insertion_percent >= 0"
      options_assert ":deletion_percent  >= 0"

      @options[:length_min]        ||= 1
      @options[:mismatch_percent]  ||= 0
      @options[:insertion_percent] ||= 0
      @options[:deletion_percent]  ||= 0

      if options[:reverse_complement]
        primer = Seq.new(seq: options[:primer], type: :dna).reverse.complement.seq
      else
        primer = options[:primer]
      end

      lmb = lambda do |input, output, run_options|
        status_track(input, output, run_options) do
          run_options[:status][:sequences_in]    = 0
          run_options[:status][:sequences_out]   = 0
          run_options[:status][:pattern_hits]    = 0
          run_options[:status][:pattern_missess] = 0
          run_options[:status][:residues_in]     = 0
          run_options[:status][:residues_out]    = 0

          input.each do |record|
            if record[:SEQ]
              entry = BioPieces::Seq.new_bp(record)
              pat   = options[:primer]
              min   = options[:length_min]

              run_options[:status][:sequences_in] += 1
              run_options[:status][:residues_in]  += entry.length

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

                    break
                  end

                  pat = pat[1 ... pat.length]
                end
              else
                raise RunTimeError, "This should never happen"
              end

              run_options[:status][:sequences_out] += 1
              run_options[:status][:residues_out]  += entry.length
            end

            output.write record
          end
        end
      end

      add(__method__, options, options_orig, lmb)

      self
    end
  end
end

