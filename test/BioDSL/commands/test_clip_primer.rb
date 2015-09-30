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

# Test class for ClipPrimer.
# rubocop:disable ClassLength
class TestClipPrimer < Test::Unit::TestCase
  def setup
    @input, @output   = BioDSL::Stream.pipe
    @input2, @output2 = BioDSL::Stream.pipe

    @p = BioDSL::Pipeline.new
  end

  test 'BioDSL::Pipeline::ClipPrimer with invalid options raises' do
    assert_raise(BioDSL::OptionError) { @p.clip_primer(foo: 'bar') }
  end

  test 'BioDSL::Pipeline::ClipPrimer with valid options dont raise' do
    assert_nothing_raised do
      @p.clip_primer(primer: 'atcg', direction: :forward)
    end
  end

  test 'BioDSL::Pipeline::ClipPrimer with forward full length match ' \
    'returns correctly' do
    @output.write(SEQ: 'TCGTATGCCGTCTTCTGCTT')
    @output.close
    @p.clip_primer(primer: 'TCGTATGCCGTCTTCTGCTT', direction: :forward).
      run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '').delete("\n")
      |{:SEQ=>"",
      | :SEQ_LEN=>0,
      | :CLIP_PRIMER_DIR=>"FORWARD",
      | :CLIP_PRIMER_POS=>0,
      | :CLIP_PRIMER_LEN=>20,
      | :CLIP_PRIMER_PAT=>"TCGTATGCCGTCTTCTGCTT"}
    EXP

    assert_equal(expected, collect_result.chomp)
  end

  test 'BioDSL::Pipeline::ClipPrimer status returns correctly' do
    @output.write(SEQ: 'TCGTATGCCGTCTTCTGCTT')
    @output.close
    @p.clip_primer(primer: 'TCGTATGCCGTCTTCTGCTT', direction: :forward).
      run(input: @input, output: @output2)

    assert_equal(1, @p.status.first[:records_in])
    assert_equal(1, @p.status.first[:records_out])
    assert_equal(1, @p.status.first[:sequences_in])
    assert_equal(1, @p.status.first[:sequences_out])
    assert_equal(20, @p.status.first[:residues_in])
    assert_equal(20, @p.status.first[:residues_out])
  end

  test 'BioDSL::Pipeline::ClipPrimer with reverse full length match ' \
    'returns correctly' do
    @output.write(SEQ: 'TCGTATGCCGTCTTCTGCTT')
    @output.close
    @p.clip_primer(primer: 'TCGTATGCCGTCTTCTGCTT', direction: :reverse).
      run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '').delete("\n")
      |{:SEQ=>"",
      | :SEQ_LEN=>0,
      | :CLIP_PRIMER_DIR=>"REVERSE",
      | :CLIP_PRIMER_POS=>0,
      | :CLIP_PRIMER_LEN=>20,
      | :CLIP_PRIMER_PAT=>"TCGTATGCCGTCTTCTGCTT"}
    EXP

    assert_equal(expected, collect_result.chomp)
  end

  test 'BioDSL::Pipeline::ClipPrimer w. forward begin match returns OK' do
    @output.write(SEQ: 'TCGTATGCCGTCTTCTGCTTactacgt')
    @output.close
    @p.clip_primer(primer: 'TCGTATGCCGTCTTCTGCTT', direction: :forward).
      run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '').delete("\n")
      |{:SEQ=>"actacgt",
      | :SEQ_LEN=>7,
      | :CLIP_PRIMER_DIR=>"FORWARD",
      | :CLIP_PRIMER_POS=>0,
      | :CLIP_PRIMER_LEN=>20,
      | :CLIP_PRIMER_PAT=>"TCGTATGCCGTCTTCTGCTT"}
    EXP

    assert_equal(expected, collect_result.chomp)
  end

  test 'BioDSL::Pipeline::ClipPrimer with reverse begin match returns OK' do
    @output.write(SEQ: 'TCGTATGCCGTCTTCTGCTTactacgt')
    @output.close
    @p.clip_primer(primer: 'TCGTATGCCGTCTTCTGCTT', direction: :reverse).
      run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '').delete("\n")
      |{:SEQ=>"",
      | :SEQ_LEN=>0,
      | :CLIP_PRIMER_DIR=>"REVERSE",
      | :CLIP_PRIMER_POS=>0,
      | :CLIP_PRIMER_LEN=>20,
      | :CLIP_PRIMER_PAT=>"TCGTATGCCGTCTTCTGCTT"}
    EXP

    assert_equal(expected, collect_result.chomp)
  end

  test 'BioDSL::Pipeline::ClipPrimer with forward middle match returns OK' do
    @output.write(SEQ: 'actgactgaTCGTATGCCGTCTTCTGCTTactacgt')
    @output.close
    @p.clip_primer(primer: 'TCGTATGCCGTCTTCTGCTT', direction: :forward).
      run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '').delete("\n")
      |{:SEQ=>"actacgt",
      | :SEQ_LEN=>7,
      | :CLIP_PRIMER_DIR=>"FORWARD",
      | :CLIP_PRIMER_POS=>9,
      | :CLIP_PRIMER_LEN=>20,
      | :CLIP_PRIMER_PAT=>"TCGTATGCCGTCTTCTGCTT"}
    EXP

    assert_equal(expected, collect_result.chomp)
  end

  test 'BioDSL::Pipeline::ClipPrimer with reverse middle match returns OK' do
    @output.write(SEQ: 'actgactgaTCGTATGCCGTCTTCTGCTTactacgt')
    @output.close
    @p.clip_primer(primer: 'TCGTATGCCGTCTTCTGCTT', direction: :reverse).
      run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '').delete("\n")
      |{:SEQ=>"actgactga",
      | :SEQ_LEN=>9,
      | :CLIP_PRIMER_DIR=>"REVERSE",
      | :CLIP_PRIMER_POS=>9,
      | :CLIP_PRIMER_LEN=>20,
      | :CLIP_PRIMER_PAT=>"TCGTATGCCGTCTTCTGCTT"}
    EXP

    assert_equal(expected, collect_result.chomp)
  end

  test 'BioDSL::Pipeline::ClipPrimer with forward end match returns OK' do
    @output.write(SEQ: 'gactgaTCGTATGCCGTCTTCTGCTT')
    @output.close
    @p.clip_primer(primer: 'TCGTATGCCGTCTTCTGCTT', direction: :forward).
      run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '').delete("\n")
      |{:SEQ=>"",
      | :SEQ_LEN=>0,
      | :CLIP_PRIMER_DIR=>"FORWARD",
      | :CLIP_PRIMER_POS=>6,
      | :CLIP_PRIMER_LEN=>20,
      | :CLIP_PRIMER_PAT=>"TCGTATGCCGTCTTCTGCTT"}
    EXP

    assert_equal(expected, collect_result.chomp)
  end

  test 'BioDSL::Pipeline::ClipPrimer with reverse end match returns OK' do
    @output.write(SEQ: 'gactgaTCGTATGCCGTCTTCTGCTT')
    @output.close
    @p.clip_primer(primer: 'TCGTATGCCGTCTTCTGCTT', direction: :reverse).
      run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '').delete("\n")
      |{:SEQ=>"gactga",
      | :SEQ_LEN=>6,
      | :CLIP_PRIMER_DIR=>"REVERSE",
      | :CLIP_PRIMER_POS=>6,
      | :CLIP_PRIMER_LEN=>20,
      | :CLIP_PRIMER_PAT=>"TCGTATGCCGTCTTCTGCTT"}
    EXP

    assert_equal(expected, collect_result.chomp)
  end

  test 'BioDSL::Pipeline::ClipPrimer with forward middle match and ' \
    'reverse_complement returns correctly' do
    @output.write(SEQ: 'actgactgaTCGTATGCCGTCTTCTGCTTactacgt')
    @output.close
    @p.clip_primer(primer: 'AAGCAGAAGACGGCATACGA', direction: :forward,
                   reverse_complement: true)
    @p.run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '').delete("\n")
      |{:SEQ=>"actacgt",
      | :SEQ_LEN=>7,
      | :CLIP_PRIMER_DIR=>"FORWARD",
      | :CLIP_PRIMER_POS=>9,
      | :CLIP_PRIMER_LEN=>20,
      | :CLIP_PRIMER_PAT=>"TCGTATGCCGTCTTCTGCTT"}
    EXP

    assert_equal(expected, collect_result.chomp)
  end

  test 'BioDSL::Pipeline::ClipPrimer with reverse middle match and ' \
    'reverse_complement returns correctly' do
    @output.write(SEQ: 'actgactgaTCGTATGCCGTCTTCTGCTTactacgt')
    @output.close
    @p.clip_primer(primer: 'AAGCAGAAGACGGCATACGA', direction: :reverse,
                   reverse_complement: true)
    @p.run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '').delete("\n")
      |{:SEQ=>"actgactga",
      | :SEQ_LEN=>9,
      | :CLIP_PRIMER_DIR=>"REVERSE",
      | :CLIP_PRIMER_POS=>9,
      | :CLIP_PRIMER_LEN=>20,
      | :CLIP_PRIMER_PAT=>"TCGTATGCCGTCTTCTGCTT"}
    EXP

    assert_equal(expected, collect_result.chomp)
  end

  test 'BioDSL::Pipeline::ClipPrimer with forward middle miss and ' \
    'search_distance returns correctly' do
    @output.write(SEQ: 'actgactgaTCGTATGCCGTCTTCTGCTTactacgt')
    @output.close
    @p.clip_primer(primer: 'TCGTATGCCGTCTTCTGCTT', direction: :forward,
                   search_distance: 28)
    @p.run(input: @input, output: @output2)

    expected = '{:SEQ=>"actgactgaTCGTATGCCGTCTTCTGCTTactacgt"}'

    assert_equal(expected, collect_result.chomp)
  end

  test 'BioDSL::Pipeline::ClipPrimer with forward middle match and ' \
    'search_distance returns correctly' do
    @output.write(SEQ: 'actgactgaTCGTATGCCGTCTTCTGCTTactacgt')
    @output.close
    @p.clip_primer(primer: 'TCGTATGCCGTCTTCTGCTT', direction: :forward,
                   search_distance: 29)
    @p.run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '').delete("\n")
      |{:SEQ=>"actacgt",
      | :SEQ_LEN=>7,
      | :CLIP_PRIMER_DIR=>"FORWARD",
      | :CLIP_PRIMER_POS=>9,
      | :CLIP_PRIMER_LEN=>20,
      | :CLIP_PRIMER_PAT=>"TCGTATGCCGTCTTCTGCTT"}
    EXP

    assert_equal(expected, collect_result.chomp)
  end

  test 'BioDSL::Pipeline::ClipPrimer with reverse middle miss and ' \
    'search_distance returns correctly' do
    @output.write(SEQ: 'actgactgaTCGTATGCCGTCTTCTGCTTactacgt')
    @output.close
    @p.clip_primer(primer: 'TCGTATGCCGTCTTCTGCTT', direction: :reverse,
                   search_distance: 26).run(input: @input, output: @output2)

    expected = '{:SEQ=>"actgactgaTCGTATGCCGTCTTCTGCTTactacgt"}'

    assert_equal(expected, collect_result.chomp)
  end

  test 'BioDSL::Pipeline::ClipPrimer with reverse middle match and ' \
    'search_distance returns correctly' do
    @output.write(SEQ: 'actgactgaTCGTATGCCGTCTTCTGCTTactacgt')
    @output.close
    @p.clip_primer(primer: 'TCGTATGCCGTCTTCTGCTT', direction: :reverse,
                   search_distance: 27).run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '').delete("\n")
      |{:SEQ=>"actgactga",
      | :SEQ_LEN=>9,
      | :CLIP_PRIMER_DIR=>"REVERSE",
      | :CLIP_PRIMER_POS=>9,
      | :CLIP_PRIMER_LEN=>20,
      | :CLIP_PRIMER_PAT=>"TCGTATGCCGTCTTCTGCTT"}
    EXP

    assert_equal(expected, collect_result.chomp)
  end

  test 'BioDSL::Pipeline::ClipPrimer with forward match and ' \
    'search_distance longer than sequence returns correctly' do
    @output.write(SEQ: 'actgactgaTCGTATGCCGTCTTCTGCTTactacgt')
    @output.close
    @p.clip_primer(primer: 'TCGTATGCCGTCTTCTGCTT', direction: :forward,
                   search_distance: 70).run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '').delete("\n")
      |{:SEQ=>"actacgt",
      | :SEQ_LEN=>7,
      | :CLIP_PRIMER_DIR=>"FORWARD",
      | :CLIP_PRIMER_POS=>9,
      | :CLIP_PRIMER_LEN=>20,
      | :CLIP_PRIMER_PAT=>"TCGTATGCCGTCTTCTGCTT"}
    EXP

    assert_equal(expected, collect_result.chomp)
  end

  test 'BioDSL::Pipeline::ClipPrimer with reverse match and ' \
    'search_distance longer than sequence returns correctly' do
    @output.write(SEQ: 'actgactgaTCGTATGCCGTCTTCTGCTTactacgt')
    @output.close
    @p.clip_primer(primer: 'TCGTATGCCGTCTTCTGCTT', direction: :reverse,
                   search_distance: 70).run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '').delete("\n")
      |{:SEQ=>"actgactga",
      | :SEQ_LEN=>9,
      | :CLIP_PRIMER_DIR=>"REVERSE",
      | :CLIP_PRIMER_POS=>9,
      | :CLIP_PRIMER_LEN=>20,
      | :CLIP_PRIMER_PAT=>"TCGTATGCCGTCTTCTGCTT"}
    EXP

    assert_equal(expected, collect_result.chomp)
  end

  test 'BioDSL::Pipeline::ClipPrimer with sequence length shorter than ' \
    'pattern returns correctly' do
    @output.write(SEQ: 'actgactgaTC')
    @output.close
    @p.clip_primer(primer: 'TCGTATGCCGTCTTCTGCTT', direction: :forward).
      run(input: @input, output: @output2)

    expected = '{:SEQ=>"actgactgaTC"}'

    assert_equal(expected, collect_result.chomp)
  end

  test 'BioDSL::Pipeline::ClipPrimer with sequence length 0 returns OK' do
    @output.write(SEQ: '')
    @output.close
    @p.clip_primer(primer: 'TCGTATGCCGTCTTCTGCTT', direction: :forward).
      run(input: @input, output: @output2)

    expected = '{:SEQ=>""}'

    assert_equal(expected, collect_result.chomp)
  end
end
