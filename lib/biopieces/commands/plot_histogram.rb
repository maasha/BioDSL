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
    # == Plot a histogram of numerical values for a specified key.
    # 
    # +plot_histogram+ create a histogram plot of the values for a specified
    # key from all records in the stream. Plotting is done using GNUplot which
    # allows for different types of output the default one being crufty ASCII
    # graphics.
    #
    # GNUplot must be installed for plot_histogram to work. Read more here:
    #
    # http://www.gnuplot.info/
    # 
    # == Usage
    # 
    #    plot_histogram(<key: <string>>[, output: <file>[, force: <bool>
    #                   [, terminal: <string>[, title: <string>
    #                   [, xlabel: <string>[, ylabel: <string>
    #                   [, ylogscale: <bool>]]]]]]])
    # 
    # === Options
    #
    # * key: <string>      - Key to use for plotting.
    # * output: <file>     - Output file.
    # * force: <bool>      - Force overwrite existing output file.
    # * terminal: <string> - Terminal for output: dumb|post|svg|x11|aqua|png|pdf (default=dumb).
    # * title: <string>    - Plot title (default="Histogram").
    # * xlabel: <string>   - X-axis label (default=<key>).
    # * ylabel: <string>   - Y-axis label (default="n").
    # * ylogscale: <bool>  - Set y-axis to log scale.
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
    def plot_histogram(options = {})
      options_orig = options.dup
      @options = options
      options_allowed :key, :output, :force, :terminal, :title, :xlabel, :ylabel, :ylogscale
      options_allowed_values terminal: [:dumb, :post, :svg, :x11, :aqua, :png, :pdf]
      options_required :key
      options_files_exists_force :output

      key = @options[:key]
      @options[:terminal] ||= :dumb
      @options[:title]    ||= "Histogram"
      @options[:xlabel]   ||= @options[:key]
      @options[:ylabel]   ||= "n"
      @options[:ylabel]   = "log10(#{@options[:ylabel]})" if @options[:ylogscale]

      lmb = lambda do |input, output, run_options|
        status_track(input, output, run_options) do
          count_hash = Hash.new(0)

          input.each do |record|
            if record[key]
              count_hash[record[key].to_i] += 1
            end

            output.write record if output
          end

          x_max = count_hash.keys.max

          x = []
          y = []

          (0 .. x_max).each do |i|
            x << i
            y << count_hash[i]
          end

          Gnuplot.open do |gp|
            Gnuplot::Plot.new(gp) do |plot|
              plot.terminal options[:terminal].to_s
              plot.title    options[:title]
              plot.xlabel   options[:xlabel]
              plot.ylabel   options[:ylabel]
              plot.output   options[:output] || "/dev/stderr"
              plot.logscale "y" if options[:ylogscale]
              plot.xrange   "[#{x.min - 1}:#{x.max + 1}]"
              plot.style    "fill solid 0.5 border"
              plot.xtics    "out"
              plot.ytics    "out"

              plot.data << Gnuplot::DataSet.new([x, y]) do |ds|
                ds.with = "boxes"
                ds.notitle
              end
            end
          end
        end
      end

      add(__method__, options, options_orig, lmb)

      self
    end
  end
end

