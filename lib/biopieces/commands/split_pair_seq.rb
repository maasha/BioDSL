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
  # == Splite pair-end sequences in the stream.
  #
  # split_pair_seq splits sequences in the stream previously merged with
  # merge_pair_seq. Sequence names must be in either Illumina1.3/1.5 format
  # trailing a /1 or /2 or Illumina1.8 containing  1: or  2:. A sequence split
  # into two will be output as two records where the first will be named with 1
  # and the second with 2.
  #
  # == Usage
  #
  #    split_pair_seq
  #
  # === Options
  #
  # == Examples
  #
  # Consider the following records created with merge_pair_seq:
  #
  #    {:SEQ_NAME=>"M01168:16:000000000-A1R9L:1:1101:14862:1868 1:N:0:14",
  #     :SEQ=>"TGGGGAATATTGGACAATGGCCTGTTTGCTACCCACGCTT",
  #     :SEQ_LEN=>40,
  #     :SCORES=>"<??????BDDDDDDDDGGGG?????BB<-<BDDDDDFEEF",
  #     :SEQ_LEN_LEFT=>20,
  #     :SEQ_LEN_RIGHT=>20}
  #    {:SEQ_NAME=>"M01168:16:000000000-A1R9L:1:1101:13906:2139 1:N:0:14",
  #     :SEQ=>"TAGGGAATCTTGCACAATGGACTCTTCGCTACCCATGCTT",
  #     :SEQ_LEN=>40,
  #     :SCORES=>"<???9?BBBDBDDBDDFFFF,5<??BB?DDABDBDDFFFF",
  #     :SEQ_LEN_LEFT=>20,
  #     :SEQ_LEN_RIGHT=>20}
  #    {:SEQ_NAME=>"M01168:16:000000000-A1R9L:1:1101:14865:2158 1:N:0:14",
  #     :SEQ=>"TAGGGAATCTTGCACAATGGCCTCTTCGCTACCCATGCTT",
  #     :SEQ_LEN=>40,
  #     :SCORES=>"?????BBBBBDDBDDBFFFF??,<??B?BB?BBBBBFF?F",
  #     :SEQ_LEN_LEFT=>20,
  #     :SEQ_LEN_RIGHT=>20}
  #
  # These can be split using split_pair_seq:
  #
  #    BP.new.
  #    read_fastq(input: "test.fq", encoding: :base_33).
  #    merge_pair_seq.
  #    split_pair_seq.
  #    dump.
  #    run
  #
  #    {:SEQ_NAME=>"M01168:16:000000000-A1R9L:1:1101:14862:1868 1:N:0:14",
  #     :SEQ=>"TGGGGAATATTGGACAATGG",
  #     :SEQ_LEN=>20,
  #     :SCORES=>"<??????BDDDDDDDDGGGG"}
  #    {:SEQ_NAME=>"M01168:16:000000000-A1R9L:1:1101:14862:1868 2:N:0:14",
  #     :SEQ=>"CCTGTTTGCTACCCACGCTT",
  #     :SEQ_LEN=>20,
  #     :SCORES=>"?????BB<-<BDDDDDFEEF"}
  #    {:SEQ_NAME=>"M01168:16:000000000-A1R9L:1:1101:13906:2139 1:N:0:14",
  #     :SEQ=>"TAGGGAATCTTGCACAATGG",
  #     :SEQ_LEN=>20,
  #     :SCORES=>"<???9?BBBDBDDBDDFFFF"}
  #    {:SEQ_NAME=>"M01168:16:000000000-A1R9L:1:1101:13906:2139 2:N:0:14",
  #     :SEQ=>"ACTCTTCGCTACCCATGCTT",
  #     :SEQ_LEN=>20,
  #     :SCORES=>",5<??BB?DDABDBDDFFFF"}
  #    {:SEQ_NAME=>"M01168:16:000000000-A1R9L:1:1101:14865:2158 1:N:0:14",
  #     :SEQ=>"TAGGGAATCTTGCACAATGG",
  #     :SEQ_LEN=>20,
  #     :SCORES=>"?????BBBBBDDBDDBFFFF"}
  #    {:SEQ_NAME=>"M01168:16:000000000-A1R9L:1:1101:14865:2158 2:N:0:14",
  #     :SEQ=>"CCTCTTCGCTACCCATGCTT",
  #     :SEQ_LEN=>20,
  #     :SCORES=>"??,<??B?BB?BBBBBFF?F"}
  class SplitPairSeq
    STATS = %i(records_in records_out sequences_in sequences_out residues_in
               residues_out)

    # Constructor for SplitPairSeq.
    #
    # @param options [Hash] Options hash.
    #
    # @return [SplitPairSeq] Class instance.
    def initialize(options)
      @options = options

      check_options
      status_init(STATS)
    end

    # Return command lambda for split_pair_seq.
    #
    # @return [Proc] Command lambda.
    def lmb
      lambda do |input, output, status|
        input.each do |record|
          @status[:records_in] += 1

          if record[:SEQ_NAME] && record[:SEQ] && record[:SEQ_LEN_LEFT] &&
             record[:SEQ_LEN_RIGHT]
            split_pair_seq(output, record)
          else
            output << record

            @status[:records_out] += 1
          end
        end
      end
    end

    private

    # Check options.
    def check_options
      options_allowed(@options, nil)
    end

    # Output two sequence entries from a sequence in the given record that has
    # been split at a position defined by the SEQ_LEN_LEFT key in the record.
    #
    # @param output [Enumerator::Yielder] Output stream.
    # @param record [Hash]                BioPieces record.
    #
    # rubocop: disable Metrics/AbcSize
    def split_pair_seq(output, record)
      entry = BioPieces::Seq.new_bp(record)

      @status[:sequences_in] += 1
      @status[:residues_in]  += entry.length

      pos = get_split_pos(record, entry)

      entry1, entry2 = split_entry(entry, pos)

      output << entry1.to_bp
      output << entry2.to_bp

      @status[:sequences_out] += 2
      @status[:residues_out]  += entry1.length + entry2.length
      @status[:records_out]   += 2
    end

    # Given a record locate the sequence split position.
    #
    # @param record [Hash]           BioPieces record.
    # @param entry  [BioPieces::Seq] Sequence entry.
    #
    # @return [Integer] Sequence split position.
    #
    # @raise [BioPieces::SeqError]
    #   If left and right lengths don't fit entry length.
    def get_split_pos(record, entry)
      len_left  = record[:SEQ_LEN_LEFT].to_i
      len_right = record[:SEQ_LEN_RIGHT].to_i

      unless len_left + len_right == entry.length
        fail BioPieces::SeqError, 'SEQ_LEN_LEFT + SEQ_LEN_RIGHT != SEQ_LEN ' \
          "#{len_left} + #{len_right} != #{entry.length}"
      end

      len_left
    end

    # Split the given entry at the given position and return two new entries.
    #
    # @param entry [BioPieces::Seq] Sequence entry.
    # @param pos   [Integer]        Split position.
    #
    # @return [Array] Tuple with the two new entries.
    def split_entry(entry, pos)
      entry1 = entry[0...pos]
      entry2 = entry[pos..-1]

      fix_seq_names(entry, entry2)

      [entry1, entry2]
    end

    # Fix sequence names.
    #
    # @param entry1 [BioPieces::Seq] Sequence entry1.
    # @param entry2 [BioPieces::Seq] Sequence entry2.
    #
    # @raise [RuntimeError] If names wasn't fixed.
    def fix_seq_names(entry1, entry2)
      if entry1.seq_name =~ /^[^ ]+ \d:/
        entry2.seq_name.sub!(/ \d:/, ' 2:')
      elsif entry1.seq_name =~ /^.+\/\d$/
        entry2.seq_name[-1] = '2'
      else
        fail "Could not match sequence name: #{entry1.seq_name}"
      end
    end
  end
end
