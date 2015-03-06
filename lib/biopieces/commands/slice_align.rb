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
# This software is part of the Biopieces framework (www.biopieces.org).          #
#                                                                                #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

module BioPieces
  module Commands
    # == Slice aligned sequences in the stream to obtain subsequences.
    #
    # +slice_align+ slices an alignment to extract subsequence from all
    # sequences in the stream. This is done by either specifying a range
    # (0-based) or a set of primers that is then used to locate the range to
    # be sliced from the sequences. This is done by matching the primers to the
    # first sequence in the stream allowing for a specified number of
    # mismatches, insertions and deletions.
    #
    # It is also possible to specify a template file using the +template_file+
    # option. The template file should be a file with one FASTA formatted
    # sequence from the alignment (with gaps). If a template file and a range
    # is specified the nucleotide positions from the ungapped template will be
    # used. If both template file and primers are specified the template sequence
    # is used for the primer search and the positions will be used for slicing.
    #
    # The sequences in the stream are replaced with the sliced subsequences.
    # 
    # == Usage
    # 
    #    slice_align(<slice: <index>|<range>> |
    #                <forward: <string> | forward_rc: <string>>,
    #                <revese: <string> | reverse_rc: <string>
    #                [, max_mismatches: <uint>[, max_insertions: <uint>
    #                [, max_deletions: <uint>[, template_file: <file>]]]])
    #
    # === Options
    #
    # * slice: <index>         - Slice a one residue subsequence.
    # * slice: <range>         - Slice a range from the sequence.
    # * forward: <string>      - Forward primer (5'-3').
    # * forward_rc: <string>   - Forward primer (3'-5').
    # * reverse: <string>      - Reverse primer (3'-5').
    # * reverse_rc: <string>   - Reverse primer (5'-3').
    # * max_mismatches: <uint> - Max number of mismatchs (default=2).
    # * max_insertions: <uint> - Max number of insertions (default=1).
    # * max_deletions: <uint>  - Max number of deletions (default=1).
    # * template_file: <file>  - File with one aligned sequence in FASTA format.
    # 
    # == Examples
    # 
    def slice_align(options = {})
      options_orig = options.dup
      options_load_rc(options, __method__)
      options_allowed(options, :slice, :forward, :reverse)
      options_tie(options, forward: :reverse, reverse: :forward)
      options_conflict(options, slice: :forward)

      lmb = lambda do |input, output, status|
        status_track(status) do
          status[:sequences_in]  = 0
          status[:sequences_out] = 0
          status[:residues_in]   = 0
          status[:residues_out]  = 0

          indels = Seq::INDELS.sort.join

          input.each do |record|
            status[:records_in] += 1

            if record[:SEQ]
              entry = BioPieces::Seq.new_bp(record)

              status[:sequences_in] += 1
              status[:residues_in]  += entry.length

              unless options[:slice]
                compact   = Seq.new(seq: entry.seq.dup.delete(indels))
                pos_index = []
                entry.seq.chars.each_with_index { |c, i| pos_index << i unless indels.include? c }

                fmatch = compact.patmatch(options[:forward],
                                          max_mismatches: options[:max_mismatches],
                                          max_insertions: options[:max_insertions],
                                          max_deletions: options[:max_deletions])

                raise BioPieces::SeqError, "forward primer: #{options[:forward]} not found" if fmatch.nil?

                rmatch = compact.patmatch(options[:reverse],
                                          max_mismatches: options[:max_mismatches],
                                          max_insertions: options[:max_insertions],
                                          max_deletions: options[:max_deletions])

                raise BioPieces::SeqError, "reverse primer: #{options[:reverse]} not found" if rmatch.nil?

                mbeg = fmatch.pos
                mend = rmatch.pos + rmatch.length - 1

                options[:slice] = Range.new(pos_index[mbeg], pos_index[mend])
              end

              entry = entry[options[:slice]]

              status[:sequences_out] += 1
              status[:residues_out]  += entry.length

              record.merge! entry.to_bp
            end

            output << record

            status[:records_out] += 1
          end

          status[:residues_delta]         = status[:residues_out] - status[:residues_in]
          status[:residues_delta_mean]    = (status[:residues_delta].to_f / status[:records_out]).round(2)
          status[:residues_delta_percent] = (100 * status[:residues_delta].to_f / status[:residues_out]).round(2)
        end
      end

      @commands << BioPieces::Pipeline::Command.new(__method__, options, options_orig, lmb)

      self
    end
  end
end

