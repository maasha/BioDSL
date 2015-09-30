#!/usr/bin/env ruby
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', '..', '..')

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
# This software is part of BioDSL (www.BioDSL.org).                      #
#                                                                              #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

require 'test/helper'

# Test class for PlotHeatmap.
# rubocop:disable ClassLength
# rubocop:disable MethodLength
class TestPlotHeatmap < Test::Unit::TestCase
  def setup
    omit('gnuplot not found') unless BioDSL::Filesys.which('gnuplot')

    @tmpdir = Dir.mktmpdir('BioDSL')
    @file   = File.join(@tmpdir, 'test.plot')

    @input, @output   = BioDSL::Stream.pipe
    @input2, @output2 = BioDSL::Stream.pipe

    setup_data
    setup_expected1
    setup_expected2

    @p = BioDSL::Pipeline.new
  end

  def setup_data
    @output.write(V0: 1, V1: 2, V2: 3, V3: 4)
    @output.write(V0: 5, V1: 6, V2: 7, V3: 8)
    @output.write(V0: 9, V1: 10, V2: 11, V3: 12)
    @output.close
  end

  def setup_expected1
    @expected = <<-EOF.gsub(/^\s+\|/, '')
      |set terminal dumb
      |set title \"Heatmap\"
      |set xlabel \"x\"
      |set ylabel \"y\"
      |set output \"\"
      |set view map
      |set autoscale xfix
      |set autoscale yfix
      |set nokey
      |set tic scale 0
      |set palette rgbformulae 22,13,10
      |unset xtics
      |unset ytics
      |plot \"-\" matrix with image
      |1 2 3 4
      |5 6 7 8
      |9 10 11 12
      |e
    EOF
  end

  def setup_expected2
    @expected2 = <<-EOF.gsub(/^\s+\|/, '')
      |set terminal dumb
      |set title \"Heatmap\"
      |set xlabel \"x\"
      |set ylabel \"y\"
      |set output \"\"
      |set view map
      |set autoscale xfix
      |set autoscale yfix
      |set nokey
      |set tic scale 0
      |set palette rgbformulae 22,13,10
      |set logscale cb
      |unset xtics
      |unset ytics
      |plot \"-\" matrix with image
      |1 2 3 4
      |5 6 7 8
      |9 10 11 12
      |e
    EOF
  end

  def teardown
    FileUtils.rm_r @tmpdir
  end

  test 'BioDSL::Pipeline::PlotHeatmap with invalid options raises' do
    assert_raise(BioDSL::OptionError) { @p.plot_heatmap(foo: 'bar') }
  end

  test 'BioDSL::Pipeline::PlotHeatmap with invalid terminal raises' do
    assert_raise(BioDSL::OptionError) { @p.plot_heatmap(terminal: 'foo') }
  end

  test 'BioDSL::Pipeline::PlotHeatmap with valid terminal don\'t raise' do
    %w(dumb post svg x11 aqua png pdf).each do |terminal|
      assert_nothing_raised { @p.plot_heatmap(terminal: terminal.to_sym) }
    end
  end

  test 'BioDSL::Pipeline::PlotHeatmap to file outputs correctly' do
    result = capture_stderr do
      @p.plot_heatmap(output: @file, test: true).
      run(input: @input, output: @output2)
    end

    result.sub!(/set output "[^"]+"/, 'set output ""')
    assert_equal(@expected, result)
  end

  test 'BioDSL::Pipeline::PlotHeatmap to file with logscale outputs OK' do
    result = capture_stderr do
      @p.plot_heatmap(output: @file, logscale: true, test: true).
      run(input: @input, output: @output2)
    end

    result.sub!(/set output "[^"]+"/, 'set output ""')
    assert_equal(@expected2, result)
  end

  test 'BioDSL::Pipeline::PlotHeatmap to existing file raises' do
    `touch #{@file}`
    assert_raise(BioDSL::OptionError) { @p.plot_heatmap(output: @file) }
  end

  test 'BioDSL::Pipeline::PlotHeatmap to existing file with :force' \
    'outputs correctly' do
    `touch #{@file}`
    result = capture_stderr do
      @p.plot_heatmap(output: @file, force: true, test: true).
      run(input: @input)
    end
    result.sub!(/set output "[^"]+"/, 'set output ""')
    assert_equal(@expected, result)
  end

  test 'BioDSL::Pipeline::PlotHeatmap with flux outputs correctly' do
    result = capture_stderr do
      @p.plot_heatmap(output: @file, force: true, test: true).
      run(input: @input, output: @output2)
    end
    result.sub!(/set output "[^"]+"/, 'set output ""')
    assert_equal(@expected, result)

    stream_expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:V0=>1, :V1=>2, :V2=>3, :V3=>4}
      |{:V0=>5, :V1=>6, :V2=>7, :V3=>8}
      |{:V0=>9, :V1=>10, :V2=>11, :V3=>12}
    EXP

    assert_equal(stream_expected, collect_result)
  end

  test 'BioDSL::Pipeline::PlotHeatmap status outputs correctly' do
    @p.plot_heatmap(output: @file, force: true).
      run(input: @input, output: @output2)

    assert_equal(3, @p.status.first[:records_in])
    assert_equal(3, @p.status.first[:records_out])
  end
end
