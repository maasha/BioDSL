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
    @tmpdir        = Dir.mktmpdir("BioPieces")
    @pattern_file  = File.join(@tmpdir, 'patterns.txt')
    @pattern_file2 = File.join(@tmpdir, 'patterns2.txt')

    File.open(@pattern_file, 'w') do |ios|
      ios.puts "test"
      ios.puts "seq"
    end

    File.open(@pattern_file2, 'w') do |ios|
      ios.puts 4
      ios.puts "SEQ"
    end

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

  def teardown
    FileUtils.rm_r @tmpdir
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

  test "BioPieces::Pipeline::Grab with evaluate and conflicting keys raises" do
    assert_raise(BioPieces::OptionError) { BioPieces::Pipeline::Command.new(:grab, evaluate: 0, select: "foo").run(nil, nil) }
    assert_raise(BioPieces::OptionError) { BioPieces::Pipeline::Command.new(:grab, evaluate: 0, reject: "foo").run(nil, nil) }
    assert_raise(BioPieces::OptionError) { BioPieces::Pipeline::Command.new(:grab, evaluate: 0, keys: "foo").run(nil, nil) }
    assert_raise(BioPieces::OptionError) { BioPieces::Pipeline::Command.new(:grab, evaluate: 0, keys_only: true).run(nil, nil) }
    assert_raise(BioPieces::OptionError) { BioPieces::Pipeline::Command.new(:grab, evaluate: 0, values_only: true).run(nil, nil) }
    assert_raise(BioPieces::OptionError) { BioPieces::Pipeline::Command.new(:grab, evaluate: 0, ignore_case: true).run(nil, nil) }
    assert_raise(BioPieces::OptionError) { BioPieces::Pipeline::Command.new(:grab, evaluate: 0, exact: true).run(nil, nil) }
  end

  test "BioPieces::Pipeline::Grab with missing select_file raises" do
    command = BioPieces::Pipeline::Command.new(:grab, select_file: "___dsfew")
    assert_raise(BioPieces::OptionError) { command.run(nil, nil) }
  end

  test "BioPieces::Pipeline::Grab with missing reject_file raises" do
    command = BioPieces::Pipeline::Command.new(:grab, reject_file: "___dsfew")
    assert_raise(BioPieces::OptionError) { command.run(nil, nil) }
  end

  test "BioPieces::Pipeline::Grab with no hits return correctly" do
    command = BioPieces::Pipeline::Command.new(:grab, select: "fish")
    command.run(@input, @output2)

    stream_result = @input2.map { |h| h.to_s }.reduce(:<<)
    assert_nil(stream_result)
  end

  test "BioPieces::Pipeline::Grab with select and key hit return correctly" do
    command = BioPieces::Pipeline::Command.new(:grab, select: "SEQ_NAME")
    command.run(@input, @output2)

    stream_result   = @input2.map { |h| h.to_s }.reduce(:<<)
    stream_expected = ""
    stream_expected << '{:SEQ_NAME=>"test1", :SEQ=>"atcg", :SEQ_LEN=>4}'
    stream_expected << '{:SEQ_NAME=>"test2", :SEQ=>"DSEQM", :SEQ_LEN=>5}'
    assert_equal(stream_expected, stream_result)
  end

  test "BioPieces::Pipeline::Grab with multiple select patterns return correctly" do
    command = BioPieces::Pipeline::Command.new(:grab, select: ["est1", "QM"])
    command.run(@input, @output2)

    stream_result   = @input2.map { |h| h.to_s }.reduce(:<<)
    stream_expected = ""
    stream_expected << '{:SEQ_NAME=>"test1", :SEQ=>"atcg", :SEQ_LEN=>4}'
    stream_expected << '{:SEQ_NAME=>"test2", :SEQ=>"DSEQM", :SEQ_LEN=>5}'
    assert_equal(stream_expected, stream_result)
  end

  test "BioPieces::Pipeline::Grab with multiple reject patterns return correctly" do
    command = BioPieces::Pipeline::Command.new(:grab, reject: ["est1", "QM"])
    command.run(@input, @output2)

    stream_result   = @input2.map { |h| h.to_s }.reduce(:<<)
    stream_expected = '{:FOO=>"SEQ"}'
    assert_equal(stream_expected, stream_result)
  end

  test "BioPieces::Pipeline::Grab with reject and key hit return correctly" do
    command = BioPieces::Pipeline::Command.new(:grab, reject: "SEQ_NAME")
    command.run(@input, @output2)

    stream_result   = @input2.map { |h| h.to_s }.reduce(:<<)
    stream_expected = '{:FOO=>"SEQ"}'
    assert_equal(stream_expected, stream_result)
  end

  test "BioPieces::Pipeline::Grab with select and value hit return correctly" do
    command = BioPieces::Pipeline::Command.new(:grab, select: "test1")
    command.run(@input, @output2)

    stream_result   = @input2.map { |h| h.to_s }.reduce(:<<)
    stream_expected = '{:SEQ_NAME=>"test1", :SEQ=>"atcg", :SEQ_LEN=>4}'
    assert_equal(stream_expected, stream_result)
  end

  test "BioPieces::Pipeline::Grab with reject and value hit return correctly" do
    command = BioPieces::Pipeline::Command.new(:grab, reject: "test1")
    command.run(@input, @output2)

    stream_result   = @input2.map { |h| h.to_s }.reduce(:<<)
    stream_expected = ""
    stream_expected << '{:SEQ_NAME=>"test2", :SEQ=>"DSEQM", :SEQ_LEN=>5}'
    stream_expected << '{:FOO=>"SEQ"}'
    assert_equal(stream_expected, stream_result)
  end

  test "BioPieces::Pipeline::Grab with select and keys_only return correctly" do
    command = BioPieces::Pipeline::Command.new(:grab, select: "SEQ", keys_only: true)
    command.run(@input, @output2)

    stream_result   = @input2.map { |h| h.to_s }.reduce(:<<)
    stream_expected = ""
    stream_expected << '{:SEQ_NAME=>"test1", :SEQ=>"atcg", :SEQ_LEN=>4}'
    stream_expected << '{:SEQ_NAME=>"test2", :SEQ=>"DSEQM", :SEQ_LEN=>5}'
    assert_equal(stream_expected, stream_result)
  end

  test "BioPieces::Pipeline::Grab with reject and keys_only return correctly" do
    command = BioPieces::Pipeline::Command.new(:grab, reject: "SEQ", keys_only: true)
    command.run(@input, @output2)

    stream_result   = @input2.map { |h| h.to_s }.reduce(:<<)
    stream_expected = '{:FOO=>"SEQ"}'
    assert_equal(stream_expected, stream_result)
  end

  test "BioPieces::Pipeline::Grab with select and values_only return correctly" do
    command = BioPieces::Pipeline::Command.new(:grab, select: "SEQ", values_only: true)
    command.run(@input, @output2)

    stream_result   = @input2.map { |h| h.to_s }.reduce(:<<)
    stream_expected = ""
    stream_expected << '{:SEQ_NAME=>"test2", :SEQ=>"DSEQM", :SEQ_LEN=>5}'
    stream_expected << '{:FOO=>"SEQ"}'
    assert_equal(stream_expected, stream_result)
  end

  test "BioPieces::Pipeline::Grab with reject and values_only return correctly" do
    command = BioPieces::Pipeline::Command.new(:grab, reject: "SEQ", values_only: true)
    command.run(@input, @output2)

    stream_result   = @input2.map { |h| h.to_s }.reduce(:<<)
    stream_expected = '{:SEQ_NAME=>"test1", :SEQ=>"atcg", :SEQ_LEN=>4}'
    assert_equal(stream_expected, stream_result)
  end

  test "BioPieces::Pipeline::Grab with select and values_only and anchor return correctly" do
    command = BioPieces::Pipeline::Command.new(:grab, select: "^SEQ", values_only: true)
    command.run(@input, @output2)

    stream_result   = @input2.map { |h| h.to_s }.reduce(:<<)
    stream_expected = '{:FOO=>"SEQ"}'
    assert_equal(stream_expected, stream_result)
  end

  test "BioPieces::Pipeline::Grab with reject and values_only and anchor return correctly" do
    command = BioPieces::Pipeline::Command.new(:grab, reject: "^SEQ", values_only: true)
    command.run(@input, @output2)

    stream_result   = @input2.map { |h| h.to_s }.reduce(:<<)
    stream_expected = ""
    stream_expected << '{:SEQ_NAME=>"test1", :SEQ=>"atcg", :SEQ_LEN=>4}'
    stream_expected << '{:SEQ_NAME=>"test2", :SEQ=>"DSEQM", :SEQ_LEN=>5}'
    assert_equal(stream_expected, stream_result)
  end

  test "BioPieces::Pipeline::Grab with select and ignore_case return correctly" do
    command = BioPieces::Pipeline::Command.new(:grab, select: "ATCG", ignore_case: true)
    command.run(@input, @output2)

    stream_result   = @input2.map { |h| h.to_s }.reduce(:<<)
    stream_expected = '{:SEQ_NAME=>"test1", :SEQ=>"atcg", :SEQ_LEN=>4}'
    assert_equal(stream_expected, stream_result)
  end

  test "BioPieces::Pipeline::Grab with reject and ignore_case return correctly" do
    command = BioPieces::Pipeline::Command.new(:grab, reject: "ATCG", ignore_case: true)
    command.run(@input, @output2)

    stream_result   = @input2.map { |h| h.to_s }.reduce(:<<)
    stream_expected = ""
    stream_expected << '{:SEQ_NAME=>"test2", :SEQ=>"DSEQM", :SEQ_LEN=>5}'
    stream_expected << '{:FOO=>"SEQ"}'
    assert_equal(stream_expected, stream_result)
  end

  test "BioPieces::Pipeline::Grab with select and specified keys return correctly" do
    command = BioPieces::Pipeline::Command.new(:grab, select: "SEQ", keys: :FOO)
    command.run(@input, @output2)

    stream_result   = @input2.map { |h| h.to_s }.reduce(:<<)
    stream_expected = '{:FOO=>"SEQ"}'
    assert_equal(stream_expected, stream_result)
  end

  test "BioPieces::Pipeline::Grab with select and multiple keys in Array return correctly" do
    command = BioPieces::Pipeline::Command.new(:grab, select: "SEQ", keys: [:FOO, :SEQ])
    command.run(@input, @output2)

    stream_result   = @input2.map { |h| h.to_s }.reduce(:<<)
    stream_expected = ""
    stream_expected << '{:SEQ_NAME=>"test2", :SEQ=>"DSEQM", :SEQ_LEN=>5}'
    stream_expected << '{:FOO=>"SEQ"}'
    assert_equal(stream_expected, stream_result)
  end

  test "BioPieces::Pipeline::Grab with select and multiple keys in String return correctly" do
    command = BioPieces::Pipeline::Command.new(:grab, select: "SEQ", keys: ":FOO, :SEQ")
    command.run(@input, @output2)

    stream_result   = @input2.map { |h| h.to_s }.reduce(:<<)
    stream_expected = ""
    stream_expected << '{:SEQ_NAME=>"test2", :SEQ=>"DSEQM", :SEQ_LEN=>5}'
    stream_expected << '{:FOO=>"SEQ"}'
    assert_equal(stream_expected, stream_result)
  end

  test "BioPieces::Pipeline::Grab with reject and specified keys return correctly" do
    command = BioPieces::Pipeline::Command.new(:grab, reject: "SEQ", keys: :FOO)
    command.run(@input, @output2)

    stream_result   = @input2.map { |h| h.to_s }.reduce(:<<)
    stream_expected = ""
    stream_expected << '{:SEQ_NAME=>"test1", :SEQ=>"atcg", :SEQ_LEN=>4}'
    stream_expected << '{:SEQ_NAME=>"test2", :SEQ=>"DSEQM", :SEQ_LEN=>5}'
    assert_equal(stream_expected, stream_result)
  end

  test "BioPieces::Pipeline::Grab with evaluate return correctly" do
    command = BioPieces::Pipeline::Command.new(:grab, evaluate: ":SEQ_LEN > 4")
    command.run(@input, @output2)

    stream_result   = @input2.map { |h| h.to_s }.reduce(:<<)
    stream_expected = '{:SEQ_NAME=>"test2", :SEQ=>"DSEQM", :SEQ_LEN=>5}'
    assert_equal(stream_expected, stream_result)
  end

  test "BioPieces::Pipeline::Grab with select_file return correctly" do
    command = BioPieces::Pipeline::Command.new(:grab, select_file: @pattern_file)
    command.run(@input, @output2)

    stream_result   = @input2.map { |h| h.to_s }.reduce(:<<)
    stream_expected = ""
    stream_expected << '{:SEQ_NAME=>"test1", :SEQ=>"atcg", :SEQ_LEN=>4}'
    stream_expected << '{:SEQ_NAME=>"test2", :SEQ=>"DSEQM", :SEQ_LEN=>5}'
    assert_equal(stream_expected, stream_result)
  end

  test "BioPieces::Pipeline::Grab with select and exact without match return correctly" do
    command = BioPieces::Pipeline::Command.new(:grab, select: "tcg", exact: true)
    command.run(@input, @output2)

    stream_result = @input2.map { |h| h.to_s }.reduce(:<<)
    assert_nil(stream_result)
  end

  test "BioPieces::Pipeline::Grab with select and exact with match return correctly" do
    command = BioPieces::Pipeline::Command.new(:grab, select: "atcg", exact: true)
    command.run(@input, @output2)

    stream_result   = @input2.map { |h| h.to_s }.reduce(:<<)
    stream_expected = '{:SEQ_NAME=>"test1", :SEQ=>"atcg", :SEQ_LEN=>4}'
    assert_equal(stream_expected, stream_result)
  end

  test "BioPieces::Pipeline::Grab with reject_file return correctly" do
    command = BioPieces::Pipeline::Command.new(:grab, reject_file: @pattern_file2, keys: :SEQ)
    command.run(@input, @output2)

    stream_result   = @input2.map { |h| h.to_s }.reduce(:<<)
    stream_expected = ""
    stream_expected << '{:SEQ_NAME=>"test1", :SEQ=>"atcg", :SEQ_LEN=>4}'
    stream_expected << '{:FOO=>"SEQ"}'
    assert_equal(stream_expected, stream_result)
  end
end

