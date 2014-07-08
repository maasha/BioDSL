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
    def mean_scores(options = {})
      options_orig = options.dup
      @options = options
      options_allowed nil

      lmb = lambda do |input, output, run_options|
        status_track(input, output, run_options) do
          input.each do |record|
            if record[:SCORES] and record[:SCORES].length > 0
              entry = BioPieces::Seq.new_bp(record)

              record[:SCORES_MEAN] = entry.scores_mean.round(2)
            end

            output.write record
          end
        end
      end

      add(__method__, options, options_orig, lmb)

      self
    end
  end
end

