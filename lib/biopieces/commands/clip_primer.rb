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
      options_allowed :forward, :reverse, :forward_rc, :reverse_rc, :forward_length,
                      :reverse_length, :mismatch_percent, :insertion_percent, :deletion_percent
      options_allowed_values forward_rc: [true, false]
      options_allowed_values reverse_rc: [true, false]
      options_required_single :forward, :reverse
      options_assert ":forward_length > 0"
      options_assert ":reverse_length > 0"
      options_assert ":mismatch_percent > 0"
      options_assert ":insertion_percent > 0"
      options_assert ":deletion_percent  > 0"

      @options[:mismatch_percent] ||= 0
      @options[:insertion_percent] ||= 0
      @options[:deletion_percent]  ||= 0

      if options[:forward_rc]
        @options[:forward] = Seq.new(seq: options[:forward], type: :dna).reverse.complement.seq
      end

      if options[:reverse_rc]
        @options[:reverse] = Seq.new(seq: options[:reverse], type: :dna).reverse.complement.seq
      end

      lmb = lambda do |input, output, run_options|
        status_track(input, output, run_options) do

          if options[:forward]
            options[:forward_length] = options[:forward].length unless options[:forward_length]

            if options[:forward_length] > options[:forward].length
              raise ArgumentError, "forward_length > forward adaptor (#{options[:forward_length]} > #{options[:forward].length})" 
            end

            fmis = percent2real(options[:forward].length, options[:mismatch_percent])
            fins = percent2real(options[:forward].length, options[:insertion_percent])
            fdel = percent2real(options[:forward].length, options[:deletion_percent])
          end

          if options[:reverse]
            options[:reverse_length] = options[:reverse].length unless options[:reverse_length]
          
            if options[:reverse_length] > options[:reverse].length
              raise ArgumentError, "reverse_length > reverse adaptor (#{options[:reverse_length]} > #{options[:reverse].length})"
            end
          
            rmis = percent2real(options[:reverse].length, options[:mismatch_percent])
            rins = percent2real(options[:reverse].length, options[:insertion_percent])
            rdel = percent2real(options[:reverse].length, options[:deletion_percent])
          end

          run_options[:status][:sequences_in]  = 0
          run_options[:status][:sequences_out] = 0
          run_options[:status][:residues_in]   = 0
          run_options[:status][:residues_out]  = 0

          input.each do |record|
            if record[:SEQ]
              entry = BioPieces::Seq.new_bp(record)

              run_options[:status][:sequences_in] += 1
              run_options[:status][:residues_in]  += entry.length

              if options[:forward] and record[:SEQ].length >= options[:forward].length
                if fmatch = entry.patmatch(options[:forward], max_mismatches: fmis, max_insertions: fins, max_deletions: fdel)
                elsif options[:forward_length] < options[:forward].length
                  len = options[:forward].length - 1
                  pat = options[:forward]

                  while len >= options[:forward_length]
                    fmis = percent2real(len, options[:mismatch_percent])
                    fins = percent2real(len, options[:insertion_percent])
                    fdel = percent2real(len, options[:deletion_percent])

                    pat = pat[1 ... pat.length]

                    if fmatch = entry.patmatch(pat, start: 0, stop: len, max_mismatches: fmis, max_insertions: fins, max_deletions: fdel)
                      break
                    end

                    len -= 1
                  end
                end
              end

              if options[:reverse] and record[:SEQ].length >= options[:reverse].length
                if rmatch = entry.patmatch(options[:reverse], max_mismatches: rmis, max_insertions: rins, max_deletions: rdel)
                elsif options[:reverse_length] < options[:reverse].length
                  len = options[:reverse].length - 1
                  pat = options[:reverse]

                  while len >= options[:reverse_length]
                    rmis = percent2real(len, options[:mismatch_percent])
                    rins = percent2real(len, options[:insertion_percent])
                    rdel = percent2real(len, options[:deletion_percent])

                    pat = pat[0 ... pat.length - 1]

                    if rmatch = entry.patmatch(pat, start: entry.length - len, max_mismatches: rmis, max_insertions: rins, max_deletions: rdel)
                      break
                    end

                    len -= 1
                  end
                end
              end

              if rmatch
                record[:ADAPTOR_POS_RIGHT] = rmatch.pos
                record[:ADAPTOR_LEN_RIGHT] = rmatch.length
                record[:ADAPTOR_PAT_RIGHT] = rmatch.match

                entry = entry[0 ... rmatch.pos]
              end

              if fmatch
                 record[:ADAPTOR_POS_LEFT] = fmatch.pos
                 record[:ADAPTOR_LEN_LEFT] = fmatch.length
                 record[:ADAPTOR_PAT_LEFT] = fmatch.match

                 if fmatch.pos + fmatch.length < entry.length
                   entry = entry[fmatch.pos + fmatch.length .. -1]
                 end
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

