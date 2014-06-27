# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

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
  trap("INT") { exit! } unless BioPieces::Config::DEBUG

  class PipelineError < StandardError; end

  class Pipeline
    attr_reader :status
    attr_accessor :commands

    include BioPieces::Commands
    include BioPieces::HistoryHelper
    include BioPieces::LogHelper
    include BioPieces::OptionsHelper
    include BioPieces::StatusHelper

    def initialize
      @commands = []
      @options  = {}
      @status   = {}
    end

    # Returns the size or number of commands in a pipeline.
    def size
      @commands.size
    end

    # Method that adds two Pipelines and return a new Pipeline.
    def +(pipeline)
      raise ArgumentError, "Not a pipeline: #{pipeline.inspect}" unless self.class === pipeline

      p = self.class.new
      p.commands = @commands + pipeline.commands
      p.commands.map { |c| c.status_file = Tempfile.new(c.command.to_s) }
      p
    end

    # Removes last command from a Pipeline and returns a new Pipeline with this command.
    def pop
      p = BioPieces::Pipeline.new
      p.commands = [@commands.pop]
      p
    end

    # Run a Pipeline.
    def run(options = {})
      @options = options
      options_allowed :verbose, :email, :progress, :subject, :input, :output
      options_tie subject: :email

      raise BioPieces::PipelineError, "No commands added to pipeline" if @commands.empty?

      out        = @options[:output]
      wait_pid   = nil
      time_start = Time.now

      @status[:status] = []
      @commands.last.progress = :true if @options[:progress]

      @commands.reverse.each_cons(2) do |command2, command1|
        input, output = Stream.pipe

        pid = fork do
          output.close
          command2.run(input, out, @commands)
        end

        input.close
        out.close if out
        out = output

        wait_pid ||= pid # only the first created process which is tail of pipeline
      end

      @commands.first.run(@options[:input], out, @commands)

      Process.waitpid(wait_pid) if wait_pid

      @status[:status] = status_load(@commands)

      time_stop = Time.now

      @status[:time_start]   = time_start
      @status[:time_stop]    = time_stop
      @status[:time_elapsed] = time_stop - time_start

      pp @status if @options[:verbose]
      email_send if @options[:email]

      log_ok

      self
    rescue Exception => exception
      unless ENV['BIOPIECES_ENV'] and ENV['BIOPIECES_ENV'] == 'test'
        STDERR.puts "Error in run: " + exception.to_s
        STDERR.puts exception.backtrace if @options[:verbose]
        log_error(exception)
        exit 2
      else
        raise exception
      end
    ensure
      history_save
    end

    # format a Pipeline to a pretty string which is returned.
    def to_s
      command_string = "BP.new"

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

    # Send email notification to email address specfied in @options[:email],
    # including a optional subject specified in @options[:subject], that will
    # otherwise default to self.to_s. The body of the email will be the
    # Pipeline status.
    def email_send
      mail = Mail.new
      mail[:from]    = "#{ENV['USER']}@#{`hostname`.strip}"
      mail[:to]      = @options[:email]
      mail[:subject] = @options[:subject] || self.to_s
      mail[:body]    = "#{self.to_s}\n\n\n#{PP.pp(@status, '')}"

      mail.deliver!
    end

    private

    # Add a command to the pipeline.
    def add(command, options, options_orig, lmb)
      @commands << Command.new(command, options, options_orig, lmb)

      self
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
      attr_reader :command
      attr_accessor :progress, :status_file

      include BioPieces::LogHelper
      include BioPieces::OptionsHelper

      def initialize(command, options = {}, options_orig = {}, lmb)
        @command     = command
        @options     = options
        @options_dup = options_orig
        @lmb         = lmb
        @status_file = Tempfile.new(command.to_s)
        @progress    = nil
        @time_start  = nil
        @time_stop   = nil
        @input       = nil
        @output      = nil
      rescue Exception => exception
        unless ENV['BIOPIECES_ENV'] and ENV['BIOPIECES_ENV'] == 'test'
          STDERR.puts "Error in #{@command}: " + exception.to_s
          STDERR.puts exception.backtrace if @options[:verbose]
          log_error(exception)
          exit 2
        else
          raise exception
        end
      end

      def run(input, output, commands)
        @input      = input
        @output     = output
        @time_start = Time.now
        @time_stop  = Time.now

        run_options = {}
        run_options[:command]     = @command
        run_options[:options]     = @options
        run_options[:status_file] = @status_file
        run_options[:time_start]  = @time_start
        run_options[:progress]    = true if self.progress
        run_options[:commands]    = commands

        @lmb.call(input, output, run_options)

        @time_stop  = Time.now
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
          elsif value.is_a? Symbol
            options_list << "#{key}: :#{value}"
          else
            options_list << "#{key}: #{value}"
          end
        end

        if @options.empty?
          ".#{@command}"
        else
          ".#{@command}(#{options_list.join(", ")})"
        end
      end
    end
  end
end
