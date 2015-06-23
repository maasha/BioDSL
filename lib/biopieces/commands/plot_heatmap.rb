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
  # == Plot tabular numerical data in a heatmap.
  #
  # A heatmap can be plotted with +plot_heatmap+ using numerical data (Non-
  # numerical data is ignored). Data should be tabular with records as rows and
  # keys as columns - the data cells plotted will be the values.
  #
  # Default graphics are crufty ASCII and you probably want high resolution
  # postscript or SVG output instead with is easy using the +terminal+ option.
  # Plotting is done using GNUplot which allows for different types of output.
  #
  # GNUplot must be installed for +plot_heatmap+ to work. Read more here:
  #
  # http://www.gnuplot.info/
  #
  # == Usage
  #
  #    plot_heatmap([keys: <list> | skip: <list>[, output: <file>
  #                 [, force: <bool> [, terminal: <string>
  #                 [, title: <string>[, xlabel: <string>[, ylabel: <string>
  #                 [, test: <bool>]]]]]]])
  #
  # === Options
  #
  # * keys: <list>        - Comma separated list of keys to plot as columns.
  # * skip: <list>        - Comma separated list of keys to skip as columns.
  # * output: <file>      - Output file.
  # * force: <bool>       - Force overwrite existing output file.
  # * terminal: <string>  - Terminal for output: dumb|post|svg|x11|aqua|png|pdf
  #                         (default=dumb).
  # * title: <string>     - Plot title (default="Heatmap").
  # * xlabel: <string>    - X-axis label (default="x").
  # * ylabel: <string>    - Y-axis label (default="y").
  # * test: <bool>        - Output Gnuplot script instead of plot.
  #
  # == Examples
  #
  # Here we plot a heatmap of data a table:
  #
  #    BP.new.read_table(input: "test.tab").plot_heatmap.run
  #
  # rubocop:disable ClassLength
  class PlotHeatmap
    require 'gnuplotter'
    require 'set'
    require 'biopieces/helpers/aux_helper'

    include AuxHelper

    STATS = %i(records_in records_out)

    # Constructor for PlotHeatmap.
    #
    # @param options [Hash] Options hash.
    # @option options [Array]   :keys List of keys to plot as column.
    # @option options [Array]   :skip List of keys to skip as column.
    # @option options [String]  :output Path to output file.
    # @option options [Boolean] :forcea Flag to force overwrite output file.
    # @option options [Symbol]  :terminal Set plot terminal type.
    # @option options [String]  :title Set plot title.
    # @option options [String]  :xlabel Set plot xlabel.
    # @option options [String]  :ylabel Set plot ylabel
    # @option options [Boolean] :logscale Logscale Z-axis.
    # @option options [Boolean] :test Output gnuplot script.
    #
    # @return [PlotHeatmap] Class instance.
    def initialize(options)
      @options   = options
      @headings  = nil
      @skip_keys = determine_skip_keys

      aux_exist('gnuplot')
      check_options
      defaults
    end

    # Return command lambda for plot_histogram.
    #
    # @return [Proc] Command lambda.
    def lmb
      lambda do |input, output, status|
        status_init(status, STATS)

        gp = GnuPlotter.new

        plot_options(gp)
        plot_dataset(gp, input, output)
        plot_output(gp)
      end
    end

    private

    # Check options.
    def check_options
      options_allowed(@options, :keys, :skip, :output, :force, :terminal,
                      :title, :xlabel, :ylabel, :logscale, :test)
      options_unique(@options, :keys, :skip)
      options_allowed_values(@options, terminal: [:dumb, :post, :svg, :x11,
                                                  :aqua, :png, :pdf])
      options_allowed_values(@options, test: [nil, true, false])
      options_allowed_values(@options, logscale: [nil, true, false])
      options_files_exist_force(@options, :output)
    end

    # Set default options.
    def defaults
      @options[:terminal] ||= :dumb
      @options[:title]    ||= 'Heatmap'
      @options[:xlabel]   ||= 'x'
      @options[:ylabel]   ||= 'y'
    end

    # Compile a set of keys to skip.
    #
    # @return [Set] Set of keys to skip.
    def determine_skip_keys
      return unless @options[:skip]
      @options[:skip].each_with_object(Set.new) { |e, a| a << e.to_sym }
    end

    # Determine the headings.
    #
    # @param record [Hash] BioPieces record.
    def determine_headings(record)
      @headings =
        if @options[:keys]
          @options[:keys].map(&:to_sym)
        elsif record.keys.first =~ /^V\d+$/
          sort_keys(record)
        else
          record.keys
        end

      @headings.reject! { |r| @skip_keys.include? r } if @options[:skip]
    end

    # Sort records keys numerically, when the keys are in the format Vn, where n
    # is an Integer.
    #
    # @param record [Hash] BioPieces record.
    #
    # @return [Array] List of sorted keys.
    def sort_keys(record)
      record.keys.sort do |a, b|
        a.to_s[1..a.to_s.size].to_i <=> b.to_s[1..a.to_s.size].to_i
      end
    end

    # Set options for plot.
    #
    # @param gp [GnuPlotter] GnuPlotter object.
    def plot_options(gp)
      gp.set terminal:  @options[:terminal].to_s
      gp.set title:     @options[:title]
      gp.set xlabel:    @options[:xlabel]
      gp.set ylabel:    @options[:ylabel]
      gp.set output:    @options[:output] if @options[:output]
      gp.set view:      'map'
      gp.set autoscale: 'xfix'
      gp.set autoscale: 'yfix'
      gp.set nokey:     true
      gp.set tic:       'scale 0'
      gp.set palette:   'rgbformulae 22,13,10'
      gp.set logscale:  'cb' if @options[:logscale]
      gp.unset xtics:   true
      gp.unset ytics:   true
    end

    # Plot relevant data from the input stream.
    #
    # @param gp [GnuPlotter] GnuPlotter object.
    # @param input [Enumerator] Input stream.
    # @param output [Enumerator::Yielder] Output stream.
    def plot_dataset(gp, input, output)
      gp.add_dataset(matrix: :true, with: 'image') do |plotter|
        input.each do |record|
          @status[:records_in] += 1

          determine_headings(record) unless @headings

          plotter << record.values_at(*@headings)

          next unless output

          output << record

          @status[:records_out] += 1
        end
      end
    end

    # Output plot data according to options.
    #
    # @param gp [GnuPlotter] GnuPlotter object.
    def plot_output(gp)
      if @options[:test]
        $stderr.puts gp.to_gp
      elsif @options[:terminal] == :dumb
        puts gp.splot
      else
        gp.splot
      end
    end
  end
end
