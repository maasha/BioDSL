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
# This software is part of Biopieces (www.biopieces.org).                        #
#                                                                                #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

module BioPieces
  module OptionsHelper
    class BioPieces::OptionError < StandardError; end;

    # Method that raises if options include any option not in the allowed list.
    def options_allowed(options, *allowed)
      options.each_key do |option|
        unless allowed.include? option
          raise BioPieces::OptionError, "Disallowed option: #{option}. Allowed options: #{allowed.join(", ")}"
        end
      end
    end

    # Method that raises of options include any option value not in the allowed hash.
    def options_allowed_values(options, allowed)
      allowed.each do |key, values|
        if options[key]
          unless values.include? options[key]
            raise BioPieces::OptionError, "Disallowed option value: #{options[key]}. Allowed options: #{values.join(", ")}"
          end
        end
      end
    end

    # Method that raises if options don't include options in the required list.
    def options_required(options, *required)
      required.each do |option|
        unless options[option]
          raise BioPieces::OptionError, "Required option missing: #{option}. Required options: #{required.join(", ")}"
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
        raise BioPieces::OptionError, "Multiple required uniques options used: #{unique.join(", ")}"
      elsif lookup.size == 0
        raise BioPieces::OptionError, "Required unique option missing: #{unique.join(", ")}"
      end
    end

    # Method that raises if options don't contain at least one option in the single list.
    def options_required_single(options, *single)
      lookup = []

      single.each do |option|
        lookup << option if options[option]
      end

      if lookup.size == 0
        raise BioPieces::OptionError, "Required single option missing: #{single.join(", ")}"
      end
    end

    # Method that raises if options include multiple options in the unique list.
    def options_unique(options, *unique)
      lookup = []

      unique.each do |option|
        lookup << option if options[option]
      end

      if lookup.size > 1
        raise BioPieces::OptionError, "Multiple uniques options used: #{unique.join(", ")}"
      end
    end

    # Method that raises if options include lists with duplicate elements.
    # Usage options_unique_list(options, :keys, :skip)
    def options_list_unique(options, *lists)
      lists.each do |list|
        if options[list] and options[list].uniq.size != options[list].size
          raise BioPieces::OptionError, "Duplicate elements found in list #{list}: #{options[list]}"
        end
      end
    end

    # Method to expand all options in the glob list into lists of paths.
    def options_glob(options, *globs)
      globs.each do |option|
        if options[option] and not options[option].is_a? Array
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
    end

    # Method that raises if one option is given without some other.
    # Example: options_tie gzip: :options, bzip2: :options
    def options_tie(options, ties)
      ties.each do |option, tie|
        if options[option] and not options[tie]
          raise BioPieces::OptionError, "Tie option: #{tie} not in @options: #{options.keys.join(", ")}"
        end
      end
    end

    # Method that raises if conflicting options are used.
    # Example: select: :evaluate, reject: :evaluate
    def options_conflict(options, conflicts)
      conflicts.each do |option, conflict|
        if options[option] and options[conflict]
          raise BioPieces::OptionError, "Conflicting options: #{option}, #{conflict}"
        end
      end
    end

    # Method that raises if given files don't exists.
    def options_files_exist(options, *args)
      args.each do |arg|
        if options[arg]
          files = (options[arg].is_a? Array) ? options[arg] : [options[arg]]

          files.each do |file|
            unless File.file? File.expand_path(file)
              raise BioPieces::OptionError, "For option #{arg} - no such file: #{file}"
            end
          end
        end
      end
    end

    # Method that raises if given directories don't exists.
    def options_dirs_exist(options, *args)
      args.each do |arg|
        if options[arg]
          dirs = (options[arg].is_a? Array) ? options[arg] : [options[arg]]

          dirs.each do |dir|
            unless File.file? File.expand_path(dir)
              raise BioPieces::OptionError, "For option #{arg} - no such directory: #{dir}"
            end
          end
        end
      end
    end

    # Method that raises if files exists unless options[:force] == true.
    # Usage: options_files_exists_force(options, :output)
    def options_files_exists_force(options, *args)
      args.each do |arg|
        if options[arg]
          files = (options[arg].is_a? Array) ? options[arg] : [options[arg]]

          files.each do |file|
            if File.file? file and not options[:force]
              raise BioPieces::OptionError, "File exists: #{file} - use 'force: true' to override"
            end
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

      unless expression =~ /:\w/
        unless eval expression
          raise BioPieces::OptionError, "Assertion failed: #{expression}"
        end
      end
    end
  end
end

