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

# Test class for PlotHistogram.
# rubocop:disable ClassLength
class TestPlotHistogram < Test::Unit::TestCase
  def setup
    omit('gnuplot not found') unless BioDSL::Filesys.which('gnuplot')

    @tmpdir = Dir.mktmpdir('BioDSL')
    @file   = File.join(@tmpdir, 'test.plot')

    @input, @output   = BioDSL::Stream.pipe
    @input2, @output2 = BioDSL::Stream.pipe

    setup_stream
    setup_expected1
    setup_expected2

    @p = BioDSL::Pipeline.new
  end

  def setup_stream
    @output.write(ID: 'x', LEN: 1)
    @output.write(ID: 'x', LEN: 2)
    @output.write(ID: 'x', LEN: 2)
    @output.write(ID: 'x', LEN: 3)
    @output.write(ID: 'y', LEN: 3)
    @output.write(ID: 'y', LEN: 3)
    @output.close
  end

  # rubocop:disable MethodLength
  def setup_expected1
    @expected1 = <<-EOF.gsub(/^\s+\|/, '')
      |set terminal dumb
      |set title \"Histogram\"
      |set xlabel \"LEN\"
      |set ylabel \"n\"
      |set autoscale xfix
      |set style fill solid 0.5 border
      |set xtics out
      |set ytics out
      |set yrange [0:*]
      |set output \"\"
      |plot \"-\" using 1:2 with boxes notitle
      |0 0
      |1 1
      |2 2
      |3 3
      |e
    EOF
  end

  def setup_expected2
    @expected2 = <<-EOF.gsub(/^\s+\|/, '')
      |set terminal dumb
      |set title \"Histogram\"
      |set xlabel \"ID\"
      |set ylabel \"n\"
      |set autoscale xfix
      |set style fill solid 0.5 border
      |set xtics out
      |set ytics out
      |set yrange [0:*]
      |set output \"\"
      |plot \"-\" using 2:xticlabels(1) with boxes notitle lc rgb \"red\"
      |x 4
      |y 2
      |e
    EOF
  end

  # rubocop:enable MethodLength
  def teardown
    FileUtils.rm_r @tmpdir
  end

  test 'BioDSL::Pipeline::PlotHistogram with invalid options raises' do
    assert_raise(BioDSL::OptionError) do
      @p.plot_histogram(key: :LEN, foo: 'bar')
    end
  end

  test 'BioDSL::Pipeline::PlotHistogram with invalid terminal raises' do
    assert_raise(BioDSL::OptionError) do
      @p.plot_histogram(key: :LEN, terminal: 'foo')
    end
  end

  test 'BioDSL::Pipeline::PlotHistogram with valid terminal don\'t raise' do
    %w(dumb post svg x11 aqua png pdf).each do |terminal|
      assert_nothing_raised do
        @p.plot_histogram(key: :LEN, terminal: terminal.to_sym)
      end
    end
  end

  test 'BioDSL::Pipeline::PlotHistogram to file with numeric outputs OK' do
    result = capture_stderr do
      @p.plot_histogram(key: :LEN, output: @file, test: true).
      run(input: @input, output: @output2)
    end

    result.sub!(/set output "[^"]+"/, 'set output ""')
    assert_equal(@expected1, result)
  end

  test 'BioDSL::Pipeline::PlotHistogram to file with non-numeric outputs ' \
    'correctly' do
    result = capture_stderr do
      @p.plot_histogram(key: :ID, output: @file, test: true).
      run(input: @input, output: @output2)
    end

    result.sub!(/set output "[^"]+"/, 'set output ""')
    assert_equal(@expected2, result)
  end

  test 'BioDSL::Pipeline::PlotHistogram to existing file raises' do
    `touch #{@file}`
    assert_raise(BioDSL::OptionError) { @p.plot_histogram(output: @file) }
  end

  test 'BioDSL::Pipeline::PlotHistogram to existing file with :force ' \
    'outputs correctly' do
    `touch #{@file}`
    result = capture_stderr do
      @p.plot_histogram(key: :LEN, output: @file, force: true, test: true).
      run(input: @input)
    end

    result.sub!(/set output "[^"]+"/, 'set output ""')
    assert_equal(@expected1, result)
  end

  test 'BioDSL::Pipeline::PlotHistogram with flux outputs correctly' do
    result = capture_stderr do
      @p.plot_histogram(key: :LEN, output: @file, force: true, test: true).
      run(input: @input, output: @output2)
    end

    result.sub!(/set output "[^"]+"/, 'set output ""')
    assert_equal(@expected1, result)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:ID=>"x", :LEN=>1}
      |{:ID=>"x", :LEN=>2}
      |{:ID=>"x", :LEN=>2}
      |{:ID=>"x", :LEN=>3}
      |{:ID=>"y", :LEN=>3}
      |{:ID=>"y", :LEN=>3}
    EXP

    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::PlotHistogram status outputs correctly' do
    @p.plot_histogram(key: :LEN, output: @file, force: true).
      run(input: @input, output: @output2)

    assert_equal(6, @p.status.first[:records_in])
    assert_equal(6, @p.status.first[:records_out])
  end
end
