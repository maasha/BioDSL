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
# This software is part of Biopieces (www.biopieces.org).                        #
#                                                                                #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

class Array
  # Method that converts variable types given an array of types.
  # Example: ["fish", 0.0, 1].convert_types([:to_s, :to_f, :to_i])
  def convert_types(types)
    raise ArgumentError, "Array and types size mismatch: #{self.size} != #{types.size}" if self.size != types.size

    types.each_with_index do |type, i|
      self[i] = self[i].send(type)
    end

    self
  end
end

module BioPieces
  class CSVError < StandardError; end

  # Class for manipulating CSV or table files.
  # Allow reading and writing of gzip and bzip2 data.
  # Auto-convert data types.
  class CSV
    def self.open(*args)
      io = IO.open(*args)

      if block_given?
        yield self.new(io)
      else
        return self.new(io)
      end
    end

    # Method that reads all CSV data from a file into
    # an array of arrays (array of rows) which is returned.
    def self.read(file)
      data = []

      self.open(file) do |ios|
        ios.each_array { |row| data << row } 
      end

      data
    end

    def initialize(io)
      @io        = io
      @delimiter = "\s"
      @header    = nil
    end

    # Method to return a table header prefixed with '#'
    # Once a table header is found, other lines prefixed
    # with '#' will be skipped.
    # The header is returned as an array.
    def header(options = {})
      return @header if @header

      @io.each_with_index do |line, i|
        line.chomp!
        next if line.empty?

        if line[0] == '#'
          delimiter = options[:delimiter] || @delimiter

          if columns = options[:columns]
            @header = line[1 .. -1].split(delimiter).values_at(*columns).map { |h| h.to_sym }
          else
            @header = line[1 .. -1].split(delimiter).map { |h| h.to_sym }
          end

          return @header
        end

        if i == 10
          break
        end
      end

      @io.rewind

      nil
    end

    # Method to skip a given number or lines.
    def skip(num)
      num.times { @io.get_entry }
    end

    # Method to iterate over a CSV IO object yielding lines or an enumerator
    #   CSV.each { |item| block }  -> ary
    #   CSV.each                   -> Enumerator
    def each
      return to_enum :each unless block_given?

      @io.each do |line|
        next if line.chomp.empty? or line[0] == '#'

        yield line
      end

      self
    end

    # Method to iterate over a CSV IO object yielding arrays or an enumerator
    #   CSV.each_array(options={}) { |item| block }  -> ary
    #   CSV.each_array(options={})                   -> Enumerator
    #
    # It is possible to specify a :delimiter and list or range of :columns.
    def each_array(options = {})
      return to_enum :each_array unless block_given?

      delimiter = options[:delimiter] || @delimiter
      types     = nil

      @io.each do |line|
        line.chomp!
        next if line.empty? or line[0] == '#'

        if columns = options[:columns]
          types = determine_types(line, delimiter).values_at(*columns) unless types

          yield line.split(delimiter).values_at(*columns).convert_types(types)
        else
          types = determine_types(line, delimiter) unless types

          yield line.split(delimiter).convert_types(types)
        end
      end

      self
    end

    # Method to iterate over a CSV IO object yielding hashes or an enumerator
    #   CSV.each_hash(options={}) { |item| block }  -> ary
    #   CSV.each_hash(options={})                   -> Enumerator
    #
    # It is possible to specify a :delimiter.
    # A list or range of :columns.
    # A list of :headers to use as keys.
    def each_hash(options = {})
      return to_enum :each_hash unless block_given?

      delimiter = options[:delimiter] || @delimiter
      types     = nil

      @io.each do |line|
        line.chomp!
        next if line.empty? or line[0] == '#'
        hash = {}

        if columns = options[:columns]
          types = determine_types(line, delimiter).values_at(*columns) unless types

          if header = options[:header]
            line.split(delimiter).values_at(*columns).convert_types(types).each_with_index { |e, i| hash[header[i].to_sym] = e }
          else
            line.split(delimiter).values_at(*columns).convert_types(types).each_with_index { |e, i| hash["V#{i}".to_sym] = e }
          end
        else
          types = determine_types(line, delimiter) unless types

          if header = options[:header]
            line.split(delimiter).convert_types(types).each_with_index { |e, i| hash[header[i].to_sym] = e }
          else
            line.split(delimiter).convert_types(types).each_with_index { |e, i| hash["V#{i}".to_sym] = e }
          end
        end

        yield hash
      end

      self
    end

    private

    # Method that determines the data types used in a row.
    def determine_types(line, delimiter)
      types = []

      line.split(delimiter).each do |field|
        field = field.to_num

        if field.is_a? Fixnum
          types << :to_i
        elsif field.is_a? Float
          types << :to_f
        elsif field.is_a? String
          types << :to_s
        else
          types << nil
        end
      end

      types
    end

    class IO < Filesys
      def rewind
        @io.rewind
      end
    end
  end
end
