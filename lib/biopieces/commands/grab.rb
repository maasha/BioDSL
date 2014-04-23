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
    # +grab+ select records from the stream by matching patterns to keys or
    # values. +grab+ is  Biopieces' equivalent of Unix' +grep+, however, +grab+
    # is much more versatile.
    # 
    # NB! If chaining multiple +grab+ commands then use the most restrictive +grab+
    # first in order to get the best performance.
    # 
    # == Usage
    # 
    #    grab(<select: <pattern>|select_file: <file>|reject: <pattern>|
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
    # * keys: <list>           - Comma separated list or array of keys to grab
    #   the value for.
    # * keys_only: <bool>      - Only grab for keys.
    # * values_only: <bool>    - Only grab for values.
    # * ignore_case: <bool>    - Ignore case when grabbing with regex (does not
    #   work with +evaluate+ and +exact+).
    # 
    # == Examples
    # 
    # To easily grab all records in the stream that has any mentioning of the
    # pattern 'human' just pipe the data stream through grab like this:
    # 
    #    grab(select: "human")
    # 
    # This will search for the pattern 'human' in all keys and all values. The
    # +select+ option alternatively uses an array of patterns, so in order to
    # match one of multiple patterns do:
    # 
    #    grab(select: ["human", "mouse"])
    # 
    # It is also possible to invoke flexible matching using regex (regular
    # expressions) instead of simple pattern matching. If you want to +grab+ 
    # records with the sequence +ATCG+ or +GCTA+ you can do this:
    # 
    #    grab(select: "ATCG|GCTA")
    # 
    # Or if you want to +grab+ sequences beginning with +ATCG+:
    # 
    #    grab(select: "^ATCG")
    # 
    # It is also possible to use the +select_file+ option to load patterns from
    # a file with one pattern per line.
    # 
    #    grab(select_file: "patterns.txt")
    # 
    # If you want the opposite result - to find all records that does not match
    # the a pattern, use the +reject+ option:
    # 
    #    grab(reject: "human")
    # 
    # Similar to +select_file+ there is a +reject_file+ option to load patterns
    # from a file, and use any of these patterns to reject records:
    #
    #    grab(reject_file: "patterns.txt")
    #
    # If you want to search the record keys only, e.g. to +grab+ all records
    # containing the key +SEQ+ you can use the +keys_only+ option. This will
    # prevent matching of +SEQ+ in any record value, and in fact +SEQ+ is a not
    # uncommon peptide sequence you could get an unwanted record. Also, this
    # will give an increase in speed since only the keys are searched:
    # 
    #    grab(select: "SEQ", keys_only: true)
    # 
    # However, if you are interested in +grabbing+ the peptide sequence +SEQ+ and
    # not the +SEQ+ key, just use the +vals_only+ option:
    # 
    #    grab(select: "SEQ", vals_only: true)
    # 
    # Also, if you want to +grab+ for certain key/value pairs you can supply a
    # comma separated list or an array of keys whos values will then be grabbed
    # using the +keys+ option. This is handy if your records contain large
    # genomic sequences and you don't want to search the entire sequence for
    # e.g. the organism name - it is much faster to tell +grab+ which keys to
    # search the value for:
    # 
    #    grab(select: "human", keys: :SEQ_NAME)
    # 
    # You can also use the +evaluate+ option to +grab+ records that fulfill an
    # expression. So to +grab+ all records with a sequence length greater than 30:
    # 
    #    grab(evaluate: 'SEQ_LEN > 30')
    # 
    # If you want to +grab+ all records containing the pattern 'human' and where the
    # sequence length is greater that 30, you do this by running the stream through
    # +grab+ twice:
    # 
    #    grab(select: 'human').grab(evaluate: 'SEQ_LEN > 30')
    # 
    # Finally, it is possible to +grab+ for exact pattern using the +exact+
    # option. This is much faster than the default regex pattern grabbing
    # because with +exact+ the patterns are used to create a lookup hash for
    # instant matching of keys or values. This is useful if you e.g. have a
    # file with ID numbers and you want to +grab+ matching records from the 
    # stream:
    # 
    #    grab(select_file: "ids.txt", keys: :ID, exact: true)
    def grab(options)
      options_orig = options.dup
      @options = options
      options_allowed :select, :select_file, :reject, :reject_file, :evaluate, :exact, :keys, :keys_only, :values_only, :ignore_case
      options_required_unique :select, :select_file, :reject, :reject_file, :evaluate
      options_conflict keys: :evaluate, keys_only: :evaluate, values_only: :evaluate, ignore_case: :evaluate, exact: :evaluate
      options_conflict keys_only: :keys, values_only: :keys
      options_unique :keys_only, :values_only
      options_files_exist :select_file, :reject_file

      lmb = lambda do |input, output, run_options|
        status_track(input, output, run_options) do
          invert  = options[:reject] || options[:reject_file]
          keys    = compile_keys(options)
          regexes = compile_regexes(options)
          lookup  = compile_lookup(options)

          input.each do |record|
            match = false

            if options[:exact]
              match = grab_exact(options, record, lookup, keys)
            elsif regexes
              match = grab_regexes(options, record, regexes, keys)
            elsif options[:evaluate]
              match = grab_expression(options, record)
            end
            
            if match and not invert
              output.write record
            elsif not match and invert
              output.write record
            end
          end
        end
      end

      add(__method__, options, options_orig, lmb)

      self
    end

    private 

    def compile_keys(options)
      if options[:keys]
        if options[:keys].is_a? Array
          keys = options[:keys]
        elsif options[:keys].is_a? Symbol
          keys = [options[:keys]]
        elsif options[:keys].is_a? String
          keys = options[:keys].split(/, */).map { |key| key = key.sub(/^:/, '').to_sym }
        end
      end

      keys
    end

    def compile_patterns(options)
      if options[:select]
        if options[:select].is_a? Array
          patterns = options[:select]
        else
          patterns = [options[:select]]
        end
      elsif options[:select_file]
        File.open(options[:select_file]) do |ios|
          patterns = []
          ios.each_line { |line| patterns << line.chomp }
        end
      elsif options[:reject]
        if options[:reject].is_a? Array
          patterns = options[:reject]
        else
          patterns = [options[:reject]]
        end
      elsif options[:reject_file]
        File.open(options[:reject_file]) do |ios|
          patterns = []
          ios.each_line { |line| patterns << line.chomp }
        end
      end

      patterns
    end

    def compile_regexes(options)
      patterns = compile_patterns(options)

      if patterns
        if options[:ignore_case]
          regexes = patterns.inject([]) { |list, pattern| list << Regexp.new(/#{pattern}/i) }
        else
          regexes = patterns.inject([]) { |list, pattern| list << Regexp.new(/#{pattern}/) }
        end
      end

      regexes
    end

    def compile_lookup(options)
      if options[:exact]
        patterns = compile_patterns

        lookup = {}

        patterns.each do |pattern|
          begin
            lookup[pattern.to_sym] = true
          rescue
            lookup[pattern] = true
          end
        end
      end

      lookup
    end

    def grab_regexes(options, record, regexes, keys)
      if keys
        keys.each do |key|
          if value = record[key]
            regexes.each { |regex| return true if value =~ regex }
          end
        end
      else
        record.each do |key, value|
          if options[:keys_only]
            regexes.each { |regex| return true if key =~ regex }
          elsif options[:values_only]
            regexes.each { |regex| return true if value =~ regex }
          else
            regexes.each { |regex| return true if key =~ regex or value =~ regex }
          end
        end
      end

      false
    end

    def grab_exact(options, record, lookup, keys)
      if keys
        keys.each do |key|
          if value = record[key]
            begin
              return true if lookup[value.to_sym]
            rescue
              return true if lookup[value]
            end
          end
        end
      else
        record.each do |key, value|
          if options[:keys_only]
            return true if lookup[key.to_sym]
          elsif options[:values_only]
            begin
              return true if lookup[value.to_sym]
            rescue
              return true if lookup[value]
            end
          else
            return true if lookup[key.to_sym]

            begin
              return true if lookup[value.to_sym]
            rescue
              return true if lookup[value]
            end
          end
        end
      end

      false
    end

    def grab_expression(options, record)
      expression = options[:evaluate].gsub(/:\w+/) do |match|
        key = match[1 .. -1].to_sym

        if record[key]
          match = record[key]
        else
          return false
        end
      end

      return true if eval expression

      false
    end
  end
end

