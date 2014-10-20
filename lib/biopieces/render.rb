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
  class Render
    require 'tilt/haml'
    require 'base64'

    def self.html(commands)
      renderer = self.new
      
      commands.map { |c| c[:time_elapsed] = (Time.mktime(0) + (c[:time_stop] - c[:time_start])).strftime("%H:%M:%S") }

      renderer.render("layout.html.haml", renderer, commands: commands)
    end

    def render(template, scope, args = {})
      Tilt.new(File.join(root_dir, template)).render(scope, args)
    end

    def render_overview(commands)
      render("overview.html.haml", self, commands: commands)
    end

    def render_command(command)
      render("command.html.haml", self, command)
    end

    def render_time(time_start, time_stop, time_elapsed)
      render("time.html.haml", self, time_start: time_start, time_stop: time_stop, time_elapsed: time_elapsed)
    end

    def render_png(options)
      path = options[:output]
      png_data = "data:image/png;base64,"

      File.open(path, "r") do |ios|
        png_data << Base64.encode64(ios.read)
      end

      render("png.html.haml", self, path: path, png_data: png_data)
    end

    def has_png?(options)
      if options[:output]   and
         options[:terminal] and
         options[:terminal] == :png
        true
      else
        false
      end
    end

    def root_dir
      File.join(File.dirname(__FILE__), '..', '..', 'www')
    end
  end
end
