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

class TestPlotHeatmap < Test::Unit::TestCase 
  def setup
    @tmpdir = Dir.mktmpdir("BioPieces")
    @file   = File.join(@tmpdir, 'test.plot')

    @input, @output   = BioPieces::Stream.pipe
    @input2, @output2 = BioPieces::Stream.pipe

    @output.write({:V0=>1, :V1=>2, :V2=>3, :V3=>4})
    @output.write({:V0=>5, :V1=>6, :V2=>7, :V3=>8})
    @output.write({:V0=>9, :V1=>10, :V2=>11, :V3=>12})
    @output.close

    @expected = <<EOF
\f





                                    Heatmap
             +---------------------------------------------------+
             |                                                   |
             |                                                   |
             |                                                   |
             |                                                   |
            y|                                                   |
             |                                                   |
             |                                                   |
             |                                                   |
             |                                                   |
             +---------------------------------------------------+


                                       x



EOF

    @p = BioPieces::Pipeline.new
  end

  def teardown
    FileUtils.rm_r @tmpdir
  end

  test "BioPieces::Pipeline::PlotHeatmap with invalid options raises" do
    assert_raise(BioPieces::OptionError) { @p.plot_heatmap(foo: "bar") }
  end

  test "BioPieces::Pipeline::PlotHeatmap with invalid terminal raises" do
    assert_raise(BioPieces::OptionError) { @p.plot_heatmap(terminal: "foo") }
  end

  test "BioPieces::Pipeline::PlotHeatmap with valid terminal don't raise" do
    %w{dumb post svg x11 aqua png pdf}.each do |terminal|
      assert_nothing_raised { @p.plot_heatmap(terminal: terminal.to_sym) }
    end
  end

#  test "BioPieces::Pipeline::PlotHeatmap to stdout outputs correctly" do
#    flunk "capture of stdout issue"
#    $VERBOSE = false
#    result = capture_stdout { @p.plot_heatmap.run(input: @input) }
#    assert_equal(@expected, result)
#  end

  test "BioPieces::Pipeline::PlotHeatmap to file outputs correctly" do
    $VERBOSE = false
    @p.plot_heatmap(output: @file).run(input: @input, output: @output2)
    result = File.open(@file).read
    assert_equal(@expected, result)
  end

  test "BioPieces::Pipeline::PlotHeatmap to existing file raises" do
    `touch #{@file}`
    assert_raise(BioPieces::OptionError) { @p.plot_heatmap(output: @file) }
  end

  test "BioPieces::Pipeline::PlotHeatmap to existing file with options[:force] outputs correctly" do
    $VERBOSE = false
    `touch #{@file}`
    @p.plot_heatmap(output: @file, force: true).run(input: @input)
    result = File.open(@file).read
    assert_equal(@expected, result)
  end

  test "BioPieces::Pipeline::PlotHeatmap with flux outputs correctly" do
    @p.plot_heatmap(output: @file, force: true).run(input: @input, output: @output2)
    result = File.open(@file).read
    assert_equal(@expected, result)

    stream_result = @input2.map { |h| h.to_s }.reduce(:<<)
    stream_expected = "{:V0=>1, :V1=>2, :V2=>3, :V3=>4}{:V0=>5, :V1=>6, :V2=>7, :V3=>8}{:V0=>9, :V1=>10, :V2=>11, :V3=>12}"
    assert_equal(stream_expected, stream_result)
  end
end
