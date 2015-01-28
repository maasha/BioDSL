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

class TestMeanScores < Test::Unit::TestCase 
  def setup
    @input, @output   = BioPieces::Stream.pipe
    @input2, @output2 = BioPieces::Stream.pipe

    @output.write({SCORES: %q{IIIIIIIIIIIIIIIIIIII}})
    @output.write({SCORES: %q{!!!!!IIIIIIIIIIIIIII}})
    @output.write({SCORES: %q{IIIIIIIIIIIIIII!!!!!}})
    @output.close

    @p = BioPieces::Pipeline.new
  end

  test "BioPieces::Pipeline::MeanScores with invalid options raises" do
    assert_raise(BioPieces::OptionError) { @p.mean_scores(foo: "bar") }
  end

  test "BioPieces::Pipeline::MeanScores with valid options don't raise" do
    assert_nothing_raised { @p.mean_scores(local: true) }
  end

  test "BioPieces::Pipeline::MeanScores with window_size and local: false raises" do
    assert_raise(BioPieces::OptionError) { @p.mean_scores(window_size: 10) }
  end

  test "BioPieces::Pipeline::MeanScores returns correctly" do
    @p.mean_scores.run(input: @input, output: @output2)

    result   = @input2.map { |h| h.to_s }.reduce(:<<)
    expected = ""
    expected << %q{{:SCORES=>"IIIIIIIIIIIIIIIIIIII", :SCORES_MEAN=>40.0}}
    expected << %q{{:SCORES=>"!!!!!IIIIIIIIIIIIIII", :SCORES_MEAN=>30.0}}
    expected << %q{{:SCORES=>"IIIIIIIIIIIIIII!!!!!", :SCORES_MEAN=>30.0}}

    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::MeanScores with local: true returns correctly" do
    @p.mean_scores(local: true).run(input: @input, output: @output2)

    result   = @input2.map { |h| h.to_s }.reduce(:<<)
    expected = ""
    expected << %q{{:SCORES=>"IIIIIIIIIIIIIIIIIIII", :SCORES_MEAN_LOCAL=>40.0}}
    expected << %q{{:SCORES=>"!!!!!IIIIIIIIIIIIIII", :SCORES_MEAN_LOCAL=>0.0}}
    expected << %q{{:SCORES=>"IIIIIIIIIIIIIII!!!!!", :SCORES_MEAN_LOCAL=>0.0}}

    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::MeanScores with local: true and :window_size returns correctly" do
    @p.mean_scores(local: true, window_size: 10).run(input: @input, output: @output2)

    result   = @input2.map { |h| h.to_s }.reduce(:<<)
    expected = ""
    expected << %q{{:SCORES=>"IIIIIIIIIIIIIIIIIIII", :SCORES_MEAN_LOCAL=>40.0}}
    expected << %q{{:SCORES=>"!!!!!IIIIIIIIIIIIIII", :SCORES_MEAN_LOCAL=>20.0}}
    expected << %q{{:SCORES=>"IIIIIIIIIIIIIII!!!!!", :SCORES_MEAN_LOCAL=>20.0}}

    assert_equal(expected, result)
  end
end
