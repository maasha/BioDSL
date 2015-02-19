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

class TestUniqueValues < Test::Unit::TestCase 
  def setup
    @input, @output   = BioPieces::Stream.pipe
    @input2, @output2 = BioPieces::Stream.pipe

    [ {V0: "HUMAN", V1: "H1"},
      {V0: "HUMAN", V1: "H2"},
      {V0: "HUMAN", V1: "H3"},
      {V0: "DOG",   V1: "D1"},
      {V0: "DOG",   V1: "D2"},
      {V0: "MOUSE", V1: "M1"},
      {FOO: "BAR"}
    ].each do |record|
      @output.write record
    end

    @output.close

    @p = BioPieces::Pipeline.new
  end

  test "BioPieces::Pipeline#unique_values with disallowed option raises" do
    assert_raise(BioPieces::OptionError) { @p.unique_values(key: :V0, foo: "bar") }
  end

  test "BioPieces::Pipeline#unique_values with allowed options don't raise" do
    assert_nothing_raised { @p.unique_values(key: :V0) }
  end

  test "BioPieces::Pipeline#unique_values returns correctly" do
    @p.unique_values(key: "V0").run(input: @input, output: @output2)

    result   = @input2.map { |h| h.to_s }.reduce(:<<)
    expected = ""
    expected << '{:V0=>"HUMAN", :V1=>"H1"}'
    expected << '{:V0=>"DOG", :V1=>"D1"}'
    expected << '{:V0=>"MOUSE", :V1=>"M1"}'
    expected << '{:FOO=>"BAR"}'

    assert_equal(expected, result)
  end

  test "BioPieces::Pipeline#unique_values with options[:invert] returns correctly" do
    @p.unique_values(key: "V0", invert: true).run(input: @input, output: @output2)

    result   = @input2.map { |h| h.to_s }.reduce(:<<)
    expected = ""
    expected << '{:V0=>"HUMAN", :V1=>"H2"}'
    expected << '{:V0=>"HUMAN", :V1=>"H3"}'
    expected << '{:V0=>"DOG", :V1=>"D2"}'
    expected << '{:FOO=>"BAR"}'

    assert_equal(expected, result)
  end
end
