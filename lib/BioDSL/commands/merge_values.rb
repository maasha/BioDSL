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
# This software is part of the BioDSL framework (www.BioDSL.org).        #
#                                                                              #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

module BioDSL
  # == Merge values of specified keys.
  #
  # +merge_values+ merges the values of a list of keys using a given delimiter
  # and saves the new value as the value of the first key.
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
  class MergeValues
    STATS = %i(records_in records_out)

    # Constructor for MergeValues.
    #
    # @param options [Hash] Options hash.
    # @option options [Array] :keys Keys whos values to merge.
    # @option options [String] :delimiter Delimiter for joining.
    #
    # @return [MergeValues] Class instance of MergeValues.
    def initialize(options)
      @options = options
      check_options
      defaults

      @keys      = options[:keys]
      @delimiter = options[:delimiter]
    end

    # Return command lambda for merge_values.
    #
    # @return [Proc] Command lambda.
    def lmb
      lambda do |input, output, status|
        status_init(status, STATS)

        input.each do |record|
          @status[:records_in] += 1

          if @keys.all? { |key| record.key? key }
            values = @keys.inject([]) { |a, e| a << record[e.to_sym] }
            record[@keys.first] = values.join(@delimiter)
          end

          output << record
          @status[:records_out] += 1
        end
      end
    end

    private

    # Check options.
    def check_options
      options_allowed(@options, :keys, :delimiter)
      options_required(@options, :keys)
    end

    # Set default options.
    def defaults
      @options[:delimiter] ||= '_'
    end
  end
end
