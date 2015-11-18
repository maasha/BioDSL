# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #
#                                                                              #
# Copyright (C) 2007-2015 Martin Asser Hansen (mail@maasha.dk).                #
#                                                                              #
# This program is free software; you can redistribute it and/or                #
# modify it under the terms of the GNU General Public License                  #
# as published by the Free Software Foundation; either version 2               #
# of the License, or (at your option) any later version.                       #
#                                                                              #
# This program is distributed in the hope that it will be useful,              #
# but WITHOUT ANY WARRANTY; without even the implied warranty of               #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                #
# GNU General Public License for more details.                                 #
#                                                                              #
# You should have received a copy of the GNU General Public License            #
# along with this program; if not, write to the Free Software                  #
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301,    #
# USA.                                                                         #
#                                                                              #
# http://www.gnu.org/copyleft/gpl.html                                         #
#                                                                              #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #
#                                                                              #
# This software is part of the BioDSL (www.BioDSL.org).                        #
#                                                                              #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

module BioDSL
  # == Split the values of a key into new key/value pairs.
  #
  # +split_values+ splits the value of a given key into multiple values that are
  # added to the record. The keys used for the values are per default based on
  # the given key with an added index, but using the +keys+ option allows
  # specifying a list of keys to use instead.
  #
  # == Usage
  #
  #    split_values(<key>: <string>>[, delimiter: <string>[, keys: <list>]])
  #
  # === Options
  #
  # # key:       <string> - Key who's value to split.
  # * keys:      <list>   - List of keys to use with split values.
  # * delimiter: <string> - Delimiter (default='_').
  #
  # == Examples
  #
  # Consider the following records:
  #
  #    {ID: "FOO:count=10", SEQ: "gataag"}
  #    {ID: "FOO_10_20", SEQ: "gataag"}
  #
  # To split the value belinging to ID do:
  #
  #    split_values(key: :ID)
  #
  #    {:ID=>"FOO:count=10", :SEQ=>"gataag"}
  #    {:ID=>"FOO_10_20", :SEQ=>"gataag", :ID_0=>"FOO", :ID_1=>10, :ID_2=>20}
  #
  # Using a different delimiter:
  #
  #    split_values(key: "ID", delimiter: ':count=')
  #
  #    {:ID=>"FOO:count=10", :SEQ=>"gataag", :ID_0=>"FOO", :ID_1=>10}
  #    {:ID=>"FOO_10_20", :SEQ=>"gataag"}
  #
  # Using a different delimiter and a list of keys:
  #
  #    split_values(key: "ID", keys: ["ID", :COUNT], delimiter: ':count=')
  #
  #    {:ID=>"FOO", :SEQ=>"gataag", :COUNT=>10}
  #    {:ID=>"FOO_10_20", :SEQ=>"gataag"}
  class SplitValues
    STATS = %i(records_in records_out)

    # Constructor for SplitValues.
    #
    # @param options [Hash] Options hash.
    # @option options [String,Symbol] :key
    # @option options [Array]         :keys
    # @option options [String]        :delimiter
    #
    # @return [SplitValues] Class instance.
    def initialize(options)
      @options     = options

      check_options

      @first       = true
      @convert     = []
      @keys        = @options[:keys]
      @key         = @options[:key].to_sym
      @delimiter   = @options[:delimiter] || '_'
    end

    # Return command lambda for split_values.
    #
    # @return [Proc] Command lambda.
    def lmb
      lambda do |input, output, status|
        status_init(status, STATS)

        input.each do |record|
          @status[:records_in] += 1

          if (value = record[@key])
            values = value.split(@delimiter)

            if values.size > 1
              determine_types(values) if @first

              split_values(values, record)
            end
          end

          output << record

          @status[:records_out] += 1
        end
      end
    end

    private

    # Check options.
    def check_options
      options_allowed(@options, :key, :keys, :delimiter)
      options_required(@options, :key)
    end

    # Given an array of values determine the types that must be converted to
    # integers or floats and save the value index in a class variable.
    #
    # @param values [Array] List of values.
    def determine_types(values)
      values.each_with_index do |val, i|
        val = val.to_num

        if val.is_a? Fixnum
          @convert[i] = :to_i
        elsif val.is_a? Float
          @convert[i] = :to_f
        end
      end

      @first = false
    end

    # Convert values and add to record.
    #
    # @param values [Array] List of values.
    # @param record [Hash]  BioDSL record.
    def split_values(values, record)
      values.each_with_index do |val, i|
        val = val.send(@convert[i]) if @convert[i]

        if @keys
          record[@keys[i].to_sym] = val
        else
          record["#{@key}_#{i}".to_sym] = val
        end
      end
    end
  end
end
