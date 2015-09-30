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

# Test class for TrimPrimer.
#
# rubocop: disable ClassLength
class TestTrimPrimer < Test::Unit::TestCase
  def setup
    @input, @output   = BioDSL::Stream.pipe
    @input2, @output2 = BioDSL::Stream.pipe

    @p = BioDSL::Pipeline.new
  end

  test 'BioDSL::Pipeline::TrimPrimer with invalid options raises' do
    assert_raise(BioDSL::OptionError) { @p.trim_primer(foo: 'bar') }
  end

  test 'BioDSL::Pipeline::TrimPrimer with valid options dont raise' do
    assert_nothing_raised do
      @p.trim_primer(primer: 'atcg', direction: :forward)
    end
  end

  test 'BioDSL::Pipeline::TrimPrimer with forward and pattern longer than ' \
    'sequence returns correctly' do
    @output.write(SEQ: 'TATG')
    @output.close
    @p.trim_primer(primer: 'TCGTATG', direction: :forward, overlap_min: 1).
      run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:SEQ=>"",
      | :SEQ_LEN=>0,
      | :TRIM_PRIMER_DIR=>"FORWARD",
      | :TRIM_PRIMER_POS=>0,
      | :TRIM_PRIMER_LEN=>4,
      | :TRIM_PRIMER_PAT=>"TATG"}
    EXP

    assert_equal(expected.delete("\n"), collect_result.delete("\n"))
  end

  test 'BioDSL::Pipeline::TrimPrimer with reverse and pattern longer than ' \
    'sequence returns correctly' do
    @output.write(SEQ: 'TCGT')
    @output.close
    @p.trim_primer(primer: 'TCGTATG', direction: :reverse, overlap_min: 1).
      run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:SEQ=>"",
      | :SEQ_LEN=>0,
      | :TRIM_PRIMER_DIR=>"REVERSE",
      | :TRIM_PRIMER_POS=>0,
      | :TRIM_PRIMER_LEN=>4,
      | :TRIM_PRIMER_PAT=>"TCGT"}
    EXP

    assert_equal(expected.delete("\n"), collect_result.delete("\n"))
  end

  test 'BioDSL::Pipeline::TrimPrimer with forward and internal match ' \
    'returns correctly' do
    @output.write(SEQ: 'aTCGTATGactgactgatcgca')
    @output.close
    @p.trim_primer(primer: 'TCGTATG', direction: :forward).
      run(input: @input, output: @output2)

    expected = '{:SEQ=>"aTCGTATGactgactgatcgca"}'

    assert_equal(expected, collect_result.chomp)
  end

  test 'BioDSL::Pipeline::TrimPrimer with reverse and internal match ' \
    'returns correctly' do
    @output.write(SEQ: 'ctgactgatcgcaaTCGTATGa')
    @output.close
    @p.trim_primer(primer: 'TCGTATG', direction: :reverse).
      run(input: @input, output: @output2)

    expected = '{:SEQ=>"ctgactgatcgcaaTCGTATGa"}'

    assert_equal(expected, collect_result.chomp)
  end

  test 'BioDSL::Pipeline::TrimPrimer w. forward and full match returns OK' do
    @output.write(SEQ: 'TCGTATGactgactgatcgca')
    @output.close
    @p.trim_primer(primer: 'TCGTATG', direction: :forward).
      run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:SEQ=>"actgactgatcgca",
      | :SEQ_LEN=>14,
      | :TRIM_PRIMER_DIR=>"FORWARD",
      | :TRIM_PRIMER_POS=>0,
      | :TRIM_PRIMER_LEN=>7,
      | :TRIM_PRIMER_PAT=>"TCGTATG"}
    EXP

    assert_equal(expected.delete("\n"), collect_result.delete("\n"))
  end

  test 'BioDSL::Pipeline::TrimPrimer w. reverse and full match returns OK' do
    @output.write(SEQ: 'ctgactgatcgcaaTCGTATG')
    @output.close
    @p.trim_primer(primer: 'TCGTATG', direction: :reverse).
      run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:SEQ=>"ctgactgatcgcaa",
      | :SEQ_LEN=>14,
      | :TRIM_PRIMER_DIR=>"REVERSE",
      | :TRIM_PRIMER_POS=>14,
      | :TRIM_PRIMER_LEN=>7,
      | :TRIM_PRIMER_PAT=>"TCGTATG"}
    EXP

    assert_equal(expected.delete("\n"), collect_result.delete("\n"))
  end

  test 'BioDSL::Pipeline::TrimPrimer w. forward and partial match returns ' \
    'correctly' do
    @output.write(SEQ: 'TATGactgactgatcgca')
    @output.close
    @p.trim_primer(primer: 'TCGTATG', direction: :forward).
      run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:SEQ=>"actgactgatcgca",
      | :SEQ_LEN=>14,
      | :TRIM_PRIMER_DIR=>"FORWARD",
      | :TRIM_PRIMER_POS=>0,
      | :TRIM_PRIMER_LEN=>4,
      | :TRIM_PRIMER_PAT=>"TATG"}
    EXP

    assert_equal(expected.delete("\n"), collect_result.delete("\n"))
  end

  test 'BioDSL::Pipeline::TrimPrimer with forward and partial match and ' \
    'reverse_complment: true returns correctly' do
    @output.write(SEQ: 'TATGactgactgatcgca')
    @output.close
    @p.trim_primer(primer: 'CATACGA', direction: :forward,
                   reverse_complement: true).
      run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:SEQ=>"actgactgatcgca",
      | :SEQ_LEN=>14,
      | :TRIM_PRIMER_DIR=>"FORWARD",
      | :TRIM_PRIMER_POS=>0,
      | :TRIM_PRIMER_LEN=>4,
      | :TRIM_PRIMER_PAT=>"TATG"}
    EXP

    assert_equal(expected.delete("\n"), collect_result.delete("\n"))
  end

  test 'BioDSL::Pipeline::TrimPrimer w. reverse and partial match returns ' \
    'correctly' do
    @output.write(SEQ: 'ctgactgatcgcaaTCGT')
    @output.close
    @p.trim_primer(primer: 'TCGTATG', direction: :reverse).
      run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:SEQ=>"ctgactgatcgcaa",
      | :SEQ_LEN=>14,
      | :TRIM_PRIMER_DIR=>"REVERSE",
      | :TRIM_PRIMER_POS=>14,
      | :TRIM_PRIMER_LEN=>4,
      | :TRIM_PRIMER_PAT=>"TCGT"}
    EXP

    assert_equal(expected.delete("\n"), collect_result.delete("\n"))
  end

  test 'BioDSL::Pipeline::TrimPrimer with reverse and partial match and ' \
    'reverse_complment: true returns correctly' do
    @output.write(SEQ: 'ctgactgatcgcaaTCGT')
    @output.close
    @p.trim_primer(primer: 'CATACGA', direction: :reverse,
                   reverse_complement: true).
      run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:SEQ=>"ctgactgatcgcaa",
      | :SEQ_LEN=>14,
      | :TRIM_PRIMER_DIR=>"REVERSE",
      | :TRIM_PRIMER_POS=>14,
      | :TRIM_PRIMER_LEN=>4,
      | :TRIM_PRIMER_PAT=>"TCGT"}
    EXP

    assert_equal(expected.delete("\n"), collect_result.delete("\n"))
  end

  test 'BioDSL::Pipeline::TrimPrimer with forward and minimum match ' \
    'returns correctly' do
    @output.write(SEQ: 'Gactgactgatcgca')
    @output.close
    @p.trim_primer(primer: 'TCGTATG', direction: :forward).
      run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:SEQ=>"actgactgatcgca",
      | :SEQ_LEN=>14,
      | :TRIM_PRIMER_DIR=>"FORWARD",
      | :TRIM_PRIMER_POS=>0,
      | :TRIM_PRIMER_LEN=>1,
      | :TRIM_PRIMER_PAT=>"G"}
    EXP

    assert_equal(expected.delete("\n"), collect_result.delete("\n"))
  end

  test 'BioDSL::Pipeline::TrimPrimer with reverse and minimum match ' \
    'returns correctly' do
    @output.write(SEQ: 'ctgactgatcgcaaT')
    @output.close
    @p.trim_primer(primer: 'TCGTATG', direction: :reverse).
      run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:SEQ=>"ctgactgatcgcaa",
      | :SEQ_LEN=>14,
      | :TRIM_PRIMER_DIR=>"REVERSE",
      | :TRIM_PRIMER_POS=>14,
      | :TRIM_PRIMER_LEN=>1,
      | :TRIM_PRIMER_PAT=>"T"}
    EXP

    assert_equal(expected.delete("\n"), collect_result.delete("\n"))
  end

  test 'BioDSL::Pipeline::TrimPrimer with forward and partial match and ' \
    'overlap_min returns correctly' do
    @output.write(SEQ: 'TATGactgactgatcgca')
    @output.close
    @p.trim_primer(primer: 'TCGTATG', direction: :forward, overlap_min: 4).
      run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:SEQ=>"actgactgatcgca",
      | :SEQ_LEN=>14,
      | :TRIM_PRIMER_DIR=>"FORWARD",
      | :TRIM_PRIMER_POS=>0,
      | :TRIM_PRIMER_LEN=>4,
      | :TRIM_PRIMER_PAT=>"TATG"}
    EXP

    assert_equal(expected.delete("\n"), collect_result.delete("\n"))
  end

  test 'BioDSL::Pipeline::TrimPrimer with reverse and partial match and ' \
    'overlap_min returns correctly' do
    @output.write(SEQ: 'ctgactgatcgcaaTCGT')
    @output.close
    @p.trim_primer(primer: 'TCGTATG', direction: :reverse, overlap_min: 4).
      run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:SEQ=>"ctgactgatcgcaa",
      | :SEQ_LEN=>14,
      | :TRIM_PRIMER_DIR=>"REVERSE",
      | :TRIM_PRIMER_POS=>14,
      | :TRIM_PRIMER_LEN=>4,
      | :TRIM_PRIMER_PAT=>"TCGT"}
    EXP

    assert_equal(expected.delete("\n"), collect_result.delete("\n"))
  end

  test 'BioDSL::Pipeline::TrimPrimer with forward and partial miss due ' \
    'to overlap_min returns correctly' do
    @output.write(SEQ: 'TATGactgactgatcgca')
    @output.close
    @p.trim_primer(primer: 'TCGTATG', direction: :forward, overlap_min: 5).
      run(input: @input, output: @output2)

    expected = '{:SEQ=>"TATGactgactgatcgca"}'

    assert_equal(expected, collect_result.chomp)
  end

  test 'BioDSL::Pipeline::TrimPrimer with reverse and partial miss due ' \
    'to overlap_min returns correctly' do
    @output.write(SEQ: 'ctgactgatcgcaaTCGT')
    @output.close
    @p.trim_primer(primer: 'TCGTATG', direction: :reverse, overlap_min: 5).
      run(input: @input, output: @output2)

    expected = '{:SEQ=>"ctgactgatcgcaaTCGT"}'

    assert_equal(expected, collect_result.chomp)
  end
end
