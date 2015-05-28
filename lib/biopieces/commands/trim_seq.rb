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
  # == Trim sequence ends removing residues with a low quality score.
  #
  # +trim_seq+ removes subquality residues from the ends of sequences in the
  # stream based on quality SCORES in a FASTQ type quality score string.
  # Trimming progresses until a stretch, specified with the +length_min+
  # option, is found thus preventing premature termination of the trimming
  # by e.g. a single good quality residue at the end. It is possible, using
  # the +mode+ option to indicate if the sequence should be trimmed from the
  # left or right end or both (default=:both).
  #
  # == Usage
  #
  #    trim_seq([quality_min: <uint>[, length_min: <uint>
  #             [, mode: <:left|:right|:both>]]])
  #
  # === Options
  #
  # * quality_min: <uint> - Minimum quality (default=20).
  # * length_min: <uint>  - Minimum stretch length (default=3).
  # * mode: <string>      - Trim mode :left|:right|:both (default=:both).
  #
  # == Examples
  #
  # Consider the following FASTQ entry in the file test.fq:
  #
  #    @test
  #    gatcgatcgtacgagcagcatctgacgtatcgatcgttgattagttgctagctatgcagtctacgacgagcat
  #    +
  #    @ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghhgfedcba`_^]\[ZYXWVUTSRQPONMLKJI
  #
  # To trim both ends simply do:
  #
  #    BP.new.read_fastq(input: "test.fq").trim_seq.trim_seq.run
  #
  #    SEQ_NAME: test
  #    SEQ: tctgacgtatcgatcgttgattagttgctagctatgcagtctacgacgagcat
  #    SEQ_LEN: 62
  #    SCORES: TUVWXYZ[\]^_`abcdefghhgfedcba`_^]\[ZYXWVUTSRQPONMLKJI
  #    ---
  #
  # Use the +quality_min+ option to change the minimum value to discard:
  #
  #    BP.new.
  #    read_fastq(input: "test.fq").
  #    trim_seq(quality_min: 25).
  #    trim_seq.
  #    run
  #
  #    SEQ_NAME: test
  #    SEQ: cgtatcgatcgttgattagttgctagctatgcagtctacgacgagcatgctagctag
  #    SEQ_LEN: 57
  #    SCORES: YZ[\]^_`abcdefghhgfedcba`_^]\[ZYXWVUTSRQPONMLKJIHGFEDChhh
  #    ---
  #
  # To trim the left end only (use :rigth for right end only), do:
  #
  #    BP.new.read_fastq(input: "test.fq").trim_seq(mode: :left).trim_seq.run
  #
  #    SEQ_NAME: test
  #    SEQ: tctgacgtatcgatcgttgattagttgctagctatgcagtctacgacgagcatgctagctag
  #    SEQ_LEN: 62
  #    SCORES: TUVWXYZ[\]^_`abcdefghhgfedcba`_^]\[ZYXWVUTSRQPONMLKJIHGFEDChhh
  #    ---
  #
  # To increase the length of stretch of good quality residues to match, use
  # the +length_min+ option:
  #
  #    BP.new.read_fastq(input: "test.fq").trim_seq(length_min: 4).trim_seq.run
  #
  #    SEQ_NAME: test
  #    SEQ: tctgacgtatcgatcgttgattagttgctagctatgcagtct
  #    SEQ_LEN: 42
  #    SCORES: TUVWXYZ[\]^_`abcdefghhgfedcba`_^]\[ZYXWVUT
  #    ---
  class TrimSeq
    require 'biopieces/helpers/options_helper'
    extend OptionsHelper

    # Check the options and return a lambda for the command.
    #
    # @param [Hash] options Options hash.
    #
    # @option options [Integer] :quality_min
    #   TrimSeq minimum quality (default=20).
    #
    # @option options [Symbol] :mode
    #   TrimSeq mode (default=:both).
    #
    # @option options [Integer] :length_min
    #   TrimSeq stretch length triggering trim (default=3).
    #
    # @return [Proc] Returns the trim_seq command lambda.
    def self.lmb(options = {})
      options_allowed(options, :quality_min, :length_min, :mode)
      options_allowed_values(options, mode: [:left, :right, :both])
      options_assert(options, ':quality_min >= 0')
      options_assert(options, ':quality_min <= 40')
      options_assert(options, ':length_min > 0')

      options[:quality_min] ||= 20
      options[:mode]        ||= :both
      options[:length_min]  ||= 3

      new(options).lmb
    end

    # Constructor for the TrimSeq class.
    #
    # @param [Hash] options Options hash.
    #
    # @option options [Integer] :quality_min
    #   TrimSeq minimum quality (default=20).
    #
    # @option options [Symbol] :mode
    #   TrimSeq mode (default=:both).
    #
    # @option options [Integer] :length_min
    #   TrimSeq stretch length triggering trim (default=3).
    #
    # @return [Proc] Returns the trim_seq command lambda.
    #
    # @return [TrimSeq] Returns an instance of the TrimSeq class.
    def initialize(options)
      @options       = options
      @records_in    = 0
      @records_out   = 0
      @sequences_in  = 0
      @sequences_out = 0
      @residues_in   = 0
      @residues_out  = 0

      @mode = options[:mode].to_sym
      @min  = options[:quality_min]
      @len  = options[:length_min]
    end

    # Return a lambda for the trim_seq command.
    #
    # @return [Proc] Returns the trim_seq command lambda.
    def lmb
      lambda do |input, output, status|
        input.each do |record|
          @records_in += 1

          trim_seq(record) if record[:SEQ] && record[:SCORES]

          output << record

          @records_out += 1
        end

        assign_status(status)
      end
    end

    private

    # Trim sequence in a given record with sequence info.
    #
    # @param record [Hash] BioPieces record
    def trim_seq(record)
      entry = BioPieces::Seq.new_bp(record)

      @sequences_in += 1
      @residues_in  += entry.length

      case @mode
      when :both  then entry.quality_trim!(@min, @len)
      when :left  then entry.quality_trim_left!(@min, @len)
      when :right then entry.quality_trim_right!(@min, @len)
      end

      @sequences_out += 1
      @residues_out  += entry.length

      record.merge! entry.to_bp
    end

    # Assign all stats to the status hash.
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
