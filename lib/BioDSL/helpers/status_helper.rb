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
# This software is part of Biopieces (www.biopieces.org).                      #
#                                                                              #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

module BioPieces
  # Namespace with methods to record and manipulate cammand status.
  module StatusHelper
    require 'tempfile'
    require 'terminal-table'

    # Given a list of symbols initialize all as status hash keys with the value
    # 0.
    #
    # @param status [Hash]  Status hash.
    # @param args   [Array] List of symbols.
    def status_init(status, args)
      args.each { |arg| status[arg] = 0 }
      @status = status
    end

    # Track the status progress of a running command in a seperate thread and
    # output the status at speficied intervals.
    #
    # @param commands [Array] List of commands whos status should be output.
    # @param block    [Proc]  Track the command in the given block.
    #
    # @raise [RunTimeError] If no block is given.
    def status_progress(commands, &block)
      fail 'No block given' unless block

      thread = Thread.new do
        print "\e[H\e[2J"   # Console code to clear screen

        loop do
          progress_print(commands)

          sleep BioPieces::Config::STATUS_PROGRESS_INTERVAL
        end
      end

      block.call

      thread.terminate

      progress_print(commands)
    end

    private

    # Print the progress table to terminal.
    #
    # @param commands [Array] List of commands whos status should be output.
    def progress_print(commands)
      print "\e[1;1H"    # Console code to move cursor to 1,1 coordinate.
      puts "Started: #{commands.first.status[:time_start]}"
      puts status_tabulate(commands)
    end

    # Create status table.
    #
    # @param commands [Array] List of commands whos status should be output.
    #
    # @return [String] Status table.
    def status_tabulate(commands)
      return unless commands.first.status[:records_in]

      table = Terminal::Table.new
      table.style = {border_x: '', border_y: '', border_i: ''}
      table.rows = status_rows(commands)

      table.align_column(1, :right)
      table.align_column(2, :right)

      table.to_s
    end

    # Compile rows with table data.
    #
    # @param commands [Array] List of commands whos status should be output.
    #
    # @return [Array] List of rows.
    def status_rows(commands)
      rows = [%w(name records_in records_out time_elapsed status)]

      commands.each do |command|
        update_time(command)

        row = []
        row << command.name
        row << command.status[:records_in].commify
        row << command.status[:records_out].commify
        row << command.status[:time_elapsed]
        row << command.run_status
        rows << row
      end

      rows
    end

    # Update the time_stop and time_elapsed for a given command.
    #
    # @param command [BioPieces::Command] Command object.
    def update_time(command)
      command.status[:time_stop] = Time.now unless command.run_status == 'done'

      command.calc_time_elapsed
    end
  end
end
