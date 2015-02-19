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
  class Render
    require 'tilt/haml'
    require 'base64'

    def self.html(pipeline)
      renderer = self.new

      commands = Marshal.load(Marshal.dump(pipeline.status[:status]))
      
      commands.each_with_index do |command, i|
        command[:time_elapsed] = (Time.mktime(0) + (command[:time_stop] - command[:time_start])).strftime("%H:%M:%S")
        command[:command] = pipeline.commands[i].to_s
      end

      renderer.render("layout.html.haml", renderer, pipeline: pipeline.to_s, commands: commands)
    end

    def render(template, scope, args = {})
      Tilt.new(File.join(root_dir, template)).render(scope, args)
    end

    def render_css
      render("css.html.haml", self)
    end

    def render_pipeline(pipeline)
      pipeline = pipeline.scan(/[^.]+\(.*?\)|[^.(]+/).join(".\n").sub(/\n/, '')

      render("pipeline.html.haml", self, pipeline: pipeline)
    end

    def render_overview(commands)
      render("overview.html.haml", self, commands: commands)
    end

    def render_command(command, index)
      stats = {}

      command.each do |key, val|
        next if key == :name
        next if key == :options
        next if key == :time_start
        next if key == :time_stop
        next if key == :time_elapsed
        next if key == :command
        stats[key] = val
      end

      command[:stats]  = stats
      command[:anchor] = "#{command[:name]}#{index}"

      render("command.html.haml", self, command)
    end

    def render_status(status)
      s = status[:status]
      status.delete :status
      render("status.html.haml", self, status: s, stats: status)
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

    def has_input?(options)
      if options[:input]
        true
      else
        false
      end
    end

    def has_output?(options)
      if options[:output]
        true
      else
        false
      end
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

    def help_url(command)
      "http://www.rubydoc.info/gems/biopieces/#{BioPieces::VERSION}/BioPieces/Commands:#{command}"
    end
  end
end
