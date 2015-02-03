# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #
#                                                                                #
# Copyright (C) 2007-2015 Martin Asser Hansen (mail@maasha.dk).                  #
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
  # Returns lines, arrays or hashes.
  class CSV
    def self.open(*args)
      io = IO.open(*args)

      if block_given?
        yield self.new(io)
      else
        return self.new(io)
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

      self.open(file) do |ios|
        ios.each_array(options) { |row| data << row } 
      end

      data
    end

    def initialize(io)
      @io        = io
      @delimiter = "\s"
      @header    = nil
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
      get_header(options)
      get_fields(options)

      return to_enum :each_array unless block_given?

      delimiter = options[:delimiter] || @delimiter

      if options[:include_header]
        if @fields
          yield @header.values_at(*@fields)
        else
          yield @header
        end
      end

      @io.each do |line|
        line.chomp!

        unless line.empty? or line[0] == '#'
          fields = line.split(delimiter)
          fields = fields.values_at(*@fields) if @fields
          types  = determine_types(fields) unless types

          yield fields.convert_types(types)
        end
      end

      self
    end

    private

    # Method to get the header as an Array from @io if present in the first 10
    # lines. If a header is found the @header variable is set and returned
    # otherwise nil is returned.
    # Options:
    #   * :delimiter - specify an alternative field delimiter (default="\s").
    #   * :select    - list of column indexes, names or a range to get.
    def get_header(options)
      delimiter = options[:delimiter] || @delimiter

      @io.first(10).each do |line|
        line.chomp!

        unless line.empty?
          if line[0] == '#'
            @header = line[1 .. -1].split(delimiter)

            if options[:select]
              if options[:select].first.is_a? Fixnum
                if options[:select].max >= @header.size
                  raise CSVError, "Selected columns out of bounds: #{options[:select].select { |c| c >= @header.size }}"
                end
              else
                options[:select].each do |value|
                  raise CSVError, "Selected value: #{value} not in header: #{@header}" unless @header.include? value.to_s
                end
              end
            elsif options[:reject]
              if options[:reject].first.is_a? Fixnum
                if options[:reject].max >= @header.size
                  raise CSVError, "Rejected columns out of bounds: #{options[:reject].reject { |c| c >= @header.size }}"
                end
              else
                options[:reject].map do |value|
                  raise CSVError, "Rejected value: #{value} not found in header: #{@header}" unless @header.include? value.to_s
                end
              end
            end

            @io.rewind

            return @header
          end
        end
      end

      @io.rewind

      nil
    end

    def get_fields(options)
      if options[:select]
        if options[:select].first.is_a? Fixnum
          @fields = options[:select]
        else
          raise CSVError, "No header found" unless @header

          fields = []

          options[:select].each do |value|
            fields << @header.index(value.to_s)
          end

          @fields = fields
        end
      elsif options[:reject]
        delimiter = options[:delimiter] || @delimiter

        @io.first(10).each do |line|
          line.chomp!

          unless line.empty?
            fields = line.split(delimiter)
          end
        end

        raise CSVError, "No data in first 10 lines" unless fields

        if options[:reject].first.is_a? Fixnum
          reject = options[:reject].is_a?(Range) ? options[:reject].to_a : options[:reject]
          @fields = (0 ... fields.size).to_a - reject
        else
          raise CSVError, "No header found" unless @header

          @fields = @header.map.with_index.to_h.delete_if { |k, v| options[:reject].include? k or options[:reject].include? k.to_sym }.values
        end

        @io.rewind
      end
    end

    # Method that determines the data types used in an array of fields.
    def determine_types(fields)
      types = []

      fields.each do |field|
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


__END__

    # Method to iterate over a CSV IO object yielding arrays or an enumerator
    #   CSV.each_array(options={}) { |item| block } -> ary
    #   CSV.each_array(options={})                  -> Enumerator
    #
    # Options:
    #   * :delimiter - specify an alternative field delimiter (default="\s").
    #   * :columns   - specify a list or range of columns to output in that order.
    #   * :select    - select columns by header to output in that order (requires header).
    #   * :reject    - reject columns by header (requires header).
    def each_array(options = {})
      return to_enum :each_array unless block_given?

      delimiter = options[:delimiter] || @delimiter
      columns   = options[:columns]

      if options[:select]
        header = self.header(delimiter: delimiter, columns: columns)

        raise BioPieces::CSVError, "No header found" unless header

        unless ([*options[:select]] - header).empty?
          raise BioPieces::CSVError, "No such columns: #{[*options[:select]] - header}"
        end

        columns = header.map.with_index.to_h.values_at(*options[:select])
      end

      if options[:reject]
        header = self.header(delimiter: delimiter, columns: columns)

        raise BioPieces::CSVError, "No header found" unless header

        unless ([*options[:reject]] - header).empty?
          raise BioPieces::CSVError, "No such columns: #{[*options[:reject]] - header}"
        end

        columns = header.map.with_index.to_h.delete_if { |k, v| options[:reject].include? k }.values
      end

      types = nil
      check = true

      @io.each do |line|
        line.chomp!
        next if line.empty? or line[0] == '#'

        fields = line.split(delimiter)

        if columns
          types  = determine_types(line, delimiter).values_at(*columns) unless types

          if check
            if columns.max >= fields.size
              raise CSVError, "Requested columns out of bounds: #{columns.select { |c| c >= fields.size }}"
            end
            check = false
          end

          yield fields.values_at(*columns).convert_types(types)
        else
          types = determine_types(line, delimiter) unless types

          yield fields.convert_types(types)
        end
      end

      self
    end



    # Method to iterate over a CSV IO object yielding hashes or an enumerator
    #   CSV.each_hash(options={}) { |item| block } -> ary
    #   CSV.each_hash(options={})                  -> Enumerator
    #
    # Options:
    #   * :delimiter - specify an alternative field delimiter (default="\s").
    #   * :columns   - specify a list or range of columns to output.
    #   * :headers   - list of headers to use as keys.
    #   * :select    - select columns by header to output (requires header).
    #   * :reject    - reject columns by header (requires header).
    def each_hash(options = {})
      return to_enum :each_hash unless block_given?

      delimiter = options[:delimiter] || @delimiter
      columns   = options[:columns]
      header    = options[:header]

      if columns and header
        if columns.size != header.size
          raise CSVError, "Requested columns and header sizes mismatch: #{columns} != #{header}"
        end
      end

      if options[:select]
        header = self.header(delimiter: delimiter, columns: columns)

        raise BioPieces::CSVError, "No header found" unless header

        unless ([*options[:select]] - header).empty?
          raise BioPieces::CSVError, "No such columns: #{[*options[:select]] - header}"
        end

        columns = header.map.with_index.to_h.values_at(*options[:select])
        header  = options[:select]
      end

      if options[:reject]
        header = self.header(delimiter: delimiter, columns: columns)

        raise BioPieces::CSVError, "No header found" unless header

        unless ([*options[:reject]] - header).empty?
          raise BioPieces::CSVError, "No such columns: #{[*options[:reject]] - header}"
        end

        columns = header.map.with_index.to_h.delete_if { |k, v| options[:reject].include? k }.values
        header.reject! { |k| options[:reject].include? k }
      end

      types = nil
      check = true

      @io.each do |line|
        line.chomp!
        next if line.empty? or line[0] == '#'
        hash = {}

        fields = line.split(delimiter)

        if columns
          types = determine_types(line, delimiter).values_at(*columns) unless types

          if check
            if columns.max > fields.size
              raise CSVError, "Requested columns out of bounds: #{columns.select { |c| c > fields.size }}"
            end

            check = false
          end

          if header
            fields.values_at(*columns).convert_types(types).each_with_index { |e, i| hash[header[i].to_sym] = e }
          else
            fields.values_at(*columns).convert_types(types).each_with_index { |e, i| hash["V#{i}".to_sym] = e }
          end
        else
          types = determine_types(line, delimiter) unless types

          if header
            if check
              if header.size > fields.size
                raise BioPieces::CSVError, "Header contains more fields than columns: #{header.size} > #{fields.size}"
              end

              check = false
            end

            fields.convert_types(types).each_with_index { |e, i| hash[header[i].to_sym] = e }
          else
            fields.convert_types(types).each_with_index { |e, i| hash["V#{i}".to_sym] = e }
          end
        end

        yield hash
      end

      self
    end

