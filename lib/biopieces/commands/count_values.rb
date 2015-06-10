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
  #    BP.new.
  #    read_table(input: "test.tab").
  #    count_values(keys: [:V0, :V1]).
  #    dump.
  #    run
  #
  #    {:V0=>"Human", :V1=>"H1", :V0_COUNT=>3, :V1_COUNT=>1}
  #    {:V0=>"Human", :V1=>"H2", :V0_COUNT=>3, :V1_COUNT=>1}
  #    {:V0=>"Human", :V1=>"H3", :V0_COUNT=>3, :V1_COUNT=>1}
  #    {:V0=>"Dog", :V1=>"D1", :V0_COUNT=>2, :V1_COUNT=>1}
  #    {:V0=>"Dog", :V1=>"D2", :V0_COUNT=>2, :V1_COUNT=>1}
  #    {:V0=>"Mouse", :V1=>"M1", :V0_COUNT=>1, :V1_COUNT=>1}
  class CountValues
    require 'biopieces/helpers/options_helper'
    require 'biopieces/helpers/status_helper'

    extend OptionsHelper
    include OptionsHelper
    include StatusHelper

    STATS = %i(records_in records_out)

    # Check options and return command lambda for CountValues.
    #
    # @param options [Hash] Options hash.
    # @option options [Array] List of keys whos values to count.
    #
    # @return [Proc] Lambda for command.
    def self.lmb(options)
      options_allowed(options, :keys)
      options_required(options, :keys)

      new(options).lmb
    end

    # Constructor for CountValues.
    #
    # @param options [Hash] Options hash.
    # @option options [Array] List of keys whos values to count.
    #
    # @return [CountValues] Instance of class.
    def initialize(options)
      @options     = options
      @keys       = @options[:keys].map(&:to_sym)
      @count_hash = Hash.new { |h, k| h[k] = Hash.new(0) }

      status_init(STATS)
    end

    # Return the command lambda for the count_values command.
    #
    # @return [Proc] Return command lambda.
    def lmb
      lambda do |input, output, status|
        TmpDir.create('count_values') do |tmp_file, _|
          process_input(input, tmp_file)
          process_output(output, tmp_file)
        end

        status_assign(status, STATS)
      end
    end

    private

    # Save serialized stream to a temporary file and counting the requested
    # values.
    #
    # @param input [Enumerator] Input stream.
    # @param tmp_file [String] Path to temp file.
    def process_input(input, tmp_file)
      File.open(tmp_file, 'wb') do |ios|
        BioPieces::Serializer.new(ios) do |s|
          input.each do |record|
            @keys.map do |key|
              @count_hash[key][record[key]] += 1 if record.key? key
            end

            @records_in += 1

            s << record
          end
        end
      end
    end

    # Output serialized stream to the output stream including value counts.
    #
    # @param output [Enumerator::Yielder] Output stream.
    # @param tmp_file [String] Path to temp file with serialized input stream.
    def process_output(output, tmp_file)
      File.open(tmp_file, 'rb') do |ios|
        BioPieces::Serializer.new(ios) do |s|
          s.each do |record|
            @keys.map do |key|
              if record.key? key
                record["#{key}_COUNT".to_sym] = @count_hash[key][record[key]]
              end
            end

            output << record
            @records_out += 1
          end
        end
      end
    end
  end
end
