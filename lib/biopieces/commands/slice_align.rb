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

# rubocop: disable LineLength
module BioPieces
  # == Slice aligned sequences in the stream to obtain subsequences.
  #
  # +slice_align+ slices an alignment to extract subsequence from all sequences
  # in the stream. This is done by either specifying a range or a set of primers
  # that is then used to locate the range to be sliced from the sequences.
  #
  # If a range is given with the +slice+ option the potitions (0-based) must be
  # corresponding the aligned sequence, i.e with gaps.
  #
  # If a set of primers are given with the +forward+ and +reverse+ options (or
  # the +forward_rc+ and +reverse_rc+ options) these primers are used to locate
  # the matching positions in the first entry and this range is used to slice
  # this and any following sequences. It is possible to specify fuzzy primer
  # matching by using the +max_mismatches+, +max_insertions+ and +max_deletions+
  # options. Moreover, IUPAC ambigity codes are allowed.
  #
  # It is also possible to specify a template file using the +template_file+
  # option. The template file should be a file with one FASTA formatted sequence
  # from the alignment (with gaps). If a template file and a range is specified
  # the nucleotide positions from the ungapped template will be used. If both
  # template file and primers are specified the template sequence is used for
  # the primer search and the positions will be used for slicing.
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
  # Consider the following alignment in the file `test.fna`
  #
  #    >ID00000000
  #    CCGCATACG-------CCCTGAGGGG----
  #    >ID00000001
  #    CCGCATGAT-------ACCTGAGGGT----
  #    >ID00000002
  #    CCGCATATACTCTTGACGCTAAAGCGTAGT
  #    >ID00000003
  #    CCGTATGTG-------CCCTTCGGGG----
  #    >ID00000004
  #    CCGGATAAG-------CCCTTACGGG----
  #    >ID00000005
  #    CCGGATAAG-------CCCTTACGGG----
  #
  # We can slice the alignment with +slice_align+ using a range:
  #
  #    BP.new.
  #    read_fasta(input: "test.fna").
  #    slice_align(slice: 14 .. 27).
  #    dump.
  #    run
  #
  #    {:SEQ_NAME=>"ID00000000", :SEQ=>"--CCCTGAGGGG--", :SEQ_LEN=>14}
  #    {:SEQ_NAME=>"ID00000001", :SEQ=>"--ACCTGAGGGT--", :SEQ_LEN=>14}
  #    {:SEQ_NAME=>"ID00000002", :SEQ=>"GACGCTAAAGCGTA", :SEQ_LEN=>14}
  #    {:SEQ_NAME=>"ID00000003", :SEQ=>"--CCCTTCGGGG--", :SEQ_LEN=>14}
  #    {:SEQ_NAME=>"ID00000004", :SEQ=>"--CCCTTACGGG--", :SEQ_LEN=>14}
  #    {:SEQ_NAME=>"ID00000005", :SEQ=>"--CCCTTACGGG--", :SEQ_LEN=>14}
  #
  # Or we could slice the alignment using a set of primers:
  #
  #    BP.new.
  #    read_fasta(input: "test.fna").
  #    slice_align(forward: "CGCATACG", reverse: "GAGGGG", max_mismatches: 0,
  #                max_insertions: 0, max_deletions: 0).
  #    dump.run
  #
  #    {:SEQ_NAME=>"ID00000000", :SEQ=>"CGCATACG-------CCCTGAGGGG", :SEQ_LEN=>25}
  #    {:SEQ_NAME=>"ID00000001", :SEQ=>"CGCATGAT-------ACCTGAGGGT", :SEQ_LEN=>25}
  #    {:SEQ_NAME=>"ID00000002", :SEQ=>"CGCATATACTCTTGACGCTAAAGCG", :SEQ_LEN=>25}
  #    {:SEQ_NAME=>"ID00000003", :SEQ=>"CGTATGTG-------CCCTTCGGGG", :SEQ_LEN=>25}
  #    {:SEQ_NAME=>"ID00000004", :SEQ=>"CGGATAAG-------CCCTTACGGG", :SEQ_LEN=>25}
  #    {:SEQ_NAME=>"ID00000005", :SEQ=>"CGGATAAG-------CCCTTACGGG", :SEQ_LEN=>25}
  #
  # Now, if we have a template file with the following FASTA entry:
  #
  #    >template
  #    CTGAATACG-------CCATTCGATGG---
  #
  # and spefifying primers these will be matched to the template and the hit
  # positions used for slicing:
  #
  #    BP.new.
  #    read_fasta(input: "test.fna").
  #    slice_align(template_file: "template.fna", forward: "GAATACG",
  #                reverse: "ATTCGAT", max_mismatches: 0, max_insertions: 0,
  #                max_deletions: 0).
  #    dump.run
  #
  #    {:SEQ_NAME=>"ID00000000", :SEQ=>"GCATACG-------CCCTGAGGG", :SEQ_LEN=>23}
  #    {:SEQ_NAME=>"ID00000001", :SEQ=>"GCATGAT-------ACCTGAGGG", :SEQ_LEN=>23}
  #    {:SEQ_NAME=>"ID00000002", :SEQ=>"GCATATACTCTTGACGCTAAAGC", :SEQ_LEN=>23}
  #    {:SEQ_NAME=>"ID00000003", :SEQ=>"GTATGTG-------CCCTTCGGG", :SEQ_LEN=>23}
  #    {:SEQ_NAME=>"ID00000004", :SEQ=>"GGATAAG-------CCCTTACGG", :SEQ_LEN=>23}
  #    {:SEQ_NAME=>"ID00000005", :SEQ=>"GGATAAG-------CCCTTACGG", :SEQ_LEN=>23}
  #
  # Finally, specifying a template file and an interval the positions used for
  # slicing will be the ungapped positions from the template sequence. This
  # is useful if you are slicing 16S rRNA alignments and want the _E.coli_
  # corresponding positions - simply use the _E.coli_ sequence as template.
  #
  #    BP.new.
  #    read_fasta(input: "test.fna").
  #    slice_align(template_file: "template.fna", slice: 4 .. 14).
  #    dump.run
  #
  #    {:SEQ_NAME=>"ID00000000", :SEQ=>"ATACG-------CCCTGA", :SEQ_LEN=>18}
  #    {:SEQ_NAME=>"ID00000001", :SEQ=>"ATGAT-------ACCTGA", :SEQ_LEN=>18}
  #    {:SEQ_NAME=>"ID00000002", :SEQ=>"ATATACTCTTGACGCTAA", :SEQ_LEN=>18}
  #    {:SEQ_NAME=>"ID00000003", :SEQ=>"ATGTG-------CCCTTC", :SEQ_LEN=>18}
  #    {:SEQ_NAME=>"ID00000004", :SEQ=>"ATAAG-------CCCTTA", :SEQ_LEN=>18}
  #    {:SEQ_NAME=>"ID00000005", :SEQ=>"ATAAG-------CCCTTA", :SEQ_LEN=>18}
  #
  # rubocop: enable LineLength
  # rubocop: disable ClassLength
  class SliceAlign
    STATS = %i(records_in records_out sequences_in sequences_out residues_in
               residues_out)

    # Constructor for SliceAlign.
    #
    # @param options  [Hash]          Options hash.
    # @option options [Range,Integer] :slice
    # @option options [String]        :forward
    # @option options [String]        :forward_rc
    # @option options [String]        :reverse
    # @option options [String]        :reverse_rc
    # @option options [Integer]       :max_mismatches
    # @option options [Integer]       :max_insertions
    # @option options [Integer]       :max_deletions
    # @option options [String]        :template_file
    #
    # @return [SliceAlign] Class instance.
    def initialize(options)
      @options  = options
      @forward  = forward
      @reverse  = reverse
      @indels   = BioPieces::Seq::INDELS.sort.join
      @template = nil
      @slice    = options[:slice]

      check_options
      status_init(STATS)
      defaults
    end

    # Return the comman lamba for slice_align.
    #
    # @return [Proc] Command lambda.
    def lmb
      lambda do |input, output, status|
        parse_template_file
        setup_template_slice

        input.each do |record|
          @status[:records_in] += 1
          slice_align(record) if record.key? :SEQ
          output << record
          @status[:records_out] += 1
        end

        status_assign(status, STATS)
      end
    end

    private

    # Check options.
    def check_options
      options_allowed(@options, :slice, :forward, :forward_rc, :reverse,
                      :reverse_rc, :max_mismatches, :max_insertions,
                      :max_deletions, :template_file)
      options_conflict(@options, slice: :forward)
      options_files_exist(@options, :template_file)
      options_assert(@options, ':max_mismatches >= 0')
      options_assert(@options, ':max_insertions >= 0')
      options_assert(@options, ':max_deletions >= 0')
      options_assert(@options, ':max_mismatches <= 5')
      options_assert(@options, ':max_insertions <= 5')
      options_assert(@options, ':max_deletions <= 5')
    end

    # Setup default primer matching attributes.
    def defaults
      @max_mis = @options[:max_mismatches] || 2
      @max_ins = @options[:max_insertions] || 1
      @max_del = @options[:max_deletions]  || 1
    end

    # Parse FASTA file with one gapped template sequence if specified.
    def parse_template_file
      return unless @options[:template_file]

      @template = BioPieces::Fasta.read(@options[:template_file]).first
    end

    # Set the slice positions using the template sequence.
    def setup_template_slice
      return unless @template

      pos_index = PosIndex.new(@template, @indels)

      if @slice
        start, stop = setup_template_slice_range(pos_index)
      else
        start, stop = setup_template_slice_primers(pos_index)
      end

      @slice = Range.new(start, stop)
    end

    # Given a position index use slice positions to locate equivalent postitions
    # in the template sequence.
    #
    # @param pos_index [PosIndex] Position index.
    def setup_template_slice_range(pos_index)
      start = pos_index[@slice.first]
      stop  = pos_index[@slice.last]

      [start, stop]
    end

    # Given a position index use primers to locate the slice positions in the
    # template sequence.
    #
    # @param pos_index [PosIndex] Position index.
    def setup_template_slice_primers(pos_index)
      compact   = Seq.new(seq: @template.seq.dup.delete(@indels))
      fmatch    = find_match(@forward, compact)
      rmatch    = find_match(@reverse, compact)
      start     = pos_index[fmatch.start]
      stop      = pos_index[rmatch.stop]

      [start, stop]
    end

    # Return the forward primer sequence and reverse-complement it if need be.
    #
    # @return [String] Forward primer sequence.
    def forward
      if @options[:forward_rc]
        @options[:forward] = Seq.new(seq: @options[:forward_rc], type: :dna).
                             reverse.complement.seq
      else
        @options[:forward]
      end
    end

    # Return the reverse primer sequence and reverse-complement it if need be.
    #
    # @return [String] Reverse primer sequence.
    def reverse
      if @options[:reverse_rc]
        @options[:reverse] = Seq.new(seq: @options[:reverse_rc], type: :dna).
                             reverse.complement.seq
      else
        @options[:reverse]
      end
    end

    # Slice sequence in given record accoding to slice positions.
    #
    # @param record [Hash] BioPieces record.
    def slice_align(record)
      entry = BioPieces::Seq.new_bp(record)

      @status[:sequences_in] += 1
      @status[:residues_in]  += entry.length

      setup_slice(entry) unless @slice

      entry = entry[@slice]

      record.merge! entry.to_bp

      @status[:sequences_out] += 1
      @status[:residues_out]  += entry.length
    end

    # Usings primers to locate slice positions in entry.
    #
    # @param entry [BioPieces::Seq] Sequence entry.
    def setup_slice(entry)
      pos_index = PosIndex.new(entry, @indels)
      compact   = Seq.new(seq: entry.seq.dup.delete(@indels))

      fmatch = find_match(@forward, compact)
      rmatch = find_match(@reverse, compact)

      @slice = Range.new(pos_index[fmatch.start], pos_index[rmatch.stop])
    end

    # Find pattern in entry and return match.
    #
    # @param pattern [String]         Search pattern.
    # @param entry   [BioPieces::Seq] Sequence to search.
    #
    # @return [BioPieces::Seq::Match] Pattern match.
    #
    # @raise [BioPieces::SeqError] If no match.
    def find_match(pattern, entry)
      match = entry.patmatch(pattern,
                             max_mismatches: @max_mis,
                             max_insertions: @max_ins,
                             max_deletions:  @max_del)

      return match unless match.nil?

      fail BioPieces::SeqError, "pattern not found: #{pattern}"
    end

    # Class for indexing gapped sequence positions to non-gapped sequence
    # positions.
    class PosIndex
      # Constructor for PosIndex.
      #
      # @param entry  [BioPieces::Seq] Gapped sequence entry.
      # @param indels [String]         String with indel alphabet.
      #
      # @return [PosIndex] Class instance.
      def initialize(entry, indels)
        @entry  = entry
        @indels = indels
        @index  = index_positions
      end

      # Given a non-gapped sequence postion return the gapped position.
      #
      # @param pos [Integer] Non-gapped sequence position.
      #
      # @return [Integer] Gapped sequence position
      def [](pos)
        @index[pos]
      end

      private

      # Return an index mapping gapped sequence positions to non-gapped
      # positions.
      #
      # @return [Array] Position index.
      def index_positions
        pos_index = []

        @entry.seq.chars.each_with_index do |c, i|
          pos_index << i unless @indels.include? c
        end

        pos_index
      end
    end
  end
end
