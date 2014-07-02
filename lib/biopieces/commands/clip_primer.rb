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
    def percent2real(length, percent)
      (length * percent * 0.01).round
    end

    # == Trim sequence ends removing residues with a low quality score.
    # 
    # +clip_primer+ removes subquality residues from the ends of sequences in the
    # stream based on quality SCORES in a FASTQ type quality score string.
    # Trimming progresses until a stretch, specified with the +length_min+
    # option, is found thus preventing premature termination of the trimming
    # by e.g. a single good quality residue at the end. It is possible, using
    # the +mode+ option to indicate if the sequence should be trimmed from the
    # left or right end or both (default=:both).
    #
    # == Usage
    # 
    #    clip_primer([quality_min: <uint>[, length_min: <uint>[, mode: <:left|:right|:both>]]])
    #
    # === Options
    #
    # * quality_min: <uint> - Minimum quality (default=20).
    # * length_min: <uint>  - Minimum stretch length (default=3).
    # * mode: <string>      - Trim mode :left|:right|:both (default=:both).
    # 
    # == Examples
    # 
    # Consider the following FASTQ entry in the file test.fq:
    # 
    #    @test
    #    gatcgatcgtacgagcagcatctgacgtatcgatcgttgattagttgctagctatgcagtctacgacgagcatgctagctag
    #    +
    #    @ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghhgfedcba`_^]\[ZYXWVUTSRQPONMLKJIHGFEDChhh
    def clip_primer(options = {})
      options_orig = options.dup
      @options = options
      options_allowed :primer, :direction, :search_distance, :reverse_complement,
                      :mismatch_percent, :insertion_percent, :deletion_percent
      options_required :primer, :direction
      options_allowed_values direction: [:forward, :reverse]
      options_allowed_values reverse_complement: [true, false]
      options_assert ":search_distance > 0"
      options_assert ":mismatch_percent > 0"
      options_assert ":insertion_percent > 0"
      options_assert ":deletion_percent  > 0"

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

          mis = percent2real(primer.length, options[:mismatch_percent])
          ins = percent2real(primer.length, options[:insertion_percent])
          del = percent2real(primer.length, options[:deletion_percent])

          input.each do |record|
            if record[:SEQ]
              entry = BioPieces::Seq.new_bp(record)
              dist  = options[:search_distance] || entry.length  

              run_options[:status][:sequences_in] += 1
              run_options[:status][:residues_in]  += entry.length

              case options[:direction]
              when :reverse
                if match = entry.patmatch(primer, start: entry.length - dist, stop: entry.length - 1, max_mismatches: mis, max_insertions: ins, max_deletions: del)
                  run_options[:status][:pattern_hits] += 1

                  record[:PRIMER_CLIP_DIRECTION] = 'REVERSE'
                  record[:PRIMER_CLIP_POS]       = match.pos
                  record[:PRIMER_CLIP_LEN]       = match.length
                  record[:PRIMER_CLIP_PAT]       = match.match

                  entry = entry[0 ... match.pos]
                else
                  run_options[:status][:pattern_missess] += 1
                end
              when :forward
                if match = entry.patmatch(primer, start: 0, stop: dist - 1, max_mismatches: mis, max_insertions: ins, max_deletions: del)
                  run_options[:status][:pattern_hits] += 1

                  record[:PRIMER_CLIP_DIRECTION] = 'FORWARD'
                  record[:PRIMER_CLIP_POS]       = match.pos
                  record[:PRIMER_CLIP_LEN]       = match.length
                  record[:PRIMER_CLIP_PAT]       = match.match

                  if match.pos + match.length < entry.length
                    entry = entry[match.pos + match.length .. -1]
                  end
                else
                  run_options[:status][:pattern_missess] += 1
                end
              else
                raise RunTimeError, "This should never happen"
              end

              run_options[:status][:sequences_out] += 1
              run_options[:status][:residues_out]  += entry.length
            end

            output.write entry.to_bp.merge(record)
          end
        end
      end

      add(__method__, options, options_orig, lmb)

      self
    end
  end
end

