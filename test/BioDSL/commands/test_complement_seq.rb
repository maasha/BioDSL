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

# Test class for ComplementSeq.
class TestComplementSeq < Test::Unit::TestCase
  def setup
    @input, @output   = BioDSL::Stream.pipe
    @input2, @output2 = BioDSL::Stream.pipe

    @p = BioDSL::Pipeline.new
  end

  test 'BioDSL::Pipeline::ComplementSeq with invalid options raises' do
    assert_raise(BioDSL::OptionError) { @p.complement_seq(foo: 'bar') }
  end

  test 'BioDSL::Pipeline::ComplementSeq of DNA returns correctly' do
    @output.write(SEQ: 'gatcGATCGT')
    @output.close
    @p.complement_seq.run(input: @input, output: @output2)

    expected = '{:SEQ=>"ctagCTAGCA", :SEQ_LEN=>10}'

    assert_equal(expected, collect_result.chomp)
  end

  test 'BioDSL::Pipeline::ComplementSeq of RNA returns correctly' do
    @output.write(SEQ: 'gaucGAUCGU')
    @output.close
    @p.complement_seq.run(input: @input, output: @output2)

    expected = '{:SEQ=>"cuagCUAGCA", :SEQ_LEN=>10}'

    assert_equal(expected, collect_result.chomp)
  end

  test 'BioDSL::Pipeline::ComplementSeq status returns correctly' do
    @output.write(SEQ: 'gaucGAUCGU')
    @output.close
    @p.complement_seq.run(input: @input, output: @output2)

    assert_equal(1, @p.status.first[:records_in])
    assert_equal(1, @p.status.first[:records_out])
    assert_equal(1, @p.status.first[:sequences_in])
    assert_equal(1, @p.status.first[:sequences_out])
    assert_equal(10, @p.status.first[:residues_in])
    assert_equal(10, @p.status.first[:residues_out])
  end
end
