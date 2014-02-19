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
  module ReadFasta
    def read_fasta_check
      options_allowed :input, :first, :last
      options_required :input
      options_glob :input
      options_files_exist :input
      options_unique :first, :last
    end

    def read_fasta
      @input.each { |record| @output.write record } if @input

      count  = 0
      buffer = []

      catch :break do
        @options[:input].each do |file|
          BioPieces::Fasta.open(file) do |ios|
            if @options[:first]
              ios.each do |entry|
                throw :break if @options[:first] == count

                @output.write entry.to_bp

                count += 1
              end
            elsif @options[:last]
              ios.each do |entry|
                buffer << entry
                buffer.shift if buffer.size > @options[:last]
              end
            else
              ios.each do |entry|
                @output.write entry.to_bp
              end
            end
          end
        end

        if @options[:last]
          buffer.each do |entry|
            @output.write entry.to_bp
          end
        end
      end
    end
  end
end

