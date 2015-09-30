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

# Test class for DereplicateSeq.
class TestDereplicateSeq < Test::Unit::TestCase
  def setup
    @input, @output   = BioDSL::Stream.pipe
    @input2, @output2 = BioDSL::Stream.pipe

    @output.write(SEQ_NAME: 'test1', SEQ: 'ATCG')
    @output.write(SEQ_NAME: 'test2', SEQ: 'ATCG')
    @output.write(SEQ_NAME: 'test3', SEQ: 'atcg')
    @output.write(SEQ_NAME: 'test4', SEQ: 'GCTA')
    @output.write(FISH: 'eel')
    @output.close

    @p = BioDSL::Pipeline.new
  end

  test 'BioDSL::Pipeline::DereplicateSeq with invalid options raises' do
    assert_raise(BioDSL::OptionError) { @p.dereplicate_seq(foo: 'bar') }
  end

  test 'BioDSL::Pipeline::DereplicateSeq with valid options don\'t raise' do
    assert_nothing_raised { @p.dereplicate_seq(ignore_case: true) }
  end

  test 'BioDSL::Pipeline::DereplicateSeq returns correctly' do
    @p.dereplicate_seq.run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:FISH=>"eel"}
      |{:SEQ_NAME=>"test1", :SEQ=>"ATCG", :SEQ_COUNT=>2}
      |{:SEQ_NAME=>"test3", :SEQ=>"atcg", :SEQ_COUNT=>1}
      |{:SEQ_NAME=>"test4", :SEQ=>"GCTA", :SEQ_COUNT=>1}
    EXP

    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::DereplicateSeq status returns correctly' do
    @p.dereplicate_seq.run(input: @input, output: @output2)

    assert_equal(5,  @p.status.first[:records_in])
    assert_equal(4,  @p.status.first[:records_out])
    assert_equal(4,  @p.status.first[:sequences_in])
    assert_equal(3,  @p.status.first[:sequences_out])
    assert_equal(16, @p.status.first[:residues_in])
    assert_equal(12, @p.status.first[:residues_out])
  end

  test 'BioDSL::Pipeline::DereplicateSeq with ignore_case returns OK' do
    @p.dereplicate_seq(ignore_case: true).run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:FISH=>"eel"}
      |{:SEQ_NAME=>"test1", :SEQ=>"ATCG", :SEQ_COUNT=>3}
      |{:SEQ_NAME=>"test4", :SEQ=>"GCTA", :SEQ_COUNT=>1}
    EXP

    assert_equal(expected, collect_result)
  end
end
