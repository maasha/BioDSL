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

# Test class for DegapSeq.
class TestDegapSeq < Test::Unit::TestCase
  def setup
    @input, @output   = BioDSL::Stream.pipe
    @input2, @output2 = BioDSL::Stream.pipe

    @p = BioDSL::Pipeline.new
  end

  test 'BioDSL::Pipeline::DegapSeq with invalid options raises' do
    assert_raise(BioDSL::OptionError) { @p.degap_seq(foo: 'bar') }
  end

  test 'BioDSL::Pipeline::DegapSeq with valid options don\'t raise' do
    assert_nothing_raised { @p.degap_seq(columns_only: true) }
  end

  test 'BioDSL::Pipeline::DegapSeq returns correctly' do
    @output.write(SEQ: 'AT--C.G~')
    @output.close
    @p.degap_seq.run(input: @input, output: @output2)

    expected = '{:SEQ=>"ATCG", :SEQ_LEN=>4}'

    assert_equal(expected, collect_result.chomp)
  end

  test 'BioDSL::Pipeline::DegapSeq status returns correctly' do
    @output.write(SEQ: 'AT--C.G~')
    @output.close
    @p.degap_seq.run(input: @input, output: @output2)

    assert_equal(1, @p.status.first[:records_in])
    assert_equal(1, @p.status.first[:records_out])
    assert_equal(1, @p.status.first[:sequences_in])
    assert_equal(1, @p.status.first[:sequences_out])
    assert_equal(8, @p.status.first[:residues_in])
    assert_equal(4, @p.status.first[:residues_out])
  end

  test 'BioDSL::Pipeline::DegapSeq with :columns_only and uneven seq ' \
    'lengths raises' do
    @output.write(SEQ: 'AT--C.G~')
    @output.write(SEQ: 'AT--C.G')
    @output.close
    assert_raise(BioDSL::SeqError) do
      @p.degap_seq(columns_only: true).run(input: @input, output: @output2)
    end
  end

  test 'BioDSL::Pipeline::DegapSeq with :columns_only returns correctly' do
    @output.write(SEQ: 'ATA-C.G~')
    @output.write(SEQ: 'AT--C.G.')
    @output.close
    @p.degap_seq(columns_only: true).run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:SEQ=>"ATACG", :SEQ_LEN=>5}
      |{:SEQ=>"AT-CG", :SEQ_LEN=>5}
    EXP

    assert_equal(expected, collect_result)
  end
end
