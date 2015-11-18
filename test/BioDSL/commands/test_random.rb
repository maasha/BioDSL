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

# Test class for Random.
class TestRandom < Test::Unit::TestCase
  def setup
    @input, @output   = BioDSL::Stream.pipe
    @input2, @output2 = BioDSL::Stream.pipe

    [{TEST: 1},
     {TEST: 2},
     {TEST: 3},
     {TEST: 4},
     {TEST: 5},
     {TEST: 6}].each do |record|
      @output.write record
    end

    @output.close

    @p = BioDSL::Pipeline.new
  end

  test 'BioDSL::Pipeline#random with disallowed option raises' do
    assert_raise(BioDSL::OptionError) { @p.random(foo: 'bar') }
  end

  test 'BioDSL::Pipeline#random with allowed options don\'t raise' do
    assert_nothing_raised { @p.random(number: 2) }
  end

  test 'BioDSL::Pipeline#random returns correctly' do
    @p.random(number: 3).run(input: @input, output: @output2)
    size = 0
    @input2.map { size += 1 }

    assert_equal(3, size)
  end

  test 'BioDSL::Pipeline#random status returns correctly' do
    @p.random(number: 3).run(input: @input, output: @output2)

    assert_equal(6, @p.status.first[:records_in])
    assert_equal(3, @p.status.first[:records_out])
  end

  test 'BioDSL::Pipeline#random with pairs: true returns correctly' do
    @p.random(number: 4, pairs: true).run(input: @input, output: @output2)

    size = 0

    @input2.each_slice(2) do |record1, record2|
      assert_equal(record1[:TEST].to_i, record2[:TEST].to_i - 1)
      size += 2
    end

    assert_equal(4, size)
  end
end
