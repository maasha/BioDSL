#!/usr/bin/env ruby
$:.unshift File.join(File.dirname(__FILE__), '..', '..', '..')

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #
#                                                                                #
# Copyright (C) 2007-2015 Martin Asser Hansen (mail@maasha.dk).                  #
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

class TestSplitValues < Test::Unit::TestCase 
  def setup
    @input, @output   = BioPieces::Stream.pipe
    @input2, @output2 = BioPieces::Stream.pipe

    @output.write({ID: "FOO:count=10", SEQ: "gataag"})
    @output.write({ID: "FOO_10_20", SEQ: "gataag"})
    @output.close

    @p = BioPieces::Pipeline.new
  end

  test "BioPieces::Pipeline::SplitValues with invalid options raises" do
    assert_raise(BioPieces::OptionError) { @p.split_values(foo: "bar") }
  end

  test "BioPieces::Pipeline::SplitValues with valid options don't raise" do
    assert_nothing_raised { @p.split_values(key: :ID) }
  end

  test "BioPieces::Pipeline::SplitValues returns correctly" do
    @p.split_values(key: :ID).run(input: @input, output: @output2)

    result   = @input2.map { |h| h.to_s }.reduce(:<<)
    expected = '{:ID=>"FOO:count=10", :SEQ=>"gataag"}{:ID=>"FOO_10_20", :SEQ=>"gataag", :ID_0=>"FOO", :ID_1=>10, :ID_2=>20}'

    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::SplitValues with :delimiter returns correctly" do
    @p.split_values(key: "ID", delimiter: ':count=').run(input: @input, output: @output2)

    result   = @input2.map { |h| h.to_s }.reduce(:<<)
    expected = '{:ID=>"FOO:count=10", :SEQ=>"gataag", :ID_0=>"FOO", :ID_1=>10}{:ID=>"FOO_10_20", :SEQ=>"gataag"}'

    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::SplitValues with :delimiter and :keys returns correctly" do
    @p.split_values(key: "ID", keys: ["ID", :COUNT], delimiter: ':count=').run(input: @input, output: @output2)

    result   = @input2.map { |h| h.to_s }.reduce(:<<)
    expected = '{:ID=>"FOO", :SEQ=>"gataag", :COUNT=>10}{:ID=>"FOO_10_20", :SEQ=>"gataag"}'

    assert_equal(expected, result)
  end
end
