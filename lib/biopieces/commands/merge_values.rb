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
    # == Merge values of specified keys.
    # 
    # +merge_values+ merges the values of a list of keys using a given
    # delimiter and saves the new value as the value of the first key.
    #
    # == Usage
    # 
    #    merge_values(<keys: <list>>[, delimiter: <string>])
    #
    # === Options
    #
    # * keys:      <list>   - List of keys to merge.
    # * delimiter: <string> - Delimiter (default='_').
    #
    # == Examples
    # 
    # Consider the following record:
    #
    #    {ID: "FOO", COUNT: 10, SEQ: "gataag"}
    # 
    # To merge the values so that the COUNT and ID is merged in that order do:
    # 
    #    merge_values(keys: [:COUNT, :ID])
    #
    #    {:ID=>"FOO", :COUNT=>"10_FOO", :SEQ=>"gataag"}
    #
    # Changing the +delimiter+ and order:
    #
    #    merge_values(keys: [:ID, :COUNT], delimiter: ':count=')
    #
    #    {:ID=>"FOO:count=10", :COUNT=>10, :SEQ=>"gataag"}
  end

  test "BioPieces::Pipeline::MergeValues with :delimiter returns correctly" do
    @p.merge_values(keys: [:ID, :COUNT], delimiter: ':count=').run(input: @input, output: @output2)

    result   = @input2.map { |h| h.to_s }.reduce(:<<)
    expected = '{:ID=>"FOO:count=10", :COUNT=>10, :SEQ=>"gataag"}{:ID=>"FOO", :SEQ=>"gataag"}'
    def merge_values(options = {})
      options_orig = options.dup
      options_allowed(options, :keys, :delimiter)
      options_required(options, :keys)

      options[:delimiter] ||= '_'

      lmb = lambda do |input, output, status|
        status_track(status) do
          input.each do |record|
            status[:records_in] += 1

            if options[:keys].all? { |key| record.key? key }
              values = options[:keys].inject([]) { |memo, obj| memo << record[obj.to_sym] }
              record[options[:keys].first] = values.join(options[:delimiter])
            end

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

