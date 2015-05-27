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
    require 'biopieces/helpers/email_helper'
    require 'biopieces/helpers/history_helper'
    require 'biopieces/helpers/log_helper'
    require 'biopieces/helpers/options_helper'
    require 'mail'

    include EmailHelper
    include LogHelper
    include HistoryHelper
    include OptionsHelper

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
      if @commands.empty?
        fail BioPieces::PipelineError, 'No commands added to pipeline'
      end

      options_allowed(options, :debug, :verbose, :email, :progress, :subject, :input, :output, :output_dir, :report, :force)
      options_allowed_values(options, debug: [true, false, nil])
      options_allowed_values(options, verbose: [true, false, nil])
      options_conflict(options, progress: :verbose)
      options_tie(options, subject: :email)
      options_files_exist_force(options, :report)

      prefix_output_dir if options[:output_dir]

      @options = options

      BioPieces.debug   = options[:debug]
      BioPieces.verbose = options[:verbose]
      BioPieces.test    = ENV['BP_TEST']

      unless @complete
        Status.track(@commands) { run_commands }
        @complete = true
      end

      status.map { |s| puts s } if @options[:verbose]
      # send_email                if @options[:email]
      # report_save               if @options[:report]
      log_ok unless BioPieces.test

      self
    rescue Exception => exception
      unless BioPieces.test
        STDERR.puts "Error in run: #{exception.message}"
        STDERR.puts exception.backtrace if BioPieces.verbose
        log_error(exception)
        exit 2
      else
        raise exception
      end
    ensure
      history_save
    end

    # Return a list of all status Objects from the commands.
    #
    # @return [Array] List of status objects.
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

          @options.each_pair { |key, value| options << "#{key}: #{value}" }

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

      const = method.to_s.split('_').map(&:capitalize).join('')

      if BioPieces.const_defined? const
        options = args.first || {}

        lmb = BioPieces.const_get(const).send(:lmb, options)

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
      return if BioPieces.const_defined? method.to_s.capitalize

      # FIXME
      # file = File.join('lib', 'biopieces', 'commands', "#{method}.rb")
      # fail Errno::ENOENT, "No such file: #{file}" unless File.exist? file

      require File.join('biopieces', 'commands', method.to_s)
    end

    # Run all commands in the Pipeline.
    def run_commands
      @commands.each do |command|
        command.status[:time_start] = Time.now
        input  = @options[:input] || @enums.last
        @enums << Enumerator.new { |output| command.call(input, output) }
        command.terminate
      end

      if @options[:output]
        @enums.last.each { |record| @options[:output].write record }
        @options[:output].close   # TODO this close is ugly here
      else
        @enums.last.each {}
      end

      @commands.each do |command| # TODO: this should be part of a #to_s
        command.status.calc_time_elapsed
        command.status.calc_delta
      end
    end

    # Create an output directory and prefix all output files in the commands
    # with this directory.
    def prefix_output_dir
      FileUtils.mkdir_p(@options[:output_dir]) unless File.exist?(@options[:output_dir])

      @commands.each do |command|
        if value = command.options[:output]
          command.options[:output] = File.join(@options[:output_dir], value)
        end
      end
    end

    # Save a HTML status report to file.
    def report_save
      file = if @options[:output_dir]
               File.join(@options[:output_dir], @options[:report])
             else
               @options[:report]
             end

      File.open(file, 'w') do |ios|
        ios.puts BioPieces::Render.html(self)
      end
    end
  end
end
