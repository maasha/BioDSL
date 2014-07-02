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

class TestClipPrimer < Test::Unit::TestCase 
  def setup
    @input, @output   = BioPieces::Pipeline::Stream.pipe
    @input2, @output2 = BioPieces::Pipeline::Stream.pipe

    hash = {
      SEQ_NAME: "test",
      SEQ: "gatcgatcgtacgagcagcatctgacgtatcgatcgttgattagttgctagctatgcagtctacgacgagcatgctagctag",
      SEQ_LEN: 82,
      SCORES: %q[!"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIIHGFEDCBA@?>=<;:9876543210/.-,+*)('&%$III]
    }

    @output.write hash
    @output.close

    @p = BioPieces::Pipeline.new
  end

  test "BioPieces::Pipeline::ClipPrimer with invalid options raises" do
    assert_raise(BioPieces::OptionError) { @p.clip_primer(foo: "bar") }
  end

  test "BioPieces::Pipeline::ClipPrimer with valid options don't raise" do
    assert_nothing_raised { @p.clip_primer(mode: :left) }
  end

  test "BioPieces::Pipeline::ClipPrimer returns correctly" do
    @p.clip_primer.run(input: @input, output: @output2)

    result   = @input2.map { |h| h.to_s }.reduce(:<<)
    expected = ""
    expected << %Q{{:SEQ_NAME=>"test", :SEQ=>"tctgacgtatcgatcgttgattagttgctagctatgcagtctacgacgagcatgctagctag", :SEQ_LEN=>62, :SCORES=>"56789:;<=>?@ABCDEFGHIIHGFEDCBA@?>=<;:9876543210/.-,+*)('&%$III"}}

    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::ClipPrimer with :quality_min returns correctly" do
    @p.clip_primer(quality_min: 25).run(input: @input, output: @output2)

    result   = @input2.map { |h| h.to_s }.reduce(:<<)
    expected = ""
    expected << %Q{{:SEQ_NAME=>"test", :SEQ=>"cgtatcgatcgttgattagttgctagctatgcagtctacgacgagcatgctagctag", :SEQ_LEN=>57, :SCORES=>":;<=>?@ABCDEFGHIIHGFEDCBA@?>=<;:9876543210/.-,+*)('&%$III"}}

    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::ClipPrimer with mode: both: returns correctly" do
    @p.clip_primer(mode: :both).run(input: @input, output: @output2)

    result   = @input2.map { |h| h.to_s }.reduce(:<<)
    expected = ""
    expected << %Q{{:SEQ_NAME=>"test", :SEQ=>"tctgacgtatcgatcgttgattagttgctagctatgcagtctacgacgagcatgctagctag", :SEQ_LEN=>62, :SCORES=>"56789:;<=>?@ABCDEFGHIIHGFEDCBA@?>=<;:9876543210/.-,+*)('&%$III"}}

    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::ClipPrimer with mode: :left returns correctly" do
    @p.clip_primer(mode: :left).run(input: @input, output: @output2)

    result   = @input2.map { |h| h.to_s }.reduce(:<<)
    expected = ""
    expected << %Q{{:SEQ_NAME=>"test", :SEQ=>"tctgacgtatcgatcgttgattagttgctagctatgcagtctacgacgagcatgctagctag", :SEQ_LEN=>62, :SCORES=>"56789:;<=>?@ABCDEFGHIIHGFEDCBA@?>=<;:9876543210/.-,+*)('&%$III"}}

    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::ClipPrimer with mode: :right returns correctly" do
    @p.clip_primer(mode: :right).run(input: @input, output: @output2)

    result   = @input2.map { |h| h.to_s }.reduce(:<<)
    expected = ""
    expected << %q[{:SEQ_NAME=>"test", :SEQ=>"gatcgatcgtacgagcagcatctgacgtatcgatcgttgattagttgctagctatgcagtctacgacgagcatgctagctag", :SEQ_LEN=>82, :SCORES=>"!\\"\\#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIIHGFEDCBA@?>=<;:9876543210/.-,+*)('&%$III"}]

    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::ClipPrimer with :length_min returns correctly" do
    @p.clip_primer(length_min: 4).run(input: @input, output: @output2)

    result   = @input2.map { |h| h.to_s }.reduce(:<<)
    expected = ""
    expected << %Q{{:SEQ_NAME=>"test", :SEQ=>"tctgacgtatcgatcgttgattagttgctagctatgcagtct", :SEQ_LEN=>42, :SCORES=>"56789:;<=>?@ABCDEFGHIIHGFEDCBA@?>=<;:98765"}}

    assert_equal(expected, result)
  end
end
