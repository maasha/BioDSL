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
# This software is part of BioDSL (http://maasha.github.io/BioDSL).            #
#                                                                              #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #
module BioDSL
  trap('INT') { fail 'Interrupted: ctrl-c pressed' }

  # Error class for Pipeline errors.
  PipelineError = Class.new(StandardError)

  # rubocop: disable ClassLength

  # Pipeline class
  class Pipeline
    require 'BioDSL/command'
    require 'BioDSL/helpers/email_helper'
    require 'BioDSL/helpers/history_helper'
    require 'BioDSL/helpers/log_helper'
    require 'BioDSL/helpers/options_helper'
    require 'BioDSL/helpers/status_helper'
    require 'mail'
    require 'yaml'

    include EmailHelper
    include LogHelper
    include HistoryHelper
    include OptionsHelper
    include StatusHelper

    attr_accessor :commands, :complete

    # Pipeline class constructor.
    def initialize
      @commands = []      # Array of Commands in the Pipeline.
      @options  = {}      # Options hash.
      @enums    = [[]]    # Array of Enumerators.
      @complete = false   # Flag denoting if run was completed.
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
      unless other.is_a?(BioDSL::Pipeline)
        fail PipelineError, "Not a pipeline: #{other.inspect}"
      end

      p = self.class.new
      p << self
      p << other
    end

    # Removes last command from a Pipeline and returns a new Pipeline with this
    # command.
    def pop
      p = BioDSL::Pipeline.new
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
      prime_variables(options)

      fail BioDSL::PipelineError, 'Empty pipeline' if @commands.empty?

      @options = options

      check_options
      command_runner
      print_status
      send_email(self)
      save_report
      log_ok

      self
    rescue => exception
      exit_gracefully(exception)
    ensure
      save_history
    end

    # Return a list of all status hashes from the commands.
    #
    # @return [Array] List of status hashes.
    def status
      @commands.each_with_object([]) do |e, a|
        if @complete
          e.calc_time_elapsed
          e.calc_delta
        end

        a << e.status
      end
    end

    # Format a Pipeline to a pretty string which is returned.
    def to_s
      command_strings = %w(BD new)

      @commands.each { |command| command_strings << command.to_s }

      if @complete
        if @options.empty?
          command_strings << 'run'
        else
          command_strings << "run(#{options_string})"
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

      const = method.to_s.split('_').map(&:capitalize).join('')

      if BioDSL.const_defined? const
        options = args.first || {}
        options_load_rc(options, method)

        klass = BioDSL.const_get(const)
        klass.send(:include, OptionsHelper)
        klass.send(:include, StatusHelper)
        lmb = klass.send(:new, options).lmb

        @commands << Command.new(method, lmb, options)
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
      return if BioDSL.const_defined? method.to_s.capitalize

      # FIXME
      # file = File.join('lib', 'BioDSL', 'commands', "#{method}.rb")
      # fail Errno::ENOENT, "No such file: #{file}" unless File.exist? file

      require File.join('BioDSL', 'commands', method.to_s)
    end

    # Print status.
    def print_status
      return unless @options[:verbose]

      @commands.each do |command|
        hash = {}
        hash[:command] = command.name
        hash[:options] = command.options
        hash[:status]  = command.status
        puts hash.to_yaml
      end
    end

    # Check all run options.
    def check_options
      options_allowed(@options, :debug, :verbose, :email, :progress, :subject,
                      :input, :output, :output_dir, :report, :force)
      options_allowed_values(@options, debug: [true, false, nil])
      options_allowed_values(@options, verbose: [true, false, nil])
      options_conflict(@options, progress: :verbose)
      options_tie(@options, subject: :email)
      options_files_exist_force(@options, :report)
    end

    # Run all commands in the Pipeline.
    def run_commands
      prefix_output_dir
      run_time_start
      run_add_enumerators
      run_enumerate
    end

    # Add start time to the status of all commands.
    def run_time_start
      time = Time.now

      @commands.each do |command|
        command.status[:time_start] = time
      end
    end

    # Add enumerators to instance array.
    def run_add_enumerators
      @commands.each do |command|
        input  = @options[:input] || @enums.last
        @enums << Enumerator.new { |output| command.call(input, output) }
      end
    end

    # Iterate through all enumerators.
    def run_enumerate
      if @options[:output]
        @enums.last.each { |record| @options[:output].write record }
        @options[:output].close   # TODO: this close is ugly here
      else
        @enums.last.each {}
      end
    end

    # Create an output directory and prefix all output files in the commands
    # with this directory.
    def prefix_output_dir
      return unless @options[:output_dir]

      unless File.exist?(@options[:output_dir])
        FileUtils.mkdir_p(@options[:output_dir])
      end

      @commands.each do |command|
        if (value = command.options[:output])
          command.options[:output] = File.join(@options[:output_dir], value)
        end
      end
    end

    # Save a HTML status report to file.
    def save_report
      return unless @options[:report]

      file = if @options[:output_dir]
               File.join(@options[:output_dir], @options[:report])
             else
               @options[:report]
             end

      File.open(file, 'w') do |ios|
        ios.puts BioDSL::HtmlReport.new(self).to_html
      end
    end

    # Run all commands.
    def command_runner
      return if @complete

      if @options[:progress]
        status_progress(@commands) { run_commands }
      else
        run_commands
      end

      @complete = true
    end

    # Set some global variables.
    #
    # @param  options [Hash]             Options hash.
    # @option options [Booleon] :debug   Debug flag.
    # @option options [Booleon] :verbose Verbose flag.
    def prime_variables(options)
      BioDSL.test    = ENV['BD_TEST']
      BioDSL.debug   = options[:debug]
      BioDSL.verbose = options[:verbose]
    end

    # Output exception message and possibly stack tracre to STDERR,
    # log error message and exit with non-zero status.
    def exit_gracefully(exception)
      fail exception if BioDSL.test

      STDERR.puts "Error in run: #{exception.message}"
      STDERR.puts exception.backtrace if BioDSL.verbose
      log_error(exception)
      exit 2
    end

    # Generate a comma separated string from the options ensuring that
    # values are in "" if need be.
    #
    # Return [Array] List of options.
    def options_string
      options = []

      @options.each_pair do |key, value|
        if value.is_a? String
          options << %(#{key}: "#{value}")
        else
          options << %(#{key}: #{value})
        end
      end

      options.join(', ')
    end
  end
end
