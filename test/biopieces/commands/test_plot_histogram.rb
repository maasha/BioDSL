#!/usr/bin/env ruby
$:.unshift File.join(File.dirname(__FILE__), '..', '..', '..')

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

require 'test/helper'

class TestPlotHistogram < Test::Unit::TestCase 
  def setup
    @tmpdir = Dir.mktmpdir("BioPieces")
    @file   = File.join(@tmpdir, 'test.plot')

    @input, @output   = BioPieces::Stream.pipe
    @input2, @output2 = BioPieces::Stream.pipe

    @output.write({ID: "x", LEN: 1})
    @output.write({ID: "x", LEN: 2})
    @output.write({ID: "x", LEN: 2})
    @output.write({ID: "x", LEN: 3})
    @output.write({ID: "y", LEN: 3})
    @output.write({ID: "y", LEN: 3})
    @output.close

    @expected1 = <<EOF
set terminal dumb
set title \"Histogram\"
set xlabel \"LEN\"
set ylabel \"n\"
set output \"\"
set yrange [0:*]
set autoscale xfix
set style fill solid 0.5 border
set xtics out
set ytics out
plot \"-\" using 1:2 with boxes notitle
0 0
1 1
2 2
3 3
e
EOF

    @expected2 = <<EOF
set terminal dumb
set title \"Histogram\"
set xlabel \"ID\"
set ylabel \"n\"
set output \"\"
set yrange [0:*]
set autoscale xfix
set style fill solid 0.5 border
set xtics out
set ytics out
plot \"-\" using 2:xticlabels(1) with boxes notitle lc rgb \"red\"
x 4
y 2
e
EOF

    @p = BioPieces::Pipeline.new
  end

  def teardown
    FileUtils.rm_r @tmpdir
  end

  test "BioPieces::Pipeline::PlotHistogram with invalid options raises" do
    assert_raise(BioPieces::OptionError) { @p.plot_histogram(key: :LEN, foo: "bar") }
  end

  test "BioPieces::Pipeline::PlotHistogram with invalid terminal raises" do
    assert_raise(BioPieces::OptionError) { @p.plot_histogram(key: :LEN, terminal: "foo") }
  end

  test "BioPieces::Pipeline::PlotHistogram with valid terminal don't raise" do
    %w{dumb post svg x11 aqua png pdf}.each do |terminal|
      assert_nothing_raised { @p.plot_histogram(key: :LEN, terminal: terminal.to_sym) }
    end
  end

  test "BioPieces::Pipeline::PlotHistogram to file with numeric outputs correctly" do
    result = capture_stderr { @p.plot_histogram(key: :LEN, output: @file, test: true).run(input: @input, output: @output2) }
    result.sub!(/set output "[^"]+"/, 'set output ""')
    assert_equal(@expected1, result)
  end

  test "BioPieces::Pipeline::PlotHistogram to file with non-numeric outputs correctly" do
    result = capture_stderr { @p.plot_histogram(key: :ID, output: @file, test: true).run(input: @input, output: @output2) }
    result.sub!(/set output "[^"]+"/, 'set output ""')
    assert_equal(@expected2, result)
  end

  test "BioPieces::Pipeline::PlotHistogram to existing file raises" do
    `touch #{@file}`
    assert_raise(BioPieces::OptionError) { @p.plot_histogram(output: @file) }
  end

  test "BioPieces::Pipeline::PlotHistogram to existing file with options[:force] outputs correctly" do
    `touch #{@file}`
    result = capture_stderr { @p.plot_histogram(key: :LEN, output: @file, force: true, test: true).run(input: @input) }
    result.sub!(/set output "[^"]+"/, 'set output ""')
    assert_equal(@expected1, result)
  end

  test "BioPieces::Pipeline::PlotHistogram with flux outputs correctly" do
    result = capture_stderr { @p.plot_histogram(key: :LEN, output: @file, force: true, test: true).run(input: @input, output: @output2) }
    result.sub!(/set output "[^"]+"/, 'set output ""')
    assert_equal(@expected1, result)

    stream_result = @input2.map { |h| h.to_s }.reduce(:<<)
    stream_expected = ""
    stream_expected << '{:ID=>"x", :LEN=>1}'
    stream_expected << '{:ID=>"x", :LEN=>2}'
    stream_expected << '{:ID=>"x", :LEN=>2}'
    stream_expected << '{:ID=>"x", :LEN=>3}'
    stream_expected << '{:ID=>"y", :LEN=>3}'
    stream_expected << '{:ID=>"y", :LEN=>3}'
    assert_equal(stream_expected, stream_result)
  end
end
