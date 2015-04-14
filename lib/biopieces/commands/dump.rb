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
    extend OptionsHelper

    def self.lmb(options)
      options_load_rc(options, __method__)
      options_allowed(options, :first, :last)
      options_unique(options, :first, :last)
      options_assert(options, ':first > 0')
      options_assert(options, ':last > 0')

      new(options).lmb
    end

    def initialize(options)
      @options     = options
      @records_in  = 0
      @records_out = 0
    end

    def lmb
      lambda do |input, output, inlines, status|
        if @options[:first]
          dump_first(input, output, inlines)
        elsif @options[:last]
          dump_last(input, output, inlines)
        else
          dump_all(input, output, inlines)
        end

        return {records_in: @records_in, records_out: @records_out}
      end
    end

    private

    def dump_first(input, output, inlines)
      input.first(@options[:first]).each do |record|
        @records_in += 1
        inlines.map { |inline| inline.call(record) }

        puts record

        if output
          output << record
          @records_out += 1
        end
      end
    end

    def dump_last(input, output, inlines)
      buffer = []
      last   = @options[:last]

      input.each do |record|
        @records_in += 1
        inlines.map { |inline| inline.call(record) }

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

    def dump_all(input, output, inlines)
      input.each do |record|
        @records_in += 1
        inlines.map { |inline| inline.call(record) }

        puts record

        if output
          output << record
          @records_out += 1
        end
      end
    end
  end
end
