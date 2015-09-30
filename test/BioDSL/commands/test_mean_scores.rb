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

# Test class for MeanScores.
class TestMeanScores < Test::Unit::TestCase
  def setup
    @input, @output   = BioDSL::Stream.pipe
    @input2, @output2 = BioDSL::Stream.pipe

    @output.write(SCORES: 'IIIIIIIIIIIIIIIIIIII')
    @output.write(SCORES: '!!!!!IIIIIIIIIIIIIII')
    @output.write(SCORES: 'IIIIIIIIIIIIIII!!!!!')
    @output.close

    @p = BioDSL::Pipeline.new
  end

  test 'BioDSL::Pipeline::MeanScores with invalid options raises' do
    assert_raise(BioDSL::OptionError) { @p.mean_scores(foo: 'bar') }
  end

  test 'BioDSL::Pipeline::MeanScores with valid options don\'t raise' do
    assert_nothing_raised { @p.mean_scores(local: true) }
  end

  test 'BioDSL::Pipeline::MeanScores with window_size and local: false ' \
    'raises' do
    assert_raise(BioDSL::OptionError) { @p.mean_scores(window_size: 10) }
  end

  test 'BioDSL::Pipeline::MeanScores returns correctly' do
    @p.mean_scores.run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:SCORES=>"IIIIIIIIIIIIIIIIIIII", :SCORES_MEAN=>40.0}
      |{:SCORES=>"!!!!!IIIIIIIIIIIIIII", :SCORES_MEAN=>30.0}
      |{:SCORES=>"IIIIIIIIIIIIIII!!!!!", :SCORES_MEAN=>30.0}
    EXP

    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::MeanScores status returns correctly' do
    @p.mean_scores.run(input: @input, output: @output2)

    assert_equal(3,     @p.status.first[:records_in])
    assert_equal(3,     @p.status.first[:records_out])
    assert_equal(0,     @p.status.first[:sequences_in])
    assert_equal(0,     @p.status.first[:sequences_out])
    assert_equal(0,     @p.status.first[:residues_in])
    assert_equal(0,     @p.status.first[:residues_out])
    assert_equal(0,     @p.status.first[:min_mean])
    assert_equal(40,    @p.status.first[:max_mean])
    assert_equal(33.33, @p.status.first[:mean_mean])
  end

  test 'BioDSL::Pipeline::MeanScores with local: true returns correctly' do
    @p.mean_scores(local: true).run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:SCORES=>"IIIIIIIIIIIIIIIIIIII", :SCORES_MEAN_LOCAL=>40.0}
      |{:SCORES=>"!!!!!IIIIIIIIIIIIIII", :SCORES_MEAN_LOCAL=>0.0}
      |{:SCORES=>"IIIIIIIIIIIIIII!!!!!", :SCORES_MEAN_LOCAL=>0.0}
    EXP

    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::MeanScores with local: true and :window_size ' \
    'returns correctly' do
    @p.mean_scores(local: true, window_size: 10).
      run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:SCORES=>"IIIIIIIIIIIIIIIIIIII", :SCORES_MEAN_LOCAL=>40.0}
      |{:SCORES=>"!!!!!IIIIIIIIIIIIIII", :SCORES_MEAN_LOCAL=>20.0}
      |{:SCORES=>"IIIIIIIIIIIIIII!!!!!", :SCORES_MEAN_LOCAL=>20.0}
    EXP

    assert_equal(expected, collect_result)
  end
end
