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

class TestAssemblePairs < Test::Unit::TestCase 
  def setup
    @input, @output   = BioPieces::Stream.pipe
    @input2, @output2 = BioPieces::Stream.pipe

    @output.write({SEQ_NAME: "test1/1", SEQ: "aaaaaaaagagtcat", SCORES: "IIIIIIIIIIIIIII", SEQ_LEN: 15})
    @output.write({SEQ_NAME: "test1/2", SEQ: "gagtcataaaaaaaa", SCORES: "!!!!!!!!!!!!!!!", SEQ_LEN: 15})
    @output.write({SEQ_NAME: "test2/1", SEQ: "aaaaaaaagagGcaG", SCORES: "IIIIIIIIIIIIIII", SEQ_LEN: 15})
    @output.write({SEQ_NAME: "test2/2", SEQ: "gagtcataaaaaaaa", SCORES: "!!!!!!!!!!!!!!!", SEQ_LEN: 15})
    @output.write({SEQ_NAME: "test3/1", SEQ: "aaaaaaaagagtcat", SCORES: "IIIIIIIIIIIIIII", SEQ_LEN: 15})
    @output.write({SEQ_NAME: "test3/2", SEQ: "ttttttttatgactc", SCORES: "!!!!!!!!!!!!!!!", SEQ_LEN: 15})
    @output.write({FOO: "SEQ"})

    @output.close

    @p = BioPieces::Pipeline.new
  end

  test "BioPieces::Pipeline::AssemblePairs with invalid options raises" do
    assert_raise(BioPieces::OptionError) { @p.assemble_pairs(foo: "bar") }
  end

  test "BioPieces::Pipeline::AssemblePairs with valid options don't raise" do
    assert_nothing_raised { @p.assemble_pairs(reverse_complement: true) }
  end

  test "BioPieces::Pipeline::AssemblePairs returns correctly" do
    @p.assemble_pairs.run(input: @input, output: @output2)

    result   = @input2.map { |h| h.to_s }.reduce(:<<)
    expected = ""
    expected << '{:SEQ_NAME=>"test1/1:overlap=7:hamming=0", :SEQ=>"aaaaaaaaGAGTCATaaaaaaaa", :SEQ_LEN=>23, :SCORES=>"IIIIIIII5555555!!!!!!!!", :OVERLAP_LEN=>7, :HAMMING_DIST=>0}'
    expected << '{:SEQ_NAME=>"test2/1:overlap=3:hamming=1", :SEQ=>"aaaaaaaagaggCAGtcataaaaaaaa", :SEQ_LEN=>27, :SCORES=>"IIIIIIIIIIII555!!!!!!!!!!!!", :OVERLAP_LEN=>3, :HAMMING_DIST=>1}'
    expected << '{:SEQ_NAME=>"test3/1:overlap=1:hamming=0", :SEQ=>"aaaaaaaagagtcaTtttttttatgactc", :SEQ_LEN=>29, :SCORES=>"IIIIIIIIIIIIII5!!!!!!!!!!!!!!", :OVERLAP_LEN=>1, :HAMMING_DIST=>0}'
    expected << '{:FOO=>"SEQ"}'

    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::AssemblePairs with :mismatch_percent returns correctly" do
    @p.assemble_pairs(mismatch_percent: 0).run(input: @input, output: @output2)

    result   = @input2.map { |h| h.to_s }.reduce(:<<)
    expected = ""
    expected << '{:SEQ_NAME=>"test1/1:overlap=7:hamming=0", :SEQ=>"aaaaaaaaGAGTCATaaaaaaaa", :SEQ_LEN=>23, :SCORES=>"IIIIIIII5555555!!!!!!!!", :OVERLAP_LEN=>7, :HAMMING_DIST=>0}'
    expected << '{:SEQ_NAME=>"test2/1:overlap=1:hamming=0", :SEQ=>"aaaaaaaagaggcaGagtcataaaaaaaa", :SEQ_LEN=>29, :SCORES=>"IIIIIIIIIIIIII5!!!!!!!!!!!!!!", :OVERLAP_LEN=>1, :HAMMING_DIST=>0}'
    expected << '{:SEQ_NAME=>"test3/1:overlap=1:hamming=0", :SEQ=>"aaaaaaaagagtcaTtttttttatgactc", :SEQ_LEN=>29, :SCORES=>"IIIIIIIIIIIIII5!!!!!!!!!!!!!!", :OVERLAP_LEN=>1, :HAMMING_DIST=>0}'
    expected << '{:FOO=>"SEQ"}'

    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::AssemblePairs with :overlap_min returns correctly" do
    @p.assemble_pairs(overlap_min: 5).run(input: @input, output: @output2)

    result   = @input2.map { |h| h.to_s }.reduce(:<<)
    expected = ""
    expected << '{:SEQ_NAME=>"test1/1:overlap=7:hamming=0", :SEQ=>"aaaaaaaaGAGTCATaaaaaaaa", :SEQ_LEN=>23, :SCORES=>"IIIIIIII5555555!!!!!!!!", :OVERLAP_LEN=>7, :HAMMING_DIST=>0}'
    expected << '{:FOO=>"SEQ"}'

    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::AssemblePairs with :overlap_max returns correctly" do
    @p.assemble_pairs(overlap_max: 5).run(input: @input, output: @output2)

    result   = @input2.map { |h| h.to_s }.reduce(:<<)
    expected = ""
    expected << '{:SEQ_NAME=>"test2/1:overlap=3:hamming=1", :SEQ=>"aaaaaaaagaggCAGtcataaaaaaaa", :SEQ_LEN=>27, :SCORES=>"IIIIIIIIIIII555!!!!!!!!!!!!", :OVERLAP_LEN=>3, :HAMMING_DIST=>1}'
    expected << '{:SEQ_NAME=>"test3/1:overlap=1:hamming=0", :SEQ=>"aaaaaaaagagtcaTtttttttatgactc", :SEQ_LEN=>29, :SCORES=>"IIIIIIIIIIIIII5!!!!!!!!!!!!!!", :OVERLAP_LEN=>1, :HAMMING_DIST=>0}'
    expected << '{:FOO=>"SEQ"}'

    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::AssemblePairs with :reverse_complement returns correctly" do
    @p.assemble_pairs(reverse_complement: true).run(input: @input, output: @output2)

    result   = @input2.map { |h| h.to_s }.reduce(:<<)
    expected = ""
    expected << '{:SEQ_NAME=>"test1/1:overlap=1:hamming=0", :SEQ=>"aaaaaaaagagtcaTtttttttatgactc", :SEQ_LEN=>29, :SCORES=>"IIIIIIIIIIIIII5!!!!!!!!!!!!!!", :OVERLAP_LEN=>1, :HAMMING_DIST=>0}'
    expected << '{:SEQ_NAME=>"test3/1:overlap=7:hamming=0", :SEQ=>"aaaaaaaaGAGTCATaaaaaaaa", :SEQ_LEN=>23, :SCORES=>"IIIIIIII5555555!!!!!!!!", :OVERLAP_LEN=>7, :HAMMING_DIST=>0}'
    expected << '{:FOO=>"SEQ"}'

    assert_equal(expected, result)
  end
end
