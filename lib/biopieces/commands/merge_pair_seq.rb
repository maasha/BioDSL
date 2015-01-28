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
    # == Merge pair-end sequences in the stream.
    # 
    # +merge_pair_seq+ merges paired sequences in the stream, if these are
    # interleaved. Sequence names must be in either Illumina1.3/1.5 format
    # trailing a /1 or /2 or Illumina1.8 containing  1: or 2:. Sequence names
    # must match accordingly in order to merge sequences.
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
    #    BP.new.read_fastq(input: "test.fq", encoding: :base_33).merge_pair_seq.dump.run
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
    def merge_pair_seq(options = {})
      options_orig = options.dup
      options_allowed(options, nil)

      lmb = lambda do |input, output, status|
        status_track(status) do
          status[:sequences_in]  = 0
          status[:sequences_out] = 0
          status[:residues_in]   = 0
          status[:residues_out]  = 0

          input.each_slice(2) do |record1, record2|
            status[:records_in] += 2

            if record1[:SEQ] and record2[:SEQ]
              entry1 = BioPieces::Seq.new_bp(record1)
              entry2 = BioPieces::Seq.new_bp(record2)

              BioPieces::Seq.check_name_pair(entry1, entry2)

              seq_len_left  = entry1.length
              seq_len_right = entry2.length

              status[:sequences_in] += 2
              status[:residues_in]  += entry1.length + entry2.length

              entry1 << entry2

              status[:sequences_out] += 1
              status[:residues_out]  += entry1.length

              new_record = entry1.to_bp
              new_record[:SEQ_LEN_LEFT]  = seq_len_left
              new_record[:SEQ_LEN_RIGHT] = seq_len_right

              output << new_record

              status[:records_out] += 1
            else
              output << record1
              output << record2

              status[:records_out] += 2
            end
          end
        end
      end

      @commands << BioPieces::Pipeline::Command.new(__method__, options, options_orig, lmb)

      self
    end
  end
end
