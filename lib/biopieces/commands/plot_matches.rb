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
    # +plot_matches+ create a histogram plot of the values for a specified
    # key from all records in the stream. Plotting is done using GNUplot which
    # allows for different types of output the default one being crufty ASCII
    # graphics.
    #
    # GNUplot must be installed for plot_matches to work. Read more here:
    #
    # http://www.gnuplot.info/
    # 
    # == Usage
    # 
    #    plot_matches([direction: <string>[, output: <file>[, force: <bool>
    #                 [, terminal: <string>[, title: <string>[, xlabel:
    #                 <string>[, ylabel: <string>]]]]]]])
    # 
    # === Options
    #
    # * direction: <string> - Direction of matches to plot: forward|reverse|both (default=both).
    # * output: <file>      - Output file.
    # * force: <bool>       - Force overwrite existing output file.
    # * terminal: <string>  - Terminal for output: dumb|post|svg|x11|aqua|png|pdf (default=dumb).
    # * title: <string>     - Plot title (default="Histogram").
    # * xlabel: <string>    - X-axis label (default=<key>).
    # * ylabel: <string>    - Y-axis label (default="n").
    #
    # == Examples
    # 
    # Here we plot a histogram of sequence lengths from a FASTA file:
    # 
    #    read_fasta(input: "test.fna").plot_matches(key: :SEQ_LEN).run
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
    #    plot_matches(key: :SEQ_LEN, terminal: :x11).run
    # 
    # To generate a PNG image and save to file:
    # 
    #    read_fasta(input: "test.fna").
    #    plot_matches(key: :SEQ_LEN, terminal: :png, output: "plot.png").run
    def plot_matches(options = {})
      require 'gnuplot'

      options_orig = options.dup
      options_allowed(options, :direction, :output, :force, :terminal, :title, :xlabel, :ylabel)
      options_allowed_values(options, direction: [:forward, :reverse, :both])
      options_allowed_values(options, terminal: [:dumb, :post, :svg, :x11, :aqua, :png, :pdf])
      options_files_exists_force(options, :output)

      options[:direction] ||= :both
      options[:terminal]  ||= :dumb
      options[:title]     ||= "Matches"
      options[:xlabel]    ||= "x"
      options[:ylabel]    ||= "y"

      lmb = lambda do |input, output, status|
        status[:matches_in] = 0

        status_track(status) do
          gp = BioPieces::GnuPlot.new
          gp.set terminal:  options[:terminal].to_s
          gp.set title:     options[:title]
          gp.set xlabel:    options[:xlabel]
          gp.set ylabel:    options[:ylabel]
          gp.set output:    options[:output] || "/dev/stderr"
          gp.set autoscale: "xfix"
          gp.set autoscale: "yfix"
          gp.set style:     "fill solid 0.5 border"
          gp.set xtics:     "border out"
          gp.set ytics:     "border out"
          gp.set grid:      :true
          gp.set nokey:     :true
          gp.set style:     "line 1 linetype 1 linecolor rgb 'green' linewidth 1 pointtype 6 pointsize default"
          gp.set style:     "line 2 linetype 1 linecolor rgb 'red'   linewidth 1 pointtype 6 pointsize default"

          gp.add_dataset(using: "1:2:3:4", with: "vectors nohead ls 1" ) do |forward|
            gp.add_dataset(using: "1:2:3:4", with: "vectors nohead ls 2") do |reverse|
              input.each do |record|
                status[:records_in] += 1

                if record[:Q_BEG] and record[:Q_END] and record[:S_BEG] and record[:S_END]
                  status[:matches_in] += 1

                  record[:Q_BEG] = record[:Q_BEG]
                  record[:S_BEG] = record[:S_BEG]
                  record[:Q_END] = record[:Q_END]
                  record[:S_END] = record[:S_END]

                  q_len = record[:Q_END] - record[:Q_BEG]
                  s_len = record[:S_END] - record[:S_BEG]

                  if strand = record[:STRAND]
                    if strand == '+'
                      forward << [record[:Q_BEG], record[:S_BEG], q_len, s_len]
                    else
                      reverse << [record[:Q_END], record[:S_BEG], -1 * q_len, s_len]
                    end
                  elsif direction = record[:DIRECTION]
                    if direction == 'forward'
                      forward << [record[:Q_BEG], record[:S_BEG], q_len, s_len]
                    else
                      reverse << [record[:Q_END], record[:S_BEG], -1 * q_len, s_len]
                    end
                  end
                end

                if output
                  output << record

                  status[:records_out] += 1
                end
              end
            end
          end

          gp.plot
        end
      end

      @commands << BioPieces::Pipeline::Command.new(__method__, options, options_orig, lmb)

      self
    end
  end
end

