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
# This software is part of BioDSL (www.github.com/maasha/BioDSL).              #
#                                                                              #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

# Monkey patching Array to add convert_types method.
class Array
  # Method that converts variable types given an array of types.
  # Example: ["fish", 0.0, 1].convert_types([:to_s, :to_f, :to_i])
  def convert_types(types)
    if size != types.size
      fail ArgumentError, "Array and types size mismatch: #{size} != " \
        "#{types.size}"
    end

    types.each_with_index do |type, i|
      self[i] = self[i].send(type)
    end

    self
  end
end

module BioDSL
  class CSVError < StandardError; end

  # rubocop: disable ClassLength

  # Class for manipulating CSV or table files.
  # Allow reading and writing of gzip and bzip2 data.
  # Auto-convert data types.
  # Returns lines, arrays or hashes.
  class CSV
    def self.open(*args)
      io = IO.open(*args)

      if block_given?
        yield new(io)
      else
        return new(io)
      end
    end

    # Method that reads all CSV data from a file into an array of arrays (array
    # of rows) which is returned. In the default mode all columns are read.
    # Using the select option subselects the columns based on a given Array or
    # if a heder line is present a given Hash. Visa versa for the reject option.
    # Header lines are prefixed with '#' and are returned if the include_header
    # option is given.
    #
    # Options:
    #   * include_header
    #   * delimiter.
    #   * select.
    #   * reject.
    def self.read_array(file, options = {})
      data = []

      open(file) do |ios|
        ios.each_array(options) { |row| data << row }
      end

      data
    end

    # Method that reads all CSV data from a file into an array of hashes (array
    # of rows) which is returned. In the default mode all columns are read.
    # Using the select option subselects the columns based on a given Array or
    # if a heder line is present a given Hash. Visa versa for the reject option.
    # Header lines are prefixed with '#'.
    #
    # Options:
    #   * delimiter.
    #   * select.
    #   * reject.
    def self.read_hash(file, options = {})
      data = []

      open(file) do |ios|
        ios.each_hash(options) { |row| data << row }
      end

      data
    end

    # Constructor method for CSV.
    def initialize(io)
      @io        = io
      @delimiter = "\s"
      @header    = nil
      @fields    = nil
      @types     = nil
    end

    # Method to skip a given number or non-empty lines.
    def skip(num)
      while num != 0 && (line = @io.gets)
        line.chomp!

        num -= 1 unless line.empty?
      end
    end

    # Method to iterate over a CSV IO object yielding arrays or an enumerator
    #   CSV.each_array(options={}) { |item| block } -> ary
    #   CSV.each_array(options={})                  -> Enumerator
    #
    # Options:
    #   * :include_header -
    #   * :delimiter      -
    #   * :select         -
    #   * :reject         -
    def each_array(options = {})
      return to_enum :each_array unless block_given?

      delimiter = options[:delimiter] || @delimiter

      @io.each do |line|
        line.chomp!
        next if line.empty?

        fields = line.split(delimiter)

        if line[0] == '#'
          get_header(fields, options) unless @header
          get_fields(fields, options) unless @fields

          yield @header.map(&:to_s) if options[:include_header]
        else
          get_header(fields, options) unless @header
          get_fields(fields, options) unless @fields

          fields = fields.values_at(*@fields) if @fields

          determine_types(fields) unless @types

          yield fields.convert_types(@types)
        end
      end

      self
    end

    # Method to iterate over a CSV IO object yielding hashes or an enumerator
    #   CSV.each_hash(options={}) { |item| block } -> hash
    #   CSV.each_hash(options={})                  -> Enumerator
    #
    # Options:
    #   * :delimiter      -
    #   * :select         -
    #   * :reject         -
    def each_hash(options = {})
      each_array(options) do |array|
        hash = {}

        array.convert_types(@types).each_with_index do |field, i|
          hash[@header[i]] = field
        end

        yield hash
      end

      self
    end

    private

    # Method to set the @header given a list of fields (a row).
    # Options:
    #   * :select - list of column indexes, names or a range to select.
    #   * :reject - list of column indexes, names or a range to reject.
    def get_header(fields, options)
      if fields[0][0] == '#'
        fields[0] = fields[0][1..-1]
        @header = fields.map(&:to_sym)
      else
        @header = []
        fields.each_with_index { |_field, i| @header << "V#{i}".to_sym }
      end

      if options[:select]
        if options[:select].first.is_a? Fixnum
          if options[:select].max >= @header.size
            fail CSVError, "Selected columns out of bounds: #{options[:select].
              select { |c| c >= @header.size }}"
          end
        else
          options[:select].each do |value|
            unless @header.include? value.to_sym
              fail CSVError, "Selected value: #{value} not in header: " \
                " #{@header}"
            end
          end
        end
      elsif options[:reject]
        if options[:reject].first.is_a? Fixnum
          if options[:reject].max >= @header.size
            fail CSVError, "Rejected columns out of bounds: #{options[:reject].
              reject { |c| c >= @header.size }}"
          end
        else
          options[:reject].map do |value|
            unless @header.include? value.to_sym
              fail CSVError, "Rejected value: #{value} not found in header: " \
                "#{@header}"
            end
          end
        end
      end

      @header
    end

    # Method to determine the indexes of fields to be parsed and store these in
    # @fields.
    # Options:
    #   * :select - list of column indexes, names or a range to select.
    #   * :reject - list of column indexes, names or a range to reject.
    def get_fields(fields, options)
      if options[:select]
        if options[:select].first.is_a? Fixnum
          @fields = options[:select]
        else
          fail CSVError, 'No header found' unless @header

          fields = []

          options[:select].each do |value|
            fields << @header.index(value.to_sym)
          end

          @fields = fields
        end

        @header = @header.values_at(*@fields)
      elsif options[:reject]
        if options[:reject].first.is_a? Fixnum
          reject = if options[:reject].is_a?(Range)
                     options[:reject].to_a
                   else
                     options[:reject]
                   end
          @fields = (0...fields.size).to_a - reject
        else
          fail CSVError, 'No header found' unless @header

          reject = options[:reject].map(&:to_sym)

          @fields = @header.map.with_index.to_h.
                    delete_if { |k, _| reject.include? k }.values
        end

        @header = @header.values_at(*@fields)
      end
    end

    # Method that determines the data types used in an array of fields.
    def determine_types(fields)
      types = []

      fields.each do |field|
        field = field.to_num

        types << if field.is_a? Fixnum
                   :to_i
                 elsif field.is_a? Float
                   :to_f
                 elsif field.is_a? String
                   :to_s
                 end
      end

      @types = types
    end

    # IO class for CSV.
    class IO < Filesys
      def gets
        @io.gets
      end
    end
  end
end
