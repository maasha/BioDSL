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
  class PipelineError < StandardError; end

  class Pipeline
    attr_reader :status

    include BioPieces::HistoryHelper
    include BioPieces::OptionsHelper

    def initialize
      @commands = []
      @options  = {}
      @status   = {}
    end

    def add(command, options = {})
      @commands << Command.new(command, options)

      self
    end

    def run(options = {})
      @options = options
      options_allowed :verbose, :email, :subject
      options_tie subject: :email

      raise BioPieces::PipelineError, "No commands added to pipeline" if @commands.empty?

      out        = nil
      wait_pid   = nil
      time_start = Time.now

      @status[:status] = []

      Dir.mktmpdir("BioPiecesStatus") do |tmpdir|
        @commands.each_with_index { |command, index| command.status_file = File.join(tmpdir, "#{index}.status") }

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
          @status[:status] << Marshal.load(File.read(file))
        end
      end

      time_stop = Time.now

      @status[:time_start]   = time_start
      @status[:time_stop]    = time_stop
      @status[:time_elapsed] = time_stop - time_start

      pp @status if @options[:verbose]

      email_send if @options[:email]

      history_save

      self
    end

    def to_s
      raise BioPieces::PipelineError, "No commands added to pipeline" if @commands.empty?

      command_string = "#{self.class}.new"

      @commands.each { |command| command_string << command.to_s }

      unless @status.empty?
        if @options.empty?
          command_string << ".run"
        else
          options = []

          @options.each_pair do |key, value|
            options << "#{key}: #{value}"
          end

          command_string << ".run(#{options.join(", ")})"
        end
      end

      command_string
    end

    def email_send
      mail = Mail.new
      mail[:from]    = "#{ENV['USER']}@#{`hostname`.strip}"
      mail[:to]      = @options[:email]
      mail[:subject] = @options[:subject] || self.to_s
      mail[:body]    = "#{self.to_s}\n\n\n#{PP.pp(@status, '')}"

      mail.deliver!
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

      attr_accessor :status_file

      def initialize(command, options = {}, status_file = nil)
        @command     = command
        @options     = options
        @options_dup = options.dup
        @status_file = status_file
        @time_start  = nil
        @time_stop   = nil
        @input       = nil
        @output      = nil

        include_command_module

        send "#{@command}_check"
      end

      def include_command_module
        command_module = @command.to_s.split("_").map { |c| c.capitalize }.join("")

        begin
          self.class.send(:include, BioPieces.const_get(command_module))
        rescue
          raise BioPieces::PipelineError, "No such command: #{@command}"
        end
      end

      def run(input, output)
        @input      = input
        @output     = output
        @time_start = Time.now

        send @command

        @time_stop = Time.now

        status_save if @status_file
      ensure
        @output.close if @output
        @input.close  if @input
      end

      def to_s
        options_list = []

        @options_dup.each do |key, value|
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

