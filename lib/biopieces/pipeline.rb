# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #
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
module BioPieces
  trap('INT') { fail 'Interrupted: ctrl-c pressed' }

  # Error class for Pipeline errors.
  PipelineError = Class.new(StandardError)

  # Pipeline class
  class Pipeline
    require 'biopieces/command'
    require 'biopieces/status'
    require 'biopieces/helpers/options_helper'

    # Constant Hash where the keys are command names [Symbol] and the value
    # is the type [Symbol] of command, which can be :iterate or :inline.
    TYPE = {
      cat:      :iterate,
      wc:       :inline,
      truncate: :inline,
      dump:     :iterate
    }

    attr_accessor :commands, :complete

    # Pipeline class constructor.
    def initialize
      @commands = []     # Array of Commands in the Pipeline.
      @options  = {}     # Options hash.
      @inlines  = [[]]   # Array of Commands to run inline.
      @enums    = [[]]   # Array of Enumerators.
      @complete = false  # Flag denoting if run was completed.
    end

    # @return [Integer] The size or number of commands in a pipeline.
    def size
      @commands.size
    end

    # Method for merging one pipeline onto another.
    #
    # @param other [Pipeline] Pipeline to merge.
    #
    # @return [self].
    def <<(other)
      other.commands.map { |command| commands << command }
      other.status.map   { |status|  self.status << status }

      self
    end

    # Method that adds two Pipelines and return a new Pipeline.
    def +(other)
      unless other.is_a?(BioPieces::Pipeline)
        fail PipelineError, "Not a pipeline: #{other.inspect}"
      end

      p = self.class.new
      p << self
      p << other
    end

    # Removes last command from a Pipeline and returns a new Pipeline with this
    # command.
    def pop
      p = BioPieces::Pipeline.new
      p.commands = [@commands.pop]
      p
    end

    # Run all the commands in the Pipeline.
    #
    # @param options [Hash]
    # @option options [Boolean] :verbose (false) Enable verbose output.
    #
    # @raise [PipelineError] If no commands are added to the pipeline.
    #
    # @return [self]
    def run(options = {})
      @options = options

      if @commands.empty?
        fail BioPieces::PipelineError, 'No commands added to pipeline'
      end

      unless @complete
        Status.track(@commands) { run_commands && @complete = true }
        @complete = true
      end

      self
    end

    # Return a list of all status hashes from the commands.
    # @todo Needs proper formatting of output.
    def status
      @commands.each_with_object([]) { |e, a| a << e.status }
    end

    # format a Pipeline to a pretty string which is returned.
    def to_s
      command_strings = %w(BP new)

      @commands.each { |command| command_strings << command.to_s }

      if @complete
        if @options.empty?
          command_strings << 'run'
        else
          options = []

          @options.each_pair do |key, value|
            options << "#{key}: #{value}"
          end

          command_strings << "run(#{options.join(', ')})"
        end
      end

      command_strings.join('.')
    end

    private

    # Add a command to the pipeline. This is done by first requiring the
    # relevant Class/Module and then calling the relevant command.
    #
    # @param method [Symbol] Method name.
    # @param args   [Array]  Method arguments.
    # @param block  [Proc]   Method block.
    #
    # @example Here we add the command `dump` to the pipeline.
    #     Pipeline.new.dump
    #       # => self
    #
    # @return [self]
    def method_missing(method, *args, &block)
      require_file(method)

      if BioPieces.const_defined? method.to_s.capitalize
        options = args.first || {}

        lmb = BioPieces.const_get(method.to_s.capitalize).send(:lmb, options)

        @commands << Command.new(method, TYPE[method], lmb, options)
      else
        super
      end

      self
    end

    # Require a file form the lib/commands directory given a method name that
    # must match the file name. E.g. `require_file(:dump)` requires the file
    # `lib/commands/dump.rb`.
    #
    # @param method [Symbol]
    #   The name of the method.
    #
    # @raise [Errno::ENOENT] If no such file was found.
    def require_file(method)
      return if BioPieces.const_defined? method.to_s.capitalize

      file = File.join('lib', 'biopieces', 'commands', "#{method}.rb")

      fail Errno::ENOENT, "No such file: #{file}" unless File.exist? file

      require File.join('biopieces', 'commands', method.to_s)
    end

    # Run all commands in the Pipeline.
    def run_commands
      @commands.each do |command|
        command.status[:time_start] = Time.now

        case command.type
        when :inline  then run_inline(command)
        when :iterate then run_iterate(command)
        else
          fail "Unknown type: #{command.type}"
        end
      end

      @enums.last.each {}

      # @commands.each do |command| # TODO: this should be part of a #to_s
      #   command.status.calc_time_elapsed
      #   command.status.calc_delta
      # end
    end

    # Run all inline commands in the Pipeline.
    def run_inline(command)
      @inlines.last << command
    end

    # Run all iterate commands in the Pipeline.
    def run_iterate(command)
      input  = @enums.last
      inline = @inlines.last
      @enums << Enumerator.new { |output| command.call(input, output, inline) }
      inline.map(&:terminate)
      command.terminate
      @inlines << []
    end
  end
end

__END__

module BioPieces
  class Pipeline
    require 'mail'

    include BioPieces::Commands
    include BioPieces::HistoryHelper
    include BioPieces::LogHelper
    include BioPieces::OptionsHelper
    include BioPieces::StatusHelper
    include BioPieces::AuxHelper

    attr_accessor :commands, :status

    def initialize
      @options  = {}
      @commands = []
      @status   = {}
    end

    # Returns the size or number of commands in a pipeline.
    def size
      @commands.size
    end

    # Run a Pipeline.
    def run(options = {})
      raise BioPieces::PipelineError, "No commands added to pipeline" if @commands.empty?

      options_allowed(options, :debug, :verbose, :email, :progress, :subject, :input, :output, :fork, :thread, :output_dir, :report, :force)
      options_allowed_values(options, debug: [true, false, nil])
      options_allowed_values(options, verbose: [true, false, nil])
      options_allowed_values(options, fork: [true, false, nil])
      options_allowed_values(options, thread: [true, false, nil])
      options_conflict(options, fork: :thread)
      options_conflict(options, progress: :verbose)
      options_tie(options, subject: :email)
      options_files_exists_force(options, :report)

      BioPieces::debug   = options[:debug]
      BioPieces::verbose = options[:verbose]
      BioPieces::test    = ENV['BP_TEST']

      if options[:output_dir]
        FileUtils.mkdir_p(options[:output_dir]) unless File.exist?(options[:output_dir])

        @commands.each do |command|
          if value = command.options[:output]
            command.options[:output] = File.join(options[:output_dir], value)
          end
        end
      end

      @options = options

      status_init

      if @options[:fork]
        @options[:progress] ? status_progress { run_fork }      : run_fork
      elsif @options[:thread]
        @options[:progress] ? status_progress { run_thread }    : run_thread
      else
        @options[:progress] ? status_progress { run_enumerate } : run_enumerate
      end

      @status[:status] = status_load

      pp @status  if @options[:verbose]
      email_send  if @options[:email]
      report_save if @options[:report]

      log_ok unless BioPieces::test

     self
    rescue Exception => exception
      unless BioPieces::test
        STDERR.puts "Error in run: #{exception.message}"
        STDERR.puts exception.backtrace if BioPieces::verbose
        log_error(exception)
        exit 2
      else
        raise exception
      end
    ensure
      history_save
    end

    def run_enumerate
      enums = [@options[:input]]

      @commands.each_with_index do |command, i|
        enums << Enumerator.new do |output|
          command.run(enums[i], output)
        end
      end

      if @options[:output]
        enums.last.each { |record| @options[:output].write record }
        @options[:output].close
      else
        enums.last.each {}
      end
    end

    # Send email notification to email address specfied in @options[:email],
    # including a optional subject specified in @options[:subject], that will
    # otherwise default to self.to_s. The body of the email will be the
    # Pipeline status.
    def email_send
      unless @options[:email] == "test@foobar.com"
        Mail.defaults do
          delivery_method :smtp, {
            address: "localhost",
            port: 25,
            enable_starttls_auto: false
          }
        end
      end

      html = BioPieces::Render.html(self)

      html_part = Mail::Part.new do
        content_type 'text/html; charset=UTF-8'
        body html
      end

      mail = Mail.new
      mail[:from]      = "do-not-reply@#{`hostname -f`.strip}"
      mail[:to]        = @options[:email]
      mail[:subject]   = @options[:subject] || self.to_s
      mail.html_part = html_part

      mail.deliver!
    end

    # Save a HTML status report to file.
    def report_save
      if @options[:output_dir]
        file = File.join(@options[:output_dir], @options[:report])
      else
        file = @options[:report]
      end

      File.open(file, 'w') do |ios|
        ios.puts BioPieces::Render.html(self)
      end
    end

    private

    class Command
      attr_accessor :status
      attr_reader :name, :options, :options_orig, :lmb

      include BioPieces::StatusHelper
      include BioPieces::LogHelper
      include BioPieces::OptionsHelper

      def initialize(name, options, options_orig, lmb)
        @name         = name
        @options      = options
        @options_orig = options_orig
        @lmb          = lmb
      end

      def run(input, output)
        self.status[:time_start] = Time.now
        self.status[:status]     = "running"
        self.lmb.call(input, output, self.status)
        self.status[:time_stop]  = Time.now
        self.status[:status]     = "done"

        status_save(self.status)

        self.status
      ensure
        input.close if input.respond_to? :close
        output.close if output.respond_to? :close
      end
    end
  end
end
