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
    omit("gnuplot not found") unless BioPieces::Filesys.which("gnuplot")

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
set title \"Residue Distribution\"
set xlabel \"Sequence position\"
set ylabel \"%\"
set output \"\"
set xtics out
set ytics out
set yrange [0:100]
set xrange [0:2]
set auto fix
set offsets \"1\"
set key outside right top vertical Left reverse noenhanced autotitles columnhead nobox
set key invert samplen 4 spacing 1 width 0 height 0
set style fill solid 0.5 border
set style histogram rowstacked
set style data histograms
set linetype 1 lc rgb '#F0A3FF'
set linetype 2 lc rgb '#0075DC'
set linetype 3 lc rgb '#993F00'
set linetype 4 lc rgb '#4C005C'
set linetype 5 lc rgb '#191919'
set linetype 6 lc rgb '#005C31'
set linetype 7 lc rgb '#2BCE48'
set linetype 8 lc rgb '#FFCC99'
set linetype 9 lc rgb '#808080'
set linetype 10 lc rgb '#94FFB5'
set linetype 11 lc rgb '#8F7C00'
set linetype 12 lc rgb '#9DCC00'
set linetype 13 lc rgb '#C20088'
set linetype 14 lc rgb '#003380'
set linetype 15 lc rgb '#FFA405'
set linetype 16 lc rgb '#FFA8BB'
set linetype 17 lc rgb '#426600'
set linetype 18 lc rgb '#FF0010'
set linetype 19 lc rgb '#5EF1F2'
set linetype 20 lc rgb '#00998F'
set linetype 21 lc rgb '#E0FF66'
set linetype 22 lc rgb '#740AFF'
set linetype 23 lc rgb '#990000'
set linetype 24 lc rgb '#FFFF80'
set linetype 25 lc rgb '#FFFF00'
set linetype 26 lc rgb '#FF5005'
set linetype cycle 26
set boxwidth 0.75 absolute
plot \"-\" using 1 with histogram lt 1 title \"T\", \"-\" using 1 with histogram lt 2 title \"N\", \"-\" using 1 with histogram lt 3 title \"G\", \"-\" using 1 with histogram lt 4 title \"C\", \"-\" using 1 with histogram lt 5 title \"A\"
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
set title \"Residue Distribution\"
set xlabel \"Sequence position\"
set ylabel \"%\"
set output \"\"
set xtics out
set ytics out
set yrange [0:100]
set xrange [0:2]
set auto fix
set offsets \"1\"
set key outside right top vertical Left reverse noenhanced autotitles columnhead nobox
set key invert samplen 4 spacing 1 width 0 height 0
set style fill solid 0.5 border
set style histogram rowstacked
set style data histograms
set linetype 1 lc rgb '#F0A3FF'
set linetype 2 lc rgb '#0075DC'
set linetype 3 lc rgb '#993F00'
set linetype 4 lc rgb '#4C005C'
set linetype 5 lc rgb '#191919'
set linetype 6 lc rgb '#005C31'
set linetype 7 lc rgb '#2BCE48'
set linetype 8 lc rgb '#FFCC99'
set linetype 9 lc rgb '#808080'
set linetype 10 lc rgb '#94FFB5'
set linetype 11 lc rgb '#8F7C00'
set linetype 12 lc rgb '#9DCC00'
set linetype 13 lc rgb '#C20088'
set linetype 14 lc rgb '#003380'
set linetype 15 lc rgb '#FFA405'
set linetype 16 lc rgb '#FFA8BB'
set linetype 17 lc rgb '#426600'
set linetype 18 lc rgb '#FF0010'
set linetype 19 lc rgb '#5EF1F2'
set linetype 20 lc rgb '#00998F'
set linetype 21 lc rgb '#E0FF66'
set linetype 22 lc rgb '#740AFF'
set linetype 23 lc rgb '#990000'
set linetype 24 lc rgb '#FFFF80'
set linetype 25 lc rgb '#FFFF00'
set linetype 26 lc rgb '#FF5005'
set linetype cycle 26
set boxwidth 0.75 absolute
plot \"-\" using 1 with histogram lt 1 title \"T\", \"-\" using 1 with histogram lt 2 title \"N\", \"-\" using 1 with histogram lt 3 title \"G\", \"-\" using 1 with histogram lt 4 title \"C\", \"-\" using 1 with histogram lt 5 title \"A\", \"-\" using 1:2 with lines lw 2 lt rgb \"black\" title \"count\"
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
