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
# This software is part of Biopieces (www.biopieces.org).                      #
#                                                                              #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

require 'test/helper'

# Test class for ReverseSeq.
class TestReverseSeq < Test::Unit::TestCase
  def setup
    @input, @output   = BioPieces::Stream.pipe
    @input2, @output2 = BioPieces::Stream.pipe

    hash = {
      SEQ_NAME: 'test',
      SEQ: 'gatcgatcgt',
      SEQ_LEN: 10,
      SCORES: 'ABCDEFGHII'
    }

    @output.write hash
    @output.close

    @p = BioPieces::Pipeline.new
  end

  test 'BioPieces::Pipeline::ReverseSeq with invalid options raises' do
    assert_raise(BioPieces::OptionError) { @p.reverse_seq(foo: 'bar') }
  end

  test 'BioPieces::Pipeline::ReverseSeq returns correctly' do
    @p.reverse_seq.run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:SEQ_NAME=>"test",
      | :SEQ=>"tgctagctag",
      | :SEQ_LEN=>10,
      | :SCORES=>"IIHGFEDCBA"}
    EXP

    assert_equal(expected.delete("\n"), collect_result.delete("\n"))
  end

  test 'BioPieces::Pipeline::ReverseSeq status returns correctly' do
    @p.reverse_seq.run(input: @input, output: @output2)

    assert_equal(1, @p.status.first[:records_in])
    assert_equal(1, @p.status.first[:records_out])
    assert_equal(1, @p.status.first[:sequences_in])
    assert_equal(1, @p.status.first[:sequences_out])
    assert_equal(10, @p.status.first[:residues_in])
    assert_equal(10, @p.status.first[:residues_out])
  end
end
