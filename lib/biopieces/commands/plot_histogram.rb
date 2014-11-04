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
    # GNUplot's facility for setting the xrange labels is used for numeric
    # values, while for non-numeric values these are used for xrange labels.
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
    #                   [, ylogscale: <bool>]]]]]]]])
    # 
    # === Options
    #
    # * key: <string>      - Key to use for plotting.
    # * value: <string>    - Alternative key who's value to use.
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
      options_load_rc(options, __method__)
      options_allowed(options, :key, :value, :output, :force, :terminal, :title, :xlabel, :ylabel, :ylogscale)
      options_allowed_values(options, terminal: [:dumb, :post, :svg, :x11, :aqua, :png, :pdf])
      options_allowed_values(options, force: [nil, true, false])
      options_required(options, :key)
      options_files_exists_force(options, :output)

      key   = options[:key]
      value = options[:value]
      options[:terminal] ||= :dumb
      options[:title]    ||= "Histogram"
      options[:xlabel]   ||= options[:key]
      options[:ylabel]   ||= "n"
      options[:ylabel]   = "log10(#{options[:ylabel]})" if options[:ylogscale]

      lmb = lambda do |input, output, status|
        status_track(status) do
          count_hash = Hash.new(0)

          input.each do |record|
            status[:records_in] += 1

            if record[key]
              if value
                if record[value]
                  count_hash[record[key]] += record[value]
                else
                  raise "value: #{value} not found in record: #{record}"
                end
              else
                count_hash[record[key]] += 1
              end
            end

            if output
              output << record

              status[:records_out] += 1
            end
          end

          gp = BioPieces::GnuPlot.new
          gp.set terminal:  options[:terminal].to_s
          gp.set title:     options[:title]
          gp.set xlabel:    options[:xlabel]
          gp.set ylabel:    options[:ylabel]
          gp.set output:    options[:output] if options[:output]

          if options[:ylogscale]
            gp.set logscale:  "y"
            gp.set yrange:    "[1:*]"
          else
            gp.set yrange:    "[0:*]"
          end

          gp.set autoscale: "xfix"
          gp.set style:     "fill solid 0.5 border"
          gp.set xtics:     "out"
          gp.set ytics:     "out"
          gp.set "datafile separator" => "\t"

          if count_hash.keys.first.is_a? Numeric
            x_max = count_hash.keys.max || 0

            gp.add_dataset(using: "1:2", with: "boxes notitle") do |plotter|
              (0 .. x_max).each do |x|
                plotter << [x, count_hash[x]]
              end
            end
          else
            if count_hash.first.first.size > 2
              gp.set xtics: "rotate right"
              gp.set xlabel: ""
            end

            gp.add_dataset(using: "2:xticlabels(1)", with: "boxes notitle") do |plotter|
              count_hash.each do |key, value|
                plotter << [key, value]
              end
            end
          end

          puts gp.plot
        end
      end

      @commands << BioPieces::Pipeline::Command.new(__method__, options, options_orig, lmb)

      self
    end
  end
end

