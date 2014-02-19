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
    @input1, @output1 = BioPieces::Pipeline::Stream.pipe
    @input2, @output2 = BioPieces::Pipeline::Stream.pipe
    @hash             = {one: 1, two: 2, three: 3}

    hash1 = {SEQ_NAME: "test1", SEQ: "atcg", SEQ_LEN: 4}
    hash2 = {SEQ_NAME: "test2", SEQ: "gtac", SEQ_LEN: 4}

    @output1.write hash1
    @output1.write hash2
    @output1.close
  end

  test "BioPieces::Pipeline#dump with disallowed option raises" do
    assert_raise(BioPieces::OptionError) { BioPieces::Pipeline::Command.new(:dump, foo: "bar") }
  end

  test "BioPieces::Pipeline#dump with first and last raises" do
    assert_raise(BioPieces::OptionError) { BioPieces::Pipeline::Command.new(:dump, first: 1, last: 1) }
  end

  test "BioPieces::Pipeline#dump returns correctly" do
    command = BioPieces::Pipeline::Command.new(:dump)

    stdout_result = capture_stdout { command.run(@input1, @output2) }
    stream_result = @input2.map { |h| h.to_s }.reduce(:<<)

    stdout_expected = "{:SEQ_NAME=>\"test1\", :SEQ=>\"atcg\", :SEQ_LEN=>4}\n{:SEQ_NAME=>\"test2\", :SEQ=>\"gtac\", :SEQ_LEN=>4}"
    stream_expected = "{:SEQ_NAME=>\"test1\", :SEQ=>\"atcg\", :SEQ_LEN=>4}{:SEQ_NAME=>\"test2\", :SEQ=>\"gtac\", :SEQ_LEN=>4}"

    assert_equal(stdout_expected, stdout_result.chomp)
    assert_equal(stream_expected, stream_result)
  end

  test "BioPieces::Pipeline#dump with options[first: 1] returns correctly" do
    command = BioPieces::Pipeline::Command.new(:dump, first: 1)

    stdout_result = capture_stdout { command.run(@input1, @output2) }
    stream_result = @input2.map { |h| h.to_s }.reduce(:<<)

    stdout_expected = "{:SEQ_NAME=>\"test1\", :SEQ=>\"atcg\", :SEQ_LEN=>4}"
    stream_expected = "{:SEQ_NAME=>\"test1\", :SEQ=>\"atcg\", :SEQ_LEN=>4}"

    assert_equal(stdout_expected, stdout_result.chomp)
    assert_equal(stream_expected, stream_result)
  end

  test "BioPieces::Pipeline#dump with options[last: 1] returns correctly" do
    command = BioPieces::Pipeline::Command.new(:dump, last: 1)

    stdout_result = capture_stdout { command.run(@input1, @output2) }
    stream_result = @input2.map { |h| h.to_s }.reduce(:<<)

    stdout_expected = "{:SEQ_NAME=>\"test2\", :SEQ=>\"gtac\", :SEQ_LEN=>4}"
    stream_expected = "{:SEQ_NAME=>\"test2\", :SEQ=>\"gtac\", :SEQ_LEN=>4}"

    assert_equal(stdout_expected, stdout_result.chomp)
    assert_equal(stream_expected, stream_result)
  end
end
