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

# Test class for MergePairSeq.
class TestMergePairSeq < Test::Unit::TestCase
  # rubocop:disable MethodLength
  def setup
    @input, @output   = BioDSL::Stream.pipe
    @input2, @output2 = BioDSL::Stream.pipe

    [
      {SEQ_NAME: 'M01168:16:000000000-A1R9L:1:1101:14862:1868 1:N:0:14',
       SEQ: 'TGGGGAATATTGGACAATGG',
       SEQ_LEN: 20,
       SCORES: '<??????BDDDDDDDDGGGG'},
      {SEQ_NAME: 'M01168:16:000000000-A1R9L:1:1101:14862:1868 2:N:0:14',
       SEQ: 'CCTGTTTGCTACCCACGCTT',
       SEQ_LEN: 20,
       SCORES: '?????BB<-<BDDDDDFEEF'},
      {SEQ_NAME: 'M01168:16:000000000-A1R9L:1:1101:13906:2139 1:N:0:14',
       SEQ: 'TAGGGAATCTTGCACAATGG',
       SEQ_LEN: 20,
       SCORES: '<???9?BBBDBDDBDDFFFF'},
      {SEQ_NAME: 'M01168:16:000000000-A1R9L:1:1101:13906:2139 2:N:0:14',
       SEQ: 'ACTCTTCGCTACCCATGCTT',
       SEQ_LEN: 20,
       SCORES: ',5<??BB?DDABDBDDFFFF'},
      {SEQ_NAME: 'M01168:16:000000000-A1R9L:1:1101:14865:2158 1:N:0:14',
       SEQ: 'TAGGGAATCTTGCACAATGG',
       SEQ_LEN: 20,
       SCORES: '?????BBBBBDDBDDBFFFF'},
      {SEQ_NAME: 'M01168:16:000000000-A1R9L:1:1101:14865:2158 2:N:0:14',
       SEQ: 'CCTCTTCGCTACCCATGCTT',
       SEQ_LEN: 20,
       SCORES: '??,<??B?BB?BBBBBFF?F'}
    ].each do |record|
      @output.write record
    end

    @output.close

    @p = BioDSL::Pipeline.new
  end

  test 'BioDSL::Pipeline::MergePairSeq with invalid options raises' do
    assert_raise(BioDSL::OptionError) { @p.merge_pair_seq(foo: 'bar') }
  end

  test 'BioDSL::Pipeline::MergePairSeq returns correctly' do
    @p.merge_pair_seq.run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:SEQ_NAME=>"M01168:16:000000000-A1R9L:1:1101:14862:1868 1:N:0:14",
      | :SEQ=>"TGGGGAATATTGGACAATGGCCTGTTTGCTACCCACGCTT",
      | :SEQ_LEN=>40,
      | :SCORES=>"<??????BDDDDDDDDGGGG?????BB<-<BDDDDDFEEF",
      | :SEQ_LEN_LEFT=>20,
      | :SEQ_LEN_RIGHT=>20}
      |{:SEQ_NAME=>"M01168:16:000000000-A1R9L:1:1101:13906:2139 1:N:0:14",
      | :SEQ=>"TAGGGAATCTTGCACAATGGACTCTTCGCTACCCATGCTT",
      | :SEQ_LEN=>40,
      | :SCORES=>"<???9?BBBDBDDBDDFFFF,5<??BB?DDABDBDDFFFF",
      | :SEQ_LEN_LEFT=>20,
      | :SEQ_LEN_RIGHT=>20}
      |{:SEQ_NAME=>"M01168:16:000000000-A1R9L:1:1101:14865:2158 1:N:0:14",
      | :SEQ=>"TAGGGAATCTTGCACAATGGCCTCTTCGCTACCCATGCTT",
      | :SEQ_LEN=>40,
      | :SCORES=>"?????BBBBBDDBDDBFFFF??,<??B?BB?BBBBBFF?F",
      | :SEQ_LEN_LEFT=>20,
      | :SEQ_LEN_RIGHT=>20}
    EXP

    assert_equal(expected.delete("\n"), collect_result.delete("\n"))
  end

  test 'BioDSL::Pipeline::MergePairSeq status returns correctly' do
    @p.merge_pair_seq.run(input: @input, output: @output2)

    assert_equal(6, @p.status.first[:records_in])
    assert_equal(3, @p.status.first[:records_out])
    assert_equal(6, @p.status.first[:sequences_in])
    assert_equal(3, @p.status.first[:sequences_out])
    assert_equal(120, @p.status.first[:residues_in])
    assert_equal(120, @p.status.first[:residues_out])
  end
end
