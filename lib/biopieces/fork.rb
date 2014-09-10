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
  class ForkError < StandardError; end

  class Fork
    attr_reader :input, :output

    def self.execute(&block)
      parent = self.new(&block)
      parent.execute
    end

    def initialize(&block)
      raise ArgumentError, "No block given" unless block

      @parent = true
      @alive  = false
      @pid    = nil
      @input  = nil
      @output = nil
      @block  = block
    end

    def execute
      @alive = true

      child_read, parent_write = BioPieces::Stream.pipe
      parent_read, child_write = BioPieces::Stream.pipe

      pid = Process.fork do
        parent_write.close
        parent_read.close

        @parent = false
        @pid    = Process.pid
        @input  = child_read
        @output = child_write

        @block.call(self)
      end

      child_write.close
      child_read.close

      @pid    = pid
      @input  = parent_read
      @output = parent_write

      self
    end

    def running?
      @pid
    end

    def read
      raise BioPieces::ForkError, "Not running" unless running?

      @input.read
    end

    def write(obj)
      raise BioPieces::ForkError, "Not running" unless running?

      @output.write(obj)
    end

    def wait
      raise BioPieces::ForkError, "Not running" unless running?
      @input.close  unless @input.closed?
      @output.close unless @output.closed?

      Process.wait(@pid)
    end
  end
end
