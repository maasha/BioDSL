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

class TestSliceSeq < Test::Unit::TestCase 
  def setup
    @input, @output   = BioPieces::Stream.pipe
    @input2, @output2 = BioPieces::Stream.pipe

    @output.write({FOO: "BAR", SEQ: "atcg"})
    @output.write({SEQ: "atcg", SCORES: "0123"})
    @output.close

    @p = BioPieces::Pipeline.new
  end

  test "BioPieces::Pipeline::SliceSeq with invalid options raises" do
    assert_raise(BioPieces::OptionError) { @p.slice_seq(slice: 1, foo: "bar") }
  end

  test "BioPieces::Pipeline::SliceSeq with valid options don't raise" do
    assert_nothing_raised { @p.slice_seq(slice: 1) }
  end

  test "BioPieces::Pipeline::SliceSeq with index returns correctly" do
    @p.slice_seq(slice: 1).run(input: @input, output: @output2)

    result   = @input2.map { |h| h.to_s }.reduce(:<<)
    expected = ""
    expected << '{:FOO=>"BAR", :SEQ=>"t", :SEQ_LEN=>1}'
    expected << '{:SEQ=>"t", :SCORES=>"1", :SEQ_LEN=>1}'

    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::SliceSeq with out of range index returns correctly" do
    @p.slice_seq(slice: 10).run(input: @input, output: @output2)

    result   = @input2.map { |h| h.to_s }.reduce(:<<)
    expected = ""
    expected << '{:FOO=>"BAR", :SEQ=>"", :SEQ_LEN=>0}'
    expected << '{:SEQ=>"", :SCORES=>"", :SEQ_LEN=>0}'

    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::SliceSeq with negative index returns correctly" do
    @p.slice_seq(slice: -1).run(input: @input, output: @output2)

    result   = @input2.map { |h| h.to_s }.reduce(:<<)
    expected = ""
    expected << '{:FOO=>"BAR", :SEQ=>"g", :SEQ_LEN=>1}'
    expected << '{:SEQ=>"g", :SCORES=>"3", :SEQ_LEN=>1}'

    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::SliceSeq with negative out of range index returns correctly" do
    @p.slice_seq(slice: -10).run(input: @input, output: @output2)

    result   = @input2.map { |h| h.to_s }.reduce(:<<)
    expected = ""
    expected << '{:FOO=>"BAR", :SEQ=>"", :SEQ_LEN=>0}'
    expected << '{:SEQ=>"", :SCORES=>"", :SEQ_LEN=>0}'

    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::SliceSeq with range returns correctly" do
    @p.slice_seq(slice: 1 .. -1).run(input: @input, output: @output2)

    result   = @input2.map { |h| h.to_s }.reduce(:<<)
    expected = ""
    expected << '{:FOO=>"BAR", :SEQ=>"tcg", :SEQ_LEN=>3}'
    expected << '{:SEQ=>"tcg", :SCORES=>"123", :SEQ_LEN=>3}'

    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::SliceSeq with out of range end range returns correctly" do
    @p.slice_seq(slice: 1 .. 10).run(input: @input, output: @output2)

    result   = @input2.map { |h| h.to_s }.reduce(:<<)
    expected = ""
    expected << '{:FOO=>"BAR", :SEQ=>"tcg", :SEQ_LEN=>3}'
    expected << '{:SEQ=>"tcg", :SCORES=>"123", :SEQ_LEN=>3}'

    assert_equal(expected, result)
  end
end
