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
  class Pipeline
    def initialize
      @commands = []
      @options = {}
    end

    def add(command, options = {})
      @commands << Command.new(command, options)

      self
    end

    def run(options = {})
      out      = nil
      wait_pid = nil

      @commands.reverse.each_cons(2) do |command2, command1|
        io_in, io_out = IO.pipe

        pid = fork do
          io_out.close
          command2.run(io_in, out)
        end

        io_in.close
        out.close if out
        out = io_out

        wait_pid ||= pid # only the first created process which is tail of pipeline
      end

      @commands.first.run(nil, out)

      Process.waitpid(wait_pid) if wait_pid
    end

    def to_s
      command_string = "#{self.class}.new"

      @commands.each do |command|
        command_string << command.to_s
      end

      if @options.empty?
        command_string << ".run"
      else
        options = []

        @options.each_pair do |key, value|
          if value.is_a? String
            options << %{#{key}: "#{Regexp::quote(value)}"}
          else
            options << "#{key}: #{value}"
          end
        end

        command_string << ".run(#{options.join(", ")})"
      end
    end

    class Command
      def initialize(command, options = {})
        @command = command
        @options = options
        @input   = nil
        @output  = nil

        self.class.send(:include, BioPieces.const_get(@command.to_s.capitalize))
      end

      def run(io_in, io_out)
        @input  = MessagePack::Unpacker.new(io_in, symbolize_keys: true)
        @output = MessagePack::Packer.new(io_out)

        send @command
      ensure
        @output.flush
        io_out.close if io_out
        io_in.close  if io_in
      end

      def to_s
        options_list = []

        @options.each do |key, value|
          if value.is_a? String
            value = Regexp::quote(value) if key == :delimiter
            options_list << %{#{key}: "#{value}"}
          else
            options_list << "#{key}: #{value}"
          end
        end

        if @options.empty?
          ".add(:#{@command})"
        else
          ".add(:#{@command}, #{options_list.join(", ")})"
        end
      end
    end
  end
end

