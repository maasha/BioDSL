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
    # == Grab records in stream.
    # 
    # +plot_histogram+ select records from the stream by matching patterns to keys or
    # values. +plot_histogram+ is  Biopieces' equivalent of Unix' +grep+, however, +plot_histogram+
    # is much more versatile.
    # 
    # == Usage
    # 
    #    plot_histogram(<select: <pattern>|select_file: <file>|reject: <pattern>|
    #                reject_file: <file>|evaluate: <expression>|exact: <bool>>
    #               [, keys: <list>|keys_only: <bool>|values_only: <bool>|
    #               ignore_case: <bool>])
    # 
    # === Options
    #
    # * select: <pattern>      - Select records matching <pattern> which is
    #   a regex or an exact match if the exact option is set.
    # * select_file: <file>    - File with one <pattern> per line to select.
    # * reject: <pattern>      - Reject records matching <pattern> which is
    #   a regex or an exact match if the exact option is set.
    # * reject_file: <file>    - File with one <pattern> per line to reject.
    # * evaluate: <expression> - Select records where <expression> is true.
    # * exact: <bool>          - Turn on exact matching for improved speed.
    # * keys: <list>           - Comma separated list or array of keys to plot_histogram
    #   the value for.
    # * keys_only: <bool>      - Only plot_histogram for keys.
    # * values_only: <bool>    - Only plot_histogram for values.
    # * ignore_case: <bool>    - Ignore case when plot_histogrambing with regex (does not
    #   work with +evaluate+ and +exact+).
    # 
    # == Examples
    # 
    # To easily plot_histogram all records in the stream that has any mentioning of the
    # pattern 'human' just pipe the data stream through plot_histogram like this:
    # 
    #    plot_histogram(select: "human")
    # 
    # This will search for the pattern 'human' in all keys and all values. The
    # +select+ option alternatively uses an array of patterns, so in order to
    # match one of multiple patterns do:
    # 
    #    plot_histogram(select: ["human", "mouse"])
    # 
    # It is also possible to invoke flexible matching using regex (regular
    # expressions) instead of simple pattern matching. If you want to +plot_histogram+ 
    # records with the sequence +ATCG+ or +GCTA+ you can do this:
    # 
    #    plot_histogram(select: "ATCG|GCTA")
    # 
    # Or if you want to +plot_histogram+ sequences beginning with +ATCG+:
    # 
    #    plot_histogram(select: "^ATCG")
    # 
    # It is also possible to use the +select_file+ option to load patterns from
    # a file with one pattern per line.
    # 
    #    plot_histogram(select_file: "patterns.txt")
    # 
    # If you want the opposite result - to find all records that does not match
    # the a pattern, use the +reject+ option:
    # 
    #    plot_histogram(reject: "human")
    # 
    # Similar to +select_file+ there is a +reject_file+ option to load patterns
    # from a file, and use any of these patterns to reject records:
    #
    #    plot_histogram(reject_file: "patterns.txt")
    #
    # If you want to search the record keys only, e.g. to +plot_histogram+ all records
    # containing the key +SEQ+ you can use the +keys_only+ option. This will
    # prevent matching of +SEQ+ in any record value, and in fact +SEQ+ is a not
    # uncommon peptide sequence you could get an unwanted record. Also, this
    # will give an increase in speed since only the keys are searched:
    # 
    #    plot_histogram(select: "SEQ", keys_only: true)
    # 
    # However, if you are interested in +plot_histogrambing+ the peptide sequence +SEQ+ and
    # not the +SEQ+ key, just use the +vals_only+ option:
    # 
    #    plot_histogram(select: "SEQ", vals_only: true)
    # 
    # Also, if you want to +plot_histogram+ for certain key/value pairs you can supply a
    # comma separated list or an array of keys whos values will then be plot_histogrambed
    # using the +keys+ option. This is handy if your records contain large
    # genomic sequences and you don't want to search the entire sequence for
    # e.g. the organism name - it is much faster to tell +plot_histogram+ which keys to
    # search the value for:
    # 
    #    plot_histogram(select: "human", keys: :SEQ_NAME)
    # 
    # You can also use the +evaluate+ option to +plot_histogram+ records that fulfill an
    # expression. So to +plot_histogram+ all records with a sequence length greater than 30:
    # 
    #    plot_histogram(evaluate: 'SEQ_LEN > 30')
    # 
    # If you want to +plot_histogram+ all records containing the pattern 'human' and where the
    # sequence length is greater that 30, you do this by running the stream through
    # +plot_histogram+ twice:
    # 
    #    plot_histogram(select: 'human').plot_histogram(evaluate: 'SEQ_LEN > 30')
    # 
    # Finally, it is possible to +plot_histogram+ for exact pattern using the +exact+
    # option. This is much faster than the default regex pattern plot_histogrambing
    # because with +exact+ the patterns are used to create a lookup hash for
    # instant matching of keys or values. This is useful if you e.g. have a
    # file with ID numbers and you want to +plot_histogram+ matching records from the 
    # stream:
    # 
    #    plot_histogram(select_file: "ids.txt", keys: :ID, exact: true)
    def plot_histogram(options = {})
      options_orig = options.dup
      @options = options
      options_allowed :key, :output, :terminal, :title, :xlabel, :ylabel, :ylogscale
      options_allowed_values terminal: [:dumb, :post, :svg, :x11, :aqua, :png, :pdf]
      options_required :key
      options_files_exists_force :output

      key      = @options[:key]
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
              plot.output   options[:data_out] || "/dev/stderr"
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

