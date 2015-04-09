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
    BioPieces::OptionsError = Class.new(StandardError)

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

    # Method that raises of options include any option value not in the allowed
    # hash.
    #
    # @param options [Hash] The Hash with options to be checked.
    # @param allowed [Symbol, Array] One or more allowed options.
    #
    # @example That raises:
    #   options_allowed_values(foo: 'bar', foo: 1)
    #
    # @example That passes:
    #   options_allowed_values(foo: 'bar', foo: ['bar', 'rab'])
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

    # Method that raises if options don't include options in the required list.
    #
    # @param options [Hash] The Hash with options to be checked.
    # @param required [Symbol, Array] One or more required options.
    #
    # @example That raises:
    #   options_required(foo: 'bar', foo: 1)
    #
    # @example That passes:
    #   options_required(foo: 'bar', one: 'two', :foo, :one)
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

    # Method that raises if options include multiple options in the unique list.
    def options_required_unique(options, *unique)
      lookup = []

      unique.each do |option|
        lookup << option if options[option]
      end

      if lookup.size > 1
        fail BioPieces::OptionError, "Multiple required uniques options used: #{unique.join(', ')}"
      elsif lookup.size == 0
        fail BioPieces::OptionError, "Required unique option missing: #{unique.join(', ')}"
      end
    end

    # Method that raises if options don't contain at least one option in the single list.
    def options_required_single(options, *single)
      lookup = []

      single.each do |option|
        lookup << option if options[option]
      end

      return unless lookup.size == 0

      fail BioPieces::OptionError, "Required single option missing: #{single.join(', ')}"
    end

    # Method that raises if options include multiple options in the unique list.
    def options_unique(options, *unique)
      lookup = []

      unique.each do |option|
        lookup << option if options[option]
      end

      return unless lookup.size > 1
      fail BioPieces::OptionError, "Multiple uniques options used: #{unique.join(', ')}"
    end

    # Method that raises if options include lists with duplicate elements.
    # Usage options_unique_list(options, :keys, :skip)
    def options_list_unique(options, *lists)
      lists.each do |list|
        if options[list] && options[list].uniq.size != options[list].size
          fail BioPieces::OptionError, "Duplicate elements found in list #{list}: #{options[list]}"
        end
      end
    end

    # Method to expand all options in the glob list into lists of paths.
    def options_glob(options, *globs)
      globs.each do |option|
        next unless options[option] && !options[option].is_a?(Array)

        expanded_paths = []
        options[option].split(/, */).each do |glob_expression|
          if glob_expression.include? '*'
            expanded_paths += Dir.glob(glob_expression).sort.select { |file| File.file? file }
          else
            expanded_paths << glob_expression
          end
        end

        options[option] = expanded_paths
      end
    end

    # Method that raises if one option is given without some other.
    # Example: options_tie gzip: :options, bzip2: :options
    def options_tie(options, ties)
      ties.each do |option, tie|
        if options[option] && !options[tie]
          fail BioPieces::OptionError, "Tie option: #{tie} not in @options: #{options.keys.join(', ')}"
        end
      end
    end

    # Method that raises if conflicting options are used.
    # Example: select: :evaluate, reject: :evaluate
    def options_conflict(options, conflicts)
      conflicts.each do |option, conflict|
        if options[option] && options[conflict]
          fail BioPieces::OptionError, "Conflicting options: #{option}, #{conflict}"
        end
      end
    end

    # Method that fails if given files don't exists.
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
            fail BioPieces::OptionError, "For option #{arg} - no such file: #{file}"
          end
        end
      end
    end

    # Method that raises if given directories don't exists.
    # Usage: options_dirs_exist(options, :dir)
    def options_dirs_exist(options, *args)
      args.each do |arg|
        next unless options[arg]

        dirs = (options[arg].is_a? Array) ? options[arg] : [options[arg]]

        dirs.each do |dir|
          unless File.directory? File.expand_path(dir)
            fail BioPieces::OptionError, "For option #{arg} - no such directory: #{dir}"
          end
        end
      end
    end

    # Method that raises if files exists unless options[:force] == true.
    # Usage: options_files_exists_force(options, :output)
    def options_files_exists_force(options, *args)
      args.each do |arg|
        next unless options[arg]

        files = (options[arg].is_a? Array) ? options[arg] : [options[arg]]

        files.each do |file|
          if File.file?(file) && !options[:force]
            fail BioPieces::OptionError, "File exists: #{file} - use 'force: true' to override"
          end
        end
      end
    end

    # Method to assert a given expression.
    # Usage: options_assert(options, ":overlap_min > 0")
    def options_assert(options, expression)
      options.each do |key, value|
        expression.gsub!(/:#{key}/, value.to_s)
      end

      return if expression[0] == ':'
      return if eval expression

      fail BioPieces::OptionError, "Assertion failed: #{expression}"
    end

    def options_load_rc(options, command)
      rc_file = File.join(ENV['HOME'], '.biopiecesrc')

      return unless File.exist? rc_file

      rc_options = Hash.new { |h, k| h[k] = [] }

      File.open(rc_file) do |ios|
        ios.each do |line|
          line.chomp!

          next if line.empty?
          next if line[0] == '#'

          fields    = line.split(/\s+/)
          fields[0] = fields[0].to_sym
          fields[1] = fields[1].to_sym

          next unless fields.first == command

          unless options.key? fields[1]
            rc_options[fields[1]] << fields[2]
          end
        end
      end

      rc_options.each do |key, value|
        if value.size == 1
          options[key] = value.first
        else
          options[key] = value
        end
      end
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
  end
end
