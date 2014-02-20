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

    # Method that raises of @options include any option not in the allowed list.
    def options_allowed(*allowed)
      @options.each_key do |option|
        unless allowed.include? option
          raise BioPieces::OptionError, "Disallowed option: #{option}. Allowed options: #{allowed.join(", ")}"
        end
      end
    end

    # Method that raises if @options don't include options in the required list.
    def options_required(*required)
      required.each do |option|
        unless @options[option]
          raise BioPieces::OptionError, "Required option missing: #{option}. Required options: #{required.join(", ")}"
        end
      end
    end

    # Method that raises if @options include multiple options in the unique list or .
    def options_required_unique(*unique)
      lookup = []

      unique.each do |option|
        lookup << option if @options[option]
      end

      if lookup.size > 1
        raise BioPieces::OptionError, "Multiple required uniques options used: #{unique.join(", ")}"
      elsif lookup.size == 0
        raise BioPieces::OptionError, "Required unique option missing: #{unique.join(", ")}"
      end
    end

    # Method that raises if @options include multiple options in the unique list.
    def options_unique(*unique)
      lookup = []

      unique.each do |option|
        lookup << option if @options[option]
      end

      if lookup.size > 1
        raise BioPieces::OptionError, "Multiple uniques options used: #{unique.join(", ")}"
      end
    end

    # Method to expand all options in the glob list into lists of paths.
    def options_glob(*globs)
      globs.each do |option|
        unless @options[option].is_a? Array
          expanded_paths = []

          @options[option].split(/, */).each do |glob_expression|
            expanded_paths += Dir.glob(glob_expression).select { |file| File.file? file }
          end

          @options[option] = expanded_paths
        end
      end
    end

    # Method that raises if one option is given without some other.
    # Example: options_tie gzip: :options, bzip2: :options
    def options_tie(ties)
      ties.each do |option, tie|
        if @options[option] and not @options[tie]
          raise BioPieces::OptionError, "Tie option: #{tie} not in @options: #{@options.keys.join(", ")}"
        end
      end
    end

    # Method that raises if conflicting options are used.
    # Example: select: :evaluate, reject: :evaluate
    def options_conflict(conflicts)
      conflicts.each do |option, conflict|
        if @options[option] and @options[conflict]
          raise BioPieces::OptionError, "Conflicting options: #{option}, #{conflict}"
        end
      end
    end

    # Method that raises if given files don't exists.
    def options_files_exist(*args)
      args.each do |arg|
        if @options[arg]
          files = (@options[arg].is_a? Array) ? @options[arg] : [@options[arg]]

          files.each do |file|
            unless File.file? file
              raise BioPieces::OptionError, "For option #{file} - no such file: #{@options[file]}"
            end
          end
        end
      end
    end

    def options_assert(expression)
      @options.each do |key, value|
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

