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

      if @options[:keys]
        if @options[:keys].is_a? Array
          keys = @options[:keys]
        elsif @options[:keys].is_a? Symbol
          keys = [@options[:keys]]
        elsif @options[:keys].is_a? String
          keys = @options[:keys].split(/, */).map { |key| key = key.sub(/^:/, '').to_sym }
        end
      end

      patterns = []

      if @options[:select]
        if @options[:select].is_a? Array
          patterns += @options[:select]
        elsif @options[:select].is_a? String
          patterns << @options[:select]
        end
      end

      if @options[:select_file]
        File.open(@options[:select_file]) do |ios|
          ios.each_line { |line| patterns << line.chomp }
        end
      end

      if @options[:reject]
        if @options[:reject].is_a? Array
          patterns += @options[:reject]
        elsif @options[:reject].is_a? String
          patterns << @options[:reject]
        end
      end

      if @options[:reject_file]
        File.open(@options[:reject_file]) do |ios|
          ios.each_line { |line| patterns << line.chomp }
        end
      end

      regexes = []

      if @options[:ignore_case]
        regexes = patterns.inject([]) { |list, pattern| list << Regexp.new(/#{pattern}/i) }
      else
        regexes = patterns.inject([]) { |list, pattern| list << Regexp.new(/#{pattern}/) }
      end

      @input.each do |record|
        gotit = false

        catch :next_record do
          if not patterns.empty?
            if keys
              keys.each do |key|
                if value = record[key]
                  regexes.each do |regex|
                    if value =~ regex
                      gotit = true
                      throw :next_record
                    end
                  end
                end
              end
            else
              record.each do |key, value|
                if @options[:keys_only]
                  regexes.each do |regex|
                    if key =~ regex
                      gotit = true
                      throw :next_record
                    end
                  end
                elsif @options[:values_only]
                  regexes.each do |regex|
                    if value =~ regex
                      gotit = true
                      throw :next_record
                    end
                  end
                else
                  regexes.each do |regex|
                    if key =~ regex
                      gotit = true
                      throw :next_record
                    end

                    if value =~ regex
                      gotit = true
                      throw :next_record
                    end
                  end
                end
              end
            end
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
              gotit = true
            end

            throw :next_record
          end
        end
        
        if gotit
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
  end
end

