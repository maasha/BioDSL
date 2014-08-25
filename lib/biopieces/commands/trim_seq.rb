# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #
#                                                                                #
# Copyright (C) 2007-2014 Martin Asser Hansen (mail@maasha.dk).                  #
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
    #    trim_seq([quality_min: <uint>[, length_min: <uint>[, mode: <:left|:right|:both>]]])
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
    #    gatcgatcgtacgagcagcatctgacgtatcgatcgttgattagttgctagctatgcagtctacgacgagcatgctagctag
    #    +
    #    @ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghhgfedcba`_^]\[ZYXWVUTSRQPONMLKJIHGFEDChhh
    # 
    # To trim both ends simply do:
    # 
    #    BP.new.read_fastq(input: "test.fq").trim_seq.dump.run
    # 
    #    SEQ_NAME: test
    #    SEQ: tctgacgtatcgatcgttgattagttgctagctatgcagtctacgacgagcatgctagctag
    #    SEQ_LEN: 62
    #    SCORES: TUVWXYZ[\]^_`abcdefghhgfedcba`_^]\[ZYXWVUTSRQPONMLKJIHGFEDChhh
    #    ---
    # 
    # Use the +quality_min+ option to change the minimum value to discard:
    # 
    #    BP.new.read_fastq(input: "test.fq").trim_seq(quality_min: 25).dump.run
    # 
    #    SEQ_NAME: test
    #    SEQ: cgtatcgatcgttgattagttgctagctatgcagtctacgacgagcatgctagctag
    #    SEQ_LEN: 57
    #    SCORES: YZ[\]^_`abcdefghhgfedcba`_^]\[ZYXWVUTSRQPONMLKJIHGFEDChhh
    #    ---
    # 
    # To trim the left end only (use :rigth for right end only), do:
    # 
    #    BP.new.read_fastq(input: "test.fq").trim_seq(mode: :left).dump.run
    # 
    #    SEQ_NAME: test
    #    SEQ: tctgacgtatcgatcgttgattagttgctagctatgcagtctacgacgagcatgctagctag
    #    SEQ_LEN: 62
    #    SCORES: TUVWXYZ[\]^_`abcdefghhgfedcba`_^]\[ZYXWVUTSRQPONMLKJIHGFEDChhh
    #    ---
    # 
    # To increase the length of stretch of good quality residues to match, use the -l
    # switch:
    # 
    #    BP.new.read_fastq(input: "test.fq").trim_seq(lengh_min: 4).dump.run
    # 
    #    SEQ_NAME: test
    #    SEQ: tctgacgtatcgatcgttgattagttgctagctatgcagtct
    #    SEQ_LEN: 42
    #    SCORES: TUVWXYZ[\]^_`abcdefghhgfedcba`_^]\[ZYXWVUT
    #    ---
    def trim_seq(options = {})
      options_orig = options.dup
      options_allowed(options, :quality_min, :length_min, :mode)
      options_allowed_values(options, mode: [:left, :right, :both])
      options_assert(options, ":quality_min >= 0")
      options_assert(options, ":quality_min <= 40")
      options_assert(options, ":length_min > 0")

      options[:quality_min] ||= 20
      options[:mode]        ||= :both
      options[:length_min]  ||= 3

      lmb = lambda do |input, output, status|
        status_track(status) do
          status[:sequences_in]  = 0
          status[:sequences_out] = 0
          status[:residues_in]   = 0
          status[:residues_out]  = 0

          mode = options[:mode].to_sym

          input.each do |record|
            status[:records_in] += 1

            if record[:SEQ] and record[:SCORES]
              entry = BioPieces::Seq.new_bp(record)

              status[:sequences_in] += 1
              status[:residues_in]  += entry.length

              case mode
              when :both  then entry.quality_trim!(options[:quality_min], options[:length_min])
              when :left  then entry.quality_trim_left!(options[:quality_min], options[:length_min])
              when :right then entry.quality_trim_right!(options[:quality_min], options[:length_min])
              end

              status[:sequences_out] += 1
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

