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
# This software is part of BioDSL (www.github.com/maasha/BioDSL).              #
#                                                                              #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

require 'test/helper'

# Test class for PlotScores.
#
# rubocop: disable ClassLength
class TestPlotScores < Test::Unit::TestCase
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
    @output.write(SCORES: %q(!"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHI))
    @output.write(SCORES: %q("#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHI))
    @output.write(SCORES: %(#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHI))
    @output.write(SCORES: %($%&'()*+,-./0123456789:;<=>?@ABCDEFGHI))
    @output.write(SCORES: %(%&'()*+,-./0123456789:;<=>?@ABCDEFGHI))
    @output.write(SCORES: %(&'()*+,-./0123456789:;<=>?@ABCDEFGHI))
    @output.close
  end

  # rubocop: disable MethodLength
  def setup_expected1
    @expected = <<-EOF.gsub(/^\s+\|/, '')
      |set terminal dumb
      |set title "Mean Quality Scores"
      |set xlabel "Sequence Position"
      |set ylabel "Mean Score"
      |set output ""
      |set xrange [0:42]
      |set yrange [0:40]
      |set style fill solid 0.5 border
      |set xtics out
      |set ytics out
      |plot "-" with boxes lc rgb "red" title "mean score"
      |1 2.5
      |2 3.5
      |3 4.5
      |4 5.5
      |5 6.5
      |6 7.5
      |7 8.5
      |8 9.5
      |9 10.5
      |10 11.5
      |11 12.5
      |12 13.5
      |13 14.5
      |14 15.5
      |15 16.5
      |16 17.5
      |17 18.5
      |18 19.5
      |19 20.5
      |20 21.5
      |21 22.5
      |22 23.5
      |23 24.5
      |24 25.5
      |25 26.5
      |26 27.5
      |27 28.5
      |28 29.5
      |29 30.5
      |30 31.5
      |31 32.5
      |32 33.5
      |33 34.5
      |34 35.5
      |35 36.5
      |36 37.5
      |37 38.0
      |38 38.5
      |39 39.0
      |40 39.5
      |41 40.0
      |e
    EOF
  end

  # rubocop: disable LineLength
  def setup_expected2
    @expected2 = <<-EOF.gsub(/^\s+\|/, '')
      |set terminal dumb
      |set title \"Mean Quality Scores\"
      |set xlabel \"Sequence Position\"
      |set ylabel \"Mean Score\"
      |set output \"\"
      |set xrange [0:42]
      |set yrange [0:40]
      |set style fill solid 0.5 border
      |set xtics out
      |set ytics out
      |plot \"-\" with boxes lc rgb \"red\" title \"mean score\", \"-\" with lines lt rgb \"black\" title \"relative count\"
      |1 2.5
      |2 3.5
      |3 4.5
      |4 5.5
      |5 6.5
      |6 7.5
      |7 8.5
      |8 9.5
      |9 10.5
      |10 11.5
      |11 12.5
      |12 13.5
      |13 14.5
      |14 15.5
      |15 16.5
      |16 17.5
      |17 18.5
      |18 19.5
      |19 20.5
      |20 21.5
      |21 22.5
      |22 23.5
      |23 24.5
      |24 25.5
      |25 26.5
      |26 27.5
      |27 28.5
      |28 29.5
      |29 30.5
      |30 31.5
      |31 32.5
      |32 33.5
      |33 34.5
      |34 35.5
      |35 36.5
      |36 37.5
      |37 38.0
      |38 38.5
      |39 39.0
      |40 39.5
      |41 40.0
      |e
      |1 40.0
      |2 40.0
      |3 40.0
      |4 40.0
      |5 40.0
      |6 40.0
      |7 40.0
      |8 40.0
      |9 40.0
      |10 40.0
      |11 40.0
      |12 40.0
      |13 40.0
      |14 40.0
      |15 40.0
      |16 40.0
      |17 40.0
      |18 40.0
      |19 40.0
      |20 40.0
      |21 40.0
      |22 40.0
      |23 40.0
      |24 40.0
      |25 40.0
      |26 40.0
      |27 40.0
      |28 40.0
      |29 40.0
      |30 40.0
      |31 40.0
      |32 40.0
      |33 40.0
      |34 40.0
      |35 40.0
      |36 40.0
      |37 33.33333206176758
      |38 26.66666603088379
      |39 20.0
      |40 13.333333015441895
      |41 6.666666507720947
      |e
    EOF
  end

  # rubocop: enable MethodLength
  # rubocop: enable LineLength
  def teardown
    FileUtils.rm_r @tmpdir
  end

  test 'BioDSL::Pipeline::PlotScores with invalid options raises' do
    assert_raise(BioDSL::OptionError) { @p.plot_scores(foo: 'bar') }
  end

  test 'BioDSL::Pipeline::PlotScores with invalid terminal raises' do
    assert_raise(BioDSL::OptionError) { @p.plot_scores(terminal: 'foo') }
  end

  test 'BioDSL::Pipeline::PlotScores with valid terminal don\'t raise' do
    %w(dumb post svg x11 aqua png pdf).each do |terminal|
      assert_nothing_raised { @p.plot_scores(terminal: terminal.to_sym) }
    end
  end

  test 'BioDSL::Pipeline::PlotScores to file outputs correctly' do
    result = capture_stderr do
      @p.plot_scores(output: @file, test: true).
      run(input: @input, output: @output2)
    end
    result.sub!(/set output "[^"]+"/, 'set output ""')
    assert_equal(@expected, result)
  end

  test 'BioDSL::Pipeline::PlotScores status outputs correctly' do
    @p.plot_scores(output: @file).
      run(input: @input, output: @output2)

    assert_equal(6, @p.status.first[:records_in])
    assert_equal(6, @p.status.first[:records_out])
    assert_equal(0, @p.status.first[:sequences_in])
    assert_equal(0, @p.status.first[:sequences_out])
    assert_equal(0, @p.status.first[:residues_in])
    assert_equal(0, @p.status.first[:residues_out])
  end

  test 'BioDSL::Pipeline::PlotScores to file with count: true outputs OK' do
    result = capture_stderr do
      @p.plot_scores(count: true, output: @file, test: true).
      run(input: @input, output: @output2)
    end
    result.sub!(/set output "[^"]+"/, 'set output ""')
    assert_equal(@expected2, result)
  end

  test 'BioDSL::Pipeline::PlotScores to existing file raises' do
    `touch #{@file}`
    assert_raise(BioDSL::OptionError) { @p.plot_scores(output: @file) }
  end

  test 'BioDSL::Pipeline::PlotScores to existing file with :force outputs ' \
    'correctly' do
    `touch #{@file}`
    result = capture_stderr do
      @p.plot_scores(output: @file, force: true, test: true).run(input: @input)
    end
    result.sub!(/set output "[^"]+"/, 'set output ""')
    assert_equal(@expected, result)
  end

  test 'BioDSL::Pipeline::PlotScores with flux outputs correctly' do
    result = capture_stderr do
      @p.plot_scores(output: @file, force: true, test: true).
      run(input: @input, output: @output2)
    end

    result.sub!(/set output "[^"]+"/, 'set output ""')
    assert_equal(@expected, result)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:SCORES=>"!\\"\\#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHI"}
      |{:SCORES=>"\\"\\#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHI"}
      |{:SCORES=>"\\#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHI"}
      |{:SCORES=>"$%&'()*+,-./0123456789:;<=>?@ABCDEFGHI"}
      |{:SCORES=>"%&'()*+,-./0123456789:;<=>?@ABCDEFGHI"}
      |{:SCORES=>"&'()*+,-./0123456789:;<=>?@ABCDEFGHI"}
    EXP

    assert_equal(expected, collect_result)
  end
end
