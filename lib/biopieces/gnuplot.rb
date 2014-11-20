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
# This software is part of Biopieces (www.biopieces.org).                        #
#                                                                                #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

module BioPieces
  # Class containing methods wrapping around GNUplot.
  # 
  # Example:
  #   data1 = [
  #     [0,   0,   0.5,  0.5],
  #     [0,   1,   -0.5, 0.5],
  #     [1,   1,   1,    0]
  #   ]
  #   
  #   data2 = [
  #     [10,   10,   1.5,  1.5],
  #     [10,   11,   -1.5, 1.5],
  #     [11,   11,   11,    10]
  #   ]
  #   
  #   gp = GnuPlot.new
  #   gp.set title:    "Foobar"
  #   gp.set terminal: "aqua"
  #   
  #   gp.add_dataset(using: "1:2:3:4", with: "vectors nohead", title: "'foo'") do |plotter|
  #     data1.map { |d| plotter << d }
  #   end
  #   
  #   gp.add_dataset(using: "1:2:3:4", with: "vectors nohead", title: "'bar'") do |plotter|
  #     data2.map { |d| plotter << d }
  #   end
  #   
  #   gp.plot
  class GnuPlot
    require 'open3'
    require 'tempfile'

    NOQUOTE = [
      :autoscale,
      :cbrange,
      :logscale,
      :nocbtics,
      :palette,
      :rtics,
      :tic,
      :style,
      :view,
      :yrange,
      :ytics,
      :xrange,
      :xtics,
      :ztics
    ]

    # Constructor method for a GnuPlot object.
    def initialize
      @options  = Hash.new { |h, k| h[k] = [] }
      @datasets = []
    end

    # Method to set an option in the GnuPlot environment e.g:
    # set(title: "Nobel Prize")
    def set(options)
      raise unless options.is_a? Hash

      options.each do |key, value|
        @options[key.to_sym] << value
      end

      self
    end

    # Method to add a dataset to the current GnuPlot.
    #   add_dataset(using: "1:2:3:4", with: "vectors nohead", title: "'bar'") do |plotter|
    #     data2.map { |d| plotter << d }
    #   end
    def add_dataset(options = {})
      raise unless block_given?

      dataset = DataSet.new(options)
      @datasets << dataset

      yield dataset
    end

    # Command to execute the plotting of added datasets.
    def plot
      raise "no datasets added" if @datasets.empty?

      @datasets.each { |dataset| dataset.close }

      result = nil

      Open3.popen3("gnuplot -persist") do |stdin, stdout, stderr, wait_thr|
        lines = []

        @options.each do |key, list|
          list.each do |value|
            if value == :true
              lines << %Q{set #{key}}
            elsif NOQUOTE.include? key.to_sym
              lines << %Q{set #{key} #{value}}
            else
              lines << %Q{set #{key} "#{value}"}
            end
          end
        end

        lines << "plot " + @datasets.map { |dataset| dataset.to_gp }.join(", ")

        lines.map { |l| $stderr.puts l } if $VERBOSE
        lines.map { |l| stdin.puts l }

        stdin.close
        result = stdout.read
        stdout.close

        exit_status = wait_thr.value

        unless exit_status.success?
          raise RuntimeError, stderr.read
        end
      end

      @datasets.each { |dataset| dataset.unlink }

      result
    end

    # Command to execute the splotting of added datasets.
    def splot
      raise "no datasets added" if @datasets.empty?

      @datasets.each { |dataset| dataset.close }

      result = nil

      Open3.popen3("gnuplot -persist") do |stdin, stdout, stderr, wait_thr|
        lines = []

        @options.each do |key, list|
          list.each do |value|
            if value == :true
              lines << %Q{set #{key}}
            elsif NOQUOTE.include? key.to_sym
              lines << %Q{set #{key} #{value}}
            else
              lines << %Q{set #{key} "#{value}"}
            end
          end
        end

        lines << "splot " + @datasets.map { |dataset| dataset.to_gp }.join(", ")

        lines.map { |l| $stderr.puts l } if $VERBOSE
        lines.map { |l| stdin.puts l }

        stdin.close
        result = stdout.read
        stdout.close

        exit_status = wait_thr.value

        unless exit_status.success?
          raise RuntimeError, stderr.read
        end
      end

      @datasets.each { |dataset| dataset.unlink }

      result
    end

    # Nested class for GnuPlot datasets.
    class DataSet
      def initialize(options = {})
        @options = options
        @file    = Tempfile.new("gp")
        @io      = @file.open
      end

      # Write method.
      def <<(*obj)
        @io.puts obj.join("\t")
      end

      alias :write :<<

      # Method that builds a plot/splot command string from dataset options.
      def to_gp
        options = []
        options << %Q{"#{@file.path}"}
        
        @options.each do |key, value|
          if value == :true
            options << "#{key}"
          else
            options << "#{key} #{value}"
          end
        end

        options.join(" ")
      end

      # Method that closes temporary file.
      def close
        @io.close
      end

      # Method that unlinks temprorary file.
      def unlink
        @file.unlink
      end
    end
  end
end
