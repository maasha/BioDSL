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

# rubocop: disable LineLength
module BioPieces
  # == Create a histogram with mean sequence quality scores.
  #
  # +plot_scores+ creates a histogram of the mean values per base of the quality
  # scores from sequence data.
  #
  # Plotting is done using GNUplot which allows for different types of output
  # the default one being crufty ASCII graphics.
  #
  # If plotting scores from sequences of variable length you can use the +count+
  # option to co-plot the relative count at each base position. This allow you
  # to detect areas with a low relative count showing a high mean score.
  #
  # GNUplot must be installed for plot_scores to work. Read more here:
  #
  # http://www.gnuplot.info/
  #
  # == Usage
  #
  #    plot_scores([count: <bool>[, output: <file>[, force: <bool>
  #                [, terminal: <string>[, title: <string>
  #                [, xlabel: <string>[, ylabel: <string>
  #                [, test: <bool>]]]]]]]])
  #
  # === Options
  #
  # * count: <bool>      - Add line plot of relative counts.
  # * output: <file>     - Output file.
  # * force: <bool>      - Force overwrite existing output file.
  # * terminal: <string> - Terminal for output: dumb|post|svg|x11|aqua|png|pdf
  #                        (default=dumb).
  # * title: <string>    - Plot title (default="Histogram").
  # * xlabel: <string>   - X-axis label (default=<key>).
  # * ylabel: <string>   - Y-axis label (default="n").
  # * test: <bool>       - Output Gnuplot script instread of plot.
  #
  # == Examples
  #
  # Here we plot the mean quality scores from a FASTQ file:
  #
  #    read_fastq(input: "test.fq").plot_scores.run
  #
  #                                 Mean Quality Scores
  #        +             +            +             +             +            +
  #    40 ++-------------+------------+-------------+-------------+------------+++
  #        |  *****************                               mean score ****** |
  #    35 ++ ***********************                                            ++
  #        ****************************** **                                    |
  #    30 +*********************************   *                                ++
  #        ************************************* *                              |
  #    25 +*************************************** *                            ++
  #        ****************************************** *****                     |
  #    20 +****************************************************  ** * *         ++
  #        ******************************************************************** *
  #    15 +**********************************************************************+
  #        **********************************************************************
  #    10 +**********************************************************************+
  #        **********************************************************************
  #     5 +**********************************************************************+
  #        **********************************************************************
  #     0 +**********************************************************************+
  #        +             +            +             +             +            +
  #        0             50          100           150           200          250
  #                                  Sequence position
  #
  # To render X11 output (i.e. instant view) use the +terminal+ option:
  #
  #    read_fastq(input: "test.fq").
  #    plot_scores(terminal: :x11).run
  #
  # To generate a PNG image and save to file:
  #
  #    read_fastq(input: "test.fq").
  #    plot_scores(terminal: :png, output: "plot.png").run
  #
  # rubocop: enable LineLength
  # rubocop: disable ClassLength
  class PlotScores
    require 'gnuplotter'
    require 'narray'
    require 'biopieces/helpers/aux_helper'

    include AuxHelper

    STATS = %i(records_in records_out sequences_in sequences_out residues_in
               records_out)

    # Constructor for PlotScores.
    #
    # @param options [Hash] Options hash.
    # @option options [Boolean] :count
    # @option options [String]  :output
    # @option options [Boolean] :force
    # @option options [Symbol]  :terminal
    # @option options [String]  :title
    # @option options [String]  :xlabel
    # @option options [String]  :ylabel
    # @option options [Boolean] :ylogscale
    # @option options [Boolean] :test
    #
    # @return [PlotScores] Class instance.
    def initialize(options)
      @options    = options
      @scores_vec = NArray.int(Config::SCORES_MAX)
      @count_vec  = NArray.int(Config::SCORES_MAX)
      @max        = 0

      aux_exist('gnuplot')
      check_options
      default
      status_init(STATS)
    end

    # Return command lambda for plot_scores.
    #
    # @return [Proc] Command lambda.
    def lmb
      lambda do |input, output, status|
        input.each do |record|
          @records_in += 1

          collect_plot_data(record)

          write_output(output, record)
        end

        prepare_plot_data

        plot_defaults
        plot_scores
        plot_count
        plot_output

        status_assign(status, STATS)
      end
    end

    private

    # Check options.
    def check_options
      options_allowed(@options, :count, :output, :force, :terminal, :title,
                      :xlabel, :ylabel, :ylogscale, :test)
      options_allowed_values(@options, count: [true, false])
      options_allowed_values(@options, test: [true, false])
      options_allowed_values(@options, terminal: [:dumb, :post, :svg, :x11,
                                                  :aqua, :png, :pdf])
      options_files_exist_force(@options, :output)
    end

    # Set default options.
    def default
      @options[:terminal] ||= :dumb
      @options[:title]    ||= 'Mean Quality Scores'
      @options[:xlabel]   ||= 'Sequence Position'
      @options[:ylabel]   ||= 'Mean Score'
    end

    # Collect plot data from a given record.
    #
    # @param record [Hash] BioPieces record.
    def collect_plot_data(record)
      scores = record[:SCORES]
      return unless scores && scores.length > 0

      check_length(scores)

      score_vec = NArray.to_na(scores, 'byte') - Seq::SCORE_BASE
      @scores_vec[0...scores.length] += score_vec
      @count_vec[0...scores.length]  += 1

      @max = scores.length if scores.length > @max
    end

    # Check if the scores string is longer than SCORES_MAX.
    #
    # @raise [BiopiecesError] if too long.
    def check_length(scores)
      return unless scores.length > Config::SCORES_MAX
      msg = "score string too long: #{scores.length} > #{SCORES_MAX}"
      fail BiopiecesError, msg
    end

    # Prepare data to plot.
    def prepare_plot_data
      @max = 1 if @max == 0   # ugly fix to avaid index error

      count_vec  = @count_vec[0...@max].to_f
      count_vec *= (Seq::SCORE_MAX / @count_vec.max(0).to_f)

      @x  = (1..@max).to_a
      @y1 = mean_vec.to_a
      @y2 = count_vec.to_a
    end

    # Calculate the mean scores vector.
    #
    # @return [NArray] NArray with mean scores.
    def mean_vec
      @scores_vec[0...@max].to_f / @count_vec[0...@max]
    end

    # Set plot defaults
    def plot_defaults
      @gp = GnuPlotter.new
      @gp.set terminal: @options[:terminal]
      @gp.set title:    @options[:title]
      @gp.set xlabel:   @options[:xlabel]
      @gp.set ylabel:   @options[:ylabel]
      @gp.set output:   @options[:output] if @options[:output]
      @gp.set xrange:   "[#{@x.min - 1}:#{@x.max + 1}]"
      @gp.set yrange:   "[#{Seq::SCORE_MIN}:#{Seq::SCORE_MAX}]"
      @gp.set style:    'fill solid 0.5 border'
      @gp.set xtics:    'out'
      @gp.set ytics:    'out'
    end

    # Plot scores data.
    def plot_scores
      style = {with: 'boxes lc rgb "red"', title: '"mean score"'}

      @gp.add_dataset(style) do |plotter|
        @x.zip(@y1).each { |e| plotter << e }
      end
    end

    # Plot count data.
    def plot_count
      return unless @options[:count]

      style = {with: 'lines lt rgb "black"', title: '"relative count"'}

      @gp.add_dataset(style) do |plotter|
        @x.zip(@y2).each { |e| plotter << e }
      end
    end

    # Output plot
    def plot_output
      if @options[:test]
        $stderr.puts @gp.to_gp
      elsif @options[:terminal] == :dumb
        puts @gp.plot
      else
        @gp.plot
      end
    end

    # Write record to output.
    def write_output(output, record)
      return unless output
      output << record
      @records_out += 1
    end
  end
end
