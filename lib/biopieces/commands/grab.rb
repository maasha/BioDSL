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
      options_conflict keys: :evaluate, keys_only: :evaluate, values_only: :evaluate, ignore_case: :evaluate
      options_unique :keys_only, :values_only

      keys    = compile_keys
      regexes = compile_regexes

      @input.each do |record|
        match = false

        catch :next_record do
          if regexes
            match = grab_regexes(regexes, record, keys, @options[:keys_only], @options[:values_only])
          elsif @options[:evaluate]
            expression = @options[:evaluate].gsub(/:\w+/) do |match|
              key = match[1 .. -1].to_sym

              if record[key]
                match = record[key]
              else
                throw :next_record
              end
            end

            if eval expression
              match = true
            end

            throw :next_record
          end
        end
        
        if match
          if @options[:select] or @options[:select_file] or @options[:evaluate]
            @output.write record if @output
          end
        else
          if @options[:reject] or @options[:reject_file]
            @output.write record if @output
          end
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

    def grab_regexes(regexes, record, keys, keys_only, values_only)
      if keys
        keys.each do |key|
          if value = record[key]
            regexes.each { |regex| return true if value =~ regex }
          end
        end
      else
        record.each do |key, value|
          if keys_only
            regexes.each { |regex| return true if key =~ regex }
          elsif values_only
            regexes.each { |regex| return true if value =~ regex }
          else
            regexes.each { |regex| return true if key =~ regex or value =~ regex }
          end
        end
      end

      false
    end
  end
end

