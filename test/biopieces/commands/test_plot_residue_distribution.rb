#!/usr/bin/env ruby
$:.unshift File.join(File.dirname(__FILE__), '..', '..', '..')

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #
#                                                                                #
# Copyright (C) 2007-2015 Martin Asser Hansen (mail@maasha.dk).                  #
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

class TestPlotResidueDistribution < Test::Unit::TestCase 
  def setup
    @tmpdir = Dir.mktmpdir("BioPieces")
    @file   = File.join(@tmpdir, 'test.plot')

    @input, @output   = BioPieces::Stream.pipe
    @input2, @output2 = BioPieces::Stream.pipe

    [{SEQ: "AN"},
     {SEQ: "T"},
     {SEQ: "C"},
     {SEQ: "G"},
     {FOO: "BAR"}].each do |record|
      @output.write(record)
    end

    @output.close

    @expected1 = <<EOF
set terminal dumb
set title "Residue Distribution"
set xlabel "Sequence position"
set ylabel "%"
set output ""
set xtics out
set ytics out
set yrange [0:100]
set xrange [0:2]
set auto fix
set offsets "1"
set key outside right top vertical Left reverse noenhanced autotitles columnhead nobox
set key invert samplen 4 spacing 1 width 0 height 0
set style fill solid 0.5 border
set style histogram rowstacked
set style data histograms
set boxwidth 0.75 absolute
plot "-" using 1 with histogram title "T", "-" using 1 with histogram title "N", "-" using 1 with histogram title "G", "-" using 1 with histogram title "C", "-" using 1 with histogram title "A"
0.0
25.0
0.0
e
0.0
0.0
100.0
e
0.0
25.0
0.0
e
0.0
25.0
0.0
e
0.0
25.0
0.0
e
EOF

    @expected2 = <<EOF
set terminal dumb
set title "Residue Distribution"
set xlabel "Sequence position"
set ylabel "%"
set output ""
set xtics out
set ytics out
set yrange [0:100]
set xrange [0:2]
set auto fix
set offsets "1"
set key outside right top vertical Left reverse noenhanced autotitles columnhead nobox
set key invert samplen 4 spacing 1 width 0 height 0
set style fill solid 0.5 border
set style histogram rowstacked
set style data histograms
set boxwidth 0.75 absolute
plot "-" using 1 with histogram title "T", "-" using 1 with histogram title "N", "-" using 1 with histogram title "G", "-" using 1 with histogram title "C", "-" using 1 with histogram title "A", "-" using 1:2 with lines lw 2 lt rgb "black" title "count"
0.0
25.0
0.0
e
0.0
0.0
100.0
e
0.0
25.0
0.0
e
0.0
25.0
0.0
e
0.0
25.0
0.0
e
0 0.0
0 100.0
1 25.0
e
EOF

    @p = BioPieces::Pipeline.new
  end

  def teardown
    FileUtils.rm_r @tmpdir
  end

  test "BioPieces::Pipeline::PlotResidueDistribution with invalid options raises" do
    assert_raise(BioPieces::OptionError) { @p.plot_residue_distribution(foo: "bar") }
  end

  test "BioPieces::Pipeline::PlotResidueDistribution with invalid terminal raises" do
    assert_raise(BioPieces::OptionError) { @p.plot_residue_distribution(terminal: "foo") }
  end

  test "BioPieces::Pipeline::PlotResidueDistribution with valid terminal don't raise" do
    %w{dumb post svg x11 aqua png pdf}.each do |terminal|
      assert_nothing_raised { @p.plot_residue_distribution(terminal: terminal.to_sym) }
    end
  end

  test "BioPieces::Pipeline::PlotResidueDistribution to file outputs correctly" do
    result = capture_stderr { @p.plot_residue_distribution(output: @file, test: true).run(input: @input, output: @output2) }
    result.sub!(/set output "[^"]+"/, 'set output ""')
    assert_equal(@expected1, result)
  end

  test "BioPieces::Pipeline::PlotResidueDistribution to file with :count outputs correctly" do
    result = capture_stderr { @p.plot_residue_distribution(output: @file, count: true, test: true).run(input: @input, output: @output2) }
    result.sub!(/set output "[^"]+"/, 'set output ""')
    assert_equal(@expected2, result)
  end

  test "BioPieces::Pipeline::PlotResidueDistribution to existing file raises" do
    `touch #{@file}`
    assert_raise(BioPieces::OptionError) { @p.plot_residue_distribution(output: @file) }
  end

  test "BioPieces::Pipeline::PlotResidueDistribution to existing file with options[:force] outputs correctly" do
    `touch #{@file}`
    result = capture_stderr { @p.plot_residue_distribution(output: @file, force: true, test: true).run(input: @input) }
    result.sub!(/set output "[^"]+"/, 'set output ""')
    assert_equal(@expected1, result)
  end

  test "BioPieces::Pipeline::PlotResidueDistribution with flux outputs correctly" do
    result = capture_stderr { @p.plot_residue_distribution(output: @file, force: true, test: true).run(input: @input, output: @output2) }
    result.sub!(/set output "[^"]+"/, 'set output ""')
    assert_equal(@expected1, result)

    stream_result = @input2.map { |h| h.to_s }.reduce(:<<)
    stream_expected = %Q{{:SEQ=>"AN"}{:SEQ=>"T"}{:SEQ=>"C"}{:SEQ=>"G"}{:FOO=>"BAR"}}
    assert_equal(stream_expected, stream_result)
  end
end
