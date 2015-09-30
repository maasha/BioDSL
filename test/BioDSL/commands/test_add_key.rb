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
# This software is part of BioDSL (www.github.com/maasha/BioDSL).              #
#                                                                              #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

require 'test/helper'

# Test class for AddKey.
class TestAddKey < Test::Unit::TestCase
  def setup
    @input, @output   = BioDSL::Stream.pipe
    @input2, @output2 = BioDSL::Stream.pipe

    @output.write(one: 1, two: 2, three: 3)
    @output.write(SEQ_NAME: 'test1', SEQ: 'atcg', SEQ_LEN: 4)
    @output.write(SEQ_NAME: 'test2', SEQ: 'gtac', SEQ_LEN: 4)
    @output.close

    @p = BioDSL::Pipeline.new
  end

  test 'BioDSL::Pipeline#add_key with disallowed option raises' do
    assert_raise(BioDSL::OptionError) { @p.add_key(foo: 'bar') }
  end

  test 'BioDSL::Pipeline#add_key with value and prefix options raise' do
    assert_raise(BioDSL::OptionError) do
      @p.add_key(key: 'SEQ_NAME', value: 'foobar', prefix: 'foo')
    end
  end

  test 'BioDSL::Pipeline#add_key with allowed options don\'t raise' do
    assert_nothing_raised { @p.add_key(key: 'SEQ_NAME', value: 'fobar') }
  end

  test 'BioDSL::Pipeline#add_key status returns correctly' do
    @p.add_key(key: 'SEQ_NAME', value: 'fobar').
      run(input: @input, output: @output2)

    assert_equal(3, @p.status.last[:records_in])
    assert_equal(3, @p.status.last[:records_out])
  end

  test 'BioDSL::Pipeline#add_key with value returns correctly' do
    @p.add_key(key: 'SEQ_NAME', value: 'fobar').
      run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:one=>1, :two=>2, :three=>3, :SEQ_NAME=>"fobar"}
      |{:SEQ_NAME=>"fobar", :SEQ=>"atcg", :SEQ_LEN=>4}
      |{:SEQ_NAME=>"fobar", :SEQ=>"gtac", :SEQ_LEN=>4}
    EXP

    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline#add_key with empty prefix returns correctly' do
    @p.add_key(key: 'SEQ_NAME', prefix: '').run(input: @input, output: @output2)
    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:one=>1, :two=>2, :three=>3, :SEQ_NAME=>"0"}
      |{:SEQ_NAME=>"1", :SEQ=>"atcg", :SEQ_LEN=>4}
      |{:SEQ_NAME=>"2", :SEQ=>"gtac", :SEQ_LEN=>4}
    EXP

    assert_equal(expected, collect_result)
  end

  test 'BioDSL::Pipeline#add_key with prefix returns correctly' do
    @p.add_key(key: 'SEQ_NAME', prefix: 'ID_').
      run(input: @input, output: @output2)

    expected = <<-EXP.gsub(/^\s+\|/, '')
      |{:one=>1, :two=>2, :three=>3, :SEQ_NAME=>"ID_0"}
      |{:SEQ_NAME=>"ID_1", :SEQ=>"atcg", :SEQ_LEN=>4}
      |{:SEQ_NAME=>"ID_2", :SEQ=>"gtac", :SEQ_LEN=>4}
    EXP

    assert_equal(expected, collect_result)
  end
end
