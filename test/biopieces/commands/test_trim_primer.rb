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

class TestTrimPrimer < Test::Unit::TestCase 
  def setup
    @input, @output   = BioPieces::Stream.pipe
    @input2, @output2 = BioPieces::Stream.pipe

    @p = BioPieces::Pipeline.new
  end

  test "BioPieces::Pipeline::ClipPrimer with invalid options raises" do
    assert_raise(BioPieces::OptionError) { @p.trim_primer(foo: "bar") }
  end

  test "BioPieces::Pipeline::ClipPrimer with valid options don't raise" do
    assert_nothing_raised { @p.trim_primer(primer: "atcg", direction: :forward) }
  end

  test "BioPieces::Pipeline::ClipPrimer with forward and internal match returns correctly" do
    @output.write({SEQ: "aTCGTATGactgactgatcgca"})
    @output.close
    @p.trim_primer(primer: "TCGTATG", direction: :forward).run(input: @input, output: @output2)

    result   = @input2.map { |h| h.to_s }.reduce(:<<)
    expected = '{:SEQ=>"aTCGTATGactgactgatcgca"}'

    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::ClipPrimer with reverse and internal match returns correctly" do
    @output.write({SEQ: "ctgactgatcgcaaTCGTATGa"})
    @output.close
    @p.trim_primer(primer: "TCGTATG", direction: :reverse).run(input: @input, output: @output2)

    result   = @input2.map { |h| h.to_s }.reduce(:<<)
    expected = '{:SEQ=>"ctgactgatcgcaaTCGTATGa"}'

    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::ClipPrimer with forward and full match returns correctly" do
    @output.write({SEQ: "TCGTATGactgactgatcgca"})
    @output.close
    @p.trim_primer(primer: "TCGTATG", direction: :forward).run(input: @input, output: @output2)

    result   = @input2.map { |h| h.to_s }.reduce(:<<)
    expected = '{:SEQ=>"actgactgatcgca", :SEQ_LEN=>14, :TRIM_PRIMER_DIR=>"FORWARD", :TRIM_PRIMER_POS=>0, :TRIM_PRIMER_LEN=>7, :TRIM_PRIMER_PAT=>"TCGTATG"}'

    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::ClipPrimer with reverse and full match returns correctly" do
    @output.write({SEQ: "ctgactgatcgcaaTCGTATG"})
    @output.close
    @p.trim_primer(primer: "TCGTATG", direction: :reverse).run(input: @input, output: @output2)

    result   = @input2.map { |h| h.to_s }.reduce(:<<)
    expected = '{:SEQ=>"ctgactgatcgcaa", :SEQ_LEN=>14, :TRIM_PRIMER_DIR=>"REVERSE", :TRIM_PRIMER_POS=>14, :TRIM_PRIMER_LEN=>7, :TRIM_PRIMER_PAT=>"TCGTATG"}'

    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::ClipPrimer with forward and partial match returns correctly" do
    @output.write({SEQ: "TATGactgactgatcgca"})
    @output.close
    @p.trim_primer(primer: "TCGTATG", direction: :forward).run(input: @input, output: @output2)

    result   = @input2.map { |h| h.to_s }.reduce(:<<)
    expected = '{:SEQ=>"actgactgatcgca", :SEQ_LEN=>14, :TRIM_PRIMER_DIR=>"FORWARD", :TRIM_PRIMER_POS=>0, :TRIM_PRIMER_LEN=>4, :TRIM_PRIMER_PAT=>"TATG"}'

    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::ClipPrimer with forward and partial match and reverse_complment: true returns correctly" do
    @output.write({SEQ: "TATGactgactgatcgca"})
    @output.close
    @p.trim_primer(primer: "CATACGA", direction: :forward, reverse_complement: true).run(input: @input, output: @output2)

    result   = @input2.map { |h| h.to_s }.reduce(:<<)
    expected = '{:SEQ=>"actgactgatcgca", :SEQ_LEN=>14, :TRIM_PRIMER_DIR=>"FORWARD", :TRIM_PRIMER_POS=>0, :TRIM_PRIMER_LEN=>4, :TRIM_PRIMER_PAT=>"TATG"}'

    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::ClipPrimer with reverse and partial match returns correctly" do
    @output.write({SEQ: "ctgactgatcgcaaTCGT"})
    @output.close
    @p.trim_primer(primer: "TCGTATG", direction: :reverse).run(input: @input, output: @output2)

    result   = @input2.map { |h| h.to_s }.reduce(:<<)
    expected = '{:SEQ=>"ctgactgatcgcaa", :SEQ_LEN=>14, :TRIM_PRIMER_DIR=>"REVERSE", :TRIM_PRIMER_POS=>14, :TRIM_PRIMER_LEN=>4, :TRIM_PRIMER_PAT=>"TCGT"}'

    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::ClipPrimer with reverse and partial match and reverse_complment: true returns correctly" do
    @output.write({SEQ: "ctgactgatcgcaaTCGT"})
    @output.close
    @p.trim_primer(primer: "CATACGA", direction: :reverse, reverse_complement: true).run(input: @input, output: @output2)

    result   = @input2.map { |h| h.to_s }.reduce(:<<)
    expected = '{:SEQ=>"ctgactgatcgcaa", :SEQ_LEN=>14, :TRIM_PRIMER_DIR=>"REVERSE", :TRIM_PRIMER_POS=>14, :TRIM_PRIMER_LEN=>4, :TRIM_PRIMER_PAT=>"TCGT"}'

    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::ClipPrimer with forward and minimum match returns correctly" do
    @output.write({SEQ: "Gactgactgatcgca"})
    @output.close
    @p.trim_primer(primer: "TCGTATG", direction: :forward).run(input: @input, output: @output2)

    result   = @input2.map { |h| h.to_s }.reduce(:<<)
    expected = '{:SEQ=>"actgactgatcgca", :SEQ_LEN=>14, :TRIM_PRIMER_DIR=>"FORWARD", :TRIM_PRIMER_POS=>0, :TRIM_PRIMER_LEN=>1, :TRIM_PRIMER_PAT=>"G"}'

    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::ClipPrimer with reverse and minimum match returns correctly" do
    @output.write({SEQ: "ctgactgatcgcaaT"})
    @output.close
    @p.trim_primer(primer: "TCGTATG", direction: :reverse).run(input: @input, output: @output2)

    result   = @input2.map { |h| h.to_s }.reduce(:<<)
    expected = '{:SEQ=>"ctgactgatcgcaa", :SEQ_LEN=>14, :TRIM_PRIMER_DIR=>"REVERSE", :TRIM_PRIMER_POS=>14, :TRIM_PRIMER_LEN=>1, :TRIM_PRIMER_PAT=>"T"}'

    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::ClipPrimer with forward and partial match and overlap_min returns correctly" do
    @output.write({SEQ: "TATGactgactgatcgca"})
    @output.close
    @p.trim_primer(primer: "TCGTATG", direction: :forward, overlap_min: 4).run(input: @input, output: @output2)

    result   = @input2.map { |h| h.to_s }.reduce(:<<)
    expected = '{:SEQ=>"actgactgatcgca", :SEQ_LEN=>14, :TRIM_PRIMER_DIR=>"FORWARD", :TRIM_PRIMER_POS=>0, :TRIM_PRIMER_LEN=>4, :TRIM_PRIMER_PAT=>"TATG"}'

    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::ClipPrimer with reverse and partial match and overlap_min returns correctly" do
    @output.write({SEQ: "ctgactgatcgcaaTCGT"})
    @output.close
    @p.trim_primer(primer: "TCGTATG", direction: :reverse, overlap_min: 4).run(input: @input, output: @output2)

    result   = @input2.map { |h| h.to_s }.reduce(:<<)
    expected = '{:SEQ=>"ctgactgatcgcaa", :SEQ_LEN=>14, :TRIM_PRIMER_DIR=>"REVERSE", :TRIM_PRIMER_POS=>14, :TRIM_PRIMER_LEN=>4, :TRIM_PRIMER_PAT=>"TCGT"}'

    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::ClipPrimer with forward and partial miss due to overlap_min returns correctly" do
    @output.write({SEQ: "TATGactgactgatcgca"})
    @output.close
    @p.trim_primer(primer: "TCGTATG", direction: :forward, overlap_min: 5).run(input: @input, output: @output2)

    result   = @input2.map { |h| h.to_s }.reduce(:<<)
    expected = '{:SEQ=>"TATGactgactgatcgca"}'

    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::ClipPrimer with reverse and partial miss due to overlap_min returns correctly" do
    @output.write({SEQ: "ctgactgatcgcaaTCGT"})
    @output.close
    @p.trim_primer(primer: "TCGTATG", direction: :reverse, overlap_min: 5).run(input: @input, output: @output2)

    result   = @input2.map { |h| h.to_s }.reduce(:<<)
    expected = '{:SEQ=>"ctgactgatcgcaaTCGT"}'

    assert_equal(expected, result)
  end
end
