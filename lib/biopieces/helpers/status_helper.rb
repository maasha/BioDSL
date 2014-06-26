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
    def status_track(input, output, run_options, &block)
      time = Time.now

      Thread.new do
        loop do
          status_save(input, output, time, run_options)

          if run_options[:progress]
            system("clear")
    
            pp status_load(run_options)
          end

          sleep BioPieces::Config::STATUS_SAVE_INTERVAL
        end
      end

      block.call

      status_save(input, output, time, run_options)
    end

    def status_load
      status = []

      @commands.each do |command|
        begin
          status << Marshal.load(File.read(command.status_file))
        rescue ArgumentError
          retry
        end
      end

      status
    end

    def status_save(input, output, time, run_options)
      options = {}

      # Remove unmashallable objects
      run_options[:options].each do |key, value|
        unless value.is_a? StringIO or value.is_a? IO
          options[key] = value
        end
      end

      status = {
        command:      run_options[:command],
        options:      options,
        records_in:   input  ? input.size  : 0,
        records_out:  output ? output.size : 0,
        time_elapsed: (Time.now - time).to_s
      }

      File.open(run_options[:status_file], 'w') do |ios|
        ios.write(Marshal.dump(status))
      end

      status
    end
  end
end

