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
    def status_update
      if (Time.now - @time_stop) > BioPieces::Config::STATUS_SAVE_INTERVAL
        status_save

        if self.progress
          system("clear")
          pp status_load
        end

        @time_stop = Time.now
      end
    end

    def status_load
      status = []

      Dir["#{@tmp_dir}/*.status"].each do |file|
        status << Marshal.load(File.read(file))
      end

      status
    end

    def status_save
      return unless @tmp_dir

      records_in  = @input  ? @input.size  : 0
      records_out = @output ? @output.size : 0

      options = {}

      # Remove unmashallable objects
      @options.each do |key, value|
        options[key] = value
      end

      status = {
        command:      @command,
        options:      options,
        records_in:   records_in,
        records_out:  records_out,
        time_elapsed: (@time_stop - @time_start).to_s
      }

      status_file = File.join(@tmp_dir, "%05d" % @index + ".status")

      File.open(status_file, 'w') do |ios|
        ios.write(Marshal.dump(status))
      end

      status
    end

    def status_display
      pp @status
    end

  end
end

