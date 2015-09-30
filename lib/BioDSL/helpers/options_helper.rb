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
# This software is part of Biopieces (www.biopieces.org).                      #
#                                                                              #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #
module BioPieces
  # Module containing methods to check options in various ways.
  module OptionsHelper
    require 'csv'

    BioPieces::OptionError = Class.new(StandardError)

    private

    # Method that fails if options include any non-allowed options.
    #
    # @param options [Hash] The Hash with options to be checked.
    # @param allowed [Symbol, Array] One or more allowed options.
    #
    # @example That raises:
    #   options_allowed({foo: 'bar'}, :foobar)
    #
    # @example That passes:
    #   options_allowed({foo: 'bar'}, :foo, :one)
    #
    # @raise [BioPieces::OptionError] If non-allowed options located.
    def options_allowed(options, *allowed)
      options.each_key do |option|
        unless allowed.include? option
          fail BioPieces::OptionError, "Disallowed option: #{option}. " \
            "Allowed options: #{allowed.join(', ')}"
        end
      end
    end

    # Method that raises if options include any non-allowed values.
    #
    # @param options [Hash] The Hash with options to be checked.
    # @param allowed [Symbol, Array] One or more allowed options.
    #
    # @example That raises:
    #   options_allowed_values({foo: 'bar'}, foo: 1)
    #
    # @example That passes:
    #   options_allowed_values({foo: 'bar'}, foo: ['bar', 'rab'])
    #
    # @raise [BioPieces::OptionError] If non-allowed options located.
    def options_allowed_values(options, allowed)
      allowed.each do |key, values|
        next unless options[key]

        unless values.include? options[key]
          fail BioPieces::OptionError, 'Disallowed option value: ' \
            "#{options[key]}. Allowed options: #{values.join(', ')}"
        end
      end
    end

    # Method that raises if options don't include all required options.
    #
    # @param options [Hash] The Hash with options to be checked.
    # @param required [Symbol, Array] One or more required options.
    #
    # @example That raises:
    #   options_required({foo: 'bar'}, foo: 1)
    #
    # @example That passes:
    #   options_required({foo: 'bar', one: 'two'}, :foo, :one)
    #
    # @raise [BioPieces::OptionError] Unless all required options are given.
    def options_required(options, *required)
      required.each do |option|
        unless options[option]
          fail BioPieces::OptionError, "Required option missing: #{option}. " \
            "Required options: #{required.join(', ')}"
        end
      end
    end

    # Method that raises if options include multiple required options.
    #
    # @param options [Hash] The Hash with options to be checked.
    # @param unique [Symbol, Array] Options that must be unique.
    #
    # @example That raises:
    #   options_required_unique({foo: 'bar', one: 'two'}, :foo, :one)
    #
    # @example That passes:
    #   options_required_unique({foo: 'bar', one: 'two'}, :foo)
    #
    # @raise [BioPieces::OptionError] If multiple required options are found.
    def options_required_unique(options, *unique)
      return unless unique.select { |option| options[option] }.size > 1

      fail BioPieces::OptionError, 'Multiple required uniques options ' \
        "used: #{unique.join(', ')}"
    end

    # Method that raises if options include non-unique options.
    #
    # @param options [Hash] Hash with options to check.
    # @param unique [Symbol, Array] List of options that must be unique.
    #
    # @example That raises:
    #   options_unique({foo: 'bar', one: 1}, :foo, :one)
    #
    # @example That passes:
    #   options_unique({foo: 'bar', one: 'two'}, :foo)
    #
    # @example That passes:
    #   options_unique({}, :foo)
    #
    # @raise [BioPieces::OptionError] If non-unique options are found.
    def options_unique(options, *unique)
      return unless unique.select { |option| options[option] }.size > 1

      fail BioPieces::OptionError, 'Multiple uniques options used: ' \
        "#{unique.join(', ')}"
    end

    # Method that raises if options include lists with duplicate elements.
    #
    # @param options [Hash] Hash with options to check.
    # @param lists [Symbol, Array] Lists whos element to check for duplicates.
    #
    # @example That raises:
    #   options_unique_list({foo: [0, 0]}, :foo)
    #
    # @example That passes:
    #   options_unique_list({foo: [0, 1]}, :foo)
    #
    # @raise [BioPieces::OptionError] If duplicate elements are found.
    def options_list_unique(options, *lists)
      lists.each do |list|
        if options[list] && options[list].uniq.size != options[list].size
          fail BioPieces::OptionError, 'Duplicate elements found in list ' \
            "#{list}: #{options[list]}"
        end
      end
    end

    # Method that raises if one option is given without some other.
    # Example: options_tie gzip: :output, bzip2: :output
    #
    # @param options [Hash] Hash with options to check.
    # @param others [Hash] Hash with key/value pairs denoting ties.
    #
    # @example That raises:
    #   options_tie({gzip: true}, gzip: :output)
    #
    # @example That passes:
    #   options_tie({output: "foo", gzip: true}, gzip: :output)
    #
    # @raise [BioPieces::OptionError] If option found without it's tie.
    def options_tie(options, others)
      others.each do |option, other|
        if options[option] && !options[other]
          fail BioPieces::OptionError, "Tie option: #{other} not in options: " \
            "#{options.keys.join(', ')}"
        end
      end
    end

    # Method that raises if conflicting options are used.
    # Example: select: :evaluate, reject: :evaluate
    #
    # @param options [Hash] Hash with options to check.
    # @param conflicts [Hash] Hash with conflicting key/value pairs.
    #
    # @example That raises:
    #   options_tie({reject: true, select: true}, reject: :select)
    #
    # @example That passes:
    #   options_tie({reject: true}, reject: :select)
    #
    # @raise [BioPieces::OptionError] If conflicting options are found.
    def options_conflict(options, conflicts)
      conflicts.each do |option, conflict|
        if options[option] && options[conflict]
          fail BioPieces::OptionError, "Conflicting options: #{option}, " \
            "#{conflict}"
        end
      end
    end

    # Method that fails if given files don't exist.
    #
    # @param options [Hash]
    #   Hash with options to check.
    #
    # @param args [Symbol, Array]
    #   Symbol or Array of Symbols which are keys in the option Hash and whos
    #   values to check.
    #
    # @example With a given Symbol.
    #   options_files_exist(options, :input)
    #
    # @example With a given Array.
    #   options_files_exist(options, [:input1, :input2])
    #
    # @raise [BioPieces::OptionError] on non-existing files.
    def options_files_exist(options, *args)
      args.each do |arg|
        next unless options[arg]
        files = (options[arg].is_a? Array) ? options[arg] : [options[arg]]

        files.each do |file|
          file = glob_check(file, arg) if file.include? '*'

          unless File.file? File.expand_path(file)
            fail BioPieces::OptionError, "For option #{arg} - no such file: " \
              "#{file}"
          end
        end
      end
    end

    # Method that fails if files exist unless the force option flag is set.
    #
    # @param options [Hash]
    #   Hash with options to check.
    #
    # @param args [Symbol, Array]
    #   Symbol or Array of Symbols which are keys in the option Hash and whos
    #   values to check.
    #
    # @example That raises
    #   options_files_exist_force({file: __FILE__}}, :file)
    #
    # @example That passes
    #   options_files_exist_force({file: __FILE__, force: true}, :file)
    #
    # @raise [BioPieces::OptionError]
    #   If files exist and the force option flag is not set
    def options_files_exist_force(options, *args)
      args.each do |arg|
        next unless options[arg]

        files = (options[arg].is_a? Array) ? options[arg] : [options[arg]]

        files.each do |file|
          if File.file?(file) && !options[:force]
            fail BioPieces::OptionError, "File exist: #{file} - use " \
              "'force: true' to override"
          end
        end
      end
    end

    # Method that fails if given directories don't exist.
    #
    # @param options [Hash]
    #   Hash with options to check.
    #
    # @param args [Symbol, Array]
    #   Symbol or Array of Symbols which are keys in the option Hash and whos
    #   values to check.
    #
    # @example With a given Symbol.
    #   options_dirs_exist(options, :input)
    #
    # @example With a given Array.
    #   options_dirs_exist(options, [:input1, :input2])
    #
    # @raise [BioPieces::OptionError] on non-existing directories.
    def options_dirs_exist(options, *args)
      args.each do |arg|
        next unless options[arg]

        dirs = (options[arg].is_a? Array) ? options[arg] : [options[arg]]

        dirs.each do |dir|
          unless File.directory? File.expand_path(dir)
            fail BioPieces::OptionError, "For option #{arg} - no such " \
              "directory: #{dir}"
          end
        end
      end
    end

    # Assert a given expression.
    #
    # @param options [Hash] Hash with options to check.
    #
    # @param expression [String] Expersion to assert.
    #
    # @example That raises:
    #   options_assert({min: 0}, ':min > 0')
    #
    # @example That passes:
    #   options_assert({{min: 0}, ':min == 0')
    #
    # @raise [BioPieces::OptionError] If assertion fails.
    def options_assert(options, expression)
      options.each do |key, value|
        expression.gsub!(/:#{key}/, value.to_s)
      end

      return if expression[0] == ':'
      return if eval expression

      fail BioPieces::OptionError, "Assertion failed: #{expression}"
    end

    # Expand a given glob expression into lists of paths.
    #
    # @param expr [String] Comma sperated glob expressions.
    #
    # @example
    #   options_glob('foo*')
    #     # => ['foo.rb', 'foo.txt']
    #
    # @return [Array] List of expanded paths.
    def options_glob(expr)
      paths = []
      list  = expr.is_a?(Array) ? expr.join(',') : expr

      list.split(/, */).each do |glob|
        if glob.include? '*'
          paths += Dir.glob(glob).sort.select { |file| File.file? file }
        else
          paths << glob
        end
      end

      paths
    end

    # Load options from rc file and use these unless given or default options
    # are specified. Option precedence: specified > default > rc.
    #
    # @param options [Hash] Hash with options to check.
    # @param command [Symbol] Command for which to load options.
    # @param file    [String] Path to file with defaults.
    #
    # @example
    #   options = {}
    #   options_load_rc(options, :some_option)
    #   options == {option1: 'value1', option2: 'value2'}
    def options_load_rc(options, command, file = BioPieces::Config::RC_FILE)
      return unless File.exist? file

      rc_options = Hash.new { |h, k| h[k] = [] }
      rc_table   = ::CSV.read(file, col_sep: "\s").
                   select { |row| row.first && row.first.to_sym == command }

      add_to_rc_options(rc_table, rc_options, options)
      add_to_options(rc_options, options)
    end

    # Check if a glob expressoin, a string with a *, matches any files and fail
    # if that is not the case.
    #
    # @param glob [String] Glob expression (containing *) to check.
    #
    # @param key [Symbol] Option Hash key whos value is the glob expression.
    #
    # @raise [BioPieces::OptionError] If the glob expression fail to match.
    #
    # @return [String] The first mathing file.
    def glob_check(glob, key)
      first = Dir.glob(glob).select { |f| File.file? f }.first
      fail BioPieces::OptionError, "For option #{key} - glob expression: " \
        "#{glob} didn't match any files" if first.nil?
      first
    end

    def add_to_options(rc_options, options)
      rc_options.each do |key, value|
        if value.size == 1
          options[key] = value.first
        else
          options[key] = value
        end
      end
    end

    def add_to_rc_options(rc_table, rc_options, options)
      rc_table.each do |row|
        options.key?(row[1].to_sym) || rc_options[row[1].to_sym] << row[2]
      end
    end
  end
end
