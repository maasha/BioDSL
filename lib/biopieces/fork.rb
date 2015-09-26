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

# BioPieces namespace.
module BioPieces
  # Error class for all Fork errors.
  ForkError = Class.new(StandardError)

  # Class containing methods to fork in an objective oriented manner.
  class Fork
    attr_reader :input, :output

    # Class method to execute a block in a seperate process.
    #
    # @param block [Proc] Block to execute.
    #
    # @return [Fork] Instance of Fork.
    def self.execute(&block)
      parent = new(&block)
      parent.execute
    end

    # Constructor for Fork.
    #
    # @param block [Proc] Block to execute.
    #
    # @raise [ArgumentError] If no block given.
    #
    # @return [Fork] Instance of Fork.
    def initialize(&block)
      fail ArgumentError, 'No block given' unless block

      @parent = true
      @alive  = false
      @pid    = nil
      @input  = nil
      @output = nil
      @block  = block
    end

    # Execute the block in a separate process.
    def execute
      @alive = true

      child_read, parent_write = BioPieces::Stream.pipe
      parent_read, child_write = BioPieces::Stream.pipe

      pid = fork_process(child_read, child_write, parent_read, parent_write)

      child_write.close
      child_read.close

      @pid    = pid
      @input  = parent_read
      @output = parent_write

      self
    end

    # Determines if process is running.
    #
    # @return [Bool] True if running else nil.
    def running?
      @pid
    end

    # Read object from forked process.
    #
    # @raise [ForkError] unless process is running.
    def read
      fail BioPieces::ForkError, 'Not running' unless running?

      @input.read
    end

    # Write object to forked process.
    #
    # @raise [ForkError] unless process is running.
    def write(obj)
      fail BioPieces::ForkError, 'Not running' unless running?

      @output.write(obj)
    end

    # Wait for forked process.
    #
    # @raise [ForkError] unless process is running.
    def wait
      fail BioPieces::ForkError, 'Not running' unless running?

      @input.close  unless @input.closed?
      @output.close unless @output.closed?

      Process.wait(@pid)
    end

    private

    # Fork process with IPC.
    #
    # @param child_read   [BioPieces::Stream] Child read IO.
    # @param child_write  [BioPieces::Stream] Child write IO.
    # @param parent_read  [BioPieces::Stream] Parent read IO.
    # @param parent_write [BioPieces::Stream] Parent write IO.
    #
    # @return [FixNum] Process ID.
    def fork_process(child_read, child_write, parent_read, parent_write)
      Process.fork do
        parent_write.close
        parent_read.close

        @parent = false
        @pid    = Process.pid
        @input  = child_read
        @output = child_write

        @block.call(self)
      end
    end
  end
end
