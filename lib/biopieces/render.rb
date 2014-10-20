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

    def self.html(template, commands)
      r = self.new(commands: commands)
      r.render(template)
    end

    attr_accessor :object

    def initialize(options)
      @options = options
    end

    def render(template, object = nil)
      @options = object if template =~ /command/

      Tilt.new(File.join(www_dir, template)).render(self, @options) {}
    end

    def has_png?
      if @options[:options][:terminal] == :png
        true
      else
        false
      end
    end

    def insert_png
      path = @options[:options][:output]
      png  = ""

      File.open(path, "r") do |ios|
        png = ios.read
      end

      "data:image/png;base64," + Base64.encode64(png)
    end

    def www_dir
      File.join(File.dirname(__FILE__), '..', '..', 'www')
    end
  end
end
