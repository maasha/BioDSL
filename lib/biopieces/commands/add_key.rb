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
    # == Add a key/value pair to all records in stream.
    # 
    # == Usage
    # 
    #    add_key(<key: <string>[, value: <string> | prefix: <string>])
    # 
    # === Options
    #
    # * key: <string>    - Key to add or overwrite.
    # * value: <string>  - Value to use with +key+.
    # * prefix: <string> - Prefix to use with +key+.
    # 
    # == Examples
    # 
    # To add_key all records in the stream:
    #
    #    add_key
    #
    # To add_key only the _first_ 10 records:
    #
    #    add_key(first: 10)
    #
    # To add_key only the _last_ 10 records:
    # 
    #    add_key(last: 10)
    def add_key(options = {})
      options_orig = options
      options_allowed(options, :key, :value, :prefix)
      options_required(options, :key)
      options_required_unique(options, :value, :prefix)

      lmb = lambda do |input, output, status|
        status_track(status) do
          input.each_with_index do |record, i|
            status[:records_in] += 1

            if options[:value]
              value = options[:value]
            else
              value = "#{options[:prefix]}#{i}"
            end

            record[options[:key].to_sym] = value

            output << record

            status[:records_out] += 1
          end
        end
      end

      @commands << BioPieces::Pipeline::Command.new(__method__, options, options_orig, lmb)

      self
    end
  end
end

