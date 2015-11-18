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
# This software is part of the BioDSL (www.BioDSL.org).                        #
#                                                                              #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

module BioDSL
  # == Reverse sequences in the stream.
  #
  # +reverse_seq+ reverses sequences in the stream. If a SCORES key is found
  # then the SCORES are also reversed.
  #
  # +reverse_seq+ can be used together with +complment_seq+ to reverse-
  # complement sequences.
  #
  # == Usage
  #
  #    reverse_seq()
  #
  # === Options
  #
  # == Examples
  #
  # Consider the following FASTQ entry in the file test.fq:
  #
  #    @M02529:88:000000000-AC0WY:1:1101:12879:1928 2:N:0:185
  #    TTGTAAAACGACGGCCAGTG
  #    +
  #    >>>>>FFFFD@A?A0AE0FG
  #
  # To reverse the sequence simply do:
  #
  #    BD.new.read_fastq(input:"test.fq").reverse_seq.dump.run
  #
  #    {:SEQ_NAME=>"M02529:88:000000000-AC0WY:1:1101:12879:1928 2:N:0:185",
  #     :SEQ=>"GTGACCGGCAGCAAAATGTT",
  #     :SEQ_LEN=>20,
  #     :SCORES=>"GF0EA0A?A@DFFFF>>>>>"}
  class ReverseSeq
    STATS = %i(records_in records_out sequences_in sequences_out residues_in
               residues_out)

    # Constructor for ReverseSeq.
    #
    # @param options [Hash] Options hash.
    #
    # @return [ReverseSeq] Class instance.
    def initialize(options)
      @options = options

      check_options
    end

    # Return command lambda for reverse_seq.
    #
    # @return [Proc] Command lambda.
    def lmb
      lambda do |input, output, status|
        status_init(status, STATS)

        input.each do |record|
          @status[:records_in] += 1
          reverse(record) if record[:SEQ]
          output << record
          @status[:records_out] += 1
        end
      end
    end

    private

    # Check options.
    def check_options
      options_allowed(@options, nil)
    end

    # Reverse sequence.
    #
    # @param record [Hash] BioDSL record.
    def reverse(record)
      entry = BioDSL::Seq.new_bp(record)
      entry.reverse!

      @status[:sequences_in] += 1
      @status[:sequences_out] += 1
      @status[:residues_in] += entry.length
      @status[:residues_out] += entry.length

      record.merge! entry.to_bp
    end
  end
end
