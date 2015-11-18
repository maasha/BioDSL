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

# Test class for TrimSeq.
class TestTrimSeq < Test::Unit::TestCase
  def setup
    @input, @output   = BioDSL::Stream.pipe
    @input2, @output2 = BioDSL::Stream.pipe

    hash = {
      SEQ_NAME: 'test',

      SEQ: 'gatcgatcgtacgagcagcatctgacgtatcgatcgttgtctacgacgagcatgctagctag',
      SEQ_LEN: 42,
      SCORES: %q[!"#$%&'()*+,-./0123456789:;<=>?@ABCDEF876543210/.-,+*)('&%$III]
    }

    @output.write hash
    @output.close

    @p = BioDSL::Pipeline.new
  end

  test 'BioDSL::Pipeline::TrimSeq with invalid options raises' do
    assert_raise(BioDSL::OptionError) { @p.trim_seq(foo: 'bar') }
  end

  test 'BioDSL::Pipeline::TrimSeq with valid options don\'t raise' do
    assert_nothing_raised { @p.trim_seq(mode: :left) }
  end

  test 'BioDSL::Pipeline::TrimSeq returns correctly' do
    @p.trim_seq.run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '').tr("\n", ' ')[0..-2]
      |{:SEQ_NAME=>"test",
      |:SEQ=>"tctgacgtatcgatcgttgtctacgacgagcatgctagctag",
      |:SEQ_LEN=>42,
      |:SCORES=>"56789:;<=>?@ABCDEF876543210/.-,+*)('&%$III"}
    EXP

    assert_equal(expected, collect_result.chomp)
  end

  test 'BioDSL::Pipeline::TrimSeq status returns correctly' do
    @p.trim_seq.run(input: @input, output: @output2)

    assert_equal(1,  @p.status.first[:records_in])
    assert_equal(1,  @p.status.first[:records_out])
    assert_equal(1,  @p.status.first[:sequences_in])
    assert_equal(1,  @p.status.first[:sequences_out])
    assert_equal(62, @p.status.first[:residues_in])
    assert_equal(42, @p.status.first[:residues_out])
  end

  test 'BioDSL::Pipeline::TrimSeq with :quality_min returns correctly' do
    @p.trim_seq(quality_min: 25).run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '').tr("\n", ' ')[0..-2]
      |{:SEQ_NAME=>"test",
      |:SEQ=>"cgtatcgatcgttgtctacgacgagcatgctagctag",
      |:SEQ_LEN=>37,
      |:SCORES=>":;<=>?@ABCDEF876543210/.-,+*)('&%$III"}
    EXP

    assert_equal(expected, collect_result.chomp)
  end

  test 'BioDSL::Pipeline::TrimSeq with mode: both: returns correctly' do
    @p.trim_seq(mode: :both).run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '').tr("\n", ' ')[0..-2]
      |{:SEQ_NAME=>"test",
      |:SEQ=>"tctgacgtatcgatcgttgtctacgacgagcatgctagctag",
      |:SEQ_LEN=>42,
      |:SCORES=>"56789:;<=>?@ABCDEF876543210/.-,+*)('&%$III"}
    EXP

    assert_equal(expected, collect_result.chomp)
  end

  test 'BioDSL::Pipeline::TrimSeq with mode: :left returns correctly' do
    @p.trim_seq(mode: :left).run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '').tr("\n", ' ')[0..-2]
      |{:SEQ_NAME=>"test",
      |:SEQ=>"tctgacgtatcgatcgttgtctacgacgagcatgctagctag",
      |:SEQ_LEN=>42,
      |:SCORES=>"56789:;<=>?@ABCDEF876543210/.-,+*)('&%$III"}
    EXP

    assert_equal(expected, collect_result.chomp)
  end

  # rubocop:disable LineLength
  test 'BioDSL::Pipeline::TrimSeq with mode: :right returns correctly' do
    @p.trim_seq(mode: :right).run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '').tr("\n", ' ')[0..-2]
      |{:SEQ_NAME=>"test",
      |:SEQ=>"gatcgatcgtacgagcagcatctgacgtatcgatcgttgtctacgacgagcatgctagctag",
      |:SEQ_LEN=>62,
      |:SCORES=>"!\\"\\#\$%&'()*+,-./0123456789:;<=>?@ABCDEF876543210/.-,+*)('&%$III"}
    EXP

    assert_equal(expected, collect_result.chomp)
  end

  test 'BioDSL::Pipeline::TrimSeq with :length_min returns correctly' do
    @p.trim_seq(length_min: 4).run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '').tr("\n", ' ')[0..-2]
      |{:SEQ_NAME=>"test",
      |:SEQ=>"tctgacgtatcgatcgttgtct",
      |:SEQ_LEN=>22,
      |:SCORES=>"56789:;<=>?@ABCDEF8765"}
    EXP

    assert_equal(expected, collect_result.chomp)
  end
end
