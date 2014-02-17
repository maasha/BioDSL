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

class TestGrab < Test::Unit::TestCase 
  def setup
    @input, @output   = BioPieces::Pipeline::Stream.pipe
    @input2, @output2 = BioPieces::Pipeline::Stream.pipe

    hash1 = {SEQ_NAME: "test1", SEQ: "atcg", SEQ_LEN: 4}
    hash2 = {SEQ_NAME: "test2", SEQ: "DSEQM", SEQ_LEN: 5}
    hash3 = {FOO: "SEQ"}

    @output.write hash1
    @output.write hash2
    @output.write hash3
    @output.close
  end

  test "BioPieces::Pipeline::Grab with invalid options raises" do
    command = BioPieces::Pipeline::Command.new(:grab, foo: "bar")
    assert_raise(BioPieces::OptionError) { command.run(nil, nil) }
  end

  test "BioPieces::Pipeline::Grab with select and reject options raises" do
    command = BioPieces::Pipeline::Command.new(:grab, select: "foo", reject: "bar")
    assert_raise(BioPieces::OptionError) { command.run(nil, nil) }
  end

  test "BioPieces::Pipeline::Grab with keys_only and values_only options raises" do
    command = BioPieces::Pipeline::Command.new(:grab, select: "foo", keys_only: true, values_only: true)
    assert_raise(BioPieces::OptionError) { command.run(nil, nil) }
  end

  test "BioPieces::Pipeline::Grab with select and no hits return correctly" do
    command = BioPieces::Pipeline::Command.new(:grab, select: "fish")
    command.run(@input, @output2)

    stream_result = @input2.map { |h| h.to_s }.reduce(:<<)
    assert_nil(stream_result)
  end

  test "BioPieces::Pipeline::Grab with select and key hit return correctly" do
    command = BioPieces::Pipeline::Command.new(:grab, select: "SEQ_NAME")
    command.run(@input, @output2)

    stream_result = @input2.map { |h| h.to_s }.reduce(:<<)
    stream_expected = ""
    stream_expected << '{:SEQ_NAME=>"test1", :SEQ=>"atcg", :SEQ_LEN=>4}'
    stream_expected << '{:SEQ_NAME=>"test2", :SEQ=>"DSEQM", :SEQ_LEN=>5}'
    assert_equal(stream_expected, stream_result)
  end

  test "BioPieces::Pipeline::Grab with select and value hit return correctly" do
    command = BioPieces::Pipeline::Command.new(:grab, select: "test1")
    command.run(@input, @output2)

    stream_result = @input2.map { |h| h.to_s }.reduce(:<<)
    stream_expected = '{:SEQ_NAME=>"test1", :SEQ=>"atcg", :SEQ_LEN=>4}'
    assert_equal(stream_expected, stream_result)
  end

  test "BioPieces::Pipeline::Grab with select and keys_only return correctly" do
    command = BioPieces::Pipeline::Command.new(:grab, select: "SEQ", keys_only: true)
    command.run(@input, @output2)

    stream_result = @input2.map { |h| h.to_s }.reduce(:<<)
    stream_expected = ""
    stream_expected << '{:SEQ_NAME=>"test1", :SEQ=>"atcg", :SEQ_LEN=>4}'
    stream_expected << '{:SEQ_NAME=>"test2", :SEQ=>"DSEQM", :SEQ_LEN=>5}'
    assert_equal(stream_expected, stream_result)
  end

  test "BioPieces::Pipeline::Grab with select and values_only return correctly" do
    command = BioPieces::Pipeline::Command.new(:grab, select: "SEQ", values_only: true)
    command.run(@input, @output2)

    stream_result = @input2.map { |h| h.to_s }.reduce(:<<)
    stream_expected = ""
    stream_expected << '{:SEQ_NAME=>"test2", :SEQ=>"DSEQM", :SEQ_LEN=>5}'
    stream_expected << '{:FOO=>"SEQ"}'
    assert_equal(stream_expected, stream_result)
  end
end

