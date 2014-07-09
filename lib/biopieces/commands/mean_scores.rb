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
    # == Calculate the mean or local mean of quality SCORES in the stream.
    # 
    # +mean_scores+ calculates either the global or local mean value or quality
    # SCORES in the stream. The quality SCORES are encoded Phred style in
    # character string.
    #
    # The global (default) behaviour calculates the SCORES_MEAN as the sum of
    # all the scores over the length of the SCORES string.
    #
    # The local means SCORES_MEAN_LOCAL are calculated using means from a
    # sliding window, where the smallest mean is returned.
    #
    # Thus, subquality records, with either an overall low mean quality or with
    # local dip in quality, can be filtered using +grab+.
    #
    # == Usage
    # 
    #    trim_seq([local: <bool>[, window_size: <uint>]])
    #
    # === Options
    #
    # * local:       <bool> - Calculate local mean score (default=false).
    # * window_size: <uint> - Size of sliding window (defaul=5).
    #
    # == Examples
    # 
    # Consider the following FASTQ entry in the file test.fq:
    # 
    #    @HWI-EAS157_20FFGAAXX:2:1:888:434
    #    TTGGTCGCTCGCTCGACCTCAGATCAGACGTGG
    #    +
    #    BCDEFGHIIIIIII,,,,,IFFIIIIIIIIIII
    #
    # The values of the scores in decimal are:
    #
    #    SCORES: 33;34;35;36;37;38;39;40;40;40;40;40;40;40;11;11;11;11;11;40;
    #            37;37;40;40;40;40;40;40;40;40;40;40;40;
    # 
    # To calculate the mean score do:
    # 
    #    BP.new.read_fastq(input: "test.fq").mean_scores.dump.run
    #
    #    {:SEQ_NAME=>"HWI-EAS157_20FFGAAXX:2:1:888:434",
    #     :SEQ=>"TTGGTCGCTCGCTCGACCTCAGATCAGACGTGG",
    #     :SEQ_LEN=>33,
    #     :SCORES=>"BCDEFGHIIIIIII,,,,,IFFIIIIIIIIIII",
    #     :SCORES_MEAN=>34.58}
    #
    # To calculate local means for a sliding window, do:
    #
    #    BP.new.read_fastq(input: "test.fq").mean_scores(local: true).dump.run
    #
    #    {:SEQ_NAME=>"HWI-EAS157_20FFGAAXX:2:1:888:434",
    #     :SEQ=>"TTGGTCGCTCGCTCGACCTCAGATCAGACGTGG",
    #     :SEQ_LEN=>33,
    #     :SCORES=>"BCDEFGHIIIIIII,,,,,IFFIIIIIIIIIII",
    #     :SCORES_MEAN_LOCAL=>11.0}
    #
    # Which indicates a local minimum was located at the stretch of ,,,,, =
    # 11+11+11+11+11 / 5 = 11.0
    def mean_scores(options = {})
      options_orig = options.dup
      @options = options
      options_allowed :local, :window_size
      options_tie window_size: :local
      options_allowed_values local: [true, false]
      options_assert ":window_size > 1"

      @options[:window_size] ||= 5

      lmb = lambda do |input, output, run_options|
        status_track(input, output, run_options) do
          input.each do |record|
            if record[:SCORES] and record[:SCORES].length > 0
              entry = BioPieces::Seq.new_bp(record)

              if options[:local]
                record[:SCORES_MEAN_LOCAL] = entry.scores_mean_local(options[:window_size]).round(2)
              else
                record[:SCORES_MEAN] = entry.scores_mean.round(2)
              end
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

