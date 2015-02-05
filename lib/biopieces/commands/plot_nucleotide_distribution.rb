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
    VEC_MAX = 10_000
    Y_MAX   = 100

    # == Plot the nucleotide distribution of sequences in the stream.
    #
    # +plot_nucleotide_distribution+ creates a nucleotide distribution plot per
    # sequence position of sequences in the stream. Plotting is done using
    # GNUplot which allows for different types of output the default one being
    # crufty ASCII graphics.
    #
    # If plotting distributions from sequences of variable length you can use
    # the +count+ option to co-plot the relative count at each base position.
    # This allow you to explain areas with a scewed distribution.
    #
    # GNUplot must be installed for +plot_nucleotide_distribution+ to work.
    # Read more here:
    #
    # http://www.gnuplot.info/
    # 
    # == Usage
    # 
    #    plot_nucleotide_distribution([count: <bool>[, output: <file>
    #                                 [, force: <bool> [, terminal: <string>
    #                                 [, title: <string>[, xlabel: <string>
    #                                 [, ylabel: <string>[, test: <bool>]]]]]]])
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
    # Here we plot a nucleotide distribution of a FASTA file:
    # 
    #    BP.new.read_fasta(input: "test.fna").plot_nucleotide_distribution.run
    def plot_nucleotide_distribution(options = {})
      require 'gnuplotter'
      require 'narray'

      options_orig = options.dup
      options_load_rc(options, __method__)
      options_allowed(options, :count, :output, :force, :terminal, :title, :xlabel, :ylabel, :test)
      options_allowed_values(options, terminal: [:dumb, :post, :svg, :x11, :aqua, :png, :pdf])
      options_allowed_values(options, count: [nil, true, false])
      options_allowed_values(options, test: [nil, true, false])
      options_files_exists_force(options, :output)

      options[:terminal] ||= :dumb
      options[:title]    ||= "Nucleotide Distribution"
      options[:xlabel]   ||= "Sequence position"
      options[:ylabel]   ||= "%"

      lmb = lambda do |input, output, status|
        status_track(status) do
          status[:sequences_in]  = 0
          status[:sequences_out] = 0

          max_len = 0

          vec_a   = NArray.int(VEC_MAX)
          vec_t   = NArray.int(VEC_MAX)
          vec_c   = NArray.int(VEC_MAX)
          vec_g   = NArray.int(VEC_MAX)
          vec_n   = NArray.int(VEC_MAX)
          vec_tot = NArray.float(VEC_MAX)

          input.each do |record|
            status[:records_in] += 1

            if record[:SEQ]
              status[:sequences_in] += 1

              seq = record[:SEQ].upcase

              unless seq.empty?
                raise BiopiecesError, "sequence too long: #{seq.length} > #{VEC_MAX}" if seq.length > VEC_MAX

                vec_seq = NArray.to_na(seq, "byte")

                vec_a[0 ... seq.length]   += vec_seq.eq('A'.ord)
                vec_t[0 ... seq.length]   += vec_seq.eq('T'.ord)
                vec_c[0 ... seq.length]   += vec_seq.eq('C'.ord)
                vec_g[0 ... seq.length]   += vec_seq.eq('G'.ord)
                vec_n[0 ... seq.length]   += vec_seq.eq('N'.ord)
                vec_tot[0 ... seq.length] += 1

                max_len = seq.length if seq.length > max_len
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

          if max_len > 0
            x = (1 .. max_len).to_a
            a = ((vec_a / vec_tot) * 100)[0 ... max_len].to_a
            t = ((vec_t / vec_tot) * 100)[0 ... max_len].to_a
            c = ((vec_c / vec_tot) * 100)[0 ... max_len].to_a
            g = ((vec_g / vec_tot) * 100)[0 ... max_len].to_a
            n = ((vec_n / vec_tot) * 100)[0 ... max_len].to_a

            vec_tot *= (Y_MAX / vec_tot.max(0).to_f)
            y = vec_tot.to_a

            a.unshift 0.0
            t.unshift 0.0
            c.unshift 0.0
            g.unshift 0.0
            n.unshift 0.0
          else
            x = a = t = c = g = n = y = []
          end

          gp = GnuPlotter.new
          gp.set   terminal:  options[:terminal].to_s
          gp.set   title:     options[:title]
          gp.set   xlabel:    options[:xlabel]
          gp.set   ylabel:    options[:ylabel]
          gp.set   output:    options[:output] if options[:output]
          gp.set   xtics:     "out"
          gp.set   ytics:     "out"
          gp.set   yrange:   "[0:#{Y_MAX}]"
          gp.set   xrange:   "[0:#{max_len}]"
          gp.set   auto:     "fix"
          gp.set   offsets:  "1"
          gp.set   key:      "outside right top vertical Left reverse enhanced autotitles columnhead nobox"
          gp.set   key:      "invert samplen 4 spacing 1 width 0 height 0"
          gp.set   style:    "fill solid 0.5 border"
          gp.set   style:    "histogram rowstacked"
          gp.set   style:    "data histograms"
          gp.set   boxwidth: "0.75 absolute"

          gp.add_dataset(using: 1, with: "histogram lt rgb \"black\"", title: "\"N\"") do |plotter|
            n.map { |nuc| plotter << nuc }
          end

          gp.add_dataset(using: 1, with: "histogram lt rgb \"yellow\"", title: "\"G\"") do |plotter|
            g.map { |nuc| plotter << nuc }
          end

          gp.add_dataset(using: 1, with: "histogram lt rgb \"blue\"", title: "\"C\"") do |plotter|
            c.map { |nuc| plotter << nuc }
          end

          gp.add_dataset(using: 1, with: "histogram lt rgb \"green\"", title: "\"T\"") do |plotter|
            t.map { |nuc| plotter << nuc }
          end

          gp.add_dataset(using: 1, with: "histogram lt rgb \"red\"", title: "\"A\"") do |plotter|
            a.map { |nuc| plotter << nuc }
          end

          if options[:count]
            gp.add_dataset(using: "1:2", with: "lines lw 2 lt rgb \"black\"", title: "\"count\"") do |plotter|
              x.zip(y).each { |pair| plotter << pair }
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
