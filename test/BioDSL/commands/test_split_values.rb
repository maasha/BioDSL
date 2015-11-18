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

# Test class for SplitValues.
class TestSplitValues < Test::Unit::TestCase
  def setup
    @input, @output   = BioDSL::Stream.pipe
    @input2, @output2 = BioDSL::Stream.pipe

    @output.write(ID: 'FOO:count=10', SEQ: 'gataag')
    @output.write(ID: 'FOO_10_20', SEQ: 'gataag')
    @output.close

    @p = BioDSL::Pipeline.new
  end

  test 'BioDSL::Pipeline::SplitValues with invalid options raises' do
    assert_raise(BioDSL::OptionError) { @p.split_values(foo: 'bar') }
  end

  test 'BioDSL::Pipeline::SplitValues with valid options don\'t raise' do
    assert_nothing_raised { @p.split_values(key: :ID) }
  end

  test 'BioDSL::Pipeline::SplitValues returns correctly' do
    @p.split_values(key: :ID).run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:ID=>"FOO:count=10", :SEQ=>"gataag"}
      |{:ID=>"FOO_10_20", :SEQ=>"gataag", :ID_0=>"FOO", :ID_1=>10, :ID_2=>20}
    EXP

    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::SplitValues status returns correctly' do
    @p.split_values(key: :ID).run(input: @input, output: @output2)

    assert_equal(2, @p.status.first[:records_in])
    assert_equal(2, @p.status.first[:records_out])
  end

  test 'BioDSL::Pipeline::SplitValues with :delimiter returns correctly' do
    @p.split_values(key: 'ID', delimiter: ':count=').
      run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:ID=>"FOO:count=10", :SEQ=>"gataag", :ID_0=>"FOO", :ID_1=>10}
      |{:ID=>"FOO_10_20", :SEQ=>"gataag"}
    EXP

    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::SplitValues w. :delimiter and :keys returns OK' do
    @p.split_values(key: 'ID', keys: ['ID', :COUNT], delimiter: ':count=').
      run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:ID=>"FOO", :SEQ=>"gataag", :COUNT=>10}
      |{:ID=>"FOO_10_20", :SEQ=>"gataag"}
    EXP

    assert_equal(expected, collect_result)
  end
end
