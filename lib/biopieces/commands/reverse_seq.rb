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
    #    BP.new.read_fastq(input:"test.fq").reverse_seq.dump.run
    #
    #    {:SEQ_NAME=>"M02529:88:000000000-AC0WY:1:1101:12879:1928 2:N:0:185",
    #     :SEQ=>"GTGACCGGCAGCAAAATGTT",
    #     :SEQ_LEN=>20,
    #     :SCORES=>"GF0EA0A?A@DFFFF>>>>>"}
    def reverse_seq(options = {})
      options_orig = options.dup
      options_load_rc(options, __method__)
      options_allowed(options, nil)

      lmb = lambda do |input, output, status|
        status_track(status) do
          status[:sequences_in]  = 0
          status[:sequences_out] = 0
          status[:residues_in]   = 0
          status[:residues_out]  = 0

          input.each do |record|
            status[:records_in] += 1

            if record[:SEQ]
              entry = BioPieces::Seq.new_bp(record)
              entry.reverse!

              status[:sequences_in]  += 1
              status[:sequences_out] += 1
              status[:residues_in]   += entry.length
              status[:residues_out]  += entry.length

              record.merge! entry.to_bp
            end

            output << record

            status[:records_out] += 1
          end
        end
      end

      @commands << BioPieces::Pipeline::Command.new(__method__, options, options_orig, lmb)

      self
    end
  end
end

