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
    # == Count the number of times values of given keys exists in stream.
    #
    # +count_values+ count the values for a given comma seperated list of keys.
    # 
    # == Usage
    # 
    #    count_values(<keys: <list>)
    # 
    # === Options
    #
    # * keys: <list>  - Keys whos values to count.
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
    # To count the values of both columns we first read the table with
    # +read_table+ and then pass the result to +count_values+:
    # 
    #    BP.new.read_table(input: "test.tab").count_values(keys: [:V0, :V1]).dump.run
    #
    #    {:V0=>"Human", :V1=>"H1", :V0_COUNT=>3, :V1_COUNT=>1}
    #    {:V0=>"Human", :V1=>"H2", :V0_COUNT=>3, :V1_COUNT=>1}
    #    {:V0=>"Human", :V1=>"H3", :V0_COUNT=>3, :V1_COUNT=>1}
    #    {:V0=>"Dog", :V1=>"D1", :V0_COUNT=>2, :V1_COUNT=>1}
    #    {:V0=>"Dog", :V1=>"D2", :V0_COUNT=>2, :V1_COUNT=>1}
    #    {:V0=>"Mouse", :V1=>"M1", :V0_COUNT=>1, :V1_COUNT=>1}
    def count_values(options = {})
      require 'tempfile'

      options_orig = options
      options_load_rc(options, __method__)
      options_allowed(options, :keys)
      options_required(options, :keys)

      lmb = lambda do |input, output, status|
        status_track(status) do
          keys       = options[:keys].map { |key| key.to_sym }
          count_hash = Hash.new { |h, k| h[k] = Hash.new(0) }
          file       = Tempfile.new("count_values")

          begin
            File.open(file, 'wb') do |ios|
              BioPieces::Serializer.new(ios) do |s|
                input.each do |record|
                  keys.map { |key| count_hash[key][record[key]] += 1 if record[key] }
                  status[:records_in] += 1

                  s << record
                end
              end
            end
            
            File.open(file, 'rb') do |ios|
              BioPieces::Serializer.new(ios) do |s|
                s.each do |record|
                  keys.map do |key|
                    if record[key]
                      record["#{key}_COUNT".to_sym] = count_hash[key][record[key]]
                    end
                  end

                  output << record
                  status[:records_out] += 1
                end
              end
            end
          ensure
            file.close
            file.unlink
          end
        end
      end

      @commands << BioPieces::Pipeline::Command.new(__method__, options, options_orig, lmb)

      self
    end
  end
end

