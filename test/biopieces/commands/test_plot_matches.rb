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

class TestPlotMatches < Test::Unit::TestCase 
  def setup
    @tmpdir = Dir.mktmpdir("BioPieces")
    @file   = File.join(@tmpdir, 'test.plot')

    @input, @output   = BioPieces::Stream.pipe
    @input2, @output2 = BioPieces::Stream.pipe

    @output.write({Q_BEG: 0, S_BEG: 0, Q_END: 10, S_END: 10, STRAND: '+'})
    @output.write({Q_BEG: 0, S_BEG: 0, Q_END: 10, S_END: 10, STRAND: '-'})
    @output.write({Q_BEG: 3, S_BEG: 3, Q_END: 6, S_END: 6, DIRECTION: 'forward'})
    @output.write({Q_BEG: 3, S_BEG: 3, Q_END: 6, S_END: 6, DIRECTION: 'reverse'})
    @output.close

    @expected = <<EOF
set terminal dumb
set title "Matches"
set xlabel "x"
set ylabel "y"
set output ""
set autoscale xfix
set autoscale yfix
set style fill solid 0.5 border
set style line 1 linetype 1 linecolor rgb 'green' linewidth 2 pointtype 6 pointsize default
set style line 2 linetype 1 linecolor rgb 'red'   linewidth 2 pointtype 6 pointsize default
set xtics border out
set ytics border out
set grid
set nokey
plot "-" using 1:2:3:4 with vectors nohead ls 1, "-" using 1:2:3:4 with vectors nohead ls 2
0 0 10 10
3 3 3 3
e
10 0 -10 10
6 3 -3 3
e
EOF

    @p = BioPieces::Pipeline.new
  end

  def teardown
    FileUtils.rm_r @tmpdir
  end

  test "BioPieces::Pipeline::PlotMatches with invalid options raises" do
    assert_raise(BioPieces::OptionError) { @p.plot_matches(foo: "bar") }
  end

  test "BioPieces::Pipeline::PlotMatches with invalid terminal raises" do
    assert_raise(BioPieces::OptionError) { @p.plot_matches(terminal: "foo") }
  end

  test "BioPieces::Pipeline::PlotMatches with valid terminal don't raise" do
    %w{dumb post svg x11 aqua png pdf}.each do |terminal|
      assert_nothing_raised { @p.plot_matches(terminal: terminal.to_sym) }
    end
  end

  test "BioPieces::Pipeline::PlotMatches to file outputs correctly" do
    result = capture_stderr { @p.plot_matches(output: @file, test: true).run(input: @input, output: @output2) }
    result.sub!(/set output "[^"]+"/, 'set output ""')
    assert_equal(@expected, result)
  end

  test "BioPieces::Pipeline::PlotMatches to existing file raises" do
    `touch #{@file}`
    assert_raise(BioPieces::OptionError) { @p.plot_matches(output: @file) }
  end

  test "BioPieces::Pipeline::PlotMatches to existing file with options[:force] outputs correctly" do
    `touch #{@file}`
    result = capture_stderr { @p.plot_matches(output: @file, force: true, test: true).run(input: @input) }
    result.sub!(/set output "[^"]+"/, 'set output ""')
    assert_equal(@expected, result)
  end

  test "BioPieces::Pipeline::PlotMatches with flux outputs correctly" do
    result = capture_stderr { @p.plot_matches(output: @file, force: true, test: true).run(input: @input, output: @output2) }
    result.sub!(/set output "[^"]+"/, 'set output ""')

    assert_equal(@expected, result)

    stream_result = @input2.map { |h| h.to_s }.reduce(:<<)
    stream_expected = ""
    stream_expected << '{:Q_BEG=>0, :S_BEG=>0, :Q_END=>10, :S_END=>10, :STRAND=>"+"}'
    stream_expected << '{:Q_BEG=>0, :S_BEG=>0, :Q_END=>10, :S_END=>10, :STRAND=>"-"}'
    stream_expected << '{:Q_BEG=>3, :S_BEG=>3, :Q_END=>6, :S_END=>6, :DIRECTION=>"forward"}'
    stream_expected << '{:Q_BEG=>3, :S_BEG=>3, :Q_END=>6, :S_END=>6, :DIRECTION=>"reverse"}'
    assert_equal(stream_expected, stream_result)
  end
end
