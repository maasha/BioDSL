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
  class Dump
    require 'biopieces/helpers/options_helper'
    require 'biopieces/helpers/status_helper'
    extend OptionsHelper
    include StatusHelper

    # Check the options and return a lambda for the command.
    #
    # @param [Hash] options Options hash.
    # @option options [Integer] :first Dump first number of records.
    # @option options [Integer] :last  Dump last number of records.
    #
    # @return [Proc] Returns the dump command lambda.
    def self.lmb(options)
      options_allowed(options, :first, :last)
      options_unique(options, :first, :last)
      options_assert(options, ':first > 0')
      options_assert(options, ':last > 0')

      new(options).lmb
    end

    # Constructor for the Dump class.
    #
    # @param [Hash] options Options hash.
    # @option options [Integer] :first Dump first number of records.
    # @option options [Integer] :last  Dump last number of records.
    #
    # @return [Dump] Returns an instance of the Dump class.
    def initialize(options)
      @options     = options
      status_init(:records_in, :records_out)
    end

    # Return a lambda for the dump command.
    #
    # @return [Proc] Returns the dump command lambda.
    def lmb
      lambda do |input, output, status|
        if @options[:first]
          dump_first(input, output)
        elsif @options[:last]
          dump_last(input, output)
        else
          dump_all(input, output)
        end

        status_assign(status, :records_in, :records_out)
      end
    end

    private

    # Dump the first number of records.
    #
    # @param input [Enumerator::Yielder] Input stream.
    # @param output [Enumerator::Yielder] Output stream.
    def dump_first(input, output)
      input.first(@options[:first]).each do |record|
        @records_in += 1

        puts record

        if output
          output << record
          @records_out += 1
        end
      end
    end

    # Dump the last number of records.
    #
    # @param input [Enumerator::Yielder] Input stream.
    # @param output [Enumerator::Yielder] Output stream.
    def dump_last(input, output)
      buffer = []
      last   = @options[:last]

      input.each do |record|
        @records_in += 1

        buffer << record
        buffer.shift if buffer.size > last
      end

      buffer.each do |record|
        puts record

        if output
          output << record
          @records_out += 1
        end
      end
    end

    # Dump all records.
    #
    # @param input [Enumerator::Yielder] Input stream.
    # @param output [Enumerator::Yielder] Output stream.
    def dump_all(input, output)
      input.each do |record|
        @records_in += 1

        puts record

        if output
          output << record
          @records_out += 1
        end
      end
    end
  end
end
