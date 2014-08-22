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

module BioPieces
  module StatusHelper
    def status_init
      @commands.map do |command|
        command.status = {
          __status_file__: Tempfile.new(command.name.to_s),
          name:            command.name,
          options:         command.options,
          records_in:      0,
          records_out:     0
        }
      end

      @commands.first.status[:__last__] = true
    end

    def status_track(status, &block)
      if @options[:progress]
        Thread.new do
          loop do
            status_save(status)

            sleep BioPieces::Config::STATUS_SAVE_INTERVAL
          end
        end
      end

      block.call

      status_save(status)
    end

    def status_progress(&block)
      Thread.new do
        loop do
          pp status_load

          sleep BioPieces::Config::STATUS_SAVE_INTERVAL
        end
      end

      block.call
    end

    def status_load
      status = []

      @commands.each do |command|
        begin
          status << Marshal.load(File.read(command.status[:__status_file__]))
        rescue ArgumentError
          retry
        end
      end

      status
    end

    def status_save(status)
      data = {}

      status.each do |key, value|
        next if key == :__status_file__ || key == :__last__

        # Skip unmarshallable objects
        begin
          Marshal.dump(key)
          Marshal.dump(value)
        rescue TypeError
          next
        end

        data[key] = value
      end

      File.open(status[:__status_file__], 'w') do |ios|
        Marshal.dump(data, ios)
      end
    end
  end
end

