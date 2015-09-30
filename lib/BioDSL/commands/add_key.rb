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
# This software is part of the Biopieces framework (www.biopieces.org).        #
#                                                                              #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

module BioPieces
  # == Add a key/value pair to all records in stream.
  #
  # +add_key+ can be used to add a fixed value to a specified key to all
  # records in the stream, or add a numeric forth running number (zero-based)
  # with a specified prefix.
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
  # To add a value to all records in the stream do:
  #
  #    add_key(key: "FOO", value: "BAR")
  #
  # To add a forth running number to all records in the stream do:
  #
  #    add_key(key: :ID, prefix: "")
  #
  # Finally, to add a forth running number with a prefix do:
  #
  #    add_key(key: :ID, prefix: "ID_")
  class AddKey
    STATS = %i(records_in records_out)

    # Constructor for AddKey.
    #
    # @param [Hash] options Options hash.
    # @option options [Symbol] :key    Key to add or replace.
    # @option options [String] :value  Value to use with :key.
    # @option options [String] :prefix Prefix to use with :key.
    #
    # @return [Proc] Returns class instance.
    def initialize(options)
      @options = options

      check_options
    end

    # Add a key or replace a key for all records with a specified value or a
    # forthrunning number with a prefix.
    #
    # @param [Hash] options Options hash.
    # @option options [Symbol] :key    Key to add or replace.
    # @option options [String] :value  Value to use with :key.
    # @option options [String] :prefix Prefix to use with :key.
    #
    # @return [Proc] Returns the command lambda.
    def lmb
      lambda do |input, output, status|
        status_init(status, STATS)

        input.each_with_index do |record, i|
          @status[:records_in] += 1

          record[@options[:key].to_sym] = @options[:value] ||
                                          "#{@options[:prefix]}#{i}"

          output << record

          @status[:records_out] += 1
        end
      end
    end

    private

    # Check all options.
    def check_options
      options_allowed(@options, :key, :value, :prefix)
      options_required(@options, :key)
      options_required_unique(@options, :value, :prefix)
    end
  end
end
