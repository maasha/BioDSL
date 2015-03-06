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
      options_allowed(options, :slice, :forward, :reverse, :max_mismatches, :max_insertions, :max_deletions, :template_file)
      options_tie(options, forward: :reverse, reverse: :forward)
      options_conflict(options, slice: :forward)
      options_files_exist(options, :template_file)
      options_assert(options, ":max_mismatches >= 0")
      options_assert(options, ":max_insertions >= 0")
      options_assert(options, ":max_deletions >= 0")
      options_assert(options, ":max_mismatches <= 5")
      options_assert(options, ":max_insertions <= 5")
      options_assert(options, ":max_deletions <= 5")

      options[:max_mismatches] ||= 2
      options[:max_insertions] ||= 1
      options[:max_deletions]  ||= 1

      lmb = lambda do |input, output, status|
        status_track(status) do
          status[:sequences_in]  = 0
          status[:sequences_out] = 0
          status[:residues_in]   = 0
          status[:residues_out]  = 0

          indels   = BioPieces::Seq::INDELS.sort.join
          template = BioPieces::Fasta.read(options[:template_file]).first if options[:template_file]

          input.each do |record|
            status[:records_in] += 1

            if record[:SEQ]
              entry = BioPieces::Seq.new_bp(record)

              status[:sequences_in] += 1
              status[:residues_in]  += entry.length

              unless options[:slice]
                pos_index = []

                if template
                  compact = Seq.new(seq: template.seq.dup.delete(indels))
                  template.seq.chars.each_with_index { |c, i| pos_index << i unless indels.include? c }
                else
                  compact = Seq.new(seq: entry.seq.dup.delete(indels))
                  entry.seq.chars.each_with_index { |c, i| pos_index << i unless indels.include? c }
                end

                fmatch = compact.patmatch(options[:forward], options)

                raise BioPieces::SeqError, "forward primer: #{options[:forward]} not found" if fmatch.nil?

                rmatch = compact.patmatch(options[:reverse], options)

                raise BioPieces::SeqError, "reverse primer: #{options[:reverse]} not found" if rmatch.nil?

                options[:slice] = Range.new(pos_index[fmatch.pos], pos_index[rmatch.pos + rmatch.length - 1])
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

