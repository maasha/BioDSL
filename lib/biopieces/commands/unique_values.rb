# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #
#                                                                                #
# Copyright (C) 2007-2015 Martin Asser Hansen (mail@maasha.dk).                  #
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
    # == Select unique or non-unique records based on the value of a given key.
    #
    # _unique_values+ selects records from the stream by checking values of a given
    # key. If a duplicate record exists based on the given key, it will only output
    # one record (the first). If the +invert+ option is used, then non-unique
    # records are selected.
    # 
    # == Usage
    # 
    #    unique_values(<key: <string>[, invert: <bool>])
    # 
    # === Options
    #
    # * key: <string>  - Key for which the value is checked for uniqueness.
    # * invert: <bool> - Select non-unique records (default=false).
    # 
    # == Examples
    # 
    # Consider the following two column table in the file `test.tab`:
    # 
    #    Human   H1
    #    Human   H2
    #    Human   H3
    #    Dog     D1
    #    Dog     D2
    #    Mouse   M1
    # 
    # To output only unique values for the first column we first read the table
    # with +read_table+ and then pass the result to +unique_values+:
    # 
    #    BP.new.read_table(input: "test.tab").unique_values(key: :V0).dump.run
    #
    #    {:V0=>"Human", :V1=>"H1"}
    #    {:V0=>"Dog", :V1=>"D1"}
    #    {:V0=>"Mouse", :V1=>"M1"}
    #
    # To output duplicate records instead use the +invert+ options:
    #
    #    BP.new.read_table(input: "test.tab").unique_values(key: :V0, invert: true).dump.run
    #
    #    {:V0=>"Human", :V1=>"H2"}
    #    {:V0=>"Human", :V1=>"H3"}
    #    {:V0=>"Dog", :V1=>"D2"}
    def unique_values(options = {})
      require 'set'

      options_orig = options
      options_load_rc(options, __method__)
      options_allowed(options, :key, :invert)
      options_required(options, :key)
      options_allowed_values(options, invert: [true, false, nil])

      lmb = lambda do |input, output, status|
        status_track(status) do
          lookup = Set.new

          input.each do |record|
            status[:records_in] += 1

            if value = record[options[:key].to_sym]
              value = value.to_sym if value.is_a? String

              if not lookup.include?(value) and not options[:invert]
                output << record
                status[:records_out] += 1

                lookup.add(value)
              elsif lookup.include?(value) and options[:invert]
                output << record
                status[:records_out] += 1
              else
                lookup.add(value)
              end
            else
              output << record
              status[:records_out] += 1
            end
          end

          status[:records_delta]         = status[:records_out] - status[:records_in]
          status[:records_delta_percent] = (100 * status[:records_delta].to_f / status[:records_in]).round(2)
        end
      end

      @commands << BioPieces::Pipeline::Command.new(__method__, options, options_orig, lmb)

      self
    end
  end
end

