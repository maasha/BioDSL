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

module BioPieces
  module StatusHelper
    require 'tempfile'
    require 'terminal-table'

    # Given a list of symbols initialize an initialize all as instance variables
    # with the value 0.
    #
    # @param args [Array] List of symbols.
    def status_init(args)
      args.each do |arg|
        instance_variable_set("@#{arg}".to_sym, 0)
      end
    end

    # Assign values to status hash from instance variables specified by a list
    # of given symbols.
    #
    # @param status [Hash]  Status hash.
    # @param args   [Array] List of symbols.
    def status_assign(status, args)
      args.each do |arg|
        status[arg] = instance_variable_get("@#{arg}".to_sym)
      end
    end

    # Track the status of a running command in a seperate thread and output
    # the status at speficied intervals.
    #
    # @param commands [Array] List of commands whos status should be output.
    # @param block    [Proc]  Track the command in the given block.
    #
    # @raise [RunTimeError] If no block is given.
    def status_track(commands, &block)
      fail 'No block given' unless block

      thread = Thread.new do
        loop do
          commands.map(&:status) # FIXME

          sleep BioPieces::Config::STATUS_SAVE_INTERVAL
        end
      end

      block.call

      thread.terminate
    end

    def status_progress(&block)
      raise
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
      raise
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
      raise
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
      raise
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
      raise
      File.open(path, 'w') { |file| file.write @status.to_yaml }
    end
  end
end

