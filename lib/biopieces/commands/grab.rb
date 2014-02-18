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
  module Grab
    # Method to grab records.
    def grab
      options_allowed :select, :select_file, :reject, :reject_file, :evaluate, :exact, :keys, :keys_only, :values_only, :ignore_case
      options_required_unique :select, :select_file, :reject, :reject_file, :evaluate
      options_conflict keys: :evaluate, keys_only: :evaluate, values_only: :evaluate, ignore_case: :evaluate, exact: :evaluate
      options_conflict keys_only: :keys, values_only: :keys
      options_unique :keys_only, :values_only
      options_files_exist :select_file, :reject_file

      invert  = @options[:reject] || @options[:reject_file]
      keys    = compile_keys
      regexes = compile_regexes
      lookup  = compile_lookup

      @input.each do |record|
        match = false

        if @options[:exact]
          match = grab_exact(record, lookup, keys)
        elsif regexes
          match = grab_regexes(record, regexes, keys)
        elsif @options[:evaluate]
          match = grab_expression(record)
        end
        
        if match and not invert
          @output.write record
        elsif not match and invert
          @output.write record
        end
      end
    end

    private 

    def compile_keys
      if @options[:keys]
        if @options[:keys].is_a? Array
          keys = @options[:keys]
        elsif @options[:keys].is_a? Symbol
          keys = [@options[:keys]]
        elsif @options[:keys].is_a? String
          keys = @options[:keys].split(/, */).map { |key| key = key.sub(/^:/, '').to_sym }
        end
      end

      keys
    end

    def compile_patterns
      if @options[:select]
        if @options[:select].is_a? Array
          patterns = @options[:select]
        elsif @options[:select].is_a? String
          patterns = [@options[:select]]
        elsif @options[:select].is_a? Symbol
          patterns = [@options[:select]]
        end
      elsif @options[:select_file]
        File.open(@options[:select_file]) do |ios|
          patterns = []
          ios.each_line { |line| patterns << line.chomp }
        end
      elsif @options[:reject]
        if @options[:reject].is_a? Array
          patterns = @options[:reject]
        elsif @options[:reject].is_a? String
          patterns = [@options[:reject]]
        elsif @options[:reject].is_a? Symbol
          patterns = [@options[:select]]
        end
      elsif @options[:reject_file]
        File.open(@options[:reject_file]) do |ios|
          patterns = []
          ios.each_line { |line| patterns << line.chomp }
        end
      end

      patterns
    end

    def compile_regexes
      patterns = compile_patterns

      if patterns
        if @options[:ignore_case]
          regexes = patterns.inject([]) { |list, pattern| list << Regexp.new(/#{pattern}/i) }
        else
          regexes = patterns.inject([]) { |list, pattern| list << Regexp.new(/#{pattern}/) }
        end
      end

      regexes
    end

    def compile_lookup
      if @options[:exact]
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

    def grab_regexes(record, regexes, keys)
      if keys
        keys.each do |key|
          if value = record[key]
            regexes.each { |regex| return true if value =~ regex }
          end
        end
      else
        record.each do |key, value|
          if @options[:keys_only]
            regexes.each { |regex| return true if key =~ regex }
          elsif @options[:values_only]
            regexes.each { |regex| return true if value =~ regex }
          else
            regexes.each { |regex| return true if key =~ regex or value =~ regex }
          end
        end
      end

      false
    end

    def grab_exact(record, lookup, keys)
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
          if @options[:keys_only]
            begin
              return true if lookup[key.to_sym]
            rescue
              return true if lookup[key]
            end
          elsif @options[:values_only]
            begin
              return true if lookup[value.to_sym]
            rescue
              return true if lookup[value]
            end
          else
            begin
              return true if lookup[key.to_sym]
            rescue
              return true if lookup[key]
            end

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

    def grab_expression(record)
      expression = @options[:evaluate].gsub(/:\w+/) do |match|
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

