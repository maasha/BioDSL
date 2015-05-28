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
  # == Sort records in the stream.
  #
  # +sort+ records in the stream given a specific key. Sorting on multiple keys
  # is currently not supported.
  #
  # == Usage
  #
  #    sort(key: <value>[, reverse: <bool>[, block_size: <uint>]])
  #
  # === Options
  #
  # * key: <value>       - Sort records on the value for key.
  # * reverse: <bool>    - Reverse sort.
  # * block_size: <uint> - Block size used for disk based sorting
  #                        (default=250_000_000).
  #
  # == Examples
  #
  # Consider the following table in the file `test.tab`:
  #
  #    #COUNT  ORGANISM
  #    4 Dog
  #    3 Cat
  #    1 Eel
  #
  # To sort this accoring to COUNT in descending order do:
  #
  #    BP.new.read_table(input: "test.tab").sort(key: :COUNT).dump.run
  #
  #    {:COUNT=>1, :ORGANISM=>"Eel"}
  #    {:COUNT=>3, :ORGANISM=>"Cat"}
  #    {:COUNT=>4, :ORGANISM=>"Dog"}
  #
  # And in ascending order:
  #
  #    BP.new.
  #    read_table(input: "test.tab").
  #    sort(key: :COUNT, reverse: true).
  #    dump.
  #    run
  #
  #    {:COUNT=>4, :ORGANISM=>"Dog"}
  #    {:COUNT=>3, :ORGANISM=>"Cat"}
  #    {:COUNT=>1, :ORGANISM=>"Eel"}
  #
  # The type of value determines the sorting, alphabetical order:
  #
  #    BP.new.read_table(input: "test.tab").sort(key: :ORGANISM).dump.run
  #
  #    {:COUNT=>3, :ORGANISM=>"Cat"}
  #    {:COUNT=>4, :ORGANISM=>"Dog"}
  #    {:COUNT=>1, :ORGANISM=>"Eel"}
  #
  # And reverse alphabetic order:
  #
  #    BP.new.
  #    read_table(input: "test.tab").
  #    sort(key: :ORGANISM, reverse: true).
  #    dump.
  #    run
  #
  #    {:COUNT=>1, :ORGANISM=>"Eel"}
  #    {:COUNT=>4, :ORGANISM=>"Dog"}
  #    {:COUNT=>3, :ORGANISM=>"Cat"}
  class Sort
    require 'pqueue'
    require 'biopieces/helpers/options_helper'

    extend OptionsHelper
    include OptionsHelper

    # Check options and return command lambda.
    #
    # @param options [Hash] Options hash.
    #
    # @option options [String,Symbol] :key
    # @option options [Boolean]       :reverse
    # @option options [Integer]       :block_size
    #
    # @return [Proc] Command lambda.
    def self.lmb(options)
      options_allowed(options, :key, :reverse, :block_size)
      options_required(options, :key)
      options_allowed_values(options, reverse: [nil, true, false])
      options_assert(options, ':block_size >  0')

      new(options).lmb
    end

    # Constructor for Sort.
    #
    # @param options [Hash] Options hash.
    #
    # @option options [String,Symbol] :key
    # @option options [Boolean]       :reverse
    # @option options [Integer]       :block_size
    #
    # @return [Sort] Class instance.
    def initialize(options)
      @options     = options
      @records_in  = 0
      @records_out = 0
      @block_size  = options[:block_size] || BioPieces::Config::SORT_BLOCK_SIZE
      @key         = options[:key].to_sym
      @files       = []
      @records     = []
      @size        = 0
      @pqueue       = pqueue_init
      @fds         = nil
    end

    # Return command lambda for Sort.
    #
    # @return [Proc] Command lambda.
    def lmb
      lambda do |input, output, status|
        input.each do |record|
          @records_in += 1
          @records << record
          @size += record.to_s.size
          save_block if @size > @block_size
        end

        save_block
        open_block_files
        fill_pqueue
        output_pqueue(output)
        assign_status(status)
      end
    end

    private

    # Initialize pqueue
    def pqueue_init
      PQueue.new do |a, b|
        if @options[:reverse]
          a.first[@key] <=> b.first[@key]
        else
          b.first[@key] <=> a.first[@key]
        end
      end
    end

    # Save a block of records after sorting this.
    def save_block
      return if @records.empty?

      @records.sort_by! { |r| r[@options[:key].to_sym] }
      @records.reverse! if @options[:reverse]

      serialize_records

      @records = []
      @size    = 0
    end

    # Save sorted records to file.
    def serialize_records
      file = Tempfile.new('sort')

      File.open(file, 'wb') do |ios|
        BioPieces::Serializer.new(ios) do |serializer|
          @records.each { |record| serializer << record }
        end
      end

      @files << file
    end

    # Open all sorted files.
    def open_block_files
      @fds = @files.inject([]) { |a, e| a << File.open(e, 'rb') }
      at_exit { @fds.map(&:close) }
    end

    # Fill the pqueue with the first record from each of the file descriptors.
    def fill_pqueue
      @fds.each_with_index do |fd, i|
        BioPieces::Serializer.new(fd) do |serializer|
          @pqueue << [serializer.next_entry, i] unless fd.eof?
        end
      end
    end

    # Output all records from the pqueue while filling this with the next record
    # from the list of file descriptors.
    #
    # @param output [Enumerator::Yeilder] Output stream.
    def output_pqueue(output)
      until @pqueue.empty?
        record, i = @pqueue.pop

        output << record
        @records_out += 1

        fd = @fds[i]

        BioPieces::Serializer.new(fd) do |serializer|
          @pqueue << [serializer.next_entry, i] unless fd.eof?
        end
      end
    end

    # Assign values to status hash.
    #
    # @param status [Hash] Status hash.
    def assign_status(status)
      status[:records_in]  = @records_in
      status[:records_out] = @records_out
    end
  end
end
