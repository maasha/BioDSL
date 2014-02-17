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
      options_allowed :select, :reject, :keys_only, :values_only, :ignore_case
      options_required_unique :select, :reject
      options_unique :keys_only, :values_only

      pattern = @options[:select] || @options[:reject]
      regex   = @options[:ignore_case] ? Regexp.new(/#{pattern}/i) : Regexp.new(/#{pattern}/)

      @input.each do |record|
        catch :next_record do
          record.each do |key, value|
            if @options[:select]
              if @options[:keys_only]
                if key =~ regex
                  @output.write record if @output
                  throw :next_record
                end
              elsif @options[:values_only]
                if value =~ regex
                  @output.write record if @output
                  throw :next_record
                end
              else
                if key =~ /#{@options[:select]}/
                  @output.write record if @output
                  throw :next_record
                elsif value =~ regex
                  @output.write record if @output
                  throw :next_record
                end
              end
            end
          end
        end
      end
    end
  end
end

