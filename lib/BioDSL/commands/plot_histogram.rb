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
  # == Plot a histogram of numerical values for a specified key.
  #
  # +plot_histogram+ create a histogram plot of the values for a specified key
  # from all records in the stream. Plotting is done using GNUplot which allows
  # for different types of output the default one being crufty ASCII graphics.
  #
  # GNUplot's facility for setting the xrange labels is used for numeric values,
  # while for non-numeric values these are used for xrange labels.
  #
  # GNUplot must be installed for plot_histogram to work. Read more here:
  #
  # http://www.gnuplot.info/
  #
  # == Usage
  #
  #    plot_histogram(<key: <string>>[, value: <string>[, output: <file>
  #                   [, force: <bool>[, terminal: <string>[, title: <string>
  #                   [, xlabel: <string>[, ylabel: <string>
  #                   [, ylogscale: <bool>[, test: <bool>]]]]]]]]])
  #
  # === Options
  #
  # * key: <string>      - Key to use for plotting.
  # * value: <string>    - Alternative key who's value to use.
  # * output: <file>     - Output file.
  # * force: <bool>      - Force overwrite existing output file.
  # * terminal: <string> - Terminal for output: dumb|post|svg|x11|aqua|png|pdf
  #                        (default=dumb).
  # * title: <string>    - Plot title (default="Histogram").
  # * xlabel: <string>   - X-axis label (default=<key>).
  # * ylabel: <string>   - Y-axis label (default="n").
  # * ylogscale: <bool>  - Set y-axis to log scale.
  # * test: <bool>       - Output Gnuplot script instead of plot.
  #
  # == Examples
  #
  # Here we plot a histogram of sequence lengths from a FASTA file:
  #
  #    read_fasta(input: "test.fna").plot_histogram(key: :SEQ_LEN).run
  #
  #                                      Histogram
  #           +             +            +            +            +             +
  #      90 +++-------------+------------+------------+------------+-------------+++
  #          |                                                                    |
  #      80 ++                                                                  **++
  #          |                                                                  **|
  #      70 ++                                                                  **++
  #      60 ++                                                                  **++
  #          |                                                                  **|
  #      50 ++                                                                  **++
  #          |                                                                  **|
  #      40 ++                                                                  **++
  #          |                                                                  **|
  #      30 ++                                                                  **++
  #      20 ++                                                                  **++
  #          |                                                                  **|
  #      10 ++                                                                  **++
  #          |                                                              ******|
  #       0 +++-------------+------------+**--------**+--***-------+**--**********++
  #           +             +            +            +            +             +
  #           0             10           20           30           40            50
  #                                         SEQ_LEN
  #
  # To render X11 output (i.e. instant view) use the +terminal+ option:
  #
  #    read_fasta(input: "test.fna").
  #    plot_histogram(key: :SEQ_LEN, terminal: :x11).run
  #
  # To generate a PNG image and save to file:
  #
  #    read_fasta(input: "test.fna").
  #    plot_histogram(key: :SEQ_LEN, terminal: :png, output: "plot.png").run
  #
  # rubocop:disable ClassLength
  # rubocop:enable LineLength
  class PlotHistogram
    require 'gnuplotter'
    require 'BioDSL/helpers/aux_helper'

    include AuxHelper

    STATS = %i(records_in records_out)

    # Constructor for PlotHistogram.
    #
    # @param options [Hash] Options hash.
    # @option options [String,:Symbol] :key
    # @option options [String,:Symbol] :value
    # @option options [String]         :output
    # @option options [Booleon]        :force
    # @option options [String,:Symbol] :terminal
    # @option options [String]         :title
    # @option options [String]         :xlabel
    # @option options [String]         :ylabel
    # @option options [Booleon]        :ylogscale
    # @option options [Booleon]        :test
    #
    # @return [PlotHistogram] class instance.
    def initialize(options)
      @options     = options
      @key         = options[:key]
      @value       = options[:value]
      @count_hash  = Hash.new(0)
      @gp          = nil

      aux_exist('gnuplot')
      check_options
      defaults
    end

    # Return the command lambda for plot_histogram
    #
    # @return [Proc] command lambda.
    def lmb
      lambda do |input, output, status|
        status_init(status, STATS)

        process_input(input, output)
        plot_create
        plot_output
      end
    end

    private

    # Check options.
    def check_options
      options_allowed(@options, :key, :value, :output, :force, :terminal,
                      :title, :xlabel, :ylabel, :ylogscale, :test)
      options_allowed_values(@options, terminal: [:dumb, :post, :svg, :x11,
                                                  :aqua, :png, :pdf])
      options_allowed_values(@options, force: [nil, true, false])
      options_allowed_values(@options, test: [nil, true, false])
      options_required(@options, :key)
      options_files_exist_force(@options, :output)
    end

    # Set default values for options hash.
    def defaults
      @options[:terminal] ||= :dumb
      @options[:title]    ||= 'Histogram'
      @options[:xlabel]   ||= @options[:key]
      @options[:ylabel]   ||= 'n'

      @options[:ylogscale] &&
        @options[:ylabel] = "log10(#{@options[:ylabel]})"
    end

    # Process the input stream, collect all plot data, and output records.
    #
    # @param input [Enumerator] Input stream.
    # @param output [Enumerator::Yielder] Output stream.
    def process_input(input, output)
      input.each do |record|
        @status[:records_in] += 1

        if (k = record[@key])
          if @value
            if (v = record[@value])
              @count_hash[k] += v
            else
              fail "value: #{@value} not found in record: #{record}"
            end
          else
            @count_hash[k] += 1
          end
        end

        process_output(output, record)
      end
    end

    # Output record to the output stream if such is defined.
    #
    # @param output [Enumerator::Yielder] Output stream.
    # @param record [Hash] BioDSL record.
    def process_output(output, record)
      return unless output
      output << record
      @status[:records_out] += 1
    end

    # Create a Gnuplot using the collected data from the input stream.
    def plot_create
      @gp = GnuPlotter.new
      plot_defaults
      plot_fix_ylogscale

      if @count_hash.empty?
        plot_empty
      elsif @count_hash.keys.first.is_a? Numeric
        plot_numeric
      else
        plot_string
      end

      plot_fix_xtics
    end

    # Set the default values for the plot.
    def plot_defaults
      @gp.set terminal:  @options[:terminal].to_s
      @gp.set title:     @options[:title]
      @gp.set xlabel:    @options[:xlabel]
      @gp.set ylabel:    @options[:ylabel]
      @gp.set autoscale: 'xfix'
      @gp.set style:     'fill solid 0.5 border'
      @gp.set xtics:     'out'
      @gp.set ytics:     'out'
    end

    # Set plot values accodingly if the ylogscale flag is set.
    def plot_fix_ylogscale
      if @options[:ylogscale]
        @gp.set logscale: 'y'
        @gp.set yrange: '[1:*]'
      else
        @gp.set yrange: '[0:*]'
      end
    end

    # Set plot values to create an empty plot if no plot data was collected.
    def plot_empty
      @gp.set yrange: '[-1:1]'
      @gp.set key:    'off'
      @gp.unset xtics: true
      @gp.unset ytics: true
    end

    # If plot data have numeric xtic values use numeric xtic labels.
    def plot_numeric
      x_max = @count_hash.keys.max || 0

      @gp.add_dataset(using: '1:2', with: 'boxes notitle') do |plotter|
        (0..x_max).each { |x| plotter << [x, @count_hash[x]] }
      end
    end

    # If plot data gave string xtic values use these as xtic labels.
    def plot_string
      plot_xtics_rotate

      @gp.add_dataset(using: '2:xticlabels(1)',
                      with: 'boxes notitle lc rgb "red"') do |plotter|
        @count_hash.each { |k, v| plotter << [k, v] }
      end
    end

    # If xtic labels are longer then 2, rotate these.
    def plot_xtics_rotate
      return unless @count_hash.first.first.size > 2
      @gp.set xtics: 'rotate'
      @gp.set xlabel: ''
    end

    # Determine if xtics should be plottet and unset these if not. Don't plot
    # xtics if more than 50 strings.
    def plot_fix_xtics
      return unless @count_hash.keys.first.class == String &&
                    @count_hash.size > 50
      @gp.unset xtics: true
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
  end
end
