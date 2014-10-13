#!/usr/bin/env ruby
$:.unshift File.join(File.dirname(__FILE__), '..', '..', '..')

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #
#                                                                                #
# Copyright (C) 2007-2014 Martin Asser Hansen (mail@maasha.dk).                  #
#                                                                                #
# This program is free software; you can redistribute it and/or                  #
# modify it under the terms of the GNU General Public License                    #
# as published by the Free Software Foundation; either version 2                 #
# of the License, or (at your option) any later version.                         #
#                                                                                #
# This program is distributed in the hope that it will be useful,                #
# but WITHOUT ANY WARRANTY; without even the implied warranty of                 #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                  #
# GNU General Public License for more details.                                   #
#                                                                                #
# You should have received a copy of the GNU General Public License              #
# along with this program; if not, write to the Free Software                    #
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA. #
#                                                                                #
# http://www.gnu.org/copyleft/gpl.html                                           #
#                                                                                #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #
#                                                                                #
# This software is part of Biopieces (www.biopieces.org).                        #
#                                                                                #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

require 'test/helper'

class TestAddKey < Test::Unit::TestCase 
  def setup
    hash1 = {one: 1, two: 2, three: 3}
    hash2 = {SEQ_NAME: "test1", SEQ: "atcg", SEQ_LEN: 4}
    hash3 = {SEQ_NAME: "test2", SEQ: "gtac", SEQ_LEN: 4}

    @input, @output   = BioPieces::Stream.pipe
    @input2, @output2 = BioPieces::Stream.pipe

    @output.write hash1
    @output.write hash2
    @output.write hash3
    @output.close

    @p = BioPieces::Pipeline.new
  end

  test "BioPieces::Pipeline#add_key with disallowed option raises" do
    assert_raise(BioPieces::OptionError) { @p.add_key(foo: "bar") }
  end

  test "BioPieces::Pipeline#add_key with value and prefix options raise" do
    assert_raise(BioPieces::OptionError) { @p.add_key(key: "SEQ_NAME", value: "fobar", prefix: "foo") }
  end

  test "BioPieces::Pipeline#add_key with allowed options don't raise" do
    assert_nothing_raised { @p.add_key(key: "SEQ_NAME", value: "fobar") }
  end

  test "BioPieces::Pipeline#add_key with value returns correctly" do
    @p.add_key(key: "SEQ_NAME", value: "fobar").run(input: @input, output: @output2)
    result   = @input2.map { |h| h.to_s }.reduce(:<<)
    expected = ""
    expected << %Q{{:one=>1, :two=>2, :three=>3, :SEQ_NAME=>"fobar"}}
    expected << %Q{{:SEQ_NAME=>"fobar", :SEQ=>"atcg", :SEQ_LEN=>4}}
    expected << %Q{{:SEQ_NAME=>"fobar", :SEQ=>"gtac", :SEQ_LEN=>4}}

    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline#add_key with empty prefix returns correctly" do
    @p.add_key(key: "SEQ_NAME", prefix: "").run(input: @input, output: @output2)
    result   = @input2.map { |h| h.to_s }.reduce(:<<)
    expected = ""
    expected << %Q{{:one=>1, :two=>2, :three=>3, :SEQ_NAME=>"0"}}
    expected << %Q{{:SEQ_NAME=>"1", :SEQ=>"atcg", :SEQ_LEN=>4}}
    expected << %Q{{:SEQ_NAME=>"2", :SEQ=>"gtac", :SEQ_LEN=>4}}

    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline#add_key with prefix returns correctly" do
    @p.add_key(key: "SEQ_NAME", prefix: "ID_").run(input: @input, output: @output2)
    result   = @input2.map { |h| h.to_s }.reduce(:<<)
    expected = ""
    expected << %Q{{:one=>1, :two=>2, :three=>3, :SEQ_NAME=>"ID_0"}}
    expected << %Q{{:SEQ_NAME=>"ID_1", :SEQ=>"atcg", :SEQ_LEN=>4}}
    expected << %Q{{:SEQ_NAME=>"ID_2", :SEQ=>"gtac", :SEQ_LEN=>4}}

    assert_equal(expected, result)
  end
end
