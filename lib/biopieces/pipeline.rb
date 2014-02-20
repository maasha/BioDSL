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
    attr_reader :status

    def initialize
      @commands = []
      @options  = {}
      @status   = []
    end

    def add(command, options = {})
      @commands << Command.new(command, options)

      self
    end

    def run(options = {})
      out      = nil
      wait_pid = nil

      Dir.mktmpdir("BioPiecesStatus") do |tmpdir|
        @commands.each_with_index { |command, index| command.tmpfile = File.join(tmpdir, "#{index}.status") }

        @commands.reverse.each_cons(2) do |command2, command1|
          input, output = Stream.pipe

          pid = fork do
            output.close
            command2.run(input, out)
          end

          input.close
          out.close if out
          out = output

          wait_pid ||= pid # only the first created process which is tail of pipeline
        end

        @commands.first.run(nil, out)

        Process.waitpid(wait_pid) if wait_pid

        Dir["#{tmpdir}/*.status"].each do |file|
          @status << Marshal.load(File.read(file))
        end
      end
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

    class Stream
      include Enumerable

      attr_reader :size

      def self.pipe
        input, output = IO.pipe

        minput  = MessagePack::Unpacker.new(input, symbolize_keys: true)
        moutput = MessagePack::Packer.new(output)

        [self.new(input, minput), self.new(output, moutput)]
      end

      def initialize(io, stream)
        @io     = io
        @stream = stream
        @size   = 0
      end

      def close
        @stream.flush if @stream.respond_to? :flush
        @io.close
      end

      def read
        @size += 1
        @stream.read
      end

      def each
        @stream.each do |record|
          @size += 1
          yield record
        end
      end

      def write(arg)
        @size += 1
        @stream.write(arg)
      end
    end

    class Command
      include BioPieces::OptionsHelper
      include BioPieces::StatusHelper

      attr_accessor :tmpfile

      def initialize(command, options = {}, tmpfile = nil)
        @command = command
        @options = options
        @tmpfile = tmpfile
        @input   = nil
        @output  = nil

        include_command_module

        send "#{@command}_check"
      end

      def include_command_module
        command_module = @command.to_s.split("_").map { |c| c.capitalize }.join("")

        self.class.send(:include, BioPieces.const_get(command_module))
      end

      def run(input, output)
        @input  = input
        @output = output

        time_start = Time.now

        send @command

        time_stop = Time.now

        records_in  = @input  ? @input.size  : 0
        records_out = @output ? @output.size : 0

        status = {
          command:      @command,
          records_in:   records_in,
          records_out:  records_out,
          time_start:   time_start.to_s,
          time_stop:    time_stop.to_s,
          time_elapsed: (time_stop - time_start).to_s
        }

        File.open(@tmpfile, 'w') { |ios| ios.write(Marshal.dump(status)) } if @tmpfile
      ensure
        @output.close if @output
        @input.close  if @input
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

