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
  # == Calculate the mean or local mean of quality SCORES in the stream.
  #
  # +mean_scores+ calculates either the global or local mean value or quality
  # SCORES in the stream. The quality SCORES are encoded Phred style in
  # character string.
  #
  # The global (default) behaviour calculates the SCORES_MEAN as the sum of all
  # the scores over the length of the SCORES string.
  #
  # The local means SCORES_MEAN_LOCAL are calculated using means from a sliding
  # window, where the smallest mean is returned.
  #
  # Thus, subquality records, with either an overall low mean quality or with
  # local dip in quality, can be filtered using +grab+.
  #
  # == Usage
  #
  #    mean_scores([local: <bool>[, window_size: <uint>]])
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
  #    SCORES: 33;34;35;36;37;38;39;40;40;40;40;40;40;40;11;11;11;11;11;40;37;
  #            37;40;40;40;40;40;40;40;40;40;40;40;
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
  class MeanScores
    require 'biopieces/helpers/options_helper'
    require 'biopieces/helpers/status_helper'

    include OptionsHelper
    include StatusHelper

    STATS = %i(records_in records_out sequences_in sequences_out residues_in
               residues_out min_mean max_mean)

    # Constructor for MeanScores.
    #
    # @param options  [Hash]    Options hash.
    # @option options [Boolean] :local
    # @option options [Fixnum]  :window_size
    #
    # @return [MeanScores] Class instance.
    def initialize(options)
      @options = options
      @min     = Float::INFINITY
      @max     = 0
      @sum     = 0
      @count   = 0

      check_options
      defaults
      status_init(STATS)
    end

    # Return command lambda for mean_scores.
    #
    # @return [Proc] Command lambda.
    def lmb
      lambda do |input, output, status|
        input.each do |record|
          @records_in += 1

          calc_mean(record) if record[:SCORES] && record[:SCORES].length > 0

          output << record

          @records_out += 1
        end

        status[:mean_mean]     = (@sum.to_f / @count).round(2)

        status_assign(status, STATS)
      end
    end

    private

    # Check options
    def check_options
      options_allowed(@options, :local, :window_size)
      options_tie(@options, window_size: :local)
      options_allowed_values(@options, local: [true, false])
      options_assert(@options, ':window_size > 1')
    end

    # Set default options.
    def defaults
      @options[:window_size] ||= 5
    end

    # Calculate the mean score for a given record and record
    # count, sum, min and max.
    #
    # @param record [Hash] BioPieces record.
    def calc_mean(record)
      entry = BioPieces::Seq.new_bp(record)

      if @options[:local]
        mean = entry.scores_mean_local(@options[:window_size]).round(2)
        record[:SCORES_MEAN_LOCAL] = mean
      else
        mean = entry.scores_mean.round(2)
        record[:SCORES_MEAN] = mean
      end

      @sum   += mean
      @min    = mean if mean < @min
      @max    = mean if mean > @max
      @count += 1
    end
  end
end
