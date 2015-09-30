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
# This software is part of the BioDSL framework (www.BioDSL.org).        #
#                                                                              #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

# rubocop:disable LineLength
module BioDSL
  # == Plot matches from the stream as a dotplot.
  #
  # +plot_matches+ is used to create dotplots of matches in the stream.
  # plot_matches uses Q_BEG, Q_END, S_BEG, S_END from the stream. If strand
  # information is available either by a STRAND key with the value '+' or '-',
  # or by a DIRECTION key with the value 'forward' or 'reverse' then forward
  # matches will be output in green and reverse matches in red (in all
  # terminals, but +dumb+).
  #
  # Default graphics are crufty ASCII and you probably want high resolution
  # postscript or SVG output instead with is easy using the +terminal+ option.
  # Plotting is done using GNUplot which allows for different types of output.
  #
  # GNUplot must be installed for plot_matches to work. Read more here:
  #
  # http://www.gnuplot.info/
  #
  # == Usage
  #
  #    plot_matches([direction: <string>[, output: <file>[, force: <bool>
  #                 [, terminal: <string>[, title: <string>[, xlabel: <string>
  #                 [, ylabel: <string>[, test: <bool>]]]]]]]])
  #
  # === Options
  #
  # * direction: <string> - Plot matches from forward|reverse|both direction(s)
  #                         (default=both).
  # * output: <file>      - Output file.
  # * force: <bool>       - Force overwrite existing output file.
  # * terminal: <string>  - Terminal for output: dumb|post|svg|x11|aqua|png|pdf
  #                         (default=dumb).
  # * title: <string>     - Plot title (default="Matches").
  # * xlabel: <string>    - X-axis label (default="x").
  # * ylabel: <string>    - Y-axis label (default="y").
  # * test: <bool>        - Output Gnuplot script instead of plot.
  #
  # == Examples
  #
  # Here we plot two matches from a table. The vector records are shown in the
  # +dump+ output:
  #
  #    BP.new.read_table(input: "test.tab").dump.plot_matches.run
  #
  #    {:Q_BEG=>0, :Q_END=>10, :S_BEG=>0, :S_END=>10, :STRAND=>"+"}
  #    {:Q_BEG=>0, :Q_END=>10, :S_BEG=>0, :S_END=>10, :STRAND=>"-"}
  #
  #                                         Matches
  #          +             +             +            +             +             +
  #      10 +>>>-----------+-------------+------------+-------------+----------->>>+
  #          |  >>>>       :             :            :             :       >>>>  |
  #          |      >>>>   :             :            :             :   >>>>      |
  #       8 ++..........>>>>>......................................>>>>>..........++
  #          |             : >>>>        :            :        >>>> :             |
  #          |             :     >>>>    :            :    >>>>     :             |
  #       6 ++.......................>>>>>............>>>>>.......................++
  #          |             :             :>>>>    >>>>:             :             |
  #          |             :             :    >>>>    :             :             |
  #          |             :             :>>>>    >>>>:             :             |
  #       4 ++.......................>>>>>............>>>>>.......................++
  #          |             :     >>>>    :            :    >>>>     :             |
  #          |             : >>>>        :            :        >>>> :             |
  #       2 ++..........>>>>>......................................>>>>>..........++
  #          |      >>>>   :             :            :             :   >>>>      |
  #          |  >>>>       :             :            :             :       >>>>  |
  #       0 +>>>-----------+-------------+------------+-------------+----------->>>+
  #          +             +             +            +             +             +
  #          0             2             4            6             8             10
  #                                            x
  #
  # To render X11 output (i.e. instant view) use the +terminal+ option:
  #
  #    plot_matches(terminal: :x11).run
  #
  # To generate a PNG image and save to file:
  #
  #    plot_matches(terminal: :png, output: "plot.png").run
  #
  # rubocop:disable ClassLength
  # rubocop:enable LineLength
  class PlotMatches
    require 'gnuplotter'
    require 'BioDSL/helpers/aux_helper'

    include AuxHelper

    STATS = %i(records_in records_out matches_in)

    # Constructor for PlotMatches.
    #
    # @param options [Hash] Options hash.
    # @option options [Symbol]  :direction
    # @option options [String]  :output
    # @option options [Boolean] :force
    # @option options [Symbol]  :terminal
    # @option options [String]  :title
    # @option options [String]  :xlabel
    # @option options [String]  :ylabel
    # @option options [Boolean] :test
    #
    # @return [PlotMatches] Class instance.
    def initialize(options)
      @options  = options
      @gp       = nil
      @style1   = {using: '1:2:3:4', with: 'vectors nohead ls 1'}
      @style2   = {using: '1:2:3:4', with: 'vectors nohead ls 2'}

      aux_exist('gnuplot')
      check_options
      defaults
    end

    # Return lambda for command plot_matches.
    #
    # @return [Proc] Command lambda.
    def lmb
      lambda do |input, output, status|
        status_init(status, STATS)

        @gp = GnuPlotter.new
        plot_defaults

        @gp.add_dataset(@style1) do |forward|
          @gp.add_dataset(@style2) do |reverse|
            input.each do |record|
              @status[:records_in] += 1

              plot_match(forward, reverse, record)

              process_output(output, record)
            end
          end
        end

        plot_output
      end
    end

    private

    # Check options.
    def check_options
      options_allowed(@options, :direction, :output, :force, :terminal, :title,
                      :xlabel, :ylabel, :test)
      options_allowed_values(@options, direction: [:forward, :reverse, :both])
      options_allowed_values(@options, terminal: [:dumb, :post, :svg, :x11,
                                                  :aqua, :png, :pdf])
      options_allowed_values(@options, test: [nil, true, false])
      options_files_exist_force(@options, :output)
    end

    # Set default options.
    def defaults
      @options[:direction] ||= :both
      @options[:terminal]  ||= :dumb
      @options[:title]     ||= 'Matches'
      @options[:xlabel]    ||= 'x'
      @options[:ylabel]    ||= 'y'
    end

    # Set plot default attributes.
    def plot_defaults
      @gp.set terminal:  @options[:terminal].to_s
      @gp.set title:     @options[:title]
      @gp.set xlabel:    @options[:xlabel]
      @gp.set ylabel:    @options[:ylabel]
      @gp.set autoscale: 'xfix'
      @gp.set autoscale: 'yfix'
      @gp.set style:     'fill solid 0.5 border'
      @gp.set xtics:     'border out'
      @gp.set ytics:     'border out'
      @gp.set grid:      :true
      @gp.set nokey:     :true
      @gp.set style:     'line 1 linetype 1 linecolor rgb "green" linewidth ' \
        '2 pointtype 6 pointsize default'
      @gp.set style:     'line 2 linetype 1 linecolor rgb "red"   linewidth ' \
        '2 pointtype 6 pointsize default'
    end

    # Add match data to forward or reverse dataset.
    #
    # @param forward [GnuPlotter::DataSet] Forward matches.
    # @param reverse [GnuPlotter::DataSet] Reverse matches.
    # @param record  [Hash] BioDSL record.
    def plot_match(forward, reverse, record)
      return unless record[:Q_BEG] && record[:Q_END] &&
                    record[:S_BEG] && record[:S_END]
      @status[:matches_in] += 1

      q_len = record[:Q_END] - record[:Q_BEG]
      s_len = record[:S_END] - record[:S_BEG]

      plot_match_strand(forward, reverse, record, q_len, s_len)
      plot_match_direction(forward, reverse, record, q_len, s_len)
    end

    # Add match data to forward or reverse dataset depeding on match strand.
    #
    # @param forward [GnuPlotter::DataSet] Forward matches.
    # @param reverse [GnuPlotter::DataSet] Reverse matches.
    # @param record  [Hash] BioDSL record.
    # @param q_len   [Integer] Length of query match.
    # @param s_len   [Integer] Length of subject match.
    def plot_match_strand(forward, reverse, record, q_len, s_len)
      return unless record[:STRAND]

      if record[:STRAND] == '+'
        forward << [record[:Q_BEG], record[:S_BEG], q_len, s_len]
      else
        reverse << [record[:Q_END], record[:S_BEG], -1 * q_len, s_len]
      end
    end

    # Add match data to forward or reverse dataset depeding on match direction.
    #
    # @param forward [GnuPlotter::DataSet] Forward matches.
    # @param reverse [GnuPlotter::DataSet] Reverse matches.
    # @param record  [Hash] BioDSL record.
    # @param q_len   [Integer] Length of query match.
    # @param s_len   [Integer] Length of subject match.
    def plot_match_direction(forward, reverse, record, q_len, s_len)
      return unless record[:DIRECTION]

      if record[:DIRECTION] == 'forward'
        forward << [record[:Q_BEG], record[:S_BEG], q_len, s_len]
      else
        reverse << [record[:Q_END], record[:S_BEG], -1 * q_len, s_len]
      end
    end

    # Output plot data
    def plot_output
      @gp.set output: @options[:output] if @options[:output]

      if @options[:test]
        $stderr.puts @gp.to_gp
      elsif @options[:terminal] == :dumb
        puts @gp.plot
      else
        @gp.plot
      end
    end

    # Emit record to output stream if defined.
    #
    # @param output [Enumerator::Yielder] Output stream.
    # @param record [Hash] BioDSL record.
    def process_output(output, record)
      return unless output
      output << record
      @status[:records_out] += 1
    end
  end
end
