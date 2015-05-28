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
  class ReverseSeq
    require 'biopieces/helpers/options_helper'

    extend OptionsHelper
    include OptionsHelper

    # Check options and return command lambda for reverse_seq.
    #
    # @param options [Hash] Options hash.
    #
    # @return [Proc] Command lambda.
    def self.lmb(options)
      options_allowed(options, nil)

      new(options).lmb
    end

    # Constructor for ReverseSeq.
    #
    # @param options [Hash] Options hash.
    #
    # @return [ReverseSeq] Class instance.
    def initialize(options)
      @options       = options
      @records_in    = 0
      @records_out   = 0
      @sequences_in  = 0
      @sequences_out = 0
      @residues_in   = 0
      @residues_out  = 0
    end

    # Return command lambda for reverse_seq.
    #
    # @return [Proc] Command lambda.
    def lmb
      lambda do |input, output, status|
        input.each do |record|
          @records_in += 1
          reverse(record) if record[:SEQ]
          output << record
          @records_out += 1
        end

        assign_status(status)
      end
    end

    private

    # Reverse sequence.
    #
    # @param record [Hash] BioPieces record.
    def reverse(record)
      entry = BioPieces::Seq.new_bp(record)
      entry.reverse!

      @sequences_in  += 1
      @sequences_out += 1
      @residues_in   += entry.length
      @residues_out  += entry.length

      record.merge! entry.to_bp
    end

    # Assign values to status hash.
    #
    # @param status [Hash] Status hash.
    def assign_status(status)
      status[:records_in]    = @records_in
      status[:records_out]   = @records_out
      status[:sequences_in]  = @sequences_in
      status[:sequences_out] = @sequences_out
      status[:residues_in]   = @residues_in
      status[:residues_out]  = @residues_out
    end
  end
end
