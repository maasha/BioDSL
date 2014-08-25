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
    # == Create a histogram with mean sequence quality scores.
    # 
    # +plot_scores+ creates a histogram of the mean values per base of the
    # quality scores from sequence data.
    # 
    # Plotting is done using GNUplot which allows for different types of output
    # the default one being crufty ASCII graphics.
    # 
    # If plotting scores from sequences of variable length you can use the
    # +count+ option to co-plot the relative count at each base position. This
    # allow you to detect areas with a low relative count showing a high mean
    # score.
    # 
    # GNUplot must be installed for plot_scores to work. Read more here:
    # 
    # http://www.gnuplot.info/
    # 
    # == Usage
    # 
    #    plot_scores([count: <bool>[, output: <file>[, force: <bool>
    #                   [, terminal: <string>[, title: <string>
    #                   [, xlabel: <string>[, ylabel: <string>]]]]]]])
    # 
    # === Options
    #
    # * count: <bool>      - Add line plot of relative counts.
    # * output: <file>     - Output file.
    # * force: <bool>      - Force overwrite existing output file.
    # * terminal: <string> - Terminal for output: dumb|post|svg|x11|aqua|png|pdf (default=dumb).
    # * title: <string>    - Plot title (default="Histogram").
    # * xlabel: <string>   - X-axis label (default=<key>).
    # * ylabel: <string>   - Y-axis label (default="n").
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
    def plot_scores(options = {})
      options_orig = options.dup
      options_allowed(options, :count, :output, :force, :terminal, :title, :xlabel, :ylabel, :ylogscale)
      options_allowed_values(options, count: [true, false])
      options_allowed_values(options, terminal: [:dumb, :post, :svg, :x11, :aqua, :png, :pdf])
      options_files_exists_force(options, :output)

      options[:terminal] ||= :dumb
      options[:title]    ||= "Mean Quality Scores"
      options[:xlabel]   ||= "Sequence Position"
      options[:ylabel]   ||= "Mean Score"

      scores_vec = NArray.int(Config::SCORES_MAX)
      count_vec  = NArray.int(Config::SCORES_MAX)
      max        = 0

      lmb = lambda do |input, output, status|
        status_track(status) do
          input.each do |record|
            status[:records_in] += 1

            if record[:SCORES]
              scores = record[:SCORES]

              if scores.length > 0
                raise BiopiecesError, "score string too long: #{scores.length} > #{SCORES_MAX}" if scores.length > Config::SCORES_MAX

                scores_vec[0 ... scores.length] += NArray.to_na(scores, "byte") - Seq::SCORE_BASE
                count_vec[0 ... scores.length]  += 1

                max = scores.length if scores.length > max
              end
            end

            output << record if output

            status[:records_out] += 1
          end

          max = 1 if max == 0   # ugly fix to avaid index error

          mean_vec   = NArray.sfloat(max)
          mean_vec   = scores_vec[0 ... max].to_f / count_vec[0 ... max]
          count_vec  = count_vec[0 ... max].to_f
          count_vec *= (Seq::SCORE_MAX / count_vec.max(0).to_f)

          x  = (1 .. max).to_a
          y1 = mean_vec.to_a
          y2 = count_vec.to_a

          Gnuplot.open do |gp|
            Gnuplot::Plot.new(gp) do |plot|
              plot.terminal options[:terminal]
              plot.title    options[:title]
              plot.xlabel   options[:xlabel]
              plot.ylabel   options[:ylabel]
              plot.output   options[:output] || "/dev/stderr"
              plot.xrange   "[#{x.min - 1}:#{x.max + 1}]"
              plot.yrange   "[#{Seq::SCORE_MIN}:#{Seq::SCORE_MAX}]"
              plot.style    "fill solid 0.5 border"
              plot.xtics    "out"
              plot.ytics    "out"
              
              plot.data << Gnuplot::DataSet.new([x, y1]) do |ds|
                ds.with  = "boxes"
                ds.title = "mean score"
              end

              if options[:count]
                plot.data << Gnuplot::DataSet.new([x, y2]) do |ds|
                  ds.with  = "lines lt rgb \"black\""
                  ds.title = "relative count"
                end
              end
            end
          end
        end
      end

      @commands << BioPieces::Pipeline::Command.new(__method__, options, options_orig, lmb)

      self
    end
  end
end
