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
# This software is part of BioDSL (http://maasha.github.io/BioDSL).            #
#                                                                              #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

require 'test/helper'

# Test class for AssemblePairs.
# rubocop:disable ClassLength
class TestAssemblePairs < Test::Unit::TestCase
  # rubocop:disable MethodLength
  def setup
    @input, @output   = BioDSL::Stream.pipe
    @input2, @output2 = BioDSL::Stream.pipe

    @output.write(SEQ_NAME: 'test1/1', SEQ: 'aaaaaaaagagtcat',
                  SCORES: 'IIIIIIIIIIIIIII', SEQ_LEN: 15)
    @output.write(SEQ_NAME: 'test1/2', SEQ: 'gagtcataaaaaaaa',
                  SCORES: '!!!!!!!!!!!!!!!', SEQ_LEN: 15)
    @output.write(SEQ_NAME: 'test2/1', SEQ: 'aaaaaaaagagGcaG',
                  SCORES: 'IIIIIIIIIIIIIII', SEQ_LEN: 15)
    @output.write(SEQ_NAME: 'test2/2', SEQ: 'gagtcataaaaaaaa',
                  SCORES: '!!!!!!!!!!!!!!!', SEQ_LEN: 15)
    @output.write(SEQ_NAME: 'test3/1', SEQ: 'aaaaaaaagagtcat',
                  SCORES: 'IIIIIIIIIIIIIII', SEQ_LEN: 15)
    @output.write(SEQ_NAME: 'test3/2', SEQ: 'ttttttttatgactc',
                  SCORES: '!!!!!!!!!!!!!!!', SEQ_LEN: 15)
    @output.write(SEQ_NAME: 'test4/1', SEQ: 'aaaaaaaaaaaaaaa',
                  SCORES: 'IIIIIIIIIIIIIII', SEQ_LEN: 15)
    @output.write(SEQ_NAME: 'test4/2', SEQ: 'ggggggggggggggg',
                  SCORES: '!!!!!!!!!!!!!!!', SEQ_LEN: 15)
    @output.write(FOO: 'SEQ')

    @output.close

    @p = BioDSL::Pipeline.new
  end

  test 'BioDSL::Pipeline::AssemblePairs with invalid options raises' do
    assert_raise(BioDSL::OptionError) { @p.assemble_pairs(foo: 'bar') }
  end

  test 'BioDSL::Pipeline::AssemblePairs with allow_unassembled and ' \
    'merge_unassembled raises' do
    assert_raise(BioDSL::OptionError) do
      @p.assemble_pairs(allow_unassembled: true, merge_unassembled: true)
    end
  end

  test 'BioDSL::Pipeline::AssemblePairs with valid options don\'t raise' do
    assert_nothing_raised { @p.assemble_pairs(reverse_complement: true) }
  end

  test 'BioDSL::Pipeline::AssemblePairs returns correctly' do
    @p.assemble_pairs.run(input: @input, output: @output2)
    expected = <<-EXP.gsub(/\s+\|/, '')
      |{:SEQ_NAME=>"test1/1:overlap=7:hamming=0",
      | :SEQ=>"aaaaaaaaGAGTCATaaaaaaaa",
      | :SEQ_LEN=>23,
      | :SCORES=>"IIIIIIII5555555!!!!!!!!",
      | :OVERLAP_LEN=>7,
      | :HAMMING_DIST=>0}
      |{:SEQ_NAME=>"test2/1:overlap=3:hamming=1",
      | :SEQ=>"aaaaaaaagaggCAGtcataaaaaaaa",
      | :SEQ_LEN=>27,
      | :SCORES=>"IIIIIIIIIIII555!!!!!!!!!!!!",
      | :OVERLAP_LEN=>3,
      | :HAMMING_DIST=>1}
      |{:SEQ_NAME=>"test3/1:overlap=1:hamming=0",
      | :SEQ=>"aaaaaaaagagtcaTtttttttatgactc",
      | :SEQ_LEN=>29,
      | :SCORES=>"IIIIIIIIIIIIII5!!!!!!!!!!!!!!",
      | :OVERLAP_LEN=>1,
      | :HAMMING_DIST=>0}
      |{:FOO=>"SEQ"}
    EXP

    assert_equal(expected.delete("\n"), collect_result.delete("\n"))
  end

  test 'BioDSL::Pipeline::AssemblePairs status returns correctly' do
    @p.assemble_pairs.run(input: @input, output: @output2)

    assert_equal(10,  @p.status.first[:records_in])
    assert_equal(4,   @p.status.first[:records_out])
    assert_equal(8,   @p.status.first[:sequences_in])
    assert_equal(8,   @p.status.first[:sequences_in])
    assert_equal(120, @p.status.first[:residues_in])
    assert_equal(120, @p.status.first[:residues_in])
  end

  test 'BioDSL::Pipeline::AssemblePairs with merge_unassembled: true ' \
    'returns correctly' do
    @p.assemble_pairs(merge_unassembled: true).
      run(input: @input, output: @output2)
    expected = <<-EXP.gsub(/\s+\|/, '')
      |{:SEQ_NAME=>"test1/1:overlap=7:hamming=0",
      | :SEQ=>"aaaaaaaaGAGTCATaaaaaaaa",
      | :SEQ_LEN=>23,
      | :SCORES=>"IIIIIIII5555555!!!!!!!!",
      | :OVERLAP_LEN=>7,
      | :HAMMING_DIST=>0}
      |{:SEQ_NAME=>"test2/1:overlap=3:hamming=1",
      | :SEQ=>"aaaaaaaagaggCAGtcataaaaaaaa",
      | :SEQ_LEN=>27,
      | :SCORES=>"IIIIIIIIIIII555!!!!!!!!!!!!",
      | :OVERLAP_LEN=>3, :HAMMING_DIST=>1}
      |{:SEQ_NAME=>"test3/1:overlap=1:hamming=0",
      | :SEQ=>"aaaaaaaagagtcaTtttttttatgactc",
      | :SEQ_LEN=>29,
      | :SCORES=>"IIIIIIIIIIIIII5!!!!!!!!!!!!!!",
      | :OVERLAP_LEN=>1,
      | :HAMMING_DIST=>0}
      |{:SEQ_NAME=>"test4/1",
      | :SEQ=>"aaaaaaaaaaaaaaaggggggggggggggg",
      | :SEQ_LEN=>30,
      | :SCORES=>"IIIIIIIIIIIIIII!!!!!!!!!!!!!!!",
      | :OVERLAP_LEN=>0,
      | :HAMMING_DIST=>30}
      |{:FOO=>"SEQ"}
    EXP

    assert_equal(expected.delete("\n"), collect_result.delete("\n"))
  end

  test 'BioDSL::Pipeline::AssemblePairs with :mismatch_percent returns OK' do
    @p.assemble_pairs(mismatch_percent: 0).run(input: @input, output: @output2)
    expected = <<-EXP.gsub(/\s+\|/, '')
      |{:SEQ_NAME=>"test1/1:overlap=7:hamming=0",
      | :SEQ=>"aaaaaaaaGAGTCATaaaaaaaa",
      | :SEQ_LEN=>23,
      | :SCORES=>"IIIIIIII5555555!!!!!!!!",
      | :OVERLAP_LEN=>7,
      | :HAMMING_DIST=>0}
      |{:SEQ_NAME=>"test2/1:overlap=1:hamming=0",
      | :SEQ=>"aaaaaaaagaggcaGagtcataaaaaaaa",
      | :SEQ_LEN=>29,
      | :SCORES=>"IIIIIIIIIIIIII5!!!!!!!!!!!!!!",
      | :OVERLAP_LEN=>1,
      | :HAMMING_DIST=>0}
      |{:SEQ_NAME=>"test3/1:overlap=1:hamming=0",
      | :SEQ=>"aaaaaaaagagtcaTtttttttatgactc",
      | :SEQ_LEN=>29,
      | :SCORES=>"IIIIIIIIIIIIII5!!!!!!!!!!!!!!",
      | :OVERLAP_LEN=>1,
      | :HAMMING_DIST=>0}
      |{:FOO=>"SEQ"}
    EXP

    assert_equal(expected.delete("\n"), collect_result.delete("\n"))
  end

  test 'BioDSL::Pipeline::AssemblePairs with :overlap_min returns OK' do
    @p.assemble_pairs(overlap_min: 5).run(input: @input, output: @output2)
    expected = <<-EXP.gsub(/\s+\|/, '')
      |{:SEQ_NAME=>"test1/1:overlap=7:hamming=0",
      | :SEQ=>"aaaaaaaaGAGTCATaaaaaaaa",
      | :SEQ_LEN=>23,
      | :SCORES=>"IIIIIIII5555555!!!!!!!!",
      | :OVERLAP_LEN=>7,
      | :HAMMING_DIST=>0}
      |{:FOO=>"SEQ"}
    EXP

    assert_equal(expected.delete("\n"), collect_result.delete("\n"))
  end

  test 'BioDSL::Pipeline::AssemblePairs with :overlap_min and ' \
    'merge_unassembled: true returns correctly' do
    @p.assemble_pairs(overlap_min: 5, merge_unassembled: true).
      run(input: @input, output: @output2)
    expected = <<-EXP.gsub(/\s+\|/, '')
      |{:SEQ_NAME=>"test1/1:overlap=7:hamming=0",
      | :SEQ=>"aaaaaaaaGAGTCATaaaaaaaa",
      | :SEQ_LEN=>23, :SCORES=>"IIIIIIII5555555!!!!!!!!",
      | :OVERLAP_LEN=>7,
      | :HAMMING_DIST=>0}
      |{:SEQ_NAME=>"test2/1",
      | :SEQ=>"aaaaaaaagagGcaGgagtcataaaaaaaa",
      | :SEQ_LEN=>30,
      | :SCORES=>"IIIIIIIIIIIIIII!!!!!!!!!!!!!!!",
      | :OVERLAP_LEN=>0,
      | :HAMMING_DIST=>30}
      |{:SEQ_NAME=>"test3/1",
      | :SEQ=>"aaaaaaaagagtcatttttttttatgactc",
      | :SEQ_LEN=>30,
      | :SCORES=>"IIIIIIIIIIIIIII!!!!!!!!!!!!!!!",
      | :OVERLAP_LEN=>0,
      | :HAMMING_DIST=>30}
      |{:SEQ_NAME=>"test4/1",
      | :SEQ=>"aaaaaaaaaaaaaaaggggggggggggggg",
      | :SEQ_LEN=>30,
      | :SCORES=>"IIIIIIIIIIIIIII!!!!!!!!!!!!!!!",
      | :OVERLAP_LEN=>0,
      | :HAMMING_DIST=>30}
      |{:FOO=>"SEQ"}
    EXP

    assert_equal(expected.delete("\n"), collect_result.delete("\n"))
  end

  test 'BioDSL::Pipeline::AssemblePairs with :overlap_max returns OK' do
    @p.assemble_pairs(overlap_max: 5).run(input: @input, output: @output2)
    expected = <<-EXP.gsub(/\s+\|/, '')
      |{:SEQ_NAME=>"test2/1:overlap=3:hamming=1",
      | :SEQ=>"aaaaaaaagaggCAGtcataaaaaaaa",
      | :SEQ_LEN=>27,
      | :SCORES=>"IIIIIIIIIIII555!!!!!!!!!!!!",
      | :OVERLAP_LEN=>3,
      | :HAMMING_DIST=>1}
      |{:SEQ_NAME=>"test3/1:overlap=1:hamming=0",
      | :SEQ=>"aaaaaaaagagtcaTtttttttatgactc",
      | :SEQ_LEN=>29,
      | :SCORES=>"IIIIIIIIIIIIII5!!!!!!!!!!!!!!",
      | :OVERLAP_LEN=>1,
      | :HAMMING_DIST=>0}
      |{:FOO=>"SEQ"}
    EXP

    assert_equal(expected.delete("\n"), collect_result.delete("\n"))
  end

  test 'BioDSL::Pipeline::AssemblePairs with :reverse_complement ' \
    'returns correctly' do
    @p.assemble_pairs(reverse_complement: true).
      run(input: @input, output: @output2)
    expected = <<-EXP.gsub(/\s+\|/, '')
      |{:SEQ_NAME=>"test1/1:overlap=1:hamming=0",
      | :SEQ=>"aaaaaaaagagtcaTtttttttatgactc",
      | :SEQ_LEN=>29,
      | :SCORES=>"IIIIIIIIIIIIII5!!!!!!!!!!!!!!",
      | :OVERLAP_LEN=>1,
      | :HAMMING_DIST=>0}
      |{:SEQ_NAME=>"test3/1:overlap=7:hamming=0",
      | :SEQ=>"aaaaaaaaGAGTCATaaaaaaaa",
      | :SEQ_LEN=>23,
      | :SCORES=>"IIIIIIII5555555!!!!!!!!",
      | :OVERLAP_LEN=>7,
      | :HAMMING_DIST=>0}
      |{:FOO=>"SEQ"}
    EXP

    assert_equal(expected.delete("\n"), collect_result.delete("\n"))
  end

  test 'BioDSL::Pipeline::AssemblePairs with :reverse_complement and ' \
    ':overlap_min returns correctly' do
    @p.assemble_pairs(reverse_complement: true, overlap_min: 5).
      run(input: @input, output: @output2)
    expected = <<-EXP.gsub(/\s+\|/, '')
      |{:SEQ_NAME=>"test3/1:overlap=7:hamming=0",
      | :SEQ=>"aaaaaaaaGAGTCATaaaaaaaa",
      | :SEQ_LEN=>23,
      | :SCORES=>"IIIIIIII5555555!!!!!!!!",
      | :OVERLAP_LEN=>7,
      | :HAMMING_DIST=>0}
      |{:FOO=>"SEQ"}
    EXP

    assert_equal(expected.delete("\n"), collect_result.delete("\n"))
  end

  test 'BioDSL::Pipeline::AssemblePairs with :reverse_complement and ' \
    'overlap_max returns correctly' do
    @p.assemble_pairs(reverse_complement: true, overlap_max: 5).
      run(input: @input, output: @output2)
    expected = <<-EXP.gsub(/\s+\|/, '')
      |{:SEQ_NAME=>"test1/1:overlap=1:hamming=0",
      | :SEQ=>"aaaaaaaagagtcaTtttttttatgactc",
      | :SEQ_LEN=>29,
      | :SCORES=>"IIIIIIIIIIIIII5!!!!!!!!!!!!!!",
      | :OVERLAP_LEN=>1,
      | :HAMMING_DIST=>0}
      |{:FOO=>"SEQ"}
    EXP

    assert_equal(expected.delete("\n"), collect_result.delete("\n"))
  end

  test 'BioDSL::Pipeline::AssemblePairs with :reverse_complement and ' \
    ':overlap_min and :merge_unassembled returns correctly' do
    @p.assemble_pairs(reverse_complement: true,
                      overlap_min: 5, merge_unassembled: true)
    @p.run(input: @input, output: @output2)
    expected = <<-EXP.gsub(/\s+\|/, '')
      |{:SEQ_NAME=>"test1/1",
      | :SEQ=>"aaaaaaaagagtcatttttttttatgactc",
      | :SEQ_LEN=>30,
      | :SCORES=>"IIIIIIIIIIIIIII!!!!!!!!!!!!!!!",
      | :OVERLAP_LEN=>0,
      | :HAMMING_DIST=>30}
      |{:SEQ_NAME=>"test2/1",
      | :SEQ=>"aaaaaaaagagGcaGttttttttatgactc",
      | :SEQ_LEN=>30,
      | :SCORES=>"IIIIIIIIIIIIIII!!!!!!!!!!!!!!!",
      | :OVERLAP_LEN=>0,
      | :HAMMING_DIST=>30}
      |{:SEQ_NAME=>"test3/1:overlap=7:hamming=0",
      | :SEQ=>"aaaaaaaaGAGTCATaaaaaaaa",
      | :SEQ_LEN=>23,
      | :SCORES=>"IIIIIIII5555555!!!!!!!!",
      | :OVERLAP_LEN=>7,
      | :HAMMING_DIST=>0}
      |{:SEQ_NAME=>"test4/1",
      | :SEQ=>"aaaaaaaaaaaaaaaccccccccccccccc",
      | :SEQ_LEN=>30,
      | :SCORES=>"IIIIIIIIIIIIIII!!!!!!!!!!!!!!!",
      | :OVERLAP_LEN=>0,
      | :HAMMING_DIST=>30}
      |{:FOO=>"SEQ"}
    EXP

    assert_equal(expected.delete("\n"), collect_result.delete("\n"))
  end

  test 'BioDSL::Pipeline::AssemblePairs with allow_unassembled returns OK' do
    @p.assemble_pairs(overlap_min: 100, allow_unassembled: true).
      run(input: @input, output: @output2)
    expected = <<-EXP.gsub(/\s+\|/, '')
      |{:SEQ_NAME=>"test1/1",
      | :SEQ=>"aaaaaaaagagtcat",
      | :SEQ_LEN=>15,
      | :SCORES=>"IIIIIIIIIIIIIII",
      | :OVERLAP_LEN=>0,
      | :HAMMING_DIST=>15}
      |{:SEQ_NAME=>"test1/2",
      | :SEQ=>"gagtcataaaaaaaa",
      | :SEQ_LEN=>15,
      | :SCORES=>"!!!!!!!!!!!!!!!",
      | :OVERLAP_LEN=>0,
      | :HAMMING_DIST=>15}
      |{:SEQ_NAME=>"test2/1",
      | :SEQ=>"aaaaaaaagagGcaG",
      | :SEQ_LEN=>15,
      | :SCORES=>"IIIIIIIIIIIIIII",
      | :OVERLAP_LEN=>0,
      | :HAMMING_DIST=>15}
      |{:SEQ_NAME=>"test2/2",
      | :SEQ=>"gagtcataaaaaaaa",
      | :SEQ_LEN=>15,
      | :SCORES=>"!!!!!!!!!!!!!!!",
      | :OVERLAP_LEN=>0,
      | :HAMMING_DIST=>15}
      |{:SEQ_NAME=>"test3/1",
      | :SEQ=>"aaaaaaaagagtcat",
      | :SEQ_LEN=>15,
      | :SCORES=>"IIIIIIIIIIIIIII",
      | :OVERLAP_LEN=>0,
      | :HAMMING_DIST=>15}
      |{:SEQ_NAME=>"test3/2",
      | :SEQ=>"ttttttttatgactc",
      | :SEQ_LEN=>15,
      | :SCORES=>"!!!!!!!!!!!!!!!",
      | :OVERLAP_LEN=>0,
      | :HAMMING_DIST=>15}
      |{:SEQ_NAME=>"test4/1",
      | :SEQ=>"aaaaaaaaaaaaaaa",
      | :SEQ_LEN=>15,
      | :SCORES=>"IIIIIIIIIIIIIII",
      | :OVERLAP_LEN=>0,
      | :HAMMING_DIST=>15}
      |{:SEQ_NAME=>"test4/2",
      | :SEQ=>"ggggggggggggggg",
      | :SEQ_LEN=>15,
      | :SCORES=>"!!!!!!!!!!!!!!!",
      | :OVERLAP_LEN=>0,
      | :HAMMING_DIST=>15}
      |{:FOO=>"SEQ"}
    EXP

    assert_equal(expected.delete("\n"), collect_result.delete("\n"))
  end

  test 'BioDSL::Pipeline::AssemblePairs with allow_unassembled and ' \
    'reverse_complement returns OK' do
    @p.assemble_pairs(overlap_min: 100, allow_unassembled: true,
                      reverse_complement: true)
    @p.run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/\s+\|/, '')
      |{:SEQ_NAME=>"test1/1",
      | :SEQ=>"aaaaaaaagagtcat",
      | :SEQ_LEN=>15,
      | :SCORES=>"IIIIIIIIIIIIIII",
      | :OVERLAP_LEN=>0,
      | :HAMMING_DIST=>15}
      |{:SEQ_NAME=>"test1/2",
      | :SEQ=>"ttttttttatgactc",
      | :SEQ_LEN=>15,
      | :SCORES=>"!!!!!!!!!!!!!!!",
      | :OVERLAP_LEN=>0,
      | :HAMMING_DIST=>15}
      |{:SEQ_NAME=>"test2/1",
      | :SEQ=>"aaaaaaaagagGcaG",
      | :SEQ_LEN=>15,
      | :SCORES=>"IIIIIIIIIIIIIII",
      | :OVERLAP_LEN=>0,
      | :HAMMING_DIST=>15}
      |{:SEQ_NAME=>"test2/2",
      | :SEQ=>"ttttttttatgactc",
      | :SEQ_LEN=>15,
      | :SCORES=>"!!!!!!!!!!!!!!!",
      | :OVERLAP_LEN=>0,
      | :HAMMING_DIST=>15}
      |{:SEQ_NAME=>"test3/1",
      | :SEQ=>"aaaaaaaagagtcat",
      | :SEQ_LEN=>15,
      | :SCORES=>"IIIIIIIIIIIIIII",
      | :OVERLAP_LEN=>0,
      | :HAMMING_DIST=>15}
      |{:SEQ_NAME=>"test3/2",
      | :SEQ=>"gagtcataaaaaaaa",
      | :SEQ_LEN=>15,
      | :SCORES=>"!!!!!!!!!!!!!!!",
      | :OVERLAP_LEN=>0,
      | :HAMMING_DIST=>15}
      |{:SEQ_NAME=>"test4/1",
      | :SEQ=>"aaaaaaaaaaaaaaa",
      | :SEQ_LEN=>15,
      | :SCORES=>"IIIIIIIIIIIIIII",
      | :OVERLAP_LEN=>0,
      | :HAMMING_DIST=>15}
      |{:SEQ_NAME=>"test4/2",
      | :SEQ=>"ccccccccccccccc",
      | :SEQ_LEN=>15,
      | :SCORES=>"!!!!!!!!!!!!!!!",
      | :OVERLAP_LEN=>0,
      | :HAMMING_DIST=>15}
      |{:FOO=>"SEQ"}
    EXP

    assert_equal(expected.delete("\n"), collect_result.delete("\n"))
  end
end
