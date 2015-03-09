# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #
#                                                                                #
# Copyright (C) 2007-2015 Martin Asser Hansen (mail@maasha.dk).                  #
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
    # == Plot the residue distribution of sequences in the stream.
    #
    # +plot_residue_distribution+ creates a residue distribution plot per
    # sequence position of sequences in the stream. Plotting is done using
    # GNUplot which allows for different types of output the default one being
    # crufty ASCII graphics.
    #
    # If plotting distributions from sequences of variable length you can use
    # the +count+ option to co-plot the relative count at each base position.
    # This allow you to explain areas with a scewed distribution.
    #
    # GNUplot must be installed for +plot_residue_distribution+ to work.
    # Read more here:
    #
    # http://www.gnuplot.info/
    # 
    # == Usage
    # 
    #    plot_residue_distribution([count: <bool>[, output: <file>
    #                              [, force: <bool> [, terminal: <string>
    #                              [, title: <string>[, xlabel: <string>
    #                              [, ylabel: <string>[, test: <bool>]]]]]]])
    # 
    # === Options
    #
    # * count: <bool>       - Plot relative count (default=false).
    # * output: <file>      - Output file.
    # * force: <bool>       - Force overwrite existing output file.
    # * terminal: <string>  - Terminal for output: dumb|post|svg|x11|aqua|png|pdf (default=dumb).
    # * title: <string>     - Plot title (default="Heatmap").
    # * xlabel: <string>    - X-axis label (default="x").
    # * ylabel: <string>    - Y-axis label (default="y").
    # * test: <bool>        - Output Gnuplot script instead of plot.
    #
    # == Examples
    # 
    # Here we plot a residue distribution of a FASTA file:
    # 
    #    BP.new.read_fasta(input: "test.fna").plot_residue_distribution.run
    def plot_residue_distribution(options = {})
      require 'gnuplotter'

      options_orig = options.dup
      options_load_rc(options, __method__)
      options_allowed(options, :count, :output, :force, :terminal, :title, :xlabel, :ylabel, :test)
      options_allowed_values(options, terminal: [:dumb, :post, :svg, :x11, :aqua, :png, :pdf])
      options_allowed_values(options, count: [nil, true, false])
      options_allowed_values(options, test: [nil, true, false])
      options_files_exists_force(options, :output)
      aux_exist("gnuplot")

      options[:terminal] ||= :dumb
      options[:title]    ||= "Residue Distribution"
      options[:xlabel]   ||= "Sequence position"
      options[:ylabel]   ||= "%"

      lmb = lambda do |input, output, status|
        status_track(status) do
          status[:sequences_in]  = 0
          status[:sequences_out] = 0
          counts   = Hash.new { |h, k| h[k] = Hash.new(0) } 
          total    = Hash.new(0)
          residues = Set.new

          input.each do |record|
            status[:records_in] += 1

            if seq = record[:SEQ]
              status[:sequences_in] += 1

              seq.upcase.chars.each_with_index do |char, i|
                c = char.to_sym
                counts[i][c] += 1
                total[i]     += 1
                residues.add(c)
              end

              if output
                output << record

                status[:records_out]   += 1
                status[:sequences_out] += 1
              end
            else
              if output
                output << record

                status[:records_out] += 1
              end
            end
          end

          gp = GnuPlotter.new
          gp.set terminal:  options[:terminal].to_s
          gp.set title:     options[:title]
          gp.set xlabel:    options[:xlabel]
          gp.set ylabel:    options[:ylabel]
          gp.set output:    options[:output] if options[:output]
          gp.set xtics:     "out"
          gp.set ytics:     "out"
          gp.set yrange:   "[0:#{100}]"
          gp.set xrange:   "[0:#{counts.size}]"
          gp.set auto:     "fix"
          gp.set offsets:  "1"
          gp.set key:      "outside right top vertical Left reverse noenhanced autotitles columnhead nobox"
          gp.set key:      "invert samplen 4 spacing 1 width 0 height 0"
          gp.set style:    "fill solid 0.5 border"
          gp.set style:    "histogram rowstacked"
          gp.set style:    "data histograms"
          # color scheme: http://en.wikipedia.org/wiki/Help:Distinguishable_colors
          gp.set linetype: "1 lc rgb '#F0A3FF'" # Amethyst
          gp.set linetype: "2 lc rgb '#0075DC'" # Blue
          gp.set linetype: "3 lc rgb '#993F00'" # Caramel
          gp.set linetype: "4 lc rgb '#4C005C'" # Damson
          gp.set linetype: "5 lc rgb '#191919'" # Ebony
          gp.set linetype: "6 lc rgb '#005C31'" # Forest
          gp.set linetype: "7 lc rgb '#2BCE48'" # Green
          gp.set linetype: "8 lc rgb '#FFCC99'" # Honeydew
          gp.set linetype: "9 lc rgb '#808080'" # Iron
          gp.set linetype: "10 lc rgb '#94FFB5'" # Jade
          gp.set linetype: "11 lc rgb '#8F7C00'" # Khaki
          gp.set linetype: "12 lc rgb '#9DCC00'" # Lime
          gp.set linetype: "13 lc rgb '#C20088'" # Mallow
          gp.set linetype: "14 lc rgb '#003380'" # Navy
          gp.set linetype: "15 lc rgb '#FFA405'" # Orpiment
          gp.set linetype: "16 lc rgb '#FFA8BB'" # Pink
          gp.set linetype: "17 lc rgb '#426600'" # Quagmire
          gp.set linetype: "18 lc rgb '#FF0010'" # Red
          gp.set linetype: "19 lc rgb '#5EF1F2'" # Sky
          gp.set linetype: "20 lc rgb '#00998F'" # Turquoise
          gp.set linetype: "21 lc rgb '#E0FF66'" # Uranium
          gp.set linetype: "22 lc rgb '#740AFF'" # Violet
          gp.set linetype: "23 lc rgb '#990000'" # Wine
          gp.set linetype: "24 lc rgb '#FFFF80'" # Xanthin
          gp.set linetype: "25 lc rgb '#FFFF00'" # Yellow
          gp.set linetype: "26 lc rgb '#FF5005'" # Zinnia
          gp.set linetype: "cycle 26"
          gp.set boxwidth: "0.75 absolute"

          offset = {} # Hackery thing to offset datasets 1 postion.

          residues.sort.reverse.each_with_index do |residue, i|
            gp.add_dataset(using: 1, with: "histogram lt #{i + 1}", title: "\"#{residue}\"") do |plotter|
              counts.each do |pos, dist|
                plotter << 0.0 unless offset[residue]
                plotter << 100 * dist[residue].to_f / total[pos]
                offset[residue] = true
              end
            end
          end

          if options[:count]
            max = total.values.max

            gp.add_dataset(using: "1:2", with: "lines lw 2 lt rgb \"black\"", title: "\"count\"") do |plotter|
              counts.each_key do |pos|
                plotter << [0, 0.0] unless offset[:count]
                plotter << [pos, 100 * total[pos].to_f / max]
                offset[:count] = true
              end
            end
          end

          if options[:test]
            $stderr.puts gp.to_gp
          elsif options[:terminal] == :dumb 
            puts gp.plot
          else
            gp.plot
          end
        end
      end

      @commands << BioPieces::Pipeline::Command.new(__method__, options, options_orig, lmb)

      self
    end
  end
end
