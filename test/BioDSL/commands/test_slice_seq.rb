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

# Test class for SliceSeq.
class TestSliceSeq < Test::Unit::TestCase
  def setup
    @input, @output   = BioDSL::Stream.pipe
    @input2, @output2 = BioDSL::Stream.pipe

    @output.write(FOO: 'BAR', SEQ: 'atcg')
    @output.write(SEQ: 'atcg', SCORES: '0123')
    @output.close

    @p = BioDSL::Pipeline.new
  end

  test 'BioDSL::Pipeline::SliceSeq with invalid options raises' do
    assert_raise(BioDSL::OptionError) { @p.slice_seq(slice: 1, foo: 'bar') }
  end

  test 'BioDSL::Pipeline::SliceSeq with valid options don\'t raise' do
    assert_nothing_raised { @p.slice_seq(slice: 1) }
  end

  test 'BioDSL::Pipeline::SliceSeq with index returns correctly' do
    @p.slice_seq(slice: 1).run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:FOO=>"BAR", :SEQ=>"t", :SEQ_LEN=>1}
      |{:SEQ=>"t", :SCORES=>"1", :SEQ_LEN=>1}
    EXP

    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::SliceSeq with out of range index returns OK' do
    @p.slice_seq(slice: 10).run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:FOO=>"BAR", :SEQ=>"", :SEQ_LEN=>0}
      |{:SEQ=>"", :SCORES=>"", :SEQ_LEN=>0}
    EXP

    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::SliceSeq with negative index returns correctly' do
    @p.slice_seq(slice: -1).run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:FOO=>"BAR", :SEQ=>"g", :SEQ_LEN=>1}
      |{:SEQ=>"g", :SCORES=>"3", :SEQ_LEN=>1}
    EXP

    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::SliceSeq with negative out of range index ' \
    'returns correctly' do
    @p.slice_seq(slice: -10).run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:FOO=>"BAR", :SEQ=>"", :SEQ_LEN=>0}
      |{:SEQ=>"", :SCORES=>"", :SEQ_LEN=>0}
    EXP

    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::SliceSeq with range returns correctly' do
    @p.slice_seq(slice: 1..-1).run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:FOO=>"BAR", :SEQ=>"tcg", :SEQ_LEN=>3}
      |{:SEQ=>"tcg", :SCORES=>"123", :SEQ_LEN=>3}
    EXP

    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::SliceSeq with out of range end range returns OK' do
    @p.slice_seq(slice: 1..10).run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:FOO=>"BAR", :SEQ=>"tcg", :SEQ_LEN=>3}
      |{:SEQ=>"tcg", :SCORES=>"123", :SEQ_LEN=>3}
    EXP

    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::SliceSeq status returns OK' do
    @p.slice_seq(slice: 1..10).run(input: @input, output: @output2)

    assert_equal(2, @p.status.first[:records_in])
    assert_equal(2, @p.status.first[:records_out])
    assert_equal(2, @p.status.first[:sequences_in])
    assert_equal(2, @p.status.first[:sequences_out])
    assert_equal(8, @p.status.first[:residues_in])
    assert_equal(6, @p.status.first[:residues_out])
  end
end
