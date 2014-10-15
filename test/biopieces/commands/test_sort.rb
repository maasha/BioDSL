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

class TestSort < Test::Unit::TestCase 
  def setup
    @input, @output   = BioPieces::Stream.pipe
    @input2, @output2 = BioPieces::Stream.pipe

    @output.write({NAME: "test2", COUNT: 4})
    @output.write({NAME: "test1", COUNT: 21})
    @output.write({NAME: "test2", COUNT: 2})
    @output.write({NAME: "test3", COUNT: 9})
    @output.close

    @p = BioPieces::Pipeline.new
  end

  test "BioPieces::Pipeline::Sort with invalid options raises" do
    assert_raise(BioPieces::OptionError) { @p.sort(key: :COUNT, foo: "bar") }
  end

  test "BioPieces::Pipeline::Sort with valid options don't raise" do
    assert_nothing_raised { @p.sort(key: :COUNT) }
  end

  test "BioPieces::Pipeline::Sort alphabetical returns correctly" do
    @p.sort(key: "NAME").run(input: @input, output: @output2)

    result   = @input2.map { |h| h.to_s }.reduce(:<<)
    expected = %Q{{:NAME=>"test1", :COUNT=>21}{:NAME=>"test2", :COUNT=>4}{:NAME=>"test2", :COUNT=>2}{:NAME=>"test3", :COUNT=>9}}

    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::Sort numerical returns correctly" do
    @p.sort(key: :COUNT).run(input: @input, output: @output2)

    result   = @input2.map { |h| h.to_s }.reduce(:<<)
    expected = %Q{{:NAME=>"test2", :COUNT=>2}{:NAME=>"test2", :COUNT=>4}{:NAME=>"test3", :COUNT=>9}{:NAME=>"test1", :COUNT=>21}}

    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::Sort reverse returns correctly" do
    @p.sort(key: :COUNT, reverse: true).run(input: @input, output: @output2)

    result   = @input2.map { |h| h.to_s }.reduce(:<<)
    expected = %Q{{:NAME=>"test1", :COUNT=>21}{:NAME=>"test3", :COUNT=>9}{:NAME=>"test2", :COUNT=>4}{:NAME=>"test2", :COUNT=>2}}

    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::Sort with block_size returns correctly" do
    @p.sort(key: :COUNT, block_size: 60).run(input: @input, output: @output2)

    result   = @input2.map { |h| h.to_s }.reduce(:<<)
    expected = %Q{{:NAME=>"test2", :COUNT=>2}{:NAME=>"test2", :COUNT=>4}{:NAME=>"test3", :COUNT=>9}{:NAME=>"test1", :COUNT=>21}}

    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline::Sort with block_size and reverse returns correctly" do
    @p.sort(key: :COUNT, block_size: 30, reverse: true).run(input: @input, output: @output2)

    result   = @input2.map { |h| h.to_s }.reduce(:<<)
    expected = %Q{{:NAME=>"test1", :COUNT=>21}{:NAME=>"test3", :COUNT=>9}{:NAME=>"test2", :COUNT=>4}{:NAME=>"test2", :COUNT=>2}}

    assert_equal(expected, result)
  end
end
