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

# Test class for MergeValues.
class TestMergeValues < Test::Unit::TestCase
  def setup
    @input, @output   = BioDSL::Stream.pipe
    @input2, @output2 = BioDSL::Stream.pipe

    @output.write(ID: 'FOO', COUNT: 10, SEQ: 'gataag')
    @output.write(ID: 'FOO', SEQ: 'gataag')
    @output.close

    @p = BioDSL::Pipeline.new
  end

  test 'BioDSL::Pipeline::MergeValues with invalid options raises' do
    assert_raise(BioDSL::OptionError) { @p.merge_values(foo: 'bar') }
  end

  test 'BioDSL::Pipeline::MergeValues with valid options don\'t raise' do
    assert_nothing_raised { @p.merge_values(keys: [:ID]) }
  end

  test 'BioDSL::Pipeline::MergeValues returns correctly' do
    @p.merge_values(keys: [:COUNT, :ID]).run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:ID=>"FOO", :COUNT=>"10_FOO", :SEQ=>"gataag"}
      |{:ID=>"FOO", :SEQ=>"gataag"}
    EXP

    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline::MergeValues status returns correctly' do
    @p.merge_values(keys: [:COUNT, :ID]).run(input: @input, output: @output2)

    assert_equal(2, @p.status.first[:records_in])
    assert_equal(2, @p.status.first[:records_out])
  end

  test 'BioDSL::Pipeline::MergeValues with :delimiter returns correctly' do
    @p.merge_values(keys: [:ID, :COUNT], delimiter: ':count=').
      run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:ID=>"FOO:count=10", :COUNT=>10, :SEQ=>"gataag"}
      |{:ID=>"FOO", :SEQ=>"gataag"}
    EXP

    assert_equal(expected, collect_result)
  end
end
