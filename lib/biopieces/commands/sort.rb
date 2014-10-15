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
# This software is part of the Biopieces framework (www.biopieces.org).          #
#                                                                                #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

module BioPieces
  module Commands
    # == Sort records in the stream.
    # 
    # +sort+ records in the stream given a specific key.
    #
    # == Usage
    # 
    #    sort(key: <value>[, reverse: <bool>[, block_size: <uint>]])
    #
    # === Options
    #
    # * key: <value>       - Sort records on the value for key.
    # * reverse: <bool>    - Reverse sort.
    # * block_size: <uint> - Block size used for disk based sorting (default=250_000_000).
    # 
    # == Examples
    # 
    def sort(options = {})
      require 'pqueue'

      options_orig = options.dup
      options_allowed(options, :key, :reverse, :block_size)
      options_required(options, :key)
      options_allowed_values(options, reverse: [nil, true, false])
      options_assert(options, ":block_size >  0")

      options[:block_size] ||= BioPieces::Config::SORT_BLOCK_SIZE

      lmb = lambda do |input, output, status|
        status_track(status) do
          files = []
          list  = []
          size  = 0

          input.each do |record|
            status[:records_in] += 1

            list << record
            size += record.to_s.size

            if size > options[:block_size]
              file = Tempfile.new('sort')

              list.sort_by! { |r| r[options[:key].to_sym] }
              list.reverse! if options[:reverse]

              File.open(file, 'w') do |ios|
                list.each do |r|
                  msg = Marshal.dump(r)
                  ios.write([msg.size].pack("I"))
                  ios.write(msg)
                end
              end

              files << file
              list  = []
              size  = 0
            end
          end

          list.sort_by! { |record| record[options[:key].to_sym] }
          list.reverse! if options[:reverse]

          unless files.empty?
            file = Tempfile.new('sort')

            File.open(file, 'w') do |ios|
              list.each do |record|
                msg = Marshal.dump(record)
                ios.write([msg.size].pack("I"))
                ios.write(msg)
              end
            end

            files << file

            begin
              fds = files.inject([]) { |memo, obj| memo << File.open(obj) } 

              if options[:reverse]
                queue = PQueue.new { |a, b| a.first[options[:key].to_sym] <=> b.first[options[:key].to_sym] }
              else
                queue = PQueue.new { |a, b| b.first[options[:key].to_sym] <=> a.first[options[:key].to_sym] }
              end

              fds.each_with_index do |fd, i|
                unless fd.eof?
                  size   = fd.read(4)
                  raise EOFError unless size
                  size   = size.unpack("I").first
                  msg    = fd.read(size)
                  record = Marshal.load(msg)

                  queue << [record, i]
                end
              end

              while ! queue.empty?
                record, i = queue.pop

                output << record
                status[:records_out] += 1

                fd = fds[i]

                unless fd.eof?
                  size   = fd.read(4)
                  raise EOFError unless size
                  size   = size.unpack("I").first
                  msg    = fd.read(size)
                  record = Marshal.load(msg)

                  queue << [record, i]
                end
              end
            ensure
              fds.each { |f| f.close }
            end
          else
            list.each do |r|
              output << r
              status[:records_out] += 1
            end
          end
        end
      end

      @commands << BioPieces::Pipeline::Command.new(__method__, options, options_orig, lmb)

      self
    end
  end
end

