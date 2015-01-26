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
    # == Plot tabular numerical data in a heatmap.
    #
    # A heatmap can be plotted with +plot_heatmap+ using numerical data (Non-
    # numerical data is ignored). Data should be tabular with records as rows
    # and keys as columns - the data cells plotted will be the values.
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
    #    plot_matches([keys: <list> | skip: <list>[, output: <file>
    #                 [, force: <bool> [, terminal: <string>
    #                 [, title: <string>[, xlabel: <string>[, ylabel: <string>[, test: <bool>]]]]]]])
    # 
    # === Options
    #
    # * keys: <list>        - Comma separated list of keys to plot as columns.
    # * skip: <list>        - Comma separated list of keys to skip as columns.
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
    # Here we plot a heatmap of data a table:
    # 
    #    BP.new.read_table(input: "test.tab").plot_heatmap.run
    def plot_heatmap(options = {})
      require 'gnuplotter'

      options_orig = options.dup
      options_load_rc(options, __method__)
      options_allowed(options, :keys, :skip, :output, :force, :terminal, :title, :xlabel, :ylabel, :test)
      options_unique(options, :keys, :skip)
      options_allowed_values(options, terminal: [:dumb, :post, :svg, :x11, :aqua, :png, :pdf])
      options_allowed_values(options, test: [nil, true, false])
      options_files_exists_force(options, :output)

      options[:terminal] ||= :dumb
      options[:title]    ||= "Heatmap"
      options[:xlabel]   ||= "x"
      options[:ylabel]   ||= "y"

      lmb = lambda do |input, output, status|
        headings  = nil
        skip_keys = options[:skip].each_with_object({}) { |i, h| h[i.to_sym] = true } if options[:skip]

        status_track(status) do
          gp = GnuPlotter.new
          gp.set   terminal:  options[:terminal].to_s
          gp.set   title:     options[:title]
          gp.set   xlabel:    options[:xlabel]
          gp.set   ylabel:    options[:ylabel]
          gp.set   output:    options[:output] if options[:output]
          gp.set   view:      "map"
          gp.set   autoscale: "xfix"
          gp.set   autoscale: "yfix"
          gp.set   nokey:     true
          gp.set   tic:       "scale 0"
          gp.set   palette:   "rgbformulae 22,13,10"
          gp.unset xtics:     true
          gp.unset ytics:     true

          keys = nil

          gp.add_dataset(matrix: :true, with: "image" ) do |plotter|
            input.each do |record|
              status[:records_in] += 1

              unless headings
                if options[:keys]
                  headings = options[:keys].map { |k| k.to_sym }
                elsif record.keys.first =~ /^V\d+$/
                  headings = record.keys.sort { |a, b| a.to_s[1 .. a.to_s.size].to_i <=> b.to_s[1 .. a.to_s.size].to_i }
                else
                  headings = record.keys
                end

                headings.reject! {|r| skip_keys[r] } if options[:skip]
              end

              plotter << record.values_at(*headings)
              keys    =  record.keys unless keys

              if output
                output << record

                status[:records_out] += 1
              end
            end
          end


          if options[:test]
            $stderr.puts gp.to_gp
          elsif options[:terminal] == :dumb 
            puts gp.splot
          else
            gp.splot
          end
        end
      end

      @commands << BioPieces::Pipeline::Command.new(__method__, options, options_orig, lmb)

      self
    end
  end
end
