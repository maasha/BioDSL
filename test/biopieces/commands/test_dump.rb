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

class TestDump < Test::Unit::TestCase 
  def setup
    @hash1  = {one: 1, two: 2, three: 3}
    @hash2  = {SEQ_NAME: "test1", SEQ: "atcg", SEQ_LEN: 4}
    @hash3  = {SEQ_NAME: "test2", SEQ: "gtac", SEQ_LEN: 4}

    @p      = BioPieces::Pipeline.new
    @input  = StringIO.new("")
    @output = StringIO.new("")
  end

  test "BioPieces::Pipeline#dump with disallowed option raises" do
    assert_raise(BioPieces::OptionError) { @p.dump(foo: "bar") }
  end

  test "BioPieces::Pipeline#dump with bad first raises" do
    assert_raise(BioPieces::OptionError) { @p.dump(first: 0) }
  end

  test "BioPieces::Pipeline#dump with bad last raises" do
    assert_raise(BioPieces::OptionError) { @p.dump(last: 0) }
  end

  test "BioPieces::Pipeline#dump with first and last raises" do
    assert_raise(BioPieces::OptionError) { @p.dump(first: 1, last: 1) }
  end

  test "BioPieces::Pipeline#dump returns correctly" do
    @input.string = PP.pp(@hash2, '') + PP.pp(@hash3, '')
    stdout_result = capture_stdout { @p.dump.run(input: @input, output: @output) }
    stream_result = @output.string

    stdout_expected = %{\"{:SEQ_NAME=>\\\"test1\\\", :SEQ=>\\\"atcg\\\", :SEQ_LEN=>4}\\n\"\n\"{:SEQ_NAME=>\\\"test2\\\", :SEQ=>\\\"gtac\\\", :SEQ_LEN=>4}\\n\"}
    stream_expected = "{:SEQ_NAME=>\"test1\", :SEQ=>\"atcg\", :SEQ_LEN=>4}\n{:SEQ_NAME=>\"test2\", :SEQ=>\"gtac\", :SEQ_LEN=>4}\n"

    assert_equal(stdout_expected, stdout_result.chomp)
    assert_equal(stream_expected, stream_result)
  end

  test "BioPieces::Pipeline#dump with options[first: 1] returns correctly" do
    @input.string = PP.pp(@hash2, '') + PP.pp(@hash3, '')
    stdout_result = capture_stdout { @p.dump(first: 1).run(input: @input, output: @output) }
    stream_result = @output.string

    stdout_expected = %{\"{:SEQ_NAME=>\\\"test1\\\", :SEQ=>\\\"atcg\\\", :SEQ_LEN=>4}\\n\"}
    stream_expected = "{:SEQ_NAME=>\"test1\", :SEQ=>\"atcg\", :SEQ_LEN=>4}\n"

    assert_equal(stdout_expected, stdout_result.chomp)
    assert_equal(stream_expected, stream_result)
  end

  test "BioPieces::Pipeline#dump with options[last: 1] returns correctly" do
    @input.string = PP.pp(@hash2, '') + PP.pp(@hash3, '')
    stdout_result = capture_stdout { @p.dump(last: 1).run(input: @input, output: @output) }
    stream_result = @output.string

    stdout_expected = %{\"{:SEQ_NAME=>\\\"test2\\\", :SEQ=>\\\"gtac\\\", :SEQ_LEN=>4}\\n\"}
    stream_expected = "{:SEQ_NAME=>\"test2\", :SEQ=>\"gtac\", :SEQ_LEN=>4}\n"

    assert_equal(stdout_expected, stdout_result.chomp)
    assert_equal(stream_expected, stream_result)
  end
end
