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
    # == Dump records in stream to STDOUT.
    # 
    # +dump+ outputs records from the stream to STDOUT.
    # 
    # == Usage
    # 
    #    dump([first: <uint> |last: <uint>])
    # 
    # === Options
    #
    # * first <uint> - Only dump the first number of records.
    # * last <uint>  - Only dump the last number of records.
    # 
    # == Examples
    # 
    # To dump all records in the stream:
    #
    #    dump
    #
    # To dump only the _first_ 10 records:
    #
    #    dump(first: 10)
    #
    # To dump only the _last_ 10 records:
    # 
    #    dump(last: 10)
    def dump(options = {})
      options_allowed(options, :first, :last)
      options_unique(options, :first, :last)
      options_assert(options, ":first > 0")
      options_assert(options, ":last > 0")

      lmb = lambda do |input, output, status|
        status_track(status) do
          if options[:first]
            input.each_with_index do |record, i|
              break if options[:first] == i

              pp record

              status[:records_in] += 1

              if output
                output << record
                status[:records_out] += 1
              end
            end
          elsif options[:last]
            buffer = []

            input.each do |record|
              status[:records_in] += 1

              buffer << record
              buffer.shift if buffer.size > options[:last]
            end

            buffer.each do |record|
              pp record

              output << record if output
            end
          else
            input.each do |record|
              status[:records_in] += 1

              pp record

              if output
                output << record
                status[:records_out] += 1
              end
            end
          end
        end
      end

      @commands << BioPieces::Pipeline::Command.new(__method__, options, lmb)

      self
    end
  end
end

