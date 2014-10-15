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
    require 'tempfile'
    require 'terminal-table'

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
        thr = Thread.new do
          loop do
            status_save(status)

            sleep BioPieces::Config::STATUS_SAVE_INTERVAL
          end
        end
      end

      block.call

      thr.terminate if @options[:progress]

      status_save(status)
    end

    def status_progress(&block)

      thr = Thread.new do
        print "\e[H\e[2J"   # Console code to clear screen

        loop do
          status = status_load

          status.map { |s| s[:time_elapsed] = (s[:time_stop] || Time.now) - s[:time_start] }

          table  = status_tabulate(status).to_s

          print "\e[1;1H"    # Console code to move cursor to 1,1 coordinate.
          puts "Started: #{status.first[:time_start]}"
          puts table 

          sleep BioPieces::Config::STATUS_SAVE_INTERVAL
        end
      end

      block.call

      status = status_load

      status.map { |s| s[:time_elapsed] = (s[:time_stop] || Time.now) - s[:time_start] }

      table  = status_tabulate(status).to_s

      print "\e[1;1H"    # Console code to move cursor to 1,1 coordinate.
      puts "Started: #{status.first[:time_start]}"
      puts table 

      thr.terminate
    end

    def status_tabulate(status)
      rows = []
      rows <<  %w{name records_in records_out time_elapsed status}

      status.each do |s|
        row = []
        row << s[:name]
        row << s[:records_in].commify
        row << s[:records_out].commify
        row << (Time.mktime(0) + s[:time_elapsed]).strftime("%H:%M:%S")
        row << s[:status]
        rows << row
      end

      table = Terminal::Table.new
      table.style = {border_x: '', border_y: '', border_i: '' }
      table.rows = rows

      table.align_column(1, :right)
      table.align_column(2, :right)

      table
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

    def status_dump(path)
      File.open(path, 'w') { |file| file.write @status.to_yaml }
    end
  end
end

