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
  # == Slice sequences in the stream and obtain subsequences.
  #
  # Slice subsequences from sequences using index positions, that is single
  # postion residues, or using ranges for stretches of residues.
  #
  # All positions are 0-based.
  #
  # If the records also contain quality SCORES these are also sliced.
  #
  # == Usage
  #
  #    slice_seq(<slice: <index>|<range>>)
  #
  # === Options
  #
  # * slice: <index> - Slice a one residue subsequence.
  # * slice: <range> - Slice a range from the sequence.
  #
  # == Examples
  #
  # Consider the following FASTQ entry in the file test.fq:
  #
  #    @HWI-EAS157_20FFGAAXX:2:1:888:434
  #    TTGGTCGCTCGCTCCGCGACCTCAGATCAGACGTGGGCGAT
  #    +
  #    !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHI
  #
  # To slice the second residue from the beginning do:
  #
  #    BP.new.read_fastq(input: "test.fq").slice_seq(slice: 2).dump.run
  #
  #    {:SEQ_NAME=>"HWI-EAS157_20FFGAAXX:2:1:888:434",
  #     :SEQ=>"G",
  #     :SEQ_LEN=>1,
  #     :SCORES=>"#"}
  #
  # To slice the last residue do:
  #
  #    BP.new.read_fastq(input: "test.fq").slice_seq(slice: -1).dump.run
  #
  #    {:SEQ_NAME=>"HWI-EAS157_20FFGAAXX:2:1:888:434",
  #     :SEQ=>"T",
  #     :SEQ_LEN=>1,
  #     :SCORES=>"I"}
  #
  # To slice the first 5 residues do:
  #
  #    BP.new.read_fastq(input: "test.fq").slice_seq(slice: 0 ... 5).dump.run
  #
  #    {:SEQ_NAME=>"HWI-EAS157_20FFGAAXX:2:1:888:434",
  #     :SEQ=>"TTGGT",
  #     :SEQ_LEN=>5,
  #     :SCORES=>"!\"\#$%"}
  #
  # To slice the last 5 residues do:
  #
  #    BP.new.read_fastq(input: "test.fq").slice_seq(slice: -5 .. -1).dump.run
  #
  #    {:SEQ_NAME=>"HWI-EAS157_20FFGAAXX:2:1:888:434",
  #     :SEQ=>"GCGAT",
  #     :SEQ_LEN=>5,
  #     :SCORES=>"EFGHI"}
  class SliceSeq
    require 'biopieces/helpers/options_helper'

    extend OptionsHelper
    include OptionsHelper

    # Check options and return lambda for command.
    #
    # @param options [Hash] Options hash.
    # @option options [Range,Integer] :slice
    #
    # @return [Proc] Command lambda.
    def self.lmb(options)
      options_load_rc(options, __method__)
      options_allowed(options, :slice)
      options_required(options, :slice)

      new(options).lmb
    end

    # Constructor for SliceSeq.
    #
    # @param options [Hash] Options hash.
    # @option options [Range,Integer] :slice
    #
    # @return [SliceSeq] Class instance.
    def initialize(options)
      @options       = options
      @records_in    = 0
      @records_out   = 0
      @sequences_in  = 0
      @sequences_out = 0
      @residues_in   = 0
      @residues_out  = 0
    end

    # Return lambda for command.
    #
    # @return [Proc] Command lambda.
    def lmb
      lambda do |input, output, status|
        input.each do |record|
          @records_in += 1

          slice_seq(record) if record.key? :SEQ

          output << record

          @records_out += 1
        end

        assign_status(status)
      end
    end

    private

    # Slice sequence in given record.
    #
    # @param record [Hash] Biopieces record.
    def slice_seq(record)
      entry = BioPieces::Seq.new_bp(record)

      @sequences_in += 1
      @residues_in  += entry.length

      entry = entry[@options[:slice]]

      @sequences_out += 1
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
