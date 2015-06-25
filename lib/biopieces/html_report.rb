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

module BioPieces
  # Class for creating HTML reports from an executed BioPieces pipeline.
  class HtmlReport
    require 'tilt/haml'
    require 'base64'
    require 'biopieces/helpers/options_helper'

    include OptionsHelper

    # Constructor for HtmlReport.
    #
    # @param pipeline [BioPeices::Pipeline] Pipeline object
    def initialize(pipeline)
      @pipeline = pipeline
      @commands = pipeline.commands
    end

    # Render HTML output.
    def to_html
      render('layout.html.haml', self, pipeline: @pipeline.to_s,
                                       commands: @commands)
    end

    private

    # Render HTML templates.
    #
    # @param template [Path]   Path to template file.
    # @param scope    [Object] Scope.
    # @param args     [Hash]   Argument hash.
    def render(template, scope, args = {})
      Tilt.new(File.join(root_dir, template)).render(scope, args)
    end

    # Render HTML CSS section.
    def render_css
      render('css.html.haml', self)
    end

    # Render HTML pipeline section
    #
    # @param pipeline [String] String from BioPieces::Pipeline#to_s
    def render_pipeline(pipeline)
      pipeline = pipeline.scan(/[^.]+\(.*?\)|[^.(]+/).join(".\n").sub(/\n/, '')

      render('pipeline.html.haml', self, pipeline: pipeline)
    end

    # Render HTML overview section.
    #
    # @param commands [Array] List of commands from a pipeline.
    def render_overview(commands)
      render('overview.html.haml', self, commands: commands)
    end

    # Render HTML command section.
    #
    # @param command [BioPieces::Command] Command object.
    def render_command(command, index)
      render('command.html.haml', self, command: command, index: index)
    end

    # Render HTML status section.
    #
    # @param command [BioPieces::Command] Command object.
    def render_status(command)
      stats = command.status.reject { |k, _| k.to_s[0..3] == 'time' }
      render('status.html.haml', self, exit_status: command.run_status, statsus: stats)
    end

    # Render HTML time section.
    #
    # @param status [BioPieces::Status] Status object.
    def render_time(status)
      render('time.html.haml', self, status: status)
    end

    # Render HTML input files section.
    #
    # @param options [Hash] Command options hash.
    def render_input_files(options)
      render('input_files.html.haml', self,
             files: options_glob(options[:input]))
    end

    # Render HTML output file section.
    #
    # @param options [Hash] Command options hash.
    def render_output_files(options)
      render('output_files.html.haml', self, options: options)
    end

    # Render PNG data.
    #
    # @param options [Hash] Command options hash.
    def render_png(options)
      path = options[:output]
      png_data = 'data:image/png;base64,'

      File.open(path, 'r') do |ios|
        png_data << Base64.encode64(ios.read)
      end

      render('png.html.haml', self, path: path, png_data: png_data)
    end

    # Detect if any input options are set.
    #
    # @param options [Hash] Options hash.
    # @option options [String] :input File glob expression.
    #
    # @return [Boolean]
    def input?(options)
      if options[:input]
        true
      else
        false
      end
    end

    # Detect if any output options are set.
    #
    # @param options [Hash] Options hash.
    # @option options [String] :output Path to output file.
    #
    # @return [Boolean]
    def output?(options)
      if options[:output]
        true
      else
        false
      end
    end

    # Detect if any PNG file is available.
    #
    # @param options [Hash] Options hash.
    # @option options [String] :output Path to output file.
    # @option options [Symbol] :terminal Plot type.
    #
    # @return [Boolean]
    def png?(options)
      if options[:output]   &&
         options[:terminal] &&
         options[:terminal] == :png &&
         File.exist?(options[:output])
        true
      else
        false
      end
    end

    # Return the path of the HTML root dir.
    #
    # @return [String] Root dir.
    def root_dir
      File.join(File.dirname(__FILE__), '..', '..', 'www')
    end

    # Return the help URL for a given command.
    #
    # @param command [Symbol] Command name.
    #
    # @return [String] HTML link.
    def help_url(command)
      camel = command.to_s.split('_').map(&:capitalize).join

      'http://www.rubydoc.info/gems/biopieces/' \
      "#{BioPieces::VERSION}/BioPieces/#{camel}"
    end
  end
end
