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
# This software is part of the Biopieces framework (www.biopieces.org).          #
#                                                                                #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

module BioPieces
  # Execute pipelines of commands in threads or processes.
  # Commands are captured in lambdas which receive IO for reading and writing.
  class Pipeline
    # Executor base class
    BaseExecutor = Struct.new :head, :tail, :commands do
      def ignore?(io)
        head.equal? io or tail.equal? io
      end

      def close(io)
        io.close if !ignore?(io) && File.pipe?(io)
      rescue Exception
        # ignore
      end

      private

      def exec_lambda(cmd, read, write)
        cmd[read, write]
      ensure
        close(write)
        close(read)
      end
    end

    # Executes pipeline in processes.
    class ProcessExecutor < BaseExecutor
      def run
        out = tail
        wait_pid = nil

        commands.reverse.each_cons(2) do |cmd2, cmd1|
          io_read, io_write = IO.pipe

          pid = fork do
            close(io_write)
            exec_lambda(cmd2, io_read, out)
          end

          close(io_read)
          close(out)
          out = io_write

          wait_pid ||= pid # only the first created process which is tail of pipeline
        end

        exec_lambda(commands.first, head, out)

        Process.waitpid(wait_pid) if wait_pid
      end
    end

    # Executes pipeline in threads.
    class ThreadExecutor < BaseExecutor
      def run
        out = tail
        to_join = nil

        commands.reverse.each_cons(2) do |cmd2, cmd1|
          io_read, io_write = IO.pipe

          th = Thread.new(cmd2, io_read, out) do |cmd, iin, iout|
            exec_lambda(cmd, iin, iout)
          end

          to_join ||= th

          out = io_write
        end

        exec_lambda(commands.first, head, out)
        to_join.join if to_join
      end
    end

    def initialize
      @cmds = []
    end

    def add(cmd)
      case cmd
      when self.class
        @cmds.concat(cmd.instance_variable_get('@cmds'))
      when Proc
        @cmds << cmd
      else
        raise ArgumentError, "Invalid: #{cmd.inspect}"
      end

      self
    end

    alias << add
    alias | add

    def +(pipe)
      raise ArgumentError, "Not a pipe: #{pipe.inspect}" unless self.class === pipe

      self.class.new.tap do |copy|
        copy.add(self).add(pipe)
      end
    end

    def execute_processes(read = $stdin, write = $stdout)
      exec = ProcessExecutor.new read, write, @cmds.dup
      exec.run
    end

    alias run execute_processes

    def execute_threads(read = $stdin, write = $stdout)
      exec = ThreadExecutor.new read, write, @cmds.dup
      exec.run
    end
  end
end
