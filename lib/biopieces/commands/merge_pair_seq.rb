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
  # == Merge pair-end sequences in the stream.
  #
  # +merge_pair_seq+ merges paired sequences in the stream, if these are
  # interleaved. Sequence names must be in either Illumina1.3/1.5 format
  # trailing a /1 or /2 or Illumina1.8 containing  1: or 2:. Sequence names must
  # match accordingly in order to merge sequences.
  #
  # == Usage
  #
  #    merge_pair_seq
  #
  # === Options
  #
  # == Examples
  #
  # Consider the following FASTQ entry in the file test.fq:
  #
  #    @M01168:16:000000000-A1R9L:1:1101:14862:1868 1:N:0:14
  #    TGGGGAATATTGGACAATGG
  #    +
  #    <??????BDDDDDDDDGGGG
  #    @M01168:16:000000000-A1R9L:1:1101:14862:1868 2:N:0:14
  #    CCTGTTTGCTACCCACGCTT
  #    +
  #    ?????BB<-<BDDDDDFEEF
  #    @M01168:16:000000000-A1R9L:1:1101:13906:2139 1:N:0:14
  #    TAGGGAATCTTGCACAATGG
  #    +
  #    <???9?BBBDBDDBDDFFFF
  #    @M01168:16:000000000-A1R9L:1:1101:13906:2139 2:N:0:14
  #    ACTCTTCGCTACCCATGCTT
  #    +
  #    ,5<??BB?DDABDBDDFFFF
  #    @M01168:16:000000000-A1R9L:1:1101:14865:2158 1:N:0:14
  #    TAGGGAATCTTGCACAATGG
  #    +
  #    ?????BBBBBDDBDDBFFFF
  #    @M01168:16:000000000-A1R9L:1:1101:14865:2158 2:N:0:14
  #    CCTCTTCGCTACCCATGCTT
  #    +
  #    ??,<??B?BB?BBBBBFF?F
  #
  # To merge these interleaved pair-end sequences use merge_pair_seq:
  #
  #    BP.new.
  #    read_fastq(input: "test.fq", encoding: :base_33).
  #    merge_pair_seq.
  #    dump.
  #    run
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
  class MergePairSeq
    STATS = %i(records_in records_out sequences_in sequences_out residues_in
               residues_out)

    # Constructor for MergePairSeq.
    #
    # @param options [Hash] Options hash.
    #
    # @return [MergePairSeq] Instance of MergePairSeq.
    def initialize(options)
      @options = options

      check_options
      status_init(STATS)
    end

    # Return the command lambda for merge_pair_seq.
    #
    # @return [Proc] Command lambda for.
    def lmb
      lambda do |input, output, status|
        input.each_slice(2) do |record1, record2|
          @status[:records_in] += record2 ? 2 : 1

          if record1[:SEQ] && record2[:SEQ]
            output << merge_pair_seq(record1, record2)

            @status[:sequences_in]  += 2
            @status[:sequences_out] += 1
            @status[:records_out]   += 1
          else
            output.puts record1, record2

            @status[:records_out] += 2
          end
        end

        status_assign(status, STATS)
      end
    end

    private

    # Check options.
    def check_options
      options_allowed(@options, nil)
    end

    # Merge entry pair and return a new biopieces record with this.
    #
    # @param record1 [Hash] BioPieces record 1.
    # @param record2 [Hash] BioPieces record 2.
    #
    # @return [Hash] BioPieces record.
    def merge_pair_seq(record1, record2)
      entry1 = BioPieces::Seq.new_bp(record1)
      entry2 = BioPieces::Seq.new_bp(record2)

      BioPieces::Seq.check_name_pair(entry1, entry2)

      @status[:residues_in] += entry1.length + entry2.length

      length1 = entry1.length
      length2 = entry2.length

      entry1 << entry2

      @status[:residues_out] += entry1.length

      new_record(entry1, length1, length2)
    end

    def new_record(entry1, length1, length2)
      new_record = entry1.to_bp
      new_record[:SEQ_LEN_LEFT]  = length1
      new_record[:SEQ_LEN_RIGHT] = length2
      new_record
    end
  end
end
