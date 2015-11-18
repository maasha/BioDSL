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

# Test class for MaskSeq.
#
# rubocop:disable Metrics/LineLength
class TestMaskSeq < Test::Unit::TestCase
  def setup
    @input, @output   = BioDSL::Stream.pipe
    @input2, @output2 = BioDSL::Stream.pipe

    hash = {
      SEQ_NAME: 'test',
      SEQ: 'gatcgatcgtacgagcagcatctgacgtatcgatcatgcagtctacgacgagcatgctagctag',
      SEQ_LEN: 82,
      SCORES: '!"#$%&()*+,-013456;<=>?@ABCDEIIHGCBA@?>=<;:9843210/.-,+*)(&%$III'
    }

    @output.write hash
    @output.close

    @p = BioDSL::Pipeline.new
  end

  test 'BioDSL::Pipeline::MaskSeq with invalid options raises' do
    assert_raise(BioDSL::OptionError) { @p.mask_seq(foo: 'bar') }
  end

  test 'BioDSL::Pipeline::MaskSeq with valid options don\'t raise' do
    assert_nothing_raised { @p.mask_seq(mask: :hard) }
  end

  test 'BioDSL::Pipeline::MaskSeq with mask: :soft returns correctly' do
    @p.mask_seq.run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:SEQ_NAME=>"test",
      | :SEQ=>"gatcgatcgtacgagcAGCATCTGACGTATCGATCATGCAGTCTAcgacgagcatgctagcTAG",
      | :SEQ_LEN=>64,
      | :SCORES=>"!\\\"\\\#$%&()*+,-013456;<=>?@ABCDEIIHGCBA@?>=<;:9843210/.-,+*)(&%$III"}
    EXP

    assert_equal(expected.delete("\n"), collect_result.delete("\n"))
  end

  test 'BioDSL::Pipeline::MaskSeq with mask: :hard returns correctly' do
    @p.mask_seq(mask: 'hard').run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:SEQ_NAME=>"test",
      | :SEQ=>"NNNNNNNNNNNNNNNNAGCATCTGACGTATCGATCATGCAGTCTANNNNNNNNNNNNNNNNTAG",
      | :SEQ_LEN=>64,
      | :SCORES=>"!\\\"\\\#$%&()*+,-013456;<=>?@ABCDEIIHGCBA@?>=<;:9843210/.-,+*)(&%$III"}
    EXP

    assert_equal(expected.delete("\n"), collect_result.delete("\n"))
  end

  test 'BioDSL::Pipeline::MaskSeq status returns correctly' do
    @p.mask_seq(mask: 'hard').run(input: @input, output: @output2)

    assert_equal(1, @p.status.first[:records_in])
    assert_equal(1, @p.status.first[:records_out])
    assert_equal(1, @p.status.first[:sequences_in])
    assert_equal(1, @p.status.first[:sequences_out])
    assert_equal(64, @p.status.first[:residues_in])
    assert_equal(64, @p.status.first[:residues_out])
  end
end
